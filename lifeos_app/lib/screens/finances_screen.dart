import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:lifeos_app/widgets/account_dashboard.dart';
import 'package:lifeos_app/services/api_service.dart';
import 'package:lifeos_app/models/account_model.dart';
import 'package:lifeos_app/models/budget_model.dart';
import 'package:lifeos_app/models/goal_model.dart';
import 'package:lifeos_app/models/category_model.dart';
import 'package:lifeos_app/models/transaction_model.dart';
import 'package:lifeos_app/screens/add_transaction_screen.dart';
import 'package:lifeos_app/screens/add_budget_screen.dart';
import 'package:lifeos_app/screens/add_goal_screen.dart';
import 'package:lifeos_app/screens/all_transactions_screen.dart';
import 'package:lifeos_app/widgets/transaction_list.dart';
import 'package:lifeos_app/utils/formatters.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:lifeos_app/screens/budget_detail_screen.dart';

class FinancesScreen extends StatefulWidget {
  const FinancesScreen({super.key});

  @override
  State<FinancesScreen> createState() => _FinancesScreenState();
}

class _FinancesScreenState extends State<FinancesScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late Future<List<Account>> _accountsFuture;
  late Future<List<Budget>> _budgetsFuture;
  late Future<List<Goal>> _goalsFuture;
  late Future<List<TransactionModel>> _transactionsFuture;
  late Future<List<Category>> _categoriesFuture;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _refreshData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refreshData() {
    setState(() {
      _accountsFuture = _apiService.getAccounts();
      _transactionsFuture = _apiService.getTransactions();
      _budgetsFuture = _apiService.getBudgets();
      _goalsFuture = _apiService.getGoals();
      _categoriesFuture = _apiService.getCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: false,
        title: const Padding(
          padding: EdgeInsets.only(left: 8.0),
          child: Text(
            'Finances',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              letterSpacing: -1.0,
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.black,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'Accounts'),
                Tab(text: 'Budgets & Goals'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildAccountsTab(), _buildBudgetsTab()],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddTransactionScreen(),
                  ),
                );

                if (result == true) {
                  _refreshData();
                }
              },
              backgroundColor: Colors.black,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : SpeedDial(
              icon: Icons.add,
              activeIcon: Icons.close,
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              activeBackgroundColor: Colors.black,
              activeForegroundColor: Colors.white,
              children: [
                SpeedDialChild(
                  child: const Icon(Icons.savings),
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  label: 'Add Budget',
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddBudgetScreen(),
                      ),
                    );

                    if (result == true) {
                      _refreshData();
                    }
                  },
                ),
                SpeedDialChild(
                  child: const Icon(Icons.flag),
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  label: 'Add Goal',
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddGoalScreen(),
                      ),
                    );

                    if (result == true) {
                      _refreshData();
                    }
                  },
                ),
              ],
            ),
    );
  }

  Widget _buildAccountsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        FutureBuilder<List<Account>>(
          future: _accountsFuture,
          builder: (context, snapshot) {
            double assets = 0;
            double liabilities = 0;
            
            if (snapshot.hasData) {
              for (var account in snapshot.data!) {
                if (account.type == 'add') continue;
                
                final balance = account.balance ?? 0;
                if (['Credit Card', 'Loan', 'Mortgage', 'Account with overdraft'].contains(account.accountType)) {
                  liabilities += balance;
                } else {
                  assets += balance;
                }
              }
            }
            
            return _buildNetWorthCard(assets, liabilities);
          },
        ),
        const SizedBox(height: 24),
        FutureBuilder<List<Account>>(
          future: _accountsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No accounts found'));
            } else {
              return AccountDashboard(
                accounts: snapshot.data!,
                onRefresh: _refreshData,
              );
            }
          },
        ),
        const SizedBox(height: 32),
        Divider(color: Colors.grey.withOpacity(0.1), thickness: 1),
        const SizedBox(height: 32),
        FutureBuilder<List<TransactionModel>>(
          future: _transactionsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              final transactions = snapshot.data ?? [];
              final recentTransactions = transactions.take(5).toList();
              return TransactionList(
                transactions: recentTransactions,
                onViewAll: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AllTransactionsScreen(),
                    ),
                  );
                },
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildBudgetsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        FutureBuilder<List<dynamic>>(
          future: Future.wait([_transactionsFuture, _categoriesFuture]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            } else if (snapshot.hasError) {
              return Text('Error loading expenses: ${snapshot.error}');
            } else {
              final transactions = snapshot.data![0] as List<TransactionModel>;
              final categories = snapshot.data![1] as List<Category>;
              return _buildExpensesStructure(transactions, categories);
            }
          },
        ),
        const SizedBox(height: 24),
        const Text(
          'Monthly Budgets',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<Budget>>(
          future: _budgetsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Text('No budgets found');
            } else {
              return Column(
                children: snapshot.data!.map((budget) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _buildCompactBudgetItem(budget),
                  );
                }).toList(),
              );
            }
          },
        ),
        const SizedBox(height: 24),
        const Text(
          'Savings Goals',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<Goal>>(
          future: _goalsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Text('No goals found');
            } else {
              return Column(
                children: snapshot.data!.map((goal) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _buildGoalItem(
                      goal.name,
                      '${Formatters.formatCurrency(goal.saved)} / ${Formatters.formatCurrency(goal.target)}',
                      goal.progress,
                      _parseColor(goal.color),
                    ),
                  );
                }).toList(),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildExpensesStructure(List<TransactionModel> transactions, List<Category> categories) {
    final now = DateTime.now();
    final currentMonthStart = DateTime(now.year, now.month, 1);
    final currentYearStart = DateTime(now.year, 1, 1);

    final expenseTransactions =
        transactions.where((t) => t.type == 'expense').toList();

    final monthlyExpenses = expenseTransactions
        .where((t) =>
            t.date.isAfter(currentMonthStart) ||
            t.date.isAtSameMomentAs(currentMonthStart))
        .toList();
    final yearlyExpenses = expenseTransactions
        .where((t) =>
            t.date.isAfter(currentYearStart) ||
            t.date.isAtSameMomentAs(currentYearStart))
        .toList();

    final monthlyTotal =
        monthlyExpenses.fold(0.0, (sum, t) => sum + t.amount);
    final yearlyTotal =
        yearlyExpenses.fold(0.0, (sum, t) => sum + t.amount);

    final daysInMonth = now.difference(currentMonthStart).inDays + 1;
    final daysInYear = now.difference(currentYearStart).inDays + 1;

    // Build a map from category ID to parent category (for subcategories)
    final Map<String, Category> categoryIdToParent = {};
    for (var parent in categories) {
      for (var child in parent.children) {
        categoryIdToParent[child.id] = parent;
      }
    }

    // Helper to group by parent category (combines subcategories under main category)
    Map<String, double> groupByParentCategory(List<TransactionModel> txns) {
      final map = <String, double>{};
      for (var t in txns) {
        if (t.category == null) {
          map['Uncategorized'] = (map['Uncategorized'] ?? 0) + t.amount;
          continue;
        }
        
        // Check if this is a subcategory
        final parentCategory = categoryIdToParent[t.category!.id];
        final catName = parentCategory?.name ?? t.category!.name;
        map[catName] = (map[catName] ?? 0) + t.amount;
      }
      return map;
    }

    // Helper to get color map for parent categories
    Map<String, Color> getParentCategoryColors(List<TransactionModel> txns) {
      final map = <String, Color>{};
      for (var t in txns) {
        if (t.category == null) {
          map['Uncategorized'] = Colors.grey;
          continue;
        }
        
        // Check if this is a subcategory
        final parentCategory = categoryIdToParent[t.category!.id];
        final catName = parentCategory?.name ?? t.category!.name;
        if (!map.containsKey(catName)) {
          // Use parent category color if it's a subcategory
          map[catName] = parentCategory != null
              ? _parseColor(parentCategory.color)
              : _parseColor(t.category!.color);
        }
      }
      return map;
    }

    final monthlyBreakdown = groupByParentCategory(monthlyExpenses);
    final yearlyBreakdown = groupByParentCategory(yearlyExpenses);

    // Combine all categories for legend
    final allCategories = {
      ...monthlyBreakdown.keys,
      ...yearlyBreakdown.keys
    }.toList();
    final categoryColors = getParentCategoryColors(
        expenseTransactions); // Get colors from all expenses to be safe

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Expenses Structure',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildChartColumn(
                'Monthly Expenses',
                'LAST $daysInMonth DAYS',
                monthlyTotal,
                monthlyBreakdown,
                categoryColors,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Container(
                height: 180,
                width: 1,
                color: Colors.grey.withOpacity(0.1),
              ),
            ),
            Expanded(
              child: _buildChartColumn(
                'Yearly Expenses',
                'LAST $daysInYear DAYS',
                yearlyTotal,
                yearlyBreakdown,
                categoryColors,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildLegend(allCategories, categoryColors),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () {
              // Navigate to detailed breakdown view (placeholder)
            },
            child: const Text('Show more', style: TextStyle(color: Colors.grey)),
          ),
        ),
      ],
    );
  }

  Widget _buildChartColumn(String title, String subtitle, double total,
      Map<String, double> breakdown, Map<String, Color> colors) {
    return Column(
      children: [
        SizedBox(
          height: 120,
          child: breakdown.isEmpty
              ? Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.withOpacity(0.2), width: 8),
                    ),
                  ),
                )
              : PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 30,
                    sections: breakdown.entries.map((e) {
                      return PieChartSectionData(
                        color: colors[e.key],
                        value: e.value,
                        title: '',
                        radius: 20,
                      );
                    }).toList(),
                  ),
                ),
        ),
        const SizedBox(height: 16),
        Text(title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 4),
        Text(subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.grey[600],
                fontSize: 10,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(Formatters.formatCurrency(total),
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildLegend(List<String> categories, Map<String, Color> colors) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: categories.map((cat) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: colors[cat],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(cat, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        );
      }).toList(),
    );
  }

  Color _parseColor(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse('0x$hexColor'));
  }

  SvgAsset _getIcon(String iconName) {
    switch (iconName) {
      case 'shoppingCart':
        return FAssets.icons.shoppingCart;
      case 'bus':
        return FAssets.icons.bus;
      case 'popcorn':
        return FAssets.icons.popcorn;
      default:
        return FAssets.icons.circleDollarSign;
    }
  }

  Widget _buildNetWorthCard(double assets, double liabilities) {
    final netWorth = assets - liabilities;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A1A), Color(0xFF2C2C2E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Net Worth',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            Formatters.formatCurrency(netWorth),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildNetWorthStat('Assets', Formatters.formatCurrency(assets), Colors.greenAccent),
              const SizedBox(width: 24),
              _buildNetWorthStat('Liabilities', '-${Formatters.formatCurrency(liabilities)}', Colors.redAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNetWorthStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }



  Widget _buildCompactBudgetItem(Budget budget) {
    final now = DateTime.now();
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final remainingDays = lastDayOfMonth.day - now.day;
    final daysPassed = now.day;
    final monthProgress = daysPassed / lastDayOfMonth.day;

    final remainingAmount = budget.limit - budget.spent;
    final dailyRemaining =
        remainingDays > 0 ? remainingAmount / remainingDays : 0.0;

    final percentage = (budget.spent / budget.limit).clamp(0.0, 1.0);
    final percentageValue = (budget.spent / budget.limit) * 100;

    Color progressColor;
    if (percentageValue > 90) {
      progressColor = Colors.red;
    } else if (percentageValue > 70) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.green;
    }

    final budgetColor = _parseColor(budget.color);

    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 4),
            spreadRadius: -1,
          )
        ],
      ),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BudgetDetailScreen(budget: budget),
            ),
          );
          if (result == true) {
            _refreshData();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: budgetColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: FIcon(_getIcon(budget.icon),
                        color: budgetColor, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          budget.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(color: Colors.black),
                            children: [
                              TextSpan(
                                text: Formatters.formatCurrency(budget.spent),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              TextSpan(
                                text:
                                    ' / ${Formatters.formatCurrency(budget.limit)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${percentageValue.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: progressColor,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${Formatters.formatCurrency(dailyRemaining)} / day left',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 6,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: percentage,
                      child: Container(
                        decoration: BoxDecoration(
                          color: progressColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment((monthProgress * 2) - 1, 0),
                      child: Container(
                        width: 2,
                        height: 6,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalItem(
    String name,
    String amount,
    double progress,
    Color color,
  ) {
    return FCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(amount, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}
