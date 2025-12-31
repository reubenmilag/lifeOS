class Goal {
  final String? id;
  final String name;
  final double saved;
  final double target;
  final String color;

  Goal({
    this.id,
    required this.name,
    required this.saved,
    required this.target,
    required this.color,
  });

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      name: json['name'],
      saved: (json['saved'] as num).toDouble(),
      target: (json['target'] as num).toDouble(),
      color: json['color'] ?? '#4B0082',
    );
  }

  double get progress => (saved / target).clamp(0.0, 1.0);
}
