import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../models/account_model.dart';
import '../services/offline/local_database_service.dart';
import '../services/offline/outbox_service.dart';
import '../services/offline/sync_status.dart';
import '../services/offline/sync_engine.dart';
import 'base_repository.dart';

/// Repository for Account entities with offline-first support
class AccountRepository extends BaseRepository<Account> {
  final _streamController = StreamController<List<Account>>.broadcast();

  AccountRepository({
    required super.db,
    required super.outbox,
    required super.syncEngine,
  });

  @override
  EntityType get entityType => EntityType.account;

  @override
  String get tableName => 'accounts';

  @override
  Account fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'] as String?,
      name: map['name'] as String?,
      balance: (map['balance'] as num?)?.toDouble(),
      color: map['color'] as String? ?? '#0099EE',
      isLocked: (map['is_locked'] as int?) == 1,
      type: map['type'] as String? ?? 'standard',
      accountType: map['account_type'] as String? ?? 'General',
    );
  }

  @override
  Map<String, dynamic> toMap(Account entity) {
    return {
      'id': entity.id,
      'name': entity.name,
      'balance': entity.balance,
      'color': entity.color,
      'is_locked': entity.isLocked ? 1 : 0,
      'type': entity.type,
      'account_type': entity.accountType,
    };
  }

  @override
  Map<String, dynamic> toSyncPayload(Account entity) {
    return {
      'name': entity.name,
      'balance': entity.balance,
      'color': entity.color,
      'isLocked': entity.isLocked,
      'type': entity.type,
      'accountType': entity.accountType,
    };
  }

  @override
  String getId(Account entity) => entity.id ?? '';

  @override
  Account withId(Account entity, String id) {
    return Account(
      id: id,
      name: entity.name,
      balance: entity.balance,
      color: entity.color,
      isLocked: entity.isLocked,
      type: entity.type,
      accountType: entity.accountType,
    );
  }

  @override
  int getVersion(Account entity) => 1;

  @override
  Stream<List<Account>> watchAll() {
    // Initial load
    getAll().then((accounts) {
      if (!_streamController.isClosed) {
        _streamController.add(accounts);
      }
    });
    return _streamController.stream;
  }

  /// Notify listeners of data changes
  Future<void> notifyListeners() async {
    final accounts = await getAll();
    if (!_streamController.isClosed) {
      _streamController.add(accounts);
    }
  }

  @override
  Future<Account> create(Account entity) async {
    final result = await super.create(entity);
    await notifyListeners();
    return result;
  }

  @override
  Future<Account> update(Account entity) async {
    final result = await super.update(entity);
    await notifyListeners();
    return result;
  }

  @override
  Future<void> delete(String id) async {
    await super.delete(id);
    await notifyListeners();
  }

  /// Get total balance across all accounts
  Future<double> getTotalBalance() async {
    final dbInstance = await db.database;
    final result = await dbInstance.rawQuery(
      'SELECT SUM(balance) as total FROM accounts WHERE is_deleted = 0',
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Get accounts by type
  Future<List<Account>> getByType(String accountType) async {
    final dbInstance = await db.database;
    final results = await dbInstance.query(
      tableName,
      where: 'is_deleted = 0 AND account_type = ?',
      whereArgs: [accountType],
      orderBy: 'name ASC',
    );
    return results.map((map) => fromMap(map)).toList();
  }

  void dispose() {
    _streamController.close();
  }
}
