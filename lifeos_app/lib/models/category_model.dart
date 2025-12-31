class Category {
  final String id;
  final String name;
  final String icon;
  final String color;
  final String type;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Unknown',
      icon: json['icon'] ?? 'help_outline',
      color: json['color'] ?? '#000000',
      type: json['type'] ?? 'expense',
    );
  }
}
