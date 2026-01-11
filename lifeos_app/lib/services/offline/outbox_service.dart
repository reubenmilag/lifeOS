import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'local_database_service.dart';
import 'sync_status.dart';
import 'sync_outbox.dart';

/// Service for managing the sync outbox queue
/// 
/// The outbox service handles adding operations to the queue,
/// updating their status, and providing entries for sync.
class OutboxService {
  final LocalDatabaseService _db;
  final Uuid _uuid = const Uuid();

  OutboxService(this._db);

  /// Add a create operation to the outbox
  Future<OutboxEntry> addCreateOperation({
    required String entityId,
    required EntityType entityType,
    required Map<String, dynamic> data,
    int version = 1,
  }) async {
    final entry = OutboxEntry(
      entityId: entityId,
      entityType: entityType,
      operationType: OperationType.create,
      payload: jsonEncode(data),
      idempotencyKey: _generateIdempotencyKey(entityType, entityId, OperationType.create),
      createdAt: DateTime.now(),
      version: version,
    );
    
    final outboxId = await _db.addToOutbox(entry);
    return entry.copyWith(outboxId: outboxId);
  }

  /// Add an update operation to the outbox
  Future<OutboxEntry> addUpdateOperation({
    required String entityId,
    required EntityType entityType,
    required Map<String, dynamic> data,
    required int version,
  }) async {
    // Check if there's already a pending create for this entity
    final existingEntries = await _db.getOutboxEntriesForEntity(entityType, entityId);
    final pendingCreate = existingEntries.where(
      (e) => e.operationType == OperationType.create && e.syncStatus != SyncStatus.synced
    ).toList();

    if (pendingCreate.isNotEmpty) {
      // Merge update into the pending create
      final createEntry = pendingCreate.first;
      final mergedData = {...createEntry.payloadJson, ...data};
      
      await _db.updateOutboxStatus(
        createEntry.outboxId!,
        status: SyncStatus.pending,
      );
      
      // Update the payload
      final db = await _db.database;
      await db.update(
        'sync_outbox',
        {'payload': jsonEncode(mergedData)},
        where: 'outbox_id = ?',
        whereArgs: [createEntry.outboxId],
      );
      
      return createEntry.copyWith(payload: jsonEncode(mergedData));
    }

    final entry = OutboxEntry(
      entityId: entityId,
      entityType: entityType,
      operationType: OperationType.update,
      payload: jsonEncode(data),
      idempotencyKey: _generateIdempotencyKey(entityType, entityId, OperationType.update, version),
      createdAt: DateTime.now(),
      version: version,
    );
    
    final outboxId = await _db.addToOutbox(entry);
    return entry.copyWith(outboxId: outboxId);
  }

  /// Add a delete operation to the outbox
  Future<OutboxEntry> addDeleteOperation({
    required String entityId,
    required EntityType entityType,
    required int version,
  }) async {
    // Check if there's a pending create - if so, we can just remove it
    final existingEntries = await _db.getOutboxEntriesForEntity(entityType, entityId);
    final pendingCreate = existingEntries.where(
      (e) => e.operationType == OperationType.create && e.syncStatus != SyncStatus.synced
    ).toList();

    if (pendingCreate.isNotEmpty) {
      // Entity was created offline and never synced - just delete from outbox
      for (final entry in pendingCreate) {
        await _db.deleteOutboxEntry(entry.outboxId!);
      }
      // Return a dummy entry to signal completion
      return OutboxEntry(
        entityId: entityId,
        entityType: entityType,
        operationType: OperationType.delete,
        payload: '{}',
        idempotencyKey: _uuid.v4(),
        createdAt: DateTime.now(),
        syncStatus: SyncStatus.synced,
        version: version,
      );
    }

    // Remove any pending updates for this entity
    final pendingUpdates = existingEntries.where(
      (e) => e.operationType == OperationType.update && e.syncStatus != SyncStatus.synced
    ).toList();
    for (final entry in pendingUpdates) {
      await _db.deleteOutboxEntry(entry.outboxId!);
    }

    final entry = OutboxEntry(
      entityId: entityId,
      entityType: entityType,
      operationType: OperationType.delete,
      payload: jsonEncode({'id': entityId}),
      idempotencyKey: _generateIdempotencyKey(entityType, entityId, OperationType.delete, version),
      createdAt: DateTime.now(),
      version: version,
    );
    
    final outboxId = await _db.addToOutbox(entry);
    return entry.copyWith(outboxId: outboxId);
  }

  /// Get all pending entries for sync
  Future<List<OutboxEntry>> getPendingEntries({int? limit}) async {
    return await _db.getPendingOutboxEntries(limit: limit);
  }

  /// Mark entry as syncing
  Future<void> markSyncing(int outboxId) async {
    await _db.updateOutboxStatus(
      outboxId,
      status: SyncStatus.syncing,
      lastAttemptAt: DateTime.now(),
    );
  }

  /// Mark entry as synced and remove from outbox
  Future<void> markSynced(int outboxId) async {
    await _db.deleteOutboxEntry(outboxId);
  }

  /// Mark entry as failed with retry info
  Future<void> markFailed(
    int outboxId, {
    required int retryCount,
    required String errorMessage,
    required bool permanentFailure,
  }) async {
    await _db.updateOutboxStatus(
      outboxId,
      status: permanentFailure ? SyncStatus.failed : SyncStatus.pending,
      retryCount: retryCount,
      lastAttemptAt: DateTime.now(),
      errorMessage: errorMessage,
    );
  }

  /// Get number of pending operations
  Future<int> getPendingCount() async {
    return await _db.getPendingOperationsCount();
  }

  /// Clear completed entries
  Future<void> clearCompleted() async {
    await _db.deleteCompletedOutboxEntries();
  }

  /// Generate a deterministic idempotency key
  String _generateIdempotencyKey(
    EntityType entityType,
    String entityId,
    OperationType operation, [
    int? version,
  ]) {
    // For creates, use entity ID + operation type + timestamp
    // For updates/deletes, include version to ensure uniqueness per version
    if (version != null) {
      return '${entityType.value}_${entityId}_${operation.value}_v$version';
    }
    return '${entityType.value}_${entityId}_${operation.value}_${DateTime.now().millisecondsSinceEpoch}';
  }
}
