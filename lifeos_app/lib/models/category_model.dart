class Category {
  final String id;
  final String name;
  final String icon;
  final String color;
  final String type;
  final String? parentId;
  final int order;
  final List<Category> children;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
    this.parentId,
    this.order = 0,
    this.children = const [],
  });

  bool get isParent => parentId == null;
  bool get hasChildren => children.isNotEmpty;

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Unknown',
      icon: json['icon'] ?? 'help_outline',
      color: json['color'] ?? '#000000',
      type: json['type'] ?? 'expense',
      parentId: json['parentId'],
      order: json['order'] ?? 0,
      children: json['children'] != null
          ? (json['children'] as List)
              .map((c) => Category.fromJson(c))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'type': type,
      'parentId': parentId,
      'order': order,
    };
  }
}
