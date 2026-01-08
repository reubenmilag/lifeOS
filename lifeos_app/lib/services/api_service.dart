import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dashboard_model.dart';
import '../models/account_model.dart';
import '../models/budget_model.dart';
import '../models/goal_model.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';

class ApiService {
  final Dio _dio;
  final String baseUrl;
  static const String _ratesKey = 'currency_rates';

  ApiService({String? baseUrl})
      : baseUrl = baseUrl ?? 'http://169.254.195.11:3000', // Updated to localhost for simulator/emulator access, might need 10.0.2.2 for Android
        _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ));

  Future<DashboardData> getDashboardData() async {
    try {
      final response = await _dio.get('$baseUrl/dashboard');
      return DashboardData.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to load dashboard data: ${e.message}');
    }
  }

  Future<List<Account>> getAccounts() async {
    try {
      final response = await _dio.get('$baseUrl/api/accounts');
      final List<dynamic> data = response.data;
      return data.map((json) => Account.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception('Failed to load accounts: ${e.message}');
    }
  }

  Future<List<String>> getAccountTypes() async {
    try {
      final response = await _dio.get('$baseUrl/api/account-types');
      final List<dynamic> data = response.data;
      return data.map((json) => json['name'] as String).toList();
    } on DioException catch (e) {
      throw Exception('Failed to load account types: ${e.message}');
    }
  }

  Future<Account> createAccount(Account account) async {
    try {
      final response = await _dio.post(
        '$baseUrl/api/accounts',
        data: account.toJson(),
      );
      return Account.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to create account: ${e.message}');
    }
  }

  Future<Account> updateAccount(Account account) async {
    try {
      final response = await _dio.put(
        '$baseUrl/api/accounts/${account.id}',
        data: account.toJson(),
      );
      return Account.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to update account: ${e.message}');
    }
  }

  Future<void> deleteAccount(String id) async {
    try {
      await _dio.delete('$baseUrl/api/accounts/$id');
    } on DioException catch (e) {
      throw Exception('Failed to delete account: ${e.message}');
    }
  }

  Future<List<Budget>> getBudgets() async {
    try {
      final response = await _dio.get('$baseUrl/api/budgets');
      final List<dynamic> data = response.data;
      return data.map((json) => Budget.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception('Failed to load budgets: ${e.message}');
    }
  }

  Future<Budget> createBudget(Budget budget) async {
    try {
      final response = await _dio.post(
        '$baseUrl/api/budgets',
        data: budget.toJson(),
      );
      return Budget.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to create budget: ${e.message}');
    }
  }

  Future<Budget> updateBudget(Budget budget) async {
    try {
      final response = await _dio.put(
        '$baseUrl/api/budgets/${budget.id}',
        data: budget.toJson(),
      );
      return Budget.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to update budget: ${e.message}');
    }
  }

  Future<void> deleteBudget(String id) async {
    try {
      await _dio.delete('$baseUrl/api/budgets/$id');
    } on DioException catch (e) {
      throw Exception('Failed to delete budget: ${e.message}');
    }
  }

  Future<List<Goal>> getGoals() async {
    try {
      final response = await _dio.get('$baseUrl/api/goals');
      final List<dynamic> data = response.data;
      return data.map((json) => Goal.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception('Failed to load goals: ${e.message}');
    }
  }

  Future<Goal> createGoal(Goal goal) async {
    try {
      final response = await _dio.post(
        '$baseUrl/api/goals',
        data: goal.toJson(),
      );
      return Goal.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to create goal: ${e.message}');
    }
  }

  Future<Goal> updateGoal(Goal goal) async {
    try {
      final response = await _dio.put(
        '$baseUrl/api/goals/${goal.id}',
        data: goal.toJson(),
      );
      return Goal.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to update goal: ${e.message}');
    }
  }

  Future<void> deleteGoal(String id) async {
    try {
      await _dio.delete('$baseUrl/api/goals/$id');
    } on DioException catch (e) {
      throw Exception('Failed to delete goal: ${e.message}');
    }
  }

  Future<List<Category>> getCategories() async {
    try {
      final response = await _dio.get('$baseUrl/api/categories');
      final List<dynamic> data = response.data;
      return data.map((json) => Category.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception('Failed to load categories: ${e.message}');
    }
  }

  Future<TransactionModel> createTransaction(TransactionModel transaction) async {
    try {
      final response = await _dio.post(
        '$baseUrl/api/transactions',
        data: transaction.toJson(),
      );
      // We don't necessarily need to parse the response if we just want to know it succeeded
      // But returning the created object is good practice
      return transaction; 
    } on DioException catch (e) {
      throw Exception('Failed to create transaction: ${e.message}');
    }
  }

  Future<TransactionModel> updateTransaction(TransactionModel transaction) async {
    try {
      final response = await _dio.put(
        '$baseUrl/api/transactions/${transaction.id}',
        data: transaction.toJson(),
      );
      return TransactionModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to update transaction: ${e.message}');
    }
  }

  Future<List<TransactionModel>> getTransactions() async {
    try {
      final response = await _dio.get('$baseUrl/api/transactions');
      final List<dynamic> data = response.data;
      return data.map((json) => TransactionModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception('Failed to load transactions: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> getTransactionsPaginated({
    int page = 1,
    int limit = 10,
    String? search,
    String? type,
    String? categoryId,
    String? accountId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'page': page,
        'limit': limit,
      };
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (type != null) queryParams['type'] = type;
      if (categoryId != null) queryParams['categoryId'] = categoryId;
      if (accountId != null) queryParams['accountId'] = accountId;
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();

      final response = await _dio.get(
        '$baseUrl/api/transactions',
        queryParameters: queryParams,
      );
      
      final List<dynamic> data = response.data['data'];
      final List<TransactionModel> transactions = data.map((json) => TransactionModel.fromJson(json)).toList();
      
      return {
        'data': transactions,
        'meta': response.data['meta'],
      };
    } on DioException catch (e) {
      throw Exception('Failed to load transactions: ${e.message}');
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      await _dio.delete('$baseUrl/api/transactions/$id');
    } on DioException catch (e) {
      throw Exception('Failed to delete transaction: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> getCurrencyRates() async {
    try {
      final response = await _dio.get('https://open.er-api.com/v6/latest/USD');
      final rates = response.data['rates'] as Map<String, dynamic>;
      final String lastUpdate = response.data['time_last_update_utc'] ?? '';
      
      final Map<String, dynamic> data = {
        'rates': {
          'USD': 1.0,
          'GBP': (rates['GBP'] as num).toDouble(),
          'INR': (rates['INR'] as num).toDouble(),
        },
        'lastUpdate': lastUpdate,
      };
      
      await _saveRates(data);
      return data;
    } catch (e) {
      final persisted = await getPersistedRates();
      if (persisted != null) return persisted;

      return {
        'rates': {'USD': 1.0, 'GBP': 0.79, 'INR': 83.12},
        'lastUpdate': 'Fallback Data',
      };
    }
  }

  Future<void> _saveRates(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_ratesKey, jsonEncode(data));
    } catch (e) {}
  }

  Future<Map<String, dynamic>?> getPersistedRates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? ratesJson = prefs.getString(_ratesKey);
      if (ratesJson != null) {
        return jsonDecode(ratesJson);
      }
    } catch (e) {}
    return null;
  }
}
