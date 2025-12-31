class DashboardData {
  final User user;
  final Finance finance;
  final List<FocusItem> focus;
  final Health health;

  DashboardData({
    required this.user,
    required this.finance,
    required this.focus,
    required this.health,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      user: User.fromJson(json['user']),
      finance: Finance.fromJson(json['finance']),
      focus: (json['focus'] as List)
          .map((item) => FocusItem.fromJson(item))
          .toList(),
      health: Health.fromJson(json['health']),
    );
  }
}

class User {
  final String name;
  final String greeting;

  User({
    required this.name,
    required this.greeting,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'],
      greeting: json['greeting'],
    );
  }
}

class Finance {
  final double totalAssets;
  final String currency;
  final double dailyChange;

  Finance({
    required this.totalAssets,
    required this.currency,
    required this.dailyChange,
  });

  factory Finance.fromJson(Map<String, dynamic> json) {
    return Finance(
      totalAssets: json['totalAssets'].toDouble(),
      currency: json['currency'],
      dailyChange: json['dailyChange'].toDouble(),
    );
  }
}

class FocusItem {
  final String type;
  final String title;
  final String? time;
  final bool? completed;
  final int? current;
  final int? target;
  final String? unit;
  final String? status;
  final int? duration;

  FocusItem({
    required this.type,
    required this.title,
    this.time,
    this.completed,
    this.current,
    this.target,
    this.unit,
    this.status,
    this.duration,
  });

  factory FocusItem.fromJson(Map<String, dynamic> json) {
    return FocusItem(
      type: json['type'],
      title: json['title'],
      time: json['time'],
      completed: json['completed'],
      current: json['current'],
      target: json['target'],
      unit: json['unit'],
      status: json['status'],
      duration: json['duration'],
    );
  }
}

class Health {
  final int caloriesConsumed;
  final int caloriesTarget;

  Health({
    required this.caloriesConsumed,
    required this.caloriesTarget,
  });

  factory Health.fromJson(Map<String, dynamic> json) {
    return Health(
      caloriesConsumed: json['caloriesConsumed'],
      caloriesTarget: json['caloriesTarget'],
    );
  }
}
