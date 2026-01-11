import 'dart:async';
import 'package:dio/dio.dart';
import 'local_database_service.dart';
import 'outbox_service.dart';
import 'sync_status.dart';
import 'sync_outbox.dart';
import 'retry_handler.dart';
import 'connectivity_service.dart';
import 'sync_logger.dart';

/// Main sync engine that orchestrates offline-first data synchronization
/// 
/// This engine handles:
/// - Pushing local changes to the server (with retry and backoff)
/// - Pulling server changes to local database
/// - Conflict detection and resolution
/// - Idempotent request handling
class SyncEngine {
  final LocalDatabaseService _db;
  final OutboxService _outbox;
  final ConnectivityService _connectivity;
  final Dio _dio;
  final String _baseUrl;
  final RetryHandler _retryHandler;
  final SyncLogger _logger;

  bool _isSyncing = false;
  Timer? _syncTimer;
  StreamSubscription? _connectivitySubscription;

  /// Stream controller for sync status updates
  final _syncStatusController = StreamController<SyncState>.broadcast();
  Stream<SyncState> get syncStatus => _syncStatusController.stream;

  /// Current sync state
  SyncState _currentState = SyncState.idle;
  SyncState get currentState => _currentState;

  SyncEngine({
    required LocalDatabaseService db,
    required OutboxService outbox,
    required ConnectivityService connectivity,
    required String baseUrl,
    Dio? dio,
    RetryConfig? retryConfig,
  })  : _db = db,
        _outbox = outbox,
        _connectivity = connectivity,
        _baseUrl = baseUrl,
        _dio = dio ?? Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        )),
        _retryHandler = RetryHandler(config: retryConfig),
        _logger = SyncLogger();

  /// Initialize sync engine and start background sync
  Future<void> initialize() async {
    _logger.logSyncStart();
    
    // Listen for connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((isConnected) {
      if (isConnected && _currentState == SyncState.offline) {
        _logger.log('Connection restored, triggering sync');
        triggerSync();
      }
    });

    // Start periodic sync timer (every 30 seconds when online)
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_connectivity.isConnected && !_isSyncing) {
        triggerSync();
      }
    });

    // Initial sync if connected - don't await to avoid blocking app startup
    if (_connectivity.isConnected) {
      // Fire and forget - sync will happen in background
      triggerSync();
    } else {
      _updateState(SyncState.offline);
    }
  }

  /// Trigger a sync operation
  Future<SyncResult> triggerSync() async {
    if (_isSyncing) {
      _logger.log('Sync already in progress, skipping');
      return SyncResult.failure('Sync already in progress');
    }

    if (!_connectivity.isConnected) {
      _updateState(SyncState.offline);
      return SyncResult.failure('No network connection');
    }

    _isSyncing = true;
    _updateState(SyncState.syncing);
    _logger.logSyncStart();

    try {
      // Phase 1: Push local changes to server
      final pushResult = await _pushChanges();
      
      // Phase 2: Pull server changes
      final pullResult = await _pullChanges();

      _updateState(SyncState.idle);
      _logger.logSyncComplete(
        pushResult.success && pullResult.success,
        pushed: pushResult.processedCount,
        pulled: pullResult.processedCount,
      );

      return SyncResult.success(
        serverId: null,
        serverVersion: null,
      );
    } catch (e) {
      _logger.logError('Sync failed', e);
      _updateState(SyncState.error);
      return SyncResult.failure(e.toString());
    } finally {
      _isSyncing = false;
    }
  }

  /// Push local changes to server
  Future<_PushResult> _pushChanges() async {
    final pendingEntries = await _outbox.getPendingEntries(limit: 50);
    
    if (pendingEntries.isEmpty) {
      _logger.log('No pending changes to push');
      return _PushResult(success: true, processedCount: 0);
    }

    _logger.log('Pushing ${pendingEntries.length} pending changes');

    int successCount = 0;
    int failedCount = 0;

    // Process entries in batches
    final batches = _batchEntries(pendingEntries, batchSize: 10);
    
    for (final batch in batches) {
      try {
        final result = await _pushBatch(batch);
        successCount += result.successCount;
        failedCount += result.failedCount;
      } catch (e) {
        _logger.logError('Batch push failed', e);
        failedCount += batch.length;
      }
    }

    return _PushResult(
      success: failedCount == 0,
      processedCount: successCount,
      failedCount: failedCount,
    );
  }

  /// Push a batch of changes to server
  Future<_BatchResult> _pushBatch(List<OutboxEntry> entries) async {
    // Build batch request
    final operations = entries.map((entry) => SyncOperation(
      idempotencyKey: entry.idempotencyKey,
      entityType: entry.entityType.value,
      operationType: entry.operationType.value,
      entityId: entry.entityId,
      data: entry.payloadJson,
      version: entry.version,
    )).toList();

    final request = SyncBatchRequest(
      operations: operations,
      clientTimestamp: DateTime.now(),
    );

    // Mark entries as syncing
    for (final entry in entries) {
      await _outbox.markSyncing(entry.outboxId!);
    }

    try {
      final response = await _retryHandler.executeWithRetry(
        operation: () => _dio.post(
          '$_baseUrl/sync/push',
          data: request.toJson(),
        ),
        shouldRetryOnError: RetryableErrorClassifier.isRetryable,
        onRetry: (attempt, delay, error) {
          _logger.logRetry(attempt, delay, error.toString());
        },
      );

      final batchResponse = SyncBatchResponse.fromJson(response.data);
      return await _processBatchResponse(entries, batchResponse);
    } catch (e) {
      // Mark entries as failed
      for (final entry in entries) {
        final newRetryCount = entry.retryCount + 1;
        await _outbox.markFailed(
          entry.outboxId!,
          retryCount: newRetryCount,
          errorMessage: e.toString(),
          permanentFailure: !_retryHandler.shouldRetry(newRetryCount),
        );
      }
      rethrow;
    }
  }

  /// Process batch response and update local state
  Future<_BatchResult> _processBatchResponse(
    List<OutboxEntry> entries,
    SyncBatchResponse response,
  ) async {
    int successCount = 0;
    int failedCount = 0;

    // Map results by idempotency key
    final resultsMap = {
      for (final r in response.results) r.idempotencyKey: r
    };

    for (final entry in entries) {
      final result = resultsMap[entry.idempotencyKey];
      
      if (result == null) {
        failedCount++;
        await _outbox.markFailed(
          entry.outboxId!,
          retryCount: entry.retryCount + 1,
          errorMessage: 'No response for operation',
          permanentFailure: false,
        );
        continue;
      }

      if (result.success || result.isIdempotentReplay) {
        successCount++;
        await _outbox.markSynced(entry.outboxId!);
        
        // Update local record with server ID and version
        if (result.serverId != null) {
          await _updateLocalRecord(entry, result);
        }
      } else if (result.isConflict) {
        // Handle conflict
        _logger.logConflict(entry.entityType.value, entry.entityId);
        await _handleConflict(entry, result);
        failedCount++;
      } else {
        failedCount++;
        final newRetryCount = entry.retryCount + 1;
        await _outbox.markFailed(
          entry.outboxId!,
          retryCount: newRetryCount,
          errorMessage: result.errorMessage ?? 'Unknown error',
          permanentFailure: !_retryHandler.shouldRetry(newRetryCount),
        );
      }
    }

    return _BatchResult(successCount: successCount, failedCount: failedCount);
  }

  /// Update local record with server response data
  Future<void> _updateLocalRecord(OutboxEntry entry, SyncOperationResult result) async {
    final tableName = _getTableName(entry.entityType);
    
    await _db.updateSyncStatus(
      tableName,
      entry.entityId,
      status: SyncStatus.synced,
      serverId: result.serverId,
      version: result.serverVersion,
    );
  }

  /// Handle sync conflict
  Future<void> _handleConflict(OutboxEntry entry, SyncOperationResult result) async {
    // Default strategy: Last write wins (server wins)
    // The server data takes precedence
    if (result.serverData != null) {
      final tableName = _getTableName(entry.entityType);
      final serverData = result.serverData!;
      
      // Update local record with server version
      await _db.upsert(tableName, {
        ...serverData,
        'id': entry.entityId,
        'server_id': result.serverId,
        'version': result.serverVersion,
        'sync_status': SyncStatus.synced.value,
        'updated_at': DateTime.now().toIso8601String(),
      }, 'id');
      
      // Remove the conflicting outbox entry
      await _outbox.markSynced(entry.outboxId!);
    }
  }

  /// Pull changes from server
  Future<_PullResult> _pullChanges() async {
    int totalPulled = 0;

    // Pull each entity type
    for (final entityType in EntityType.values) {
      try {
        final pulled = await _pullEntityType(entityType);
        totalPulled += pulled;
      } catch (e) {
        _logger.logError('Failed to pull ${entityType.value}', e);
      }
    }

    return _PullResult(success: true, processedCount: totalPulled);
  }

  /// Pull changes for a specific entity type
  Future<int> _pullEntityType(EntityType entityType) async {
    final lastPull = await _db.getLastPullTimestamp(entityType);
    final since = lastPull?.toIso8601String();

    try {
      final response = await _dio.get(
        '$_baseUrl/sync/pull',
        queryParameters: {
          'entityType': entityType.value,
          if (since != null) 'since': since,
        },
      );

      final items = response.data['items'] as List;
      final serverTimestamp = DateTime.parse(response.data['serverTimestamp'] as String);

      if (items.isEmpty) {
        await _db.updateLastPullTimestamp(entityType, serverTimestamp);
        return 0;
      }

      final tableName = _getTableName(entityType);

      for (final item in items) {
        await _mergeServerItem(tableName, item as Map<String, dynamic>, entityType);
      }

      await _db.updateLastPullTimestamp(entityType, serverTimestamp);
      
      _logger.log('Pulled ${items.length} ${entityType.value} items');
      return items.length;
    } catch (e) {
      _logger.logError('Pull failed for ${entityType.value}', e);
      rethrow;
    }
  }

  /// Merge a server item into local database
  Future<void> _mergeServerItem(
    String tableName,
    Map<String, dynamic> serverItem,
    EntityType entityType,
  ) async {
    final serverId = serverItem['_id'] ?? serverItem['id'];
    final serverVersion = serverItem['version'] as int? ?? 1;
    
    // Check if we have a local record with this server ID
    final db = await _db.database;
    final existing = await db.query(
      tableName,
      where: 'server_id = ?',
      whereArgs: [serverId],
    );

    if (existing.isEmpty) {
      // New record from server - insert it
      final localData = _convertServerToLocal(serverItem, entityType);
      localData['server_id'] = serverId;
      localData['sync_status'] = SyncStatus.synced.value;
      localData['version'] = serverVersion;
      
      await _db.upsert(tableName, localData, 'id');
    } else {
      // Existing record - check for conflicts
      final localRecord = existing.first;
      final localVersion = localRecord['version'] as int? ?? 1;
      final localSyncStatus = SyncStatusExtension.fromString(
        localRecord['sync_status'] as String? ?? 'SYNCED'
      );

      // If local has pending changes, skip server update (local wins for now)
      if (localSyncStatus == SyncStatus.pending || localSyncStatus == SyncStatus.syncing) {
        _logger.log('Skipping server update for ${entityType.value} - local has pending changes');
        return;
      }

      // Server version is newer - update local
      if (serverVersion > localVersion) {
        final localData = _convertServerToLocal(serverItem, entityType);
        localData['id'] = localRecord['id'];
        localData['server_id'] = serverId;
        localData['sync_status'] = SyncStatus.synced.value;
        localData['version'] = serverVersion;
        
        await _db.upsert(tableName, localData, 'id');
      }
    }
  }

  /// Convert server response to local database format
  Map<String, dynamic> _convertServerToLocal(
    Map<String, dynamic> serverItem,
    EntityType entityType,
  ) {
    final now = DateTime.now().toIso8601String();
    
    switch (entityType) {
      case EntityType.account:
        return {
          'id': serverItem['_id'] ?? serverItem['id'],
          'name': serverItem['name'],
          'balance': serverItem['balance'],
          'color': serverItem['color'],
          'is_locked': serverItem['isLocked'] == true ? 1 : 0,
          'account_type': serverItem['accountType'],
          'type': serverItem['type'],
          'updated_at': serverItem['updatedAt'] ?? now,
          'is_deleted': serverItem['isDeleted'] == true ? 1 : 0,
        };
      
      case EntityType.transaction:
        return {
          'id': serverItem['_id'] ?? serverItem['id'],
          'amount': serverItem['amount'],
          'type': serverItem['type'],
          'account_id': serverItem['accountId'],
          'to_account_id': serverItem['toAccountId'],
          'category_id': serverItem['categoryId'],
          'description': serverItem['description'],
          'tags': serverItem['tags']?.join(','),
          'date': serverItem['date'],
          'updated_at': serverItem['updatedAt'] ?? now,
          'is_deleted': serverItem['isDeleted'] == true ? 1 : 0,
        };
      
      case EntityType.budget:
        return {
          'id': serverItem['_id'] ?? serverItem['id'],
          'name': serverItem['name'],
          'spent': serverItem['spent'],
          'budget_limit': serverItem['limit'],
          'color': serverItem['color'],
          'icon': serverItem['icon'],
          'period': serverItem['period'],
          'start_date': serverItem['startDate'],
          'end_date': serverItem['endDate'],
          'category_ids': (serverItem['categories'] as List?)?.join(','),
          'account_id': serverItem['account'],
          'updated_at': serverItem['updatedAt'] ?? now,
          'is_deleted': serverItem['isDeleted'] == true ? 1 : 0,
        };
      
      case EntityType.goal:
        return {
          'id': serverItem['_id'] ?? serverItem['id'],
          'name': serverItem['name'],
          'saved': serverItem['saved'],
          'target': serverItem['target'],
          'color': serverItem['color'],
          'icon': serverItem['icon'],
          'deadline': serverItem['deadline'],
          'note': serverItem['note'],
          'updated_at': serverItem['updatedAt'] ?? now,
          'is_deleted': serverItem['isDeleted'] == true ? 1 : 0,
        };
      
      case EntityType.category:
        return {
          'id': serverItem['_id'] ?? serverItem['id'],
          'name': serverItem['name'],
          'icon': serverItem['icon'],
          'color': serverItem['color'],
          'type': serverItem['type'],
          'parent_id': serverItem['parentId'],
          'sort_order': serverItem['order'],
          'updated_at': serverItem['updatedAt'] ?? now,
          'is_deleted': serverItem['isDeleted'] == true ? 1 : 0,
        };
      
      case EntityType.event:
        return {
          'id': serverItem['_id'] ?? serverItem['id'],
          'title': serverItem['title'],
          'start_time': serverItem['startTime'],
          'end_time': serverItem['endTime'],
          'notes': serverItem['notes'],
          'color': serverItem['color'],
          'is_all_day': serverItem['isAllDay'] == true ? 1 : 0,
          'updated_at': serverItem['updatedAt'] ?? now,
          'is_deleted': serverItem['isDeleted'] == true ? 1 : 0,
        };
    }
  }

  /// Get table name for entity type
  String _getTableName(EntityType type) {
    switch (type) {
      case EntityType.account:
        return 'accounts';
      case EntityType.transaction:
        return 'transactions';
      case EntityType.budget:
        return 'budgets';
      case EntityType.goal:
        return 'goals';
      case EntityType.category:
        return 'categories';
      case EntityType.event:
        return 'events';
    }
  }

  /// Batch entries into groups
  List<List<OutboxEntry>> _batchEntries(List<OutboxEntry> entries, {int batchSize = 10}) {
    final batches = <List<OutboxEntry>>[];
    for (var i = 0; i < entries.length; i += batchSize) {
      batches.add(entries.sublist(i, i + batchSize > entries.length ? entries.length : i + batchSize));
    }
    return batches;
  }

  /// Update sync state
  void _updateState(SyncState state) {
    _currentState = state;
    _syncStatusController.add(state);
  }

  /// Dispose resources
  void dispose() {
    _syncTimer?.cancel();
    _connectivitySubscription?.cancel();
    _syncStatusController.close();
    _logger.logSyncComplete(true);
  }
}

/// Sync state enum
enum SyncState {
  idle,
  syncing,
  offline,
  error,
}

/// Internal result types
class _PushResult {
  final bool success;
  final int processedCount;
  final int failedCount;

  _PushResult({
    required this.success,
    required this.processedCount,
    this.failedCount = 0,
  });
}

class _PullResult {
  final bool success;
  final int processedCount;

  _PullResult({required this.success, required this.processedCount});
}

class _BatchResult {
  final int successCount;
  final int failedCount;

  _BatchResult({required this.successCount, required this.failedCount});
}
