class Account {
  final String? id;
  final String? name;
  final double? balance;
  final String color;
  final bool isLocked;
  final String type;
  final String accountType;

  Account({
    this.id,
    this.name,
    this.balance,
    required this.color,
    this.isLocked = false,
    this.type = 'standard',
    this.accountType = 'General',
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      name: json['name'],
      balance: (json['balance'] as num?)?.toDouble(),
      color: json['color'] ?? '#0099EE',
      isLocked: json['isLocked'] ?? false,
      type: json['type'] ?? 'standard',
      accountType: json['accountType'] ?? 'General',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'balance': balance,
      'color': color,
      'isLocked': isLocked,
      'type': type,
      'accountType': accountType,
    };
  }
}
