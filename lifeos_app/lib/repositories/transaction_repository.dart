import 'dart:async';
import '../models/transaction_model.dart';
import '../services/offline/local_database_service.dart';
import '../services/offline/outbox_service.dart';
import '../services/offline/sync_status.dart';
import '../services/offline/sync_engine.dart';
import 'base_repository.dart';

/// Repository for Transaction entities with offline-first support
class TransactionRepository extends BaseRepository<TransactionModel> 
    with PaginatedRepository<TransactionModel> {
  final _streamController = StreamController<List<TransactionModel>>.broadcast();

  TransactionRepository({
    required super.db,
    required super.outbox,
    required super.syncEngine,
  });

  @override
  EntityType get entityType => EntityType.transaction;

  @override
  String get tableName => 'transactions';

  @override
  TransactionModel fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as String?,
      amount: (map['amount'] as num).toDouble(),
      type: map['type'] as String? ?? 'expense',
      accountId: map['account_id'] as String?,
      toAccountId: map['to_account_id'] as String?,
      categoryId: map['category_id'] as String?,
      description: map['description'] as String?,
      tags: map['tags'] != null 
          ? (map['tags'] as String).split(',').where((t) => t.isNotEmpty).toList() 
          : [],
      date: DateTime.parse(map['date'] as String).toLocal(),
    );
  }

  @override
  Map<String, dynamic> toMap(TransactionModel entity) {
    return {
      'id': entity.id,
      'amount': entity.amount,
      'type': entity.type,
      'account_id': entity.accountId,
      'to_account_id': entity.toAccountId,
      'category_id': entity.categoryId,
      'description': entity.description,
      'tags': entity.tags?.join(','),
      'date': entity.date.toIso8601String(),
    };
  }

  @override
  Map<String, dynamic> toSyncPayload(TransactionModel entity) {
    return {
      'amount': entity.amount,
      'type': entity.type,
      'accountId': entity.accountId,
      'toAccountId': entity.toAccountId,
      'categoryId': entity.categoryId,
      'description': entity.description,
      'tags': entity.tags,
      'date': entity.date.toIso8601String(),
    };
  }

  @override
  String getId(TransactionModel entity) => entity.id ?? '';

  @override
  TransactionModel withId(TransactionModel entity, String id) {
    return TransactionModel(
      id: id,
      amount: entity.amount,
      type: entity.type,
      accountId: entity.accountId,
      account: entity.account,
      toAccountId: entity.toAccountId,
      toAccount: entity.toAccount,
      categoryId: entity.categoryId,
      category: entity.category,
      description: entity.description,
      tags: entity.tags,
      date: entity.date,
    );
  }

  @override
  int getVersion(TransactionModel entity) => 1;

  @override
  Stream<List<TransactionModel>> watchAll() {
    // Initial load
    getAll().then((transactions) {
      if (!_streamController.isClosed) {
        _streamController.add(transactions);
      }
    });
    return _streamController.stream;
  }

  /// Notify listeners of data changes
  Future<void> notifyListeners() async {
    final transactions = await getAll();
    if (!_streamController.isClosed) {
      _streamController.add(transactions);
    }
  }

  @override
  Future<List<TransactionModel>> getAll() async {
    final results = await db.getAll(tableName, orderBy: 'date DESC');
    return results.map((map) => fromMap(map)).toList();
  }

  @override
  Future<TransactionModel> create(TransactionModel entity) async {
    final result = await super.create(entity);
    await notifyListeners();
    return result;
  }

  @override
  Future<TransactionModel> update(TransactionModel entity) async {
    final result = await super.update(entity);
    await notifyListeners();
    return result;
  }

  @override
  Future<void> delete(String id) async {
    await super.delete(id);
    await notifyListeners();
  }

  /// Get transactions by date range
  Future<List<TransactionModel>> getByDateRange(DateTime start, DateTime end) async {
    final dbInstance = await db.database;
    final results = await dbInstance.query(
      tableName,
      where: 'is_deleted = 0 AND date >= ? AND date <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date DESC',
    );
    return results.map((map) => fromMap(map)).toList();
  }

  /// Get transactions by account
  Future<List<TransactionModel>> getByAccount(String accountId) async {
    final dbInstance = await db.database;
    final results = await dbInstance.query(
      tableName,
      where: 'is_deleted = 0 AND (account_id = ? OR to_account_id = ?)',
      whereArgs: [accountId, accountId],
      orderBy: 'date DESC',
    );
    return results.map((map) => fromMap(map)).toList();
  }

  /// Get transactions by category
  Future<List<TransactionModel>> getByCategory(String categoryId) async {
    final dbInstance = await db.database;
    final results = await dbInstance.query(
      tableName,
      where: 'is_deleted = 0 AND category_id = ?',
      whereArgs: [categoryId],
      orderBy: 'date DESC',
    );
    return results.map((map) => fromMap(map)).toList();
  }

  /// Get total income for period
  Future<double> getTotalIncome({DateTime? start, DateTime? end}) async {
    final dbInstance = await db.database;
    var sql = 'SELECT SUM(amount) as total FROM transactions WHERE is_deleted = 0 AND type = ?';
    final args = <dynamic>['income'];
    
    if (start != null && end != null) {
      sql += ' AND date >= ? AND date <= ?';
      args.addAll([start.toIso8601String(), end.toIso8601String()]);
    }
    
    final result = await dbInstance.rawQuery(sql, args);
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Get total expenses for period
  Future<double> getTotalExpenses({DateTime? start, DateTime? end}) async {
    final dbInstance = await db.database;
    var sql = 'SELECT SUM(amount) as total FROM transactions WHERE is_deleted = 0 AND type = ?';
    final args = <dynamic>['expense'];
    
    if (start != null && end != null) {
      sql += ' AND date >= ? AND date <= ?';
      args.addAll([start.toIso8601String(), end.toIso8601String()]);
    }
    
    final result = await dbInstance.rawQuery(sql, args);
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  void dispose() {
    _streamController.close();
  }
}
