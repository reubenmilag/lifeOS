import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

class CurrencyConverterSheet extends StatefulWidget {
  final ValueNotifier<Map<String, dynamic>?> ratesNotifier;

  const CurrencyConverterSheet({super.key, required this.ratesNotifier});

  @override
  State<CurrencyConverterSheet> createState() => _CurrencyConverterSheetState();
}

class _CurrencyConverterSheetState extends State<CurrencyConverterSheet> {
  late TextEditingController _usdController;
  late TextEditingController _gbpController;
  late TextEditingController _inrController;
  Map<String, double>? _currentRates;
  String? _lastUpdate;

  // To prevent recursive updates
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _usdController = TextEditingController(text: '1.00');
    _gbpController = TextEditingController();
    _inrController = TextEditingController();
    
    final initialData = widget.ratesNotifier.value;
    if (initialData != null) {
      _currentRates = Map<String, double>.from(
        (initialData['rates'] as Map).map((k, v) => MapEntry(k.toString(), (v as num).toDouble())),
      );
      _lastUpdate = initialData['lastUpdate'];
    }
    
    widget.ratesNotifier.addListener(_onRatesChanged);

    if (_currentRates != null) {
      _updateValues(1.0, 'USD');
    }
  }

  @override
  void dispose() {
    widget.ratesNotifier.removeListener(_onRatesChanged);
    _usdController.dispose();
    _gbpController.dispose();
    _inrController.dispose();
    super.dispose();
  }

  void _onRatesChanged() {
    final newData = widget.ratesNotifier.value;
    if (newData == null) return;

    final newRates = Map<String, double>.from(
      (newData['rates'] as Map).map((k, v) => MapEntry(k.toString(), (v as num).toDouble())),
    );
    final newUpdate = newData['lastUpdate'];

    if (_currentRates == null) {
      setState(() {
        _currentRates = newRates;
        _lastUpdate = newUpdate;
        _updateValues(1.0, 'USD');
      });
    } else {
      // Check if rates are significantly different
      if ((newRates['INR']! - _currentRates!['INR']!).abs() > 0.01) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rates updated: ${_formatUpdateDate(newUpdate)}'),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              left: 20,
              right: 20,
            ),
            action: SnackBarAction(
              label: 'Update',
              onPressed: () {
                setState(() {
                  _currentRates = newRates;
                  _lastUpdate = newUpdate;
                  final usdValue = double.tryParse(_usdController.text) ?? 1.0;
                  _updateValues(usdValue, 'USD');
                });
              },
            ),
          ),
        );
      }
    }
  }

  String _formatUpdateDate(String? dateStr) {
    if (dateStr == null || dateStr == 'Fallback Data') return 'Unknown';
    try {
      // open.er-api format is usually "Fri, 27 Dec 2024 00:00:01 +0000"
      final parts = dateStr.split(' ');
      if (parts.length >= 5) {
        return '${parts.sublist(0, 4).join(' ')} at ${parts[4]}';
      }
      return dateStr;
    } catch (e) {
      return dateStr;
    }
  }

  void _updateValues(double value, String sourceCurrency) {
    if (_isUpdating || _currentRates == null) return;
    _isUpdating = true;

    // Convert input to USD first (base currency)
    double valueInUsd;
    if (sourceCurrency == 'USD') {
      valueInUsd = value;
    } else {
      valueInUsd = value / _currentRates![sourceCurrency]!;
    }

    // Update all controllers except the source
    if (sourceCurrency != 'USD') {
      _usdController.text = valueInUsd.toStringAsFixed(2);
    }
    if (sourceCurrency != 'GBP') {
      _gbpController.text = (valueInUsd * _currentRates!['GBP']!).toStringAsFixed(2);
    }
    if (sourceCurrency != 'INR') {
      _inrController.text = (valueInUsd * _currentRates!['INR']!).toStringAsFixed(2);
    }

    _isUpdating = false;
  }

  void _onChanged(String value, String currency) {
    if (value.isEmpty) return;
    final double? amount = double.tryParse(value);
    if (amount != null) {
      _updateValues(amount, currency);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentRates == null) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.4,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Currency Converter',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          if (_lastUpdate != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Last updated: ${_formatUpdateDate(_lastUpdate)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                _buildCurrencyInput(
                  controller: _usdController,
                  currency: 'USD',
                  flag: '🇺🇸',
                  name: 'US Dollar',
                  color: Colors.green,
                ),
                const SizedBox(height: 16),
                _buildCurrencyInput(
                  controller: _gbpController,
                  currency: 'GBP',
                  flag: '🇬🇧',
                  name: 'British Pound',
                  color: Colors.blue,
                ),
                const SizedBox(height: 16),
                _buildCurrencyInput(
                  controller: _inrController,
                  currency: 'INR',
                  flag: '🇮🇳',
                  name: 'Indian Rupee',
                  color: Colors.orange,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyInput({
    required TextEditingController controller,
    required String currency,
    required String flag,
    required String name,
    required Color color,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.9 + (0.1 * value),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                flag,
                style: const TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currency,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    name,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 120,
              child: TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) => _onChanged(value, currency),
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.end,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                  hintText: '0.00',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
