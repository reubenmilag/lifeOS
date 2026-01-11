import 'dart:async';
import '../models/category_model.dart';
import '../services/offline/local_database_service.dart';
import '../services/offline/outbox_service.dart';
import '../services/offline/sync_status.dart';
import '../services/offline/sync_engine.dart';
import 'base_repository.dart';

/// Repository for Category entities with offline-first support
class CategoryRepository extends BaseRepository<Category> {
  final _streamController = StreamController<List<Category>>.broadcast();

  CategoryRepository({
    required super.db,
    required super.outbox,
    required super.syncEngine,
  });

  @override
  EntityType get entityType => EntityType.category;

  @override
  String get tableName => 'categories';

  @override
  Category fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      name: map['name'] as String,
      icon: map['icon'] as String? ?? 'help_outline',
      color: map['color'] as String? ?? '#000000',
      type: map['type'] as String? ?? 'expense',
      parentId: map['parent_id'] as String?,
      order: map['sort_order'] as int? ?? 0,
    );
  }

  @override
  Map<String, dynamic> toMap(Category entity) {
    return {
      'id': entity.id,
      'name': entity.name,
      'icon': entity.icon,
      'color': entity.color,
      'type': entity.type,
      'parent_id': entity.parentId,
      'sort_order': entity.order,
    };
  }

  @override
  Map<String, dynamic> toSyncPayload(Category entity) {
    return {
      'name': entity.name,
      'icon': entity.icon,
      'color': entity.color,
      'type': entity.type,
      'parentId': entity.parentId,
      'order': entity.order,
    };
  }

  @override
  String getId(Category entity) => entity.id;

  @override
  Category withId(Category entity, String id) {
    return Category(
      id: id,
      name: entity.name,
      icon: entity.icon,
      color: entity.color,
      type: entity.type,
      parentId: entity.parentId,
      order: entity.order,
    );
  }

  @override
  int getVersion(Category entity) => 1;

  @override
  Stream<List<Category>> watchAll() {
    getAll().then((categories) {
      if (!_streamController.isClosed) {
        _streamController.add(categories);
      }
    });
    return _streamController.stream;
  }

  Future<void> notifyListeners() async {
    final categories = await getAll();
    if (!_streamController.isClosed) {
      _streamController.add(categories);
    }
  }

  @override
  Future<List<Category>> getAll() async {
    final results = await db.getAll(tableName, orderBy: 'sort_order ASC, name ASC');
    return results.map((map) => fromMap(map)).toList();
  }

  @override
  Future<Category> create(Category entity) async {
    final result = await super.create(entity);
    await notifyListeners();
    return result;
  }

  @override
  Future<Category> update(Category entity) async {
    final result = await super.update(entity);
    await notifyListeners();
    return result;
  }

  @override
  Future<void> delete(String id) async {
    await super.delete(id);
    await notifyListeners();
  }

  /// Get categories by type (income/expense)
  Future<List<Category>> getByType(String type) async {
    final dbInstance = await db.database;
    final results = await dbInstance.query(
      tableName,
      where: 'is_deleted = 0 AND type = ?',
      whereArgs: [type],
      orderBy: 'sort_order ASC, name ASC',
    );
    return results.map((map) => fromMap(map)).toList();
  }

  /// Get parent categories only (no parentId)
  Future<List<Category>> getParentCategories() async {
    final dbInstance = await db.database;
    final results = await dbInstance.query(
      tableName,
      where: 'is_deleted = 0 AND parent_id IS NULL',
      orderBy: 'sort_order ASC, name ASC',
    );
    return results.map((map) => fromMap(map)).toList();
  }

  /// Get child categories for a parent
  Future<List<Category>> getChildCategories(String parentId) async {
    final dbInstance = await db.database;
    final results = await dbInstance.query(
      tableName,
      where: 'is_deleted = 0 AND parent_id = ?',
      whereArgs: [parentId],
      orderBy: 'sort_order ASC, name ASC',
    );
    return results.map((map) => fromMap(map)).toList();
  }

  /// Get hierarchical categories (parents with children)
  Future<List<Category>> getHierarchicalCategories() async {
    final all = await getAll();
    final parents = all.where((c) => c.parentId == null).toList();
    
    return parents.map((parent) {
      final children = all.where((c) => c.parentId == parent.id).toList();
      return Category(
        id: parent.id,
        name: parent.name,
        icon: parent.icon,
        color: parent.color,
        type: parent.type,
        parentId: parent.parentId,
        order: parent.order,
        children: children,
      );
    }).toList();
  }

  void dispose() {
    _streamController.close();
  }
}
