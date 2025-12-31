import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:lifeos_app/widgets/account_dashboard.dart';
import 'package:lifeos_app/services/api_service.dart';
import 'package:lifeos_app/models/account_model.dart';
import 'package:lifeos_app/models/budget_model.dart';
import 'package:lifeos_app/models/goal_model.dart';
import 'package:lifeos_app/models/transaction_model.dart';
import 'package:lifeos_app/screens/add_transaction_screen.dart';
import 'package:lifeos_app/widgets/transaction_list.dart';

class FinancesScreen extends StatefulWidget {
  const FinancesScreen({super.key});

  @override
  State<FinancesScreen> createState() => _FinancesScreenState();
}

class _FinancesScreenState extends State<FinancesScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Account>> _accountsFuture;
  late Future<List<Budget>> _budgetsFuture;
  late Future<List<Goal>> _goalsFuture;
  late Future<List<TransactionModel>> _transactionsFuture;

  @override
  void initState() {
    super.initState();
    _refreshAccounts();
    _budgetsFuture = _apiService.getBudgets();
    _goalsFuture = _apiService.getGoals();
  }

  void _refreshAccounts() {
    setState(() {
      _accountsFuture = _apiService.getAccounts();
      _transactionsFuture = _apiService.getTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
              child: const TabBar(
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.black,
                indicatorWeight: 3,
                labelStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                tabs: [
                  Tab(text: 'Accounts'),
                  Tab(text: 'Budgets & Goals'),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(children: [_buildAccountsTab(), _buildBudgetsTab()]),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddTransactionScreen(),
              ),
            );
            
            if (result == true) {
              _refreshAccounts();
            }
          },
          backgroundColor: Colors.black,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildAccountsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildNetWorthCard(),
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
                onRefresh: _refreshAccounts,
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
                  // Navigate to full transaction history
                  // For now just show a snackbar or print
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('View All Transactions - Coming Soon')),
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
        _buildBudgetSummaryCard(),
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
                    child: _buildBudgetItem(
                      budget.name,
                      '\$${budget.spent.toInt()} / \$${budget.limit.toInt()}',
                      budget.progress,
                      _parseColor(budget.color),
                      _getIcon(budget.icon),
                    ),
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
                      '\$${goal.saved.toInt()} / \$${goal.target.toInt()}',
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

  Widget _buildNetWorthCard() {
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
          const Text(
            '\$84,750.70',
            style: TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildNetWorthStat('Assets', '\$85,990', Colors.greenAccent),
              const SizedBox(width: 24),
              _buildNetWorthStat('Liabilities', '-\$1,240', Colors.redAccent),
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

  Widget _buildBudgetSummaryCard() {
    return FCard(
      title: const Text('Monthly Spending'),
      subtitle: const Text('\$1,250 spent of \$2,000 limit'),
      child: Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: 0.625,
                minHeight: 12,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation(Colors.black),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '62.5% Used',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '\$750 left',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetItem(
    String name,
    String amount,
    double progress,
    Color color,
    SvgAsset icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: FIcon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                amount,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
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
