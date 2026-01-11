import 'dart:convert';
import 'sync_status.dart';

/// Represents a pending change in the sync outbox queue
/// 
/// The outbox acts as a reliable queue for all local changes that need
/// to be synced to the server. It survives app restarts and ensures
/// no data is lost during offline periods.
class OutboxEntry {
  /// Unique identifier for this outbox entry
  final int? outboxId;
  
  /// Client-generated UUID for the entity
  final String entityId;
  
  /// Type of entity (account, transaction, etc.)
  final EntityType entityType;
  
  /// Type of operation (create, update, delete)
  final OperationType operationType;
  
  /// Serialized JSON payload of the entity data
  final String payload;
  
  /// Current sync status
  final SyncStatus syncStatus;
  
  /// Number of retry attempts made
  final int retryCount;
  
  /// Timestamp of last sync attempt
  final DateTime? lastAttemptAt;
  
  /// Unique key for idempotent server operations
  final String idempotencyKey;
  
  /// Timestamp when this entry was created
  final DateTime createdAt;
  
  /// Error message from last failed attempt
  final String? errorMessage;
  
  /// Entity version for conflict detection
  final int version;

  const OutboxEntry({
    this.outboxId,
    required this.entityId,
    required this.entityType,
    required this.operationType,
    required this.payload,
    this.syncStatus = SyncStatus.pending,
    this.retryCount = 0,
    this.lastAttemptAt,
    required this.idempotencyKey,
    required this.createdAt,
    this.errorMessage,
    this.version = 1,
  });

  /// Create a copy with updated fields
  OutboxEntry copyWith({
    int? outboxId,
    String? entityId,
    EntityType? entityType,
    OperationType? operationType,
    String? payload,
    SyncStatus? syncStatus,
    int? retryCount,
    DateTime? lastAttemptAt,
    String? idempotencyKey,
    DateTime? createdAt,
    String? errorMessage,
    int? version,
  }) {
    return OutboxEntry(
      outboxId: outboxId ?? this.outboxId,
      entityId: entityId ?? this.entityId,
      entityType: entityType ?? this.entityType,
      operationType: operationType ?? this.operationType,
      payload: payload ?? this.payload,
      syncStatus: syncStatus ?? this.syncStatus,
      retryCount: retryCount ?? this.retryCount,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      createdAt: createdAt ?? this.createdAt,
      errorMessage: errorMessage ?? this.errorMessage,
      version: version ?? this.version,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      if (outboxId != null) 'outbox_id': outboxId,
      'entity_id': entityId,
      'entity_type': entityType.value,
      'operation_type': operationType.value,
      'payload': payload,
      'sync_status': syncStatus.value,
      'retry_count': retryCount,
      'last_attempt_at': lastAttemptAt?.toIso8601String(),
      'idempotency_key': idempotencyKey,
      'created_at': createdAt.toIso8601String(),
      'error_message': errorMessage,
      'version': version,
    };
  }

  /// Create from database map
  factory OutboxEntry.fromMap(Map<String, dynamic> map) {
    return OutboxEntry(
      outboxId: map['outbox_id'] as int?,
      entityId: map['entity_id'] as String,
      entityType: EntityTypeExtension.fromString(map['entity_type'] as String),
      operationType: OperationTypeExtension.fromString(map['operation_type'] as String),
      payload: map['payload'] as String,
      syncStatus: SyncStatusExtension.fromString(map['sync_status'] as String? ?? 'PENDING'),
      retryCount: map['retry_count'] as int? ?? 0,
      lastAttemptAt: map['last_attempt_at'] != null 
          ? DateTime.parse(map['last_attempt_at'] as String) 
          : null,
      idempotencyKey: map['idempotency_key'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      errorMessage: map['error_message'] as String?,
      version: map['version'] as int? ?? 1,
    );
  }

  /// Parse the payload JSON
  Map<String, dynamic> get payloadJson => jsonDecode(payload) as Map<String, dynamic>;

  /// Check if this entry should be retried
  bool get shouldRetry => 
      syncStatus != SyncStatus.synced && 
      syncStatus != SyncStatus.failed;

  /// Check if max retries exceeded
  bool hasExceededMaxRetries(int maxRetries) => retryCount >= maxRetries;

  @override
  String toString() {
    return 'OutboxEntry(outboxId: $outboxId, entityId: $entityId, entityType: ${entityType.value}, '
        'operationType: ${operationType.value}, syncStatus: ${syncStatus.value}, retryCount: $retryCount)';
  }
}

/// Result of a sync operation
class SyncResult {
  final bool success;
  final String? serverId;
  final int? serverVersion;
  final String? errorMessage;
  final bool isConflict;
  final Map<String, dynamic>? serverData;

