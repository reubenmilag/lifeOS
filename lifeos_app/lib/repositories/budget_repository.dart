import 'dart:async';
import '../models/budget_model.dart';
import '../services/offline/local_database_service.dart';
import '../services/offline/outbox_service.dart';
import '../services/offline/sync_status.dart';
import '../services/offline/sync_engine.dart';
import 'base_repository.dart';

/// Repository for Budget entities with offline-first support
class BudgetRepository extends BaseRepository<Budget> {
  final _streamController = StreamController<List<Budget>>.broadcast();

  BudgetRepository({
    required super.db,
    required super.outbox,
    required super.syncEngine,
  });

  @override
  EntityType get entityType => EntityType.budget;

  @override
  String get tableName => 'budgets';

  @override
  Budget fromMap(Map<String, dynamic> map) {
    final categoryIdsStr = map['category_ids'] as String?;
    final categoryIds = categoryIdsStr != null && categoryIdsStr.isNotEmpty
        ? categoryIdsStr.split(',').where((id) => id.isNotEmpty).toList()
        : <String>[];

    return Budget(
      id: map['id'] as String?,
      name: map['name'] as String,
      spent: (map['spent'] as num).toDouble(),
      limit: (map['budget_limit'] as num).toDouble(),
      color: map['color'] as String? ?? '#FFA500',
      icon: map['icon'] as String? ?? 'shoppingCart',
      period: map['period'] as String? ?? 'Month',
      startDate: map['start_date'] != null 
          ? DateTime.parse(map['start_date'] as String).toLocal()
          : null,
      endDate: map['end_date'] != null 
          ? DateTime.parse(map['end_date'] as String).toLocal()
          : null,
      categoryIds: categoryIds,
      accountId: map['account_id'] as String?,
    );
  }

  @override
  Map<String, dynamic> toMap(Budget entity) {
    return {
      'id': entity.id,
      'name': entity.name,
      'spent': entity.spent,
      'budget_limit': entity.limit,
      'color': entity.color,
      'icon': entity.icon,
      'period': entity.period,
      'start_date': entity.startDate?.toIso8601String(),
      'end_date': entity.endDate?.toIso8601String(),
      'category_ids': entity.categoryIds.join(','),
      'account_id': entity.accountId,
    };
  }

  @override
  Map<String, dynamic> toSyncPayload(Budget entity) {
    return {
      'name': entity.name,
      'spent': entity.spent,
      'limit': entity.limit,
      'color': entity.color,
      'icon': entity.icon,
      'period': entity.period,
      'startDate': entity.startDate?.toIso8601String(),
      'endDate': entity.endDate?.toIso8601String(),
      'categories': entity.categoryIds,
      'account': entity.accountId,
    };
  }

  @override
  String getId(Budget entity) => entity.id ?? '';

  @override
  Budget withId(Budget entity, String id) {
    return Budget(
      id: id,
      name: entity.name,
      spent: entity.spent,
      limit: entity.limit,
      color: entity.color,
      icon: entity.icon,
      period: entity.period,
      startDate: entity.startDate,
      endDate: entity.endDate,
      categoryIds: entity.categoryIds,
      accountId: entity.accountId,
    );
  }

  @override
  int getVersion(Budget entity) => 1;

  @override
  Stream<List<Budget>> watchAll() {
    getAll().then((budgets) {
      if (!_streamController.isClosed) {
        _streamController.add(budgets);
      }
    });
    return _streamController.stream;
  }

  Future<void> notifyListeners() async {
    final budgets = await getAll();
    if (!_streamController.isClosed) {
      _streamController.add(budgets);
    }
  }

  @override
  Future<Budget> create(Budget entity) async {
    final result = await super.create(entity);
    await notifyListeners();
    return result;
  }

  @override
  Future<Budget> update(Budget entity) async {
    final result = await super.update(entity);
    await notifyListeners();
    return result;
  }

  @override
  Future<void> delete(String id) async {
    await super.delete(id);
    await notifyListeners();
  }

  /// Get active budgets (within date range or no dates)
  Future<List<Budget>> getActiveBudgets() async {
    final now = DateTime.now();
    final all = await getAll();
    return all.where((budget) {
      if (budget.startDate == null && budget.endDate == null) {
        return true;
      }
      if (budget.startDate != null && budget.startDate!.isAfter(now)) {
        return false;
      }
      if (budget.endDate != null && budget.endDate!.isBefore(now)) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Get budgets by category
  Future<List<Budget>> getByCategory(String categoryId) async {
    final all = await getAll();
    return all.where((budget) => budget.categoryIds.contains(categoryId)).toList();
  }

  void dispose() {
    _streamController.close();
  }
}
