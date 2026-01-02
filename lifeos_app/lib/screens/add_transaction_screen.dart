import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import '../models/account_model.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../services/api_service.dart';
import '../utils/currency_input_formatter.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  final ApiService _apiService = ApiService();

  String _selectedType = 'expense'; // expense, income, transfer
  Account? _selectedAccount;
  Account? _selectedToAccount;
  Category? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isLoading = false;

  List<Account> _accounts = [];
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final accounts = await _apiService.getAccounts();
      final categories = await _apiService.getCategories();
      
      if (mounted) {
        setState(() {
          _accounts = accounts.where((a) => a.type != 'add').toList();
          _categories = categories;
          if (_accounts.isNotEmpty) {
            _selectedAccount = _accounts.first;
          }
        });
      }
    } catch (e) {
      // Handle error
      print('Error loading data: $e');
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAccount == null) return;
    if (_selectedType == 'transfer' && _selectedToAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a destination account')),
      );
      return;
    }
    if (_selectedType != 'transfer' && _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // Clean the amount string before parsing (remove commas)
      final cleanAmount = _amountController.text.replaceAll(',', '');

      final transaction = TransactionModel(
        amount: double.parse(cleanAmount),
        type: _selectedType,
        accountId: _selectedAccount!.id!,
        toAccountId: _selectedToAccount?.id,
        categoryId: _selectedCategory?.id,
        description: _descriptionController.text,
        tags: _tagsController.text.isNotEmpty 
            ? _tagsController.text.split(',').map((e) => e.trim()).toList() 
            : [],
        date: dateTime,
      );

      await _apiService.createTransaction(transaction);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving transaction: $e')),
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Add Transaction',
          style: TextStyle(
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
              onPressed: _saveTransaction,
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
              // Type Selector
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildTypeButton('Expense', 'expense'),
                    _buildTypeButton('Income', 'income'),
                    _buildTypeButton('Transfer', 'transfer'),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),

              // Amount Input
              Center(
                child: IntrinsicWidth(
                  child: TextFormField(
                    controller: _amountController,
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
                        return 'Enter amount';
                      }
                      // Remove commas for validation
                      final cleanValue = value.replaceAll(',', '');
                      if (double.tryParse(cleanValue) == null) {
                        return 'Invalid amount';
                      }
                      return null;
                    },
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // From Account
              const Text('From Account', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              _buildAccountDropdown(
                value: _selectedAccount,
                onChanged: (Account? value) {
                  setState(() => _selectedAccount = value);
                },
              ),

              const SizedBox(height: 16),

              // To Account (Transfer only) or Category
              if (_selectedType == 'transfer') ...[
                const Text('To Account', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _buildAccountDropdown(
                  value: _selectedToAccount,
                  onChanged: (Account? value) {
                    setState(() => _selectedToAccount = value);
                  },
                ),
              ] else ...[
                const Text('Category', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _buildCategoryDropdown(),
              ],

              const SizedBox(height: 16),

              // Date & Time
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Date', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (date != null) {
                              setState(() => _selectedDate = date);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16),
                                const SizedBox(width: 8),
                                Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Time', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: _selectedTime,
                            );
                            if (time != null) {
                              setState(() => _selectedTime = time);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time, size: 16),
                                const SizedBox(width: 8),
                                Text(_selectedTime.format(context)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Description
              const Text('Description', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              FTextField(
                controller: _descriptionController,
                hint: 'What is this for?',
                maxLines: 1,
              ),

              const SizedBox(height: 16),

              // Tags
              const Text('Tags', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              FTextField(
                controller: _tagsController,
                hint: 'Comma separated tags',
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton(String label, String value) {
    final isSelected = _selectedType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.black : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountDropdown({
    required Account? value,
    required ValueChanged<Account?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Account>(
          value: value,
          isExpanded: true,
          hint: const Text('Select Account'),
          items: _accounts.map((account) {
            return DropdownMenuItem(
              value: account,
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _parseColor(account.color),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(account.name ?? 'Unknown'),
                  const Spacer(),
                  Text(
                    '₹${account.balance?.toStringAsFixed(0)}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    // Filter categories based on type (income/expense)
    final filteredCategories = _categories.where((c) => c.type == _selectedType).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Category>(
          value: _selectedCategory != null && _selectedCategory!.type == _selectedType 
              ? _selectedCategory 
              : null,
          isExpanded: true,
          hint: const Text('Select Category'),
          items: filteredCategories.map((category) {
            return DropdownMenuItem(
              value: category,
              child: Row(
                children: [
                  // We could use an Icon here if we map the icon string to IconData
                  // For now just text
                  Text(category.name),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedCategory = value),
        ),
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
