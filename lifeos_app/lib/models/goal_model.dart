class Goal {
  final String? id;
  final String name;
  final double saved;
  final double target;
  final String color;
  final String icon;
  final DateTime deadline;
  final String? note;

  Goal({
    this.id,
    required this.name,
    required this.saved,
    required this.target,
    required this.color,
    required this.icon,
    required this.deadline,
    this.note,
  });

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      name: json['name'],
      saved: (json['saved'] as num).toDouble(),
      target: (json['target'] as num).toDouble(),
      color: json['color'] ?? '#4B0082',
      icon: json['icon'] ?? 'star',
      deadline: json['deadline'] != null 
          ? DateTime.parse(json['deadline']) 
          : DateTime.now().add(const Duration(days: 30)),
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'saved': saved,
      'target': target,
      'color': color,
      'icon': icon,
      'deadline': deadline.toIso8601String(),
      if (note != null) 'note': note,
    };
  }

  double get progress => (saved / target).clamp(0.0, 1.0);
}
