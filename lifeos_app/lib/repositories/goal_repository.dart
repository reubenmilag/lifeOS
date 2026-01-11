import 'dart:async';
import '../models/goal_model.dart';
import '../services/offline/local_database_service.dart';
import '../services/offline/outbox_service.dart';
import '../services/offline/sync_status.dart';
import '../services/offline/sync_engine.dart';
import 'base_repository.dart';

/// Repository for Goal entities with offline-first support
class GoalRepository extends BaseRepository<Goal> {
  final _streamController = StreamController<List<Goal>>.broadcast();

  GoalRepository({
    required super.db,
    required super.outbox,
    required super.syncEngine,
  });

  @override
  EntityType get entityType => EntityType.goal;

  @override
  String get tableName => 'goals';

  @override
  Goal fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['id'] as String?,
      name: map['name'] as String,
      saved: (map['saved'] as num).toDouble(),
      target: (map['target'] as num).toDouble(),
      color: map['color'] as String? ?? '#4B0082',
      icon: map['icon'] as String? ?? 'star',
      deadline: DateTime.parse(map['deadline'] as String).toLocal(),
      note: map['note'] as String?,
    );
  }

  @override
  Map<String, dynamic> toMap(Goal entity) {
    return {
      'id': entity.id,
      'name': entity.name,
      'saved': entity.saved,
      'target': entity.target,
      'color': entity.color,
      'icon': entity.icon,
      'deadline': entity.deadline.toIso8601String(),
      'note': entity.note,
    };
  }

  @override
  Map<String, dynamic> toSyncPayload(Goal entity) {
    return {
      'name': entity.name,
      'saved': entity.saved,
      'target': entity.target,
      'color': entity.color,
      'icon': entity.icon,
      'deadline': entity.deadline.toIso8601String(),
      'note': entity.note,
    };
  }

  @override
  String getId(Goal entity) => entity.id ?? '';

  @override
  Goal withId(Goal entity, String id) {
    return Goal(
      id: id,
      name: entity.name,
      saved: entity.saved,
      target: entity.target,
      color: entity.color,
      icon: entity.icon,
      deadline: entity.deadline,
      note: entity.note,
    );
  }

  @override
  int getVersion(Goal entity) => 1;

  @override
  Stream<List<Goal>> watchAll() {
    getAll().then((goals) {
      if (!_streamController.isClosed) {
        _streamController.add(goals);
      }
    });
    return _streamController.stream;
  }

  Future<void> notifyListeners() async {
    final goals = await getAll();
    if (!_streamController.isClosed) {
      _streamController.add(goals);
    }
  }

  @override
  Future<Goal> create(Goal entity) async {
    final result = await super.create(entity);
    await notifyListeners();
    return result;
  }

  @override
  Future<Goal> update(Goal entity) async {
    final result = await super.update(entity);
    await notifyListeners();
    return result;
  }

  @override
  Future<void> delete(String id) async {
    await super.delete(id);
    await notifyListeners();
  }

  /// Get active goals (not yet past deadline)
  Future<List<Goal>> getActiveGoals() async {
    final dbInstance = await db.database;
    final now = DateTime.now().toIso8601String();
    final results = await dbInstance.query(
      tableName,
      where: 'is_deleted = 0 AND deadline >= ?',
      whereArgs: [now],
      orderBy: 'deadline ASC',
    );
    return results.map((map) => fromMap(map)).toList();
  }

  /// Get completed goals (saved >= target)
  Future<List<Goal>> getCompletedGoals() async {
    final dbInstance = await db.database;
    final results = await dbInstance.query(
      tableName,
      where: 'is_deleted = 0 AND saved >= target',
      orderBy: 'deadline DESC',
    );
    return results.map((map) => fromMap(map)).toList();
  }

  void dispose() {
    _streamController.close();
  }
}
