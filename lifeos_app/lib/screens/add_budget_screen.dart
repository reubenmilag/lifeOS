import 'package:flutter/material.dart';
import 'package:lifeos_app/models/account_model.dart';
import 'package:lifeos_app/models/budget_model.dart';
import 'package:lifeos_app/models/category_model.dart';
import 'package:lifeos_app/services/api_service.dart';
import 'package:intl/intl.dart';

class AddBudgetScreen extends StatefulWidget {
  final Budget? budget;

  const AddBudgetScreen({super.key, this.budget});

  @override
  State<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends State<AddBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  String _name = '';
  String _period = 'Month';
  DateTime? _startDate;
  DateTime? _endDate;
  double _amount = 0;
  String? _selectedCategoryId;
  String? _selectedAccountId;

  // Default color and icon
  String _color = '#FFA500';
  String _icon = 'shoppingCart';

  List<Category> _categories = [];
  List<Account> _accounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.budget != null) {
      _name = widget.budget!.name;
      _period = widget.budget!.period;
      _startDate = widget.budget!.startDate;
      _endDate = widget.budget!.endDate;
      _amount = widget.budget!.limit;
      _selectedCategoryId = widget.budget!.categoryId;
      _selectedAccountId = widget.budget!.accountId;
      _color = widget.budget!.color;
      _icon = widget.budget!.icon;
    }
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final categories = await _apiService.getCategories();
      final accounts = await _apiService.getAccounts();
      setState(() {
        _categories = categories;
        _accounts = accounts;
        _isLoading = false;
      });
    } catch (e) {
      // Handle error
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_period == 'One Time' && (_startDate == null || _endDate == null)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please select start and end dates for One Time budget')),
        );
        return;
      }

      // If category is selected, use its color and icon
      if (_selectedCategoryId != null) {
        final category =
            _categories.firstWhere((c) => c.id == _selectedCategoryId);
        _color = category.color;
        _icon = category.icon;
      }

      final newBudget = Budget(
        id: widget.budget?.id,
        name: _name,
        spent: widget.budget?.spent ?? 0,
        limit: _amount,
        color: _color,
        icon: _icon,
        period: _period,
        startDate: _startDate,
        endDate: _endDate,
        categoryId: _selectedCategoryId,
        accountId: _selectedAccountId,
      );

      try {
        if (widget.budget != null) {
          await _apiService.updateBudget(newBudget);
        } else {
          await _apiService.createBudget(newBudget);
        }
        if (mounted) {
          Navigator.pop(context, true); // Return true to indicate success
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving budget: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.budget != null ? 'Edit Budget' : 'New Budget',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Budget Name'),
                    TextFormField(
                      initialValue: _name,
                      decoration: _inputDecoration('e.g., Monthly Groceries'),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please enter a name'
                          : null,
                      onSaved: (value) => _name = value!,
                    ),
                    const SizedBox(height: 24),
                    _buildLabel('Time Period'),
                    DropdownButtonFormField<String>(
                      value: _period,
                      decoration: _inputDecoration('Select Period'),
                      items: ['Week', 'Month', 'Year', 'One Time']
                          .map((label) => DropdownMenuItem(
                                value: label,
                                child: Text(label),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _period = value!;
                        });
                      },
                    ),
                    if (_period == 'One Time') ...[
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Start Date'),
                                GestureDetector(
                                  onTap: () => _selectDate(context, true),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _startDate == null
                                              ? 'Select Date'
                                              : DateFormat('MMM dd, yyyy')
                                                  .format(_startDate!),
                                          style: TextStyle(
                                            color: _startDate == null
                                                ? Colors.grey
                                                : Colors.black,
                                          ),
                                        ),
                                        const Icon(Icons.calendar_today,
                                            size: 16, color: Colors.grey),
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
                                _buildLabel('End Date'),
                                GestureDetector(
                                  onTap: () => _selectDate(context, false),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _endDate == null
                                              ? 'Select Date'
                                              : DateFormat('MMM dd, yyyy')
                                                  .format(_endDate!),
                                          style: TextStyle(
                                            color: _endDate == null
                                                ? Colors.grey
                                                : Colors.black,
                                          ),
                                        ),
                                        const Icon(Icons.calendar_today,
                                            size: 16, color: Colors.grey),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    _buildLabel('Amount'),
                    TextFormField(
                      initialValue: widget.budget != null ? _amount.toString() : null,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('0.00', prefixText: '₹ '),
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Please enter an amount';
                        if (double.tryParse(value) == null)
                          return 'Invalid amount';
                        return null;
                      },
                      onSaved: (value) => _amount = double.parse(value!),
                    ),
                    const SizedBox(height: 24),
                    _buildLabel('Category'),
                    DropdownButtonFormField<String?>(
                      value: _selectedCategoryId,
                      decoration: _inputDecoration('Select Category'),
                      items: _categories.map((category) {
                        return DropdownMenuItem<String?>(
                          value: category.id,
                          child: Text(category.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategoryId = value;
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Please select a category' : null,
                    ),
                    const SizedBox(height: 24),
                    _buildLabel('Account (Optional)'),
                    DropdownButtonFormField<String?>(
                      value: _selectedAccountId,
                      decoration: _inputDecoration('All Accounts'),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('All Accounts'),
                        ),
                        ..._accounts.map((account) {
                          return DropdownMenuItem<String?>(
                            value: account.id,
                            child: Text(account.name ?? 'Unnamed Account'),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedAccountId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          widget.budget != null ? 'Update Budget' : 'Create Budget',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, {String? prefixText}) {
    return InputDecoration(
      hintText: hint,
      prefixText: prefixText,
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black, width: 1),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
    );
  }
}
