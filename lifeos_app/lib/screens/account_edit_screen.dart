import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../models/account_model.dart';
import '../services/api_service.dart';

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
    if (widget.account != null) {
      _nameController.text = widget.account!.name ?? '';
      _balanceController.text = widget.account!.balance?.toString() ?? '';
      _selectedColor = widget.account!.color;
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
      final account = Account(
        id: widget.account?.id,
        name: _nameController.text,
        balance: double.tryParse(_balanceController.text) ?? 0.0,
        color: _selectedColor,
        isLocked: widget.account?.isLocked ?? false,
        type: 'standard',
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
                          if (double.tryParse(value) == null) {
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
