/// Sync status enum representing the state of a local record's synchronization
enum SyncStatus {
  /// Record has pending changes that need to be synced
  pending,
  
  /// Record is currently being synced
  syncing,
  
  /// Record has been successfully synced with the server
  synced,
  
  /// Record sync failed after max retries
  failed,
}

/// Extension to convert SyncStatus to/from string for database storage
extension SyncStatusExtension on SyncStatus {
  String get value {
    switch (this) {
      case SyncStatus.pending:
        return 'PENDING';
      case SyncStatus.syncing:
        return 'SYNCING';
      case SyncStatus.synced:
        return 'SYNCED';
      case SyncStatus.failed:
        return 'FAILED';
    }
  }

  static SyncStatus fromString(String value) {
    switch (value.toUpperCase()) {
      case 'PENDING':
        return SyncStatus.pending;
      case 'SYNCING':
        return SyncStatus.syncing;
      case 'SYNCED':
        return SyncStatus.synced;
      case 'FAILED':
        return SyncStatus.failed;
      default:
        return SyncStatus.pending;
    }
  }
}

/// Operation type for tracking what kind of change was made
enum OperationType {
  create,
  update,
  delete,
}

extension OperationTypeExtension on OperationType {
  String get value {
    switch (this) {
      case OperationType.create:
        return 'CREATE';
      case OperationType.update:
        return 'UPDATE';
      case OperationType.delete:
        return 'DELETE';
    }
  }

  static OperationType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'CREATE':
        return OperationType.create;
      case 'UPDATE':
        return OperationType.update;
      case 'DELETE':
        return OperationType.delete;
      default:
        return OperationType.update;
    }
  }
}

/// Entity types that can be synced
enum EntityType {
  account,
  transaction,
  budget,
  goal,
  category,
  event,
}

extension EntityTypeExtension on EntityType {
  String get value {
    switch (this) {
      case EntityType.account:
        return 'account';
      case EntityType.transaction:
        return 'transaction';
      case EntityType.budget:
        return 'budget';
      case EntityType.goal:
        return 'goal';
      case EntityType.category:
        return 'category';
      case EntityType.event:
        return 'event';
    }
  }

  static EntityType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'account':
        return EntityType.account;
      case 'transaction':
        return EntityType.transaction;
      case 'budget':
        return EntityType.budget;
      case 'goal':
        return EntityType.goal;
      case 'category':
        return EntityType.category;
      case 'event':
        return EntityType.event;
      default:
        throw ArgumentError('Unknown entity type: $value');
    }
  }
}