  const SyncResult({
    required this.success,
    this.serverId,
    this.serverVersion,
    this.errorMessage,
    this.isConflict = false,
    this.serverData,
  });

  factory SyncResult.success({String? serverId, int? serverVersion, Map<String, dynamic>? serverData}) {
    return SyncResult(
      success: true,
      serverId: serverId,
      serverVersion: serverVersion,
      serverData: serverData,
    );
  }

  factory SyncResult.failure(String errorMessage, {bool isConflict = false}) {
    return SyncResult(
      success: false,
      errorMessage: errorMessage,
      isConflict: isConflict,
    );
  }

  factory SyncResult.conflict(Map<String, dynamic> serverData) {
    return SyncResult(
      success: false,
      isConflict: true,
      serverData: serverData,
      errorMessage: 'Conflict detected: server has newer version',
    );
  }
}

/// Batch sync request payload
class SyncBatchRequest {
  final List<SyncOperation> operations;
  final DateTime clientTimestamp;

  const SyncBatchRequest({
    required this.operations,
    required this.clientTimestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'operations': operations.map((op) => op.toJson()).toList(),
      'clientTimestamp': clientTimestamp.toIso8601String(),
    };
  }
}

/// Single sync operation in a batch
class SyncOperation {
  final String idempotencyKey;
  final String entityType;
  final String operationType;
  final String entityId;
  final Map<String, dynamic> data;
  final int version;

  const SyncOperation({
    required this.idempotencyKey,
    required this.entityType,
    required this.operationType,
    required this.entityId,
    required this.data,
    required this.version,
  });

  Map<String, dynamic> toJson() {
    return {
      'idempotencyKey': idempotencyKey,
      'entityType': entityType,
      'operationType': operationType,
      'entityId': entityId,
      'data': data,
      'version': version,
    };
  }
}

/// Response from batch sync
class SyncBatchResponse {
  final List<SyncOperationResult> results;
  final DateTime serverTimestamp;

  const SyncBatchResponse({
    required this.results,
    required this.serverTimestamp,
  });

  factory SyncBatchResponse.fromJson(Map<String, dynamic> json) {
    return SyncBatchResponse(
      results: (json['results'] as List)
          .map((r) => SyncOperationResult.fromJson(r as Map<String, dynamic>))
          .toList(),
      serverTimestamp: DateTime.parse(json['serverTimestamp'] as String),
    );
  }
}

/// Result of a single operation in batch sync
class SyncOperationResult {
  final String idempotencyKey;
  final bool success;
  final String? serverId;
  final int? serverVersion;
  final String? errorMessage;
  final String? errorCode;
  final Map<String, dynamic>? serverData;

  const SyncOperationResult({
    required this.idempotencyKey,
    required this.success,
    this.serverId,
    this.serverVersion,
    this.errorMessage,
    this.errorCode,
    this.serverData,
  });

  factory SyncOperationResult.fromJson(Map<String, dynamic> json) {
    return SyncOperationResult(
      idempotencyKey: json['idempotencyKey'] as String,
      success: json['success'] as bool,
      serverId: json['serverId'] as String?,
      serverVersion: json['serverVersion'] as int?,
      errorMessage: json['errorMessage'] as String?,
      errorCode: json['errorCode'] as String?,
      serverData: json['serverData'] as Map<String, dynamic>?,
    );
  }

  bool get isConflict => errorCode == 'CONFLICT';
  bool get isIdempotentReplay => errorCode == 'IDEMPOTENT_REPLAY';
}
