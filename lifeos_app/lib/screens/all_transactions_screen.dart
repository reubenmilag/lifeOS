import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lifeos_app/models/account_model.dart';
import 'package:lifeos_app/models/category_model.dart';
import 'package:lifeos_app/models/transaction_model.dart';
import 'package:lifeos_app/services/api_service.dart';

class AllTransactionsScreen extends StatefulWidget {
  const AllTransactionsScreen({super.key});

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  List<TransactionModel> _transactions = [];
  List<Category> _categories = [];
  List<Account> _accounts = [];
  
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _page = 1;
  int _totalPages = 1;
  final int _limit = 10;

  // Filters
  String? _selectedType;
  String? _selectedCategoryId;
  String? _selectedAccountId;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _page < _totalPages) {
      _loadMoreTransactions();
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _resetAndFetch();
    });
  }

  Future<void> _fetchInitialData() async {
    try {
      final results = await Future.wait([
        _apiService.getCategories(),
        _apiService.getAccounts(),
        _fetchTransactions(page: 1),
      ]);

      if (mounted) {
        setState(() {
          _categories = results[0] as List<Category>;
          _accounts = results[1] as List<Account>;
          // Transactions handled in _fetchTransactions
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _resetAndFetch() async {
    setState(() {
      _isLoading = true;
      _page = 1;
      _transactions.clear();
    });
    await _fetchTransactions(page: 1);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<List<TransactionModel>> _fetchTransactions({required int page}) async {
    try {
      final result = await _apiService.getTransactionsPaginated(
        page: page,
        limit: _limit,
        search: _searchController.text,
        type: _selectedType,
        categoryId: _selectedCategoryId,
        accountId: _selectedAccountId,
        startDate: _startDate,
        endDate: _endDate,
      );

      final newTransactions = result['data'] as List<TransactionModel>;
      final meta = result['meta'];

      if (mounted) {
        setState(() {
          if (page == 1) {
            _transactions = newTransactions;
          } else {
            _transactions.addAll(newTransactions);
          }
          _page = meta['page'];
          _totalPages = meta['totalPages'];
        });
      }
      return newTransactions;
    } catch (e) {
      debugPrint('Error fetching transactions: $e');
      return [];
    }
  }

  Future<void> _loadMoreTransactions() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    await _fetchTransactions(page: _page + 1);
    if (mounted) setState(() => _isLoadingMore = false);
  }

  Future<void> _deleteTransaction(String id) async {
    try {
      await _apiService.deleteTransaction(id);
      setState(() {
        _transactions.removeWhere((t) => t.id == id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting transaction: $e')),
        );
      }
    }
  }

  Map<String, List<TransactionModel>> _groupTransactionsByMonth() {
    final Map<String, List<TransactionModel>> grouped = {};
    for (var transaction in _transactions) {
      final key = DateFormat('MMMM yyyy').format(transaction.date);
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(transaction);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final groupedTransactions = _groupTransactionsByMonth();
    final keys = groupedTransactions.keys.toList();
    final bool isFilterActive = _selectedType != null || 
                               _selectedCategoryId != null || 
                               _selectedAccountId != null || 
                               _startDate != null || 
                               _endDate != null;

    // Calculate closing balances
    // Only valid if we are looking at a complete timeline (no filters that hide transactions)
    // Exception: Account filter is okay if we only want that account's balance history
    final bool isTimelineComplete = _selectedType == null && 
                                    _selectedCategoryId == null && 
                                    _searchController.text.isEmpty &&
                                    _startDate == null && 
                                    _endDate == null;

    double currentBalance = 0;
    if (isTimelineComplete) {
      if (_selectedAccountId != null) {
        final account = _accounts.firstWhere((a) => a.id == _selectedAccountId, orElse: () => Account(color: '', name: ''));
        currentBalance = account.balance ?? 0;
      } else {
        currentBalance = _accounts.fold(0, (sum, a) => sum + (a.balance ?? 0));
      }
    }

    final Map<String, double> closingBalances = {};
    if (isTimelineComplete) {
      for (var key in keys) {
        closingBalances[key] = currentBalance;
        final transactions = groupedTransactions[key]!;
        double income = 0;
        double expense = 0;
        for (var t in transactions) {
          if (t.type == 'income') income += t.amount;
          if (t.type == 'expense') expense += t.amount;
        }
        currentBalance -= (income - expense);
      }
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('All Transactions', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search transactions...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: isFilterActive ? Colors.black : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.filter_list,
                      color: isFilterActive ? Colors.white : Colors.black,
                    ),
                    onPressed: _showFilterBottomSheet,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? _buildSkeletonLoader()
          : RefreshIndicator(
              onRefresh: _resetAndFetch,
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: keys.length + (_isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == keys.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final monthKey = keys[index];
                  final transactions = groupedTransactions[monthKey]!;
                  
                  // Calculate totals
                  double income = 0;
                  double expense = 0;
                  for (var t in transactions) {
                    if (t.type == 'income') income += t.amount;
                    if (t.type == 'expense') expense += t.amount;
                  }
                  final netFlow = income - expense;
                  final closingBalance = isTimelineComplete ? closingBalances[monthKey] : null;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMonthHeader(monthKey, netFlow, closingBalance),
                      ...transactions.map((t) => _buildTransactionItem(t)),
                    ],
                  );
                },
              ),
            ),
    );
  }

  Widget _buildMonthHeader(String title, double netFlow, double? closingBalance) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.grey[50],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              if (closingBalance != null)
                Text(
                  'Closing Balance: ₹${closingBalance.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Net Flow',
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
              Text(
                '${netFlow >= 0 ? '+' : ''}${netFlow.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: netFlow >= 0 ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(TransactionModel transaction) {
    final isExpense = transaction.type == 'expense';
    final isTransfer = transaction.type == 'transfer';
    final color = isTransfer ? Colors.blue : (isExpense ? Colors.red : Colors.green);
    final icon = isTransfer ? Icons.swap_horiz : (isExpense ? Icons.arrow_upward : Icons.arrow_downward);

    return Dismissible(
      key: Key(transaction.id ?? UniqueKey().toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Transaction'),
            content: const Text('Are you sure you want to delete this transaction?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        if (transaction.id != null) {
          _deleteTransaction(transaction.id!);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Text(
            transaction.description ?? 'No Description',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                transaction.category?.name ?? 'Uncategorized',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                DateFormat('MMM d, h:mm a').format(transaction.date),
                style: TextStyle(fontSize: 11, color: Colors.grey[400]),
              ),
            ],
          ),
          trailing: Text(
            '${isExpense ? '-' : (isTransfer ? '' : '+')}₹${transaction.amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return ListView.builder(
      itemCount: 10,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 16,
                      color: Colors.grey[200],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 80,
                      height: 12,
                      color: Colors.grey[200],
                    ),
                  ],
                ),
              ),
              Container(
                width: 60,
                height: 16,
                color: Colors.grey[200],
                margin: const EdgeInsets.only(right: 16),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filters',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text('Transaction Type', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['income', 'expense', 'transfer'].map((type) {
                      final isSelected = _selectedType == type;
                      return FilterChip(
                        label: Text(type.toUpperCase()),
                        selected: isSelected,
                        onSelected: (selected) {
                          setModalState(() {
                            _selectedType = selected ? type : null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('Category', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedCategoryId,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Categories')),
                      ..._categories.map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          )),
                    ],
                    onChanged: (value) {
                      setModalState(() => _selectedCategoryId = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Account', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedAccountId,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Accounts')),
                      ..._accounts.map((a) => DropdownMenuItem(
                            value: a.id,
                            child: Text(a.name ?? 'Unknown Account'),
                          )),
                    ],
                    onChanged: (value) {
                      setModalState(() => _selectedAccountId = value);
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _resetAndFetch();
                      },
                      child: const Text('Apply Filters'),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
