import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dashboard_model.dart';

class ApiService {
  final Dio _dio;
  final String baseUrl;
  static const String _ratesKey = 'currency_rates';

  ApiService({String? baseUrl})
      : baseUrl = baseUrl ?? 'http://192.168.0.102:3000',
        _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 3),
        ));

  Future<DashboardData> getDashboardData() async {
    try {
      final response = await _dio.get('$baseUrl/dashboard');
      return DashboardData.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to load dashboard data: ${e.message}');
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
