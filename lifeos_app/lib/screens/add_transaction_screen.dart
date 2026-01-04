import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import '../models/account_model.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../services/api_service.dart';
import '../utils/currency_input_formatter.dart';
import '../widgets/hierarchical_category_selector.dart';

class AddTransactionScreen extends StatefulWidget {
  final TransactionModel? transaction;

  const AddTransactionScreen({super.key, this.transaction});

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
    if (widget.transaction != null) {
      _initializeWithTransaction(widget.transaction!);
    }
    _loadData();
  }

  void _initializeWithTransaction(TransactionModel transaction) {
    _selectedType = transaction.type;
    _amountController.text = transaction.amount.toString();
    _descriptionController.text = transaction.description ?? '';
    _tagsController.text = transaction.tags?.join(', ') ?? '';
    _selectedDate = transaction.date;
    _selectedTime = TimeOfDay.fromDateTime(transaction.date);
    // Account and Category selection will be handled in _loadData after fetching lists
  }

  /// Find a category by ID in the hierarchical structure
  Category? _findCategoryById(String id) {
    for (final parent in _categories) {
      if (parent.id == id) return parent;
      for (final child in parent.children) {
        if (child.id == id) return child;
      }
    }
    return null;
  }

  Future<void> _loadData() async {
    try {
      final accounts = await _apiService.getAccounts();
      final categories = await _apiService.getCategories();
      
      if (mounted) {
        setState(() {
          _accounts = accounts.where((a) => a.type != 'add').toList();
          _categories = categories;
          
          if (widget.transaction != null) {
            // Set selected values for edit mode
            try {
              _selectedAccount = _accounts.firstWhere((a) => a.id == widget.transaction!.accountId);
              if (widget.transaction!.toAccountId != null) {
                _selectedToAccount = _accounts.firstWhere((a) => a.id == widget.transaction!.toAccountId);
              }
              if (widget.transaction!.categoryId != null) {
                _selectedCategory = _findCategoryById(widget.transaction!.categoryId!);
              }
            } catch (e) {
              debugPrint('Error matching transaction data: $e');
            }
          } else if (_accounts.isNotEmpty) {
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
        id: widget.transaction?.id, // Preserve ID if editing
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

      if (widget.transaction != null) {
        await _apiService.updateTransaction(transaction);
      } else {
        await _apiService.createTransaction(transaction);
      }

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
        title: Text(
          widget.transaction != null ? 'Edit Transaction' : 'Add Transaction',
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
    return InkWell(
      onTap: () async {
        final result = await showCategorySelector(
          context: context,
          categories: _categories,
          mode: CategorySelectionMode.single,
          filterType: _selectedType,
          initialSingleSelectedId: _selectedCategory?.id,
          title: 'Select Category',
        );
        if (result != null && result.selectedCategories.isNotEmpty) {
          setState(() {
            _selectedCategory = result.selectedCategories.first;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            if (_selectedCategory != null) ...[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _parseColor(_selectedCategory!.color).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getIconData(_selectedCategory!.icon),
                  color: _parseColor(_selectedCategory!.color),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _selectedCategory!.name,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ] else ...[
              Expanded(
                child: Text(
                  'Select Category',
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

  IconData _getIconData(String iconName) {
    const iconMap = {
      'restaurant': Icons.restaurant,
      'restaurant_menu': Icons.restaurant_menu,
      'local_bar': Icons.local_bar,
      'local_cafe': Icons.local_cafe,
      'shopping_cart': Icons.shopping_cart,
      'fastfood': Icons.fastfood,
      'shopping_bag': Icons.shopping_bag,
      'checkroom': Icons.checkroom,
      'hiking': Icons.hiking,
      'local_pharmacy': Icons.local_pharmacy,
      'devices': Icons.devices,
      'sports_esports': Icons.sports_esports,
      'card_giftcard': Icons.card_giftcard,
      'celebration': Icons.celebration,
      'favorite': Icons.favorite,
      'spa': Icons.spa,
      'home': Icons.home,
      'yard': Icons.yard,
      'diamond': Icons.diamond,
      'child_care': Icons.child_care,
      'pets': Icons.pets,
      'construction': Icons.construction,
      'bolt': Icons.bolt,
      'build': Icons.build,
      'account_balance': Icons.account_balance,
      'security': Icons.security,
      'key': Icons.key,
      'cleaning_services': Icons.cleaning_services,
      'directions_bus': Icons.directions_bus,
      'business_center': Icons.business_center,
      'flight': Icons.flight,
      'train': Icons.train,
      'local_taxi': Icons.local_taxi,
      'directions_car': Icons.directions_car,
      'local_gas_station': Icons.local_gas_station,
      'assignment': Icons.assignment,
      'local_parking': Icons.local_parking,
      'car_rental': Icons.car_rental,
      'verified_user': Icons.verified_user,
      'car_repair': Icons.car_repair,
      'theater_comedy': Icons.theater_comedy,
      'fitness_center': Icons.fitness_center,
      'smoking_rooms': Icons.smoking_rooms,
      'library_books': Icons.library_books,
      'volunteer_activism': Icons.volunteer_activism,
      'stadium': Icons.stadium,
      'school': Icons.school,
      'psychology': Icons.psychology,
      'medical_services': Icons.medical_services,
      'brush': Icons.brush,
      'luggage': Icons.luggage,
      'cake': Icons.cake,
      'casino': Icons.casino,
      'live_tv': Icons.live_tv,
      'self_improvement': Icons.self_improvement,
      'computer': Icons.computer,
      'wifi': Icons.wifi,
      'phone_android': Icons.phone_android,
      'mail': Icons.mail,
      'apps': Icons.apps,
      'support_agent': Icons.support_agent,
      'receipt_long': Icons.receipt_long,
      'family_restroom': Icons.family_restroom,
      'gavel': Icons.gavel,
      'health_and_safety': Icons.health_and_safety,
      'money_off': Icons.money_off,
      'receipt': Icons.receipt,
      'trending_up': Icons.trending_up,
      'collections': Icons.collections,
      'insert_chart': Icons.insert_chart,
      'real_estate_agent': Icons.real_estate_agent,
      'savings': Icons.savings,
      'currency_bitcoin': Icons.currency_bitcoin,
      'pie_chart': Icons.pie_chart,
      'show_chart': Icons.show_chart,
      'business': Icons.business,
      'inventory_2': Icons.inventory_2,
      'groups': Icons.groups,
      'hotel': Icons.hotel,
      'engineering': Icons.engineering,
      'workspace_premium': Icons.workspace_premium,
      'child_friendly': Icons.child_friendly,
      'elderly': Icons.elderly,
      'subscriptions': Icons.subscriptions,
      'music_note': Icons.music_note,
      'movie': Icons.movie,
      'cloud': Icons.cloud,
      'build_circle': Icons.build_circle,
      'warning': Icons.warning,
      'emergency': Icons.emergency,
      'local_hospital': Icons.local_hospital,
      'home_repair_service': Icons.home_repair_service,
      'more_horiz': Icons.more_horiz,
      'help_outline': Icons.help_outline,
      'attach_money': Icons.attach_money,
      'payments': Icons.payments,
      'work': Icons.work,
    };
    return iconMap[iconName] ?? Icons.category;
  }

  Color _parseColor(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse('0x$hexColor'));
  }
}
