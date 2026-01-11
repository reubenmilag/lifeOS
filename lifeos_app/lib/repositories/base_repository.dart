import 'dart:async';
import 'package:uuid/uuid.dart';
import '../services/offline/local_database_service.dart';
import '../services/offline/outbox_service.dart';
import '../services/offline/sync_status.dart';
import '../services/offline/sync_engine.dart';

/// Base repository providing offline-first data access
/// 
/// All entity-specific repositories should extend this class
/// to inherit common offline-first functionality.
abstract class BaseRepository<T> {
  final LocalDatabaseService db;
  final OutboxService outbox;
  final SyncEngine syncEngine;
  final Uuid _uuid = const Uuid();

  BaseRepository({
    required this.db,
    required this.outbox,
    required this.syncEngine,
  });

  /// Entity type for this repository
  EntityType get entityType;

  /// Database table name
  String get tableName;

  /// Convert database map to entity
  T fromMap(Map<String, dynamic> map);

  /// Convert entity to database map
  Map<String, dynamic> toMap(T entity);

  /// Convert entity to sync payload (for server)
  Map<String, dynamic> toSyncPayload(T entity);

  /// Get entity ID
  String getId(T entity);

  /// Set entity ID
  T withId(T entity, String id);

  /// Get entity version
  int getVersion(T entity);

  /// Generate a new client-side UUID
  String generateId() => _uuid.v4();

  /// Stream of all entities (for UI)
  Stream<List<T>> watchAll();

  /// Get all entities from local database
  Future<List<T>> getAll() async {
    final results = await db.getAll(tableName, orderBy: 'updated_at DESC');
    return results.map((map) => fromMap(map)).toList();
  }

  /// Get entity by ID from local database
  Future<T?> getById(String id) async {
    final result = await db.getById(tableName, id);
    if (result == null) return null;
    return fromMap(result);
  }

  /// Create a new entity (offline-first)
  /// 
  /// Saves locally first, then queues for sync
  Future<T> create(T entity) async {
    // Generate client ID if needed
    String id = getId(entity);
    if (id.isEmpty) {
      id = generateId();
      entity = withId(entity, id);
    }

    final now = DateTime.now();
    final map = toMap(entity);
    map['id'] = id;
    map['version'] = 1;
    map['updated_at'] = now.toIso8601String();
    map['sync_status'] = SyncStatus.pending.value;
    map['is_deleted'] = 0;

    // Save to local database
    await db.upsert(tableName, map, 'id');

    // Add to sync outbox
    await outbox.addCreateOperation(
      entityId: id,
      entityType: entityType,
      data: toSyncPayload(entity),
      version: 1,
    );

    // Trigger sync if online
    syncEngine.triggerSync();

    return entity;
  }

  /// Update an existing entity (offline-first)
  Future<T> update(T entity) async {
    final id = getId(entity);
    
    // Get current version
    final existing = await db.getById(tableName, id);
    final currentVersion = (existing?['version'] as int?) ?? 1;
    final newVersion = currentVersion + 1;

    final now = DateTime.now();
    final map = toMap(entity);
    map['id'] = id;
    map['version'] = newVersion;
    map['updated_at'] = now.toIso8601String();
    map['sync_status'] = SyncStatus.pending.value;

    // Update local database
    await db.upsert(tableName, map, 'id');

    // Add to sync outbox
    await outbox.addUpdateOperation(
      entityId: id,
      entityType: entityType,
      data: toSyncPayload(entity),
      version: newVersion,
    );

    // Trigger sync if online
    syncEngine.triggerSync();

    return entity;
  }

  /// Delete an entity (offline-first soft delete)
  Future<void> delete(String id) async {
    // Get current version
    final existing = await db.getById(tableName, id);
    if (existing == null) return;

    final currentVersion = (existing['version'] as int?) ?? 1;
    final newVersion = currentVersion + 1;

    // Soft delete in local database
    final dbInstance = await db.database;
    await dbInstance.update(
      tableName,
      {
        'is_deleted': 1,
        'version': newVersion,
        'updated_at': DateTime.now().toIso8601String(),
        'sync_status': SyncStatus.pending.value,
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    // Add to sync outbox
    await outbox.addDeleteOperation(
      entityId: id,
      entityType: entityType,
      version: newVersion,
    );

    // Trigger sync if online
    syncEngine.triggerSync();
  }

  /// Get count of pending sync operations for this entity type
  Future<int> getPendingSyncCount() async {
    final dbInstance = await db.database;
    final result = await dbInstance.rawQuery(
      'SELECT COUNT(*) as count FROM $tableName WHERE sync_status IN (?, ?)',
      [SyncStatus.pending.value, SyncStatus.syncing.value],
    );
    return result.first['count'] as int? ?? 0;
  }

  /// Refresh data from server
  Future<void> refresh() async {
    await syncEngine.triggerSync();
  }
}

/// Mixin for repositories that support pagination
mixin PaginatedRepository<T> on BaseRepository<T> {
  /// Get paginated results
  Future<PaginatedResult<T>> getPaginated({
    int page = 1,
    int limit = 20,
    String? orderBy,
    Map<String, dynamic>? filters,
  }) async {
    final dbInstance = await db.database;
    final offset = (page - 1) * limit;

    // Build where clause
    final whereClause = StringBuffer('is_deleted = 0');
    final whereArgs = <dynamic>[];

    if (filters != null) {
      for (final entry in filters.entries) {
        if (entry.value != null) {
          whereClause.write(' AND ${entry.key} = ?');
          whereArgs.add(entry.value);
        }
      }
    }

    // Get total count
    final countResult = await dbInstance.rawQuery(
      'SELECT COUNT(*) as count FROM $tableName WHERE $whereClause',
      whereArgs,
    );
    final total = countResult.first['count'] as int? ?? 0;

    // Get page data
    final results = await dbInstance.query(
      tableName,
      where: whereClause.toString(),
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: orderBy ?? 'updated_at DESC',
      limit: limit,
      offset: offset,
    );

    final items = results.map((map) => fromMap(map)).toList();

    return PaginatedResult(
      items: items,
      total: total,
      page: page,
      limit: limit,
      totalPages: (total / limit).ceil(),
    );
  }
}

/// Paginated result container
class PaginatedResult<T> {
  final List<T> items;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const PaginatedResult({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  bool get hasMore => page < totalPages;
}
