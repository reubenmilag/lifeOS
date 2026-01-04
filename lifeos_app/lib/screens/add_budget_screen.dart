import 'package:flutter/material.dart';
import 'package:lifeos_app/models/account_model.dart';
import 'package:lifeos_app/models/budget_model.dart';
import 'package:lifeos_app/models/category_model.dart';
import 'package:lifeos_app/services/api_service.dart';
import 'package:lifeos_app/widgets/hierarchical_category_selector.dart';
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
  List<String> _selectedCategoryIds = [];
  List<Category> _selectedCategories = [];
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
      _selectedCategoryIds = List.from(widget.budget!.categoryIds);
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
        
        // Find selected categories for editing mode
        if (_selectedCategoryIds.isNotEmpty) {
          _selectedCategories = _selectedCategoryIds
              .map((id) => _findCategoryById(id))
              .whereType<Category>()
              .toList();
        }
      });
    } catch (e) {
      // Handle error
      setState(() {
        _isLoading = false;
      });
    }
  }

  Category? _findCategoryById(String id) {
    for (final parent in _categories) {
      if (parent.id == id) return parent;
      for (final child in parent.children) {
        if (child.id == id) return child;
      }
    }
    return null;
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

      if (_selectedCategoryIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one category')),
        );
        return;
      }

      // Use first selected category's color and icon for the budget
      if (_selectedCategories.isNotEmpty) {
        _color = _selectedCategories.first.color;
        _icon = _selectedCategories.first.icon;
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
        categoryIds: _selectedCategoryIds,
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
                    _buildCategorySelector(),
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

  Widget _buildCategorySelector() {
    return InkWell(
      onTap: () async {
        final result = await showCategorySelector(
          context: context,
          categories: _categories,
          mode: CategorySelectionMode.multi,
          filterType: 'expense', // Budgets are typically for expenses
          initialSelectedIds: _selectedCategoryIds,
          title: 'Select Categories',
        );
        if (result != null) {
          setState(() {
            _selectedCategories = result.selectedCategories;
            _selectedCategoryIds = result.selectedIds;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            if (_selectedCategories.isNotEmpty) ...[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _parseColor(_selectedCategories.first.color).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _selectedCategories.length > 1
                    ? Center(
                        child: Text(
                          '${_selectedCategories.length}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _parseColor(_selectedCategories.first.color),
                          ),
                        ),
                      )
                    : Icon(
                        _getIconData(_selectedCategories.first.icon),
                        color: _parseColor(_selectedCategories.first.color),
                        size: 20,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _selectedCategories.length == 1
                      ? _selectedCategories.first.name
                      : '${_selectedCategories.length} categories selected',
                  style: const TextStyle(fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ] else ...[
              Expanded(
                child: Text(
                  'Select Categories',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
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

  IconData _getIconData(String iconName) {
    const iconMap = {
      'restaurant': Icons.restaurant,
      'shopping_bag': Icons.shopping_bag,
      'home': Icons.home,
      'directions_bus': Icons.directions_bus,
      'directions_car': Icons.directions_car,
      'theater_comedy': Icons.theater_comedy,
      'computer': Icons.computer,
      'account_balance': Icons.account_balance,
      'trending_up': Icons.trending_up,
      'business': Icons.business,
      'family_restroom': Icons.family_restroom,
      'subscriptions': Icons.subscriptions,
      'warning': Icons.warning,
      'more_horiz': Icons.more_horiz,
      'attach_money': Icons.attach_money,
    };
    return iconMap[iconName] ?? Icons.category;
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
