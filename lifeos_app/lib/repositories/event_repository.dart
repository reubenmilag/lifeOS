import 'dart:async';
import '../models/event_model.dart';
import '../services/offline/local_database_service.dart';
import '../services/offline/outbox_service.dart';
import '../services/offline/sync_status.dart';
import '../services/offline/sync_engine.dart';
import 'base_repository.dart';

/// Repository for Event entities with offline-first support
class EventRepository extends BaseRepository<PlannerEvent> {
  final _streamController = StreamController<List<PlannerEvent>>.broadcast();

  EventRepository({
    required super.db,
    required super.outbox,
    required super.syncEngine,
  });

  @override
  EntityType get entityType => EntityType.event;

  @override
  String get tableName => 'events';

  @override
  PlannerEvent fromMap(Map<String, dynamic> map) {
    return PlannerEvent(
      id: map['id'] as String?,
      title: map['title'] as String,
      startTime: DateTime.parse(map['start_time'] as String).toLocal(),
      endTime: DateTime.parse(map['end_time'] as String).toLocal(),
      notes: map['notes'] as String?,
      color: map['color'] as String? ?? '#18181B',
      isAllDay: (map['is_all_day'] as int?) == 1,
    );
  }

  @override
  Map<String, dynamic> toMap(PlannerEvent entity) {
    return {
      'id': entity.id,
      'title': entity.title,
      'start_time': entity.startTime.toIso8601String(),
      'end_time': entity.endTime.toIso8601String(),
      'notes': entity.notes,
      'color': entity.color,
      'is_all_day': entity.isAllDay ? 1 : 0,
    };
  }

  @override
  Map<String, dynamic> toSyncPayload(PlannerEvent entity) {
    return {
      'title': entity.title,
      'startTime': entity.startTime.toUtc().toIso8601String(),
      'endTime': entity.endTime.toUtc().toIso8601String(),
      'notes': entity.notes,
      'color': entity.color,
      'isAllDay': entity.isAllDay,
    };
  }

  @override
  String getId(PlannerEvent entity) => entity.id ?? '';

  @override
  PlannerEvent withId(PlannerEvent entity, String id) {
    return PlannerEvent(
      id: id,
      title: entity.title,
      startTime: entity.startTime,
      endTime: entity.endTime,
      notes: entity.notes,
      color: entity.color,
      isAllDay: entity.isAllDay,
    );
  }

  @override
  int getVersion(PlannerEvent entity) => 1;

  @override
  Stream<List<PlannerEvent>> watchAll() {
    getAll().then((events) {
      if (!_streamController.isClosed) {
        _streamController.add(events);
      }
    });
    return _streamController.stream;
  }

  Future<void> notifyListeners() async {
    final events = await getAll();
    if (!_streamController.isClosed) {
      _streamController.add(events);
    }
  }

  @override
  Future<List<PlannerEvent>> getAll() async {
    final results = await db.getAll(tableName, orderBy: 'start_time ASC');
    return results.map((map) => fromMap(map)).toList();
  }

  @override
  Future<PlannerEvent> create(PlannerEvent entity) async {
    final result = await super.create(entity);
    await notifyListeners();
    return result;
  }

  @override
  Future<PlannerEvent> update(PlannerEvent entity) async {
    final result = await super.update(entity);
    await notifyListeners();
    return result;
  }

  @override
  Future<void> delete(String id) async {
    await super.delete(id);
    await notifyListeners();
  }

  /// Get events for a specific date range
  Future<List<PlannerEvent>> getByDateRange(DateTime start, DateTime end) async {
    final dbInstance = await db.database;
    final results = await dbInstance.query(
      tableName,
      where: 'is_deleted = 0 AND start_time <= ? AND end_time >= ?',
      whereArgs: [end.toIso8601String(), start.toIso8601String()],
      orderBy: 'start_time ASC',
    );
    return results.map((map) => fromMap(map)).toList();
  }

  /// Get events for a specific day
  Future<List<PlannerEvent>> getEventsForDay(DateTime day) async {
    final startOfDay = DateTime(day.year, day.month, day.day);
    final endOfDay = startOfDay.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
    return getByDateRange(startOfDay, endOfDay);
  }

  /// Get upcoming events
  Future<List<PlannerEvent>> getUpcomingEvents({int limit = 10}) async {
    final dbInstance = await db.database;
    final now = DateTime.now().toIso8601String();
    final results = await dbInstance.query(
      tableName,
      where: 'is_deleted = 0 AND start_time >= ?',
      whereArgs: [now],
      orderBy: 'start_time ASC',
      limit: limit,
    );
    return results.map((map) => fromMap(map)).toList();
  }

  void dispose() {
    _streamController.close();
  }
}
