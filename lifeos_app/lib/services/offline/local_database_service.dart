import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'sync_status.dart';
import 'sync_outbox.dart';

/// Local SQLite database service for offline-first data storage
/// 
/// This service manages the local SQLite database that serves as the
/// source of truth for the UI. All data is stored locally first, then
/// synced to the server in the background.
class LocalDatabaseService {
  static const String _databaseName = 'lifeos_offline.db';
  static const int _databaseVersion = 1;
  
  static LocalDatabaseService? _instance;
  static Database? _database;

  LocalDatabaseService._();

  /// Get singleton instance
  static LocalDatabaseService get instance {
    _instance ??= LocalDatabaseService._();
    return _instance!;
  }

  /// Get database instance, creating if necessary
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Initialize the database
  Future<Database> _initDatabase() async {
    final String path = join(await getDatabasesPath(), _databaseName);
    
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    // Sync outbox table - queue for pending changes
    await db.execute('''
      CREATE TABLE sync_outbox (
        outbox_id INTEGER PRIMARY KEY AUTOINCREMENT,
        entity_id TEXT NOT NULL,
        entity_type TEXT NOT NULL,
        operation_type TEXT NOT NULL,
        payload TEXT NOT NULL,
        sync_status TEXT DEFAULT 'PENDING',
        retry_count INTEGER DEFAULT 0,
        last_attempt_at TEXT,
        idempotency_key TEXT NOT NULL UNIQUE,
        created_at TEXT NOT NULL,
        error_message TEXT,
        version INTEGER DEFAULT 1
      )
    ''');

    // Sync metadata table - tracks sync state for each entity
    await db.execute('''
      CREATE TABLE sync_metadata (
        id TEXT PRIMARY KEY,
        entity_type TEXT NOT NULL,
        server_id TEXT,
        sync_status TEXT DEFAULT 'PENDING',
        version INTEGER DEFAULT 1,
        updated_at TEXT NOT NULL,
        last_synced_at TEXT,
        retry_count INTEGER DEFAULT 0,
        last_attempt_at TEXT,
        idempotency_key TEXT,
        error_message TEXT
      )
    ''');

    // Last sync timestamp table
    await db.execute('''
      CREATE TABLE sync_timestamps (
        entity_type TEXT PRIMARY KEY,
        last_pull_at TEXT,
        last_push_at TEXT
      )
    ''');

    // Accounts table
    await db.execute('''
      CREATE TABLE accounts (
        id TEXT PRIMARY KEY,
        server_id TEXT,
        name TEXT,
        balance REAL DEFAULT 0.0,
        color TEXT DEFAULT '#0099EE',
        is_locked INTEGER DEFAULT 0,
        account_type TEXT DEFAULT 'General',
        type TEXT DEFAULT 'standard',
        version INTEGER DEFAULT 1,
        updated_at TEXT NOT NULL,
        sync_status TEXT DEFAULT 'PENDING',
        is_deleted INTEGER DEFAULT 0
      )
    ''');

    // Transactions table
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        server_id TEXT,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        account_id TEXT NOT NULL,
        to_account_id TEXT,
        category_id TEXT,
        description TEXT,
        tags TEXT,
        date TEXT NOT NULL,
        version INTEGER DEFAULT 1,
        updated_at TEXT NOT NULL,
        sync_status TEXT DEFAULT 'PENDING',
        is_deleted INTEGER DEFAULT 0,
        FOREIGN KEY (account_id) REFERENCES accounts(id),
        FOREIGN KEY (to_account_id) REFERENCES accounts(id),
        FOREIGN KEY (category_id) REFERENCES categories(id)
      )
    ''');

    // Budgets table
    await db.execute('''
      CREATE TABLE budgets (
        id TEXT PRIMARY KEY,
        server_id TEXT,
        name TEXT NOT NULL,
        spent REAL DEFAULT 0.0,
        budget_limit REAL NOT NULL,
        color TEXT DEFAULT '#FFA500',
        icon TEXT DEFAULT 'shoppingCart',
        period TEXT DEFAULT 'Month',
        start_date TEXT,
        end_date TEXT,
        category_ids TEXT,
        account_id TEXT,
        version INTEGER DEFAULT 1,
        updated_at TEXT NOT NULL,
        sync_status TEXT DEFAULT 'PENDING',
        is_deleted INTEGER DEFAULT 0
      )
    ''');

    // Goals table
    await db.execute('''
      CREATE TABLE goals (
        id TEXT PRIMARY KEY,
        server_id TEXT,
        name TEXT NOT NULL,
        saved REAL DEFAULT 0.0,
        target REAL NOT NULL,
        color TEXT DEFAULT '#4B0082',
        icon TEXT DEFAULT 'star',
        deadline TEXT NOT NULL,
        note TEXT,
        version INTEGER DEFAULT 1,
        updated_at TEXT NOT NULL,
        sync_status TEXT DEFAULT 'PENDING',
        is_deleted INTEGER DEFAULT 0
      )
    ''');

    // Categories table
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        server_id TEXT,
        name TEXT NOT NULL,
        icon TEXT DEFAULT 'help_outline',
        color TEXT DEFAULT '#000000',
        type TEXT DEFAULT 'expense',
        parent_id TEXT,
        sort_order INTEGER DEFAULT 0,
        version INTEGER DEFAULT 1,
        updated_at TEXT NOT NULL,
        sync_status TEXT DEFAULT 'PENDING',
        is_deleted INTEGER DEFAULT 0
      )
    ''');

    // Events table
    await db.execute('''
      CREATE TABLE events (
        id TEXT PRIMARY KEY,
        server_id TEXT,
        title TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        notes TEXT,
        color TEXT DEFAULT '#18181B',
        is_all_day INTEGER DEFAULT 0,
        version INTEGER DEFAULT 1,
        updated_at TEXT NOT NULL,
        sync_status TEXT DEFAULT 'PENDING',
        is_deleted INTEGER DEFAULT 0
      )
    ''');

    // Create indexes for performance
    await db.execute('CREATE INDEX idx_outbox_status ON sync_outbox(sync_status)');
    await db.execute('CREATE INDEX idx_outbox_entity ON sync_outbox(entity_type, entity_id)');
    await db.execute('CREATE INDEX idx_accounts_sync ON accounts(sync_status)');
    await db.execute('CREATE INDEX idx_transactions_sync ON transactions(sync_status)');
    await db.execute('CREATE INDEX idx_transactions_date ON transactions(date)');
    await db.execute('CREATE INDEX idx_budgets_sync ON budgets(sync_status)');
    await db.execute('CREATE INDEX idx_goals_sync ON goals(sync_status)');
    await db.execute('CREATE INDEX idx_categories_sync ON categories(sync_status)');
    await db.execute('CREATE INDEX idx_events_sync ON events(sync_status)');
    await db.execute('CREATE INDEX idx_events_dates ON events(start_time, end_time)');
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle migrations for future versions
    // if (oldVersion < 2) { ... }
  }

  // ============= OUTBOX OPERATIONS =============

  /// Add entry to sync outbox
  Future<int> addToOutbox(OutboxEntry entry) async {
    final db = await database;
    return await db.insert('sync_outbox', entry.toMap());
  }

  /// Get all pending outbox entries
  Future<List<OutboxEntry>> getPendingOutboxEntries({int? limit}) async {
    final db = await database;
    final results = await db.query(
      'sync_outbox',
      where: 'sync_status IN (?, ?)',
      whereArgs: [SyncStatus.pending.value, SyncStatus.failed.value],
      orderBy: 'created_at ASC',
      limit: limit,
    );
    return results.map((map) => OutboxEntry.fromMap(map)).toList();
  }

  /// Get outbox entries by entity
  Future<List<OutboxEntry>> getOutboxEntriesForEntity(
    EntityType entityType,
    String entityId,
  ) async {
    final db = await database;
    final results = await db.query(
      'sync_outbox',
      where: 'entity_type = ? AND entity_id = ?',
      whereArgs: [entityType.value, entityId],
      orderBy: 'created_at ASC',
    );
    return results.map((map) => OutboxEntry.fromMap(map)).toList();
  }

  /// Update outbox entry status
  Future<void> updateOutboxStatus(
    int outboxId, {
    required SyncStatus status,
    int? retryCount,
    DateTime? lastAttemptAt,
    String? errorMessage,
  }) async {
    final db = await database;
    final updates = <String, dynamic>{
      'sync_status': status.value,
    };
    if (retryCount != null) updates['retry_count'] = retryCount;
    if (lastAttemptAt != null) updates['last_attempt_at'] = lastAttemptAt.toIso8601String();
    if (errorMessage != null) updates['error_message'] = errorMessage;

    await db.update(
      'sync_outbox',
      updates,
      where: 'outbox_id = ?',
      whereArgs: [outboxId],
    );
  }

  /// Delete synced outbox entry
  Future<void> deleteOutboxEntry(int outboxId) async {
    final db = await database;
    await db.delete(
      'sync_outbox',
      where: 'outbox_id = ?',
      whereArgs: [outboxId],
    );
  }

  /// Delete all synced entries
  Future<void> deleteCompletedOutboxEntries() async {
    final db = await database;
    await db.delete(
      'sync_outbox',
      where: 'sync_status = ?',
      whereArgs: [SyncStatus.synced.value],
    );
  }

  /// Get count of pending operations
  Future<int> getPendingOperationsCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM sync_outbox WHERE sync_status IN (?, ?)',
      [SyncStatus.pending.value, SyncStatus.syncing.value],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ============= SYNC TIMESTAMP OPERATIONS =============

  /// Get last pull timestamp for entity type
  Future<DateTime?> getLastPullTimestamp(EntityType entityType) async {
    final db = await database;
    final results = await db.query(
      'sync_timestamps',
      where: 'entity_type = ?',
      whereArgs: [entityType.value],
    );
    if (results.isEmpty) return null;
    final lastPullAt = results.first['last_pull_at'] as String?;
    return lastPullAt != null ? DateTime.parse(lastPullAt) : null;
  }

  /// Update last pull timestamp
  Future<void> updateLastPullTimestamp(EntityType entityType, DateTime timestamp) async {
    final db = await database;
    await db.insert(
      'sync_timestamps',
      {
        'entity_type': entityType.value,
        'last_pull_at': timestamp.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ============= GENERIC CRUD HELPERS =============

  /// Insert or update a record in any table
  Future<void> upsert(String table, Map<String, dynamic> data, String idColumn) async {
    final db = await database;
    await db.insert(
      table,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Soft delete a record
  Future<void> softDelete(String table, String id) async {
    final db = await database;
    await db.update(
      table,
      {
        'is_deleted': 1,
        'updated_at': DateTime.now().toIso8601String(),
        'sync_status': SyncStatus.pending.value,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get all non-deleted records from a table
  Future<List<Map<String, dynamic>>> getAll(String table, {String? orderBy}) async {
    final db = await database;
    return await db.query(
      table,
      where: 'is_deleted = 0',
      orderBy: orderBy,
    );
  }

  /// Get a single record by ID
  Future<Map<String, dynamic>?> getById(String table, String id) async {
    final db = await database;
    final results = await db.query(
      table,
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Update sync status for a record
  Future<void> updateSyncStatus(
    String table,
    String id, {
    required SyncStatus status,
    String? serverId,
    int? version,
  }) async {
    final db = await database;
    final updates = <String, dynamic>{
      'sync_status': status.value,
    };
    if (serverId != null) updates['server_id'] = serverId;
    if (version != null) updates['version'] = version;

    await db.update(
      table,
      updates,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get records pending sync
  Future<List<Map<String, dynamic>>> getPendingSync(String table) async {
    final db = await database;
    return await db.query(
      table,
      where: 'sync_status IN (?, ?)',
      whereArgs: [SyncStatus.pending.value, SyncStatus.failed.value],
    );
  }

  /// Execute raw query
  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<Object?>? arguments]) async {
    final db = await database;
    return await db.rawQuery(sql, arguments);
  }

  /// Execute in transaction
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await database;
    return await db.transaction(action);
  }

  /// Close database
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  /// Clear all data (for testing/logout)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('sync_outbox');
    await db.delete('sync_metadata');
    await db.delete('sync_timestamps');
    await db.delete('accounts');
    await db.delete('transactions');
    await db.delete('budgets');
    await db.delete('goals');
    await db.delete('categories');
    await db.delete('events');
  }
}
