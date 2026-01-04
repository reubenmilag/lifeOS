class Budget {
  final String? id;
  final String name;
  final double spent;
  final double limit;
  final String color;
  final String icon;
  final String period;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String> categoryIds;
  final String? accountId;

  // Legacy single category support (for backwards compatibility)
  String? get categoryId => categoryIds.isNotEmpty ? categoryIds.first : null;

  Budget({
    this.id,
    required this.name,
    required this.spent,
    required this.limit,
    required this.color,
    required this.icon,
    this.period = 'Month',
    this.startDate,
    this.endDate,
    List<String>? categoryIds,
    String? categoryId, // Legacy support
    this.accountId,
  }) : categoryIds = categoryIds ?? (categoryId != null ? [categoryId] : []);

  factory Budget.fromJson(Map<String, dynamic> json) {
    // Handle both 'categories' array and legacy 'category' single field
    List<String> categoryIds = [];
    
    if (json['categories'] != null) {
      categoryIds = (json['categories'] as List).map((c) {
        if (c is Map) return c['_id']?.toString() ?? '';
        return c?.toString() ?? '';
      }).where((id) => id.isNotEmpty).toList();
    } else if (json['category'] != null) {
      // Legacy single category support
      final catId = json['category'] is Map
          ? json['category']['_id']?.toString()
          : json['category']?.toString();
      if (catId != null && catId.isNotEmpty) {
        categoryIds = [catId];
      }
    }

    return Budget(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      name: json['name'],
      spent: (json['spent'] as num).toDouble(),
      limit: (json['limit'] as num).toDouble(),
      color: json['color'] ?? '#FFA500',
      icon: json['icon'] ?? 'shoppingCart',
      period: json['period'] ?? 'Month',
      startDate:
          json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      categoryIds: categoryIds,
      accountId: json['account'] is Map
          ? json['account']['_id']
          : json['account']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'spent': spent,
      'limit': limit,
      'color': color,
      'icon': icon,
      'period': period,
      if (startDate != null) 'startDate': startDate!.toIso8601String(),
      if (endDate != null) 'endDate': endDate!.toIso8601String(),
      if (categoryIds.isNotEmpty) 'categories': categoryIds,
      if (accountId != null) 'account': accountId,
    };
  }

  double get progress => (spent / limit).clamp(0.0, 1.0);
}
