import 'sync_status.dart';

/// Base mixin for entities that can be synced offline
/// 
/// All syncable entities must implement this interface to participate
/// in the offline-first sync architecture.
mixin SyncableEntity {
  /// Client-generated UUID for the record
  String get id;
  
  /// Server-assigned ID (may differ from client ID)
  String? get serverId;
  
  /// Last modification timestamp on the client
  DateTime get updatedAt;
  
  /// Current sync status of this record
  SyncStatus get syncStatus;
  
  /// Version number for conflict detection
  int get version;
  
  /// Convert entity to JSON for storage/sync
  Map<String, dynamic> toJson();
  
  /// Convert entity to JSON for sync payload (excludes sync metadata)
  Map<String, dynamic> toSyncJson();
}

/// Metadata added to syncable entities for local storage
class SyncMetadata {
  final String id;
  final String? serverId;
  final SyncStatus syncStatus;
  final int version;
  final DateTime updatedAt;
  final DateTime? lastSyncedAt;
  final int retryCount;
  final DateTime? lastAttemptAt;
  final String? idempotencyKey;
  final String? errorMessage;

  const SyncMetadata({
    required this.id,
    this.serverId,
    this.syncStatus = SyncStatus.pending,
    this.version = 1,
    required this.updatedAt,
    this.lastSyncedAt,
    this.retryCount = 0,
    this.lastAttemptAt,
    this.idempotencyKey,
    this.errorMessage,
  });

  SyncMetadata copyWith({
    String? id,
    String? serverId,
    SyncStatus? syncStatus,
    int? version,
    DateTime? updatedAt,
    DateTime? lastSyncedAt,
    int? retryCount,
    DateTime? lastAttemptAt,
    String? idempotencyKey,
    String? errorMessage,
  }) {
    return SyncMetadata(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      syncStatus: syncStatus ?? this.syncStatus,
      version: version ?? this.version,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      retryCount: retryCount ?? this.retryCount,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'server_id': serverId,
      'sync_status': syncStatus.value,
      'version': version,
      'updated_at': updatedAt.toIso8601String(),
      'last_synced_at': lastSyncedAt?.toIso8601String(),
      'retry_count': retryCount,
      'last_attempt_at': lastAttemptAt?.toIso8601String(),
      'idempotency_key': idempotencyKey,
      'error_message': errorMessage,
    };
  }

  factory SyncMetadata.fromMap(Map<String, dynamic> map) {
    return SyncMetadata(
      id: map['id'] as String,
      serverId: map['server_id'] as String?,
      syncStatus: SyncStatusExtension.fromString(map['sync_status'] as String? ?? 'PENDING'),
      version: map['version'] as int? ?? 1,
      updatedAt: DateTime.parse(map['updated_at'] as String),
      lastSyncedAt: map['last_synced_at'] != null 
          ? DateTime.parse(map['last_synced_at'] as String) 
          : null,
      retryCount: map['retry_count'] as int? ?? 0,
      lastAttemptAt: map['last_attempt_at'] != null 
          ? DateTime.parse(map['last_attempt_at'] as String) 
          : null,
      idempotencyKey: map['idempotency_key'] as String?,
      errorMessage: map['error_message'] as String?,
    );
  }
}
