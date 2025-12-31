import 'category_model.dart';
import 'account_model.dart';

class TransactionModel {
  final String? id;
  final double amount;
  final String type; // 'income', 'expense', 'transfer'
  final String? accountId;
  final Account? account; // Populated account
  final String? toAccountId;
  final Account? toAccount; // Populated toAccount
  final String? categoryId;
  final Category? category; // Populated category
  final String? description;
  final List<String>? tags;
  final DateTime date;

  TransactionModel({
    this.id,
    required this.amount,
    required this.type,
    this.accountId,
    this.account,
    this.toAccountId,
    this.toAccount,
    this.categoryId,
    this.category,
    this.description,
    this.tags,
    required this.date,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    Category? category;
    String? categoryId;
    Account? account;
    String? accountId;
    Account? toAccount;
    String? toAccountId;

    if (json['categoryId'] is Map) {
      category = Category.fromJson(json['categoryId']);
      categoryId = category.id;
    } else {
      categoryId = json['categoryId'];
    }

    if (json['accountId'] is Map) {
      account = Account.fromJson(json['accountId']);
      accountId = account.id;
    } else {
      accountId = json['accountId'];
    }

    if (json['toAccountId'] is Map) {
      toAccount = Account.fromJson(json['toAccountId']);
      toAccountId = toAccount.id;
    } else {
      toAccountId = json['toAccountId'];
    }

    return TransactionModel(
      id: json['_id'],
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] ?? 'expense',
      accountId: accountId,
      account: account,
      toAccountId: toAccountId,
      toAccount: toAccount,
      categoryId: categoryId,
      category: category,
      description: json['description'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      date: DateTime.parse(json['date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'type': type,
      'accountId': accountId,
      'toAccountId': toAccountId,
      'categoryId': categoryId,
      'description': description,
      'tags': tags,
      'date': date.toIso8601String(),
    };
  }
}
