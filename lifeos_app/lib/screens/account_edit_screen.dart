import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../models/account_model.dart';
import '../services/api_service.dart';
import '../utils/currency_input_formatter.dart';

class AccountEditScreen extends StatefulWidget {
  final Account? account;

  const AccountEditScreen({super.key, this.account});

  @override
  State<AccountEditScreen> createState() => _AccountEditScreenState();
}

class _AccountEditScreenState extends State<AccountEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  final ApiService _apiService = ApiService();
  
  String _selectedColor = '#0099EE';
  bool _isLoading = false;
  List<String> _accountTypes = [];
  String? _selectedAccountType;

  final List<String> _colors = [
    '#0099EE', // Blue
    '#AA66CC', // Purple
    '#333333', // Dark Grey
    '#FF8800', // Orange
    '#4CAF50', // Green
    '#F44336', // Red
    '#E91E63', // Pink
    '#9C27B0', // Deep Purple
  ];

  @override
  void initState() {
    super.initState();
    _loadAccountTypes();
    if (widget.account != null) {
      _nameController.text = widget.account!.name ?? '';
      // Format initial value if exists
      if (widget.account!.balance != null) {
        // We use a temporary formatter just to format the initial string
        final formatter = CurrencyInputFormatter();
        final initialValue = TextEditingValue(text: widget.account!.balance!.toString());
        _balanceController.text = formatter.formatEditUpdate(
          TextEditingValue.empty, 
          initialValue
        ).text;
      }
      _selectedColor = widget.account!.color;
      _selectedAccountType = widget.account!.accountType;
    }
  }

  Future<void> _loadAccountTypes() async {
    try {
      final types = await _apiService.getAccountTypes();
      setState(() {
        _accountTypes = types;
        if (_selectedAccountType == null && types.isNotEmpty) {
          _selectedAccountType = types.first;
        }
      });
    } catch (e) {
      print('Error loading account types: $e');
      // Fallback if API fails
      if (mounted) {
        setState(() {
          _accountTypes = ['General', 'Cash', 'Wallets', 'Current Account', 'Credit Card', 'Saving Account', 'Bonus', 'Insurance', 'Investment', 'Loan', 'Mortgage', 'Account with overdraft'];
          if (_selectedAccountType == null) {
            _selectedAccountType = _accountTypes.first;
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _saveAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Clean the balance string before parsing (remove commas)
      final cleanBalance = _balanceController.text.replaceAll(',', '');
      
      final account = Account(
        id: widget.account?.id,
        name: _nameController.text,
        balance: double.tryParse(cleanBalance) ?? 0.0,
        color: _selectedColor,
        isLocked: widget.account?.isLocked ?? false,
        type: 'standard',
        accountType: _selectedAccountType ?? 'General',
      );

      if (widget.account == null) {
        await _apiService.createAccount(account);
      } else {
        await _apiService.updateAccount(account);
      }

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate refresh needed
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving account: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.account != null;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isEditing ? 'Edit Account' : 'New Account',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveAccount,
              child: const Text(
                'Save',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Balance Input
              Center(
                child: Column(
                  children: [
                    const Text(
                      'Current Balance',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    IntrinsicWidth(
                      child: TextFormField(
                        controller: _balanceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [CurrencyInputFormatter()],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: const InputDecoration(
                          prefixText: '₹',
                          border: InputBorder.none,
                          hintText: '0.00',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a balance';
                          }
                          // Remove commas for validation
                          final cleanValue = value.replaceAll(',', '');
                          if (double.tryParse(cleanValue) == null) {
                            return 'Invalid number';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),

              // Name Input
              const Text(
                'Account Name',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              FTextField(
                controller: _nameController,
                hint: 'e.g. Main Checking',
                // validator: (value) {
                //   if (value == null || value.isEmpty) {
                //     return 'Please enter a name';
                //   }
                //   return null;
                // },
              ),

              const SizedBox(height: 32),

              // Account Type Input
              const Text(
                'Account Type',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedAccountType,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down),
                    items: _accountTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedAccountType = value;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Color Picker
              const Text(
                'Color',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  ..._colors.map((color) {
                    final isSelected = _selectedColor == color;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = color),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: _parseColor(color),
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.black, width: 3)
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    );
                  }),
                  GestureDetector(
                    onTap: _showColorPicker,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: !_colors.contains(_selectedColor)
                            ? _parseColor(_selectedColor)
                            : Colors.white,
                        shape: BoxShape.circle,
                        border: !_colors.contains(_selectedColor)
                            ? Border.all(color: Colors.black, width: 3)
                            : Border.all(color: Colors.grey.shade300, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: !_colors.contains(_selectedColor)
                          ? const Icon(Icons.check, color: Colors.white)
                          : const Icon(Icons.add, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _parseColor(_selectedColor),
            onColorChanged: (color) {
              setState(() {
                _selectedColor = '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
              });
            },
            enableAlpha: false,
            displayThumbColor: true,
            paletteType: PaletteType.hsvWithHue,
          ),
        ),
        actions: <Widget>[
          ElevatedButton(
            child: const Text('Got it'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Color _parseColor(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse('0x$hexColor'));
  }
}
