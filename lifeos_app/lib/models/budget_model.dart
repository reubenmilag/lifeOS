class Budget {
  final String? id;
  final String name;
  final double spent;
  final double limit;
  final String color;
  final String icon;

  Budget({
    this.id,
    required this.name,
    required this.spent,
    required this.limit,
    required this.color,
    required this.icon,
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      name: json['name'],
      spent: (json['spent'] as num).toDouble(),
      limit: (json['limit'] as num).toDouble(),
      color: json['color'] ?? '#FFA500',
      icon: json['icon'] ?? 'shoppingCart',
    );
  }

  double get progress => (spent / limit).clamp(0.0, 1.0);
}
