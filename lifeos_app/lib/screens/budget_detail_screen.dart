import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:lifeos_app/models/budget_model.dart';
import 'package:lifeos_app/models/transaction_model.dart';
import 'package:lifeos_app/screens/add_budget_screen.dart';
import 'package:lifeos_app/services/api_service.dart';
import 'package:lifeos_app/utils/formatters.dart';
import 'package:lifeos_app/widgets/transaction_list.dart';

class BudgetDetailScreen extends StatefulWidget {
  final Budget budget;

  const BudgetDetailScreen({super.key, required this.budget});

  @override
  State<BudgetDetailScreen> createState() => _BudgetDetailScreenState();
}

class _BudgetDetailScreenState extends State<BudgetDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  List<TransactionModel> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchTransactions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchTransactions() async {
    DateTime now = DateTime.now();
    DateTime startDate;
    DateTime endDate;

    if (widget.budget.period == 'One Time') {
      startDate = widget.budget.startDate ?? now;
      endDate = widget.budget.endDate ?? now;
    } else if (widget.budget.period == 'Year') {
      startDate = DateTime(now.year, 1, 1);
      endDate = DateTime(now.year, 12, 31);
    } else if (widget.budget.period == 'Week') {
      startDate = now.subtract(Duration(days: now.weekday - 1));
      endDate = startDate.add(const Duration(days: 6));
    } else {
      // Default to Month
      startDate = DateTime(now.year, now.month, 1);
      endDate = DateTime(now.year, now.month + 1, 0);
    }

    try {
      final result = await _apiService.getTransactionsPaginated(
        limit: 100, // Fetch enough for the detail view
        categoryId: widget.budget.categoryId,
        accountId: widget.budget.accountId,
        startDate: startDate,
        endDate: endDate,
        type: 'expense',
      );

      final allTransactions = result['data'] as List<TransactionModel>;

      // Client-side filtering to ensure strict adherence to budget constraints
      // This acts as a safeguard in case the API returns broader results
      final filteredTransactions = allTransactions.where((t) {
        if (widget.budget.categoryId != null &&
            widget.budget.categoryId!.isNotEmpty) {
          if (t.categoryId != widget.budget.categoryId) return false;
        }
        if (widget.budget.accountId != null &&
            widget.budget.accountId!.isNotEmpty) {
          if (t.accountId != widget.budget.accountId) return false;
        }
        return true;
      }).toList();

      setState(() {
        _transactions = filteredTransactions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Handle error silently or show snackbar
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Budget'),
        content: const Text('Are you sure you want to delete this budget?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.black)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog
              try {
                await _apiService.deleteBudget(widget.budget.id!);
                if (mounted) {
                  Navigator.pop(context, true); // Return to previous screen with refresh signal
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting budget: $e')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.budget.name,
          style:
              const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.black),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddBudgetScreen(budget: widget.budget),
                ),
              );
              if (result == true) {
                // Refresh data if budget was updated
                // Since we don't have a way to refresh the parent's budget object easily without a callback or state management,
                // we might need to pop this screen or refetch the budget.
                // For now, let's just pop to refresh the list in FinancesScreen, or we could refetch here if we had an ID.
                // But wait, the budget object is passed in. If we update it, this screen's widget.budget is stale.
                // Ideally, we should refetch the budget details.
                // But we don't have a getBudgetById method yet.
                // Let's just pop for now, so the user goes back to the list which refreshes.
                Navigator.pop(context, true);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _confirmDelete(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.black,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Transactions'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildTransactionsTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(),
          const SizedBox(height: 24),
          const Text(
            'Spending Trend',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildSpendingChart(),
          const SizedBox(height: 24),
          if (_transactions.isNotEmpty)
            TransactionList(
              transactions: _transactions.take(4).toList(),
              onViewAll: () {
                _tabController.animateTo(1);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTransactionsTab() {
    if (_transactions.isEmpty) {
      return const Center(child: Text('No transactions found'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        return _buildTransactionItem(_transactions[index]);
      },
    );
  }

  Widget _buildSummaryCard() {
    // Calculate time progress and daily allowance
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;

    if (widget.budget.period == 'One Time') {
      startDate = widget.budget.startDate ?? now;
      endDate = widget.budget.endDate ?? now;
    } else if (widget.budget.period == 'Year') {
      startDate = DateTime(now.year, 1, 1);
      endDate = DateTime(now.year, 12, 31);
    } else if (widget.budget.period == 'Week') {
      startDate = now.subtract(Duration(days: now.weekday - 1));
      endDate = startDate.add(const Duration(days: 6));
    } else {
      // Default to Month
      startDate = DateTime(now.year, now.month, 1);
      endDate = DateTime(now.year, now.month + 1, 0);
    }

    // Normalize dates to ignore time components
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    final current = DateTime(now.year, now.month, now.day);

    final totalDays = end.difference(start).inDays + 1;
    final daysPassed = current.difference(start).inDays + 1;
    final remainingDays = end.difference(current).inDays + 1;

    final timeProgress = (daysPassed / totalDays).clamp(0.0, 1.0);
    
    final remainingAmount = widget.budget.limit - widget.budget.spent;
    final dailyRemaining = remainingDays > 0 
        ? (remainingAmount > 0 ? remainingAmount / remainingDays : 0.0) 
        : 0.0;

    final percentage = (widget.budget.spent / widget.budget.limit).clamp(0.0, 1.0);
    final percentageValue = (widget.budget.spent / widget.budget.limit) * 100;
    Color progressColor = percentageValue > 90
        ? Colors.red
        : (percentageValue > 70 ? Colors.orange : Colors.green);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Spent',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Formatters.formatCurrency(widget.budget.spent),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Budget Limit',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Formatters.formatCurrency(widget.budget.limit),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 12,
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
                  alignment: Alignment((timeProgress * 2) - 1, 0),
                  child: Container(
                    width: 2,
                    height: 12,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${Formatters.formatCurrency(dailyRemaining)} / day left',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${percentageValue.toStringAsFixed(1)}% Used',
                style: TextStyle(
                  color: progressColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingChart() {
    // Calculate date range
    DateTime now = DateTime.now();
    DateTime startDate;
    DateTime endDate;

    if (widget.budget.period == 'One Time') {
      startDate = widget.budget.startDate ?? now;
      endDate = widget.budget.endDate ?? now;
    } else if (widget.budget.period == 'Year') {
      startDate = DateTime(now.year, 1, 1);
      endDate = DateTime(now.year, 12, 31);
    } else if (widget.budget.period == 'Week') {
      startDate = now.subtract(Duration(days: now.weekday - 1));
      endDate = startDate.add(const Duration(days: 6));
    } else {
      startDate = DateTime(now.year, now.month, 1);
      endDate = DateTime(now.year, now.month + 1, 0);
    }

    final totalDays = endDate.difference(startDate).inDays + 1;

    // Prepare spots
    List<FlSpot> spots = [];
    double currentSpent = 0;

    // Create a map of date -> amount spent that day
    Map<int, double> dailyAmounts = {};
    for (var t in _transactions) {
      // Normalize date to remove time
      final date = DateTime(t.date.year, t.date.month, t.date.day);
      final dayDiff = date.difference(startDate).inDays;
      if (dayDiff >= 0 && dayDiff < totalDays) {
        dailyAmounts[dayDiff] = (dailyAmounts[dayDiff] ?? 0) + t.amount;
      }
    }

    // Generate cumulative spots
    for (int i = 0; i < totalDays; i++) {
      if (dailyAmounts.containsKey(i)) {
        currentSpent += dailyAmounts[i]!;
      }

      final date = startDate.add(Duration(days: i));
      // Stop plotting if date is in the future
      if (date.isAfter(now)) {
        break;
      }

      spots.add(FlSpot(i.toDouble(), currentSpent));
    }

    // If no spots, add at least start point
    if (spots.isEmpty) {
      spots.add(const FlSpot(0, 0));
    }

    final maxY = widget.budget.limit > 0 ? widget.budget.limit * 1.2 : 100.0;
    final interval = maxY / 5;

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          clipData: const FlClipData.all(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.shade100,
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                interval: interval,
                getTitlesWidget: (value, meta) {
                  if (value > maxY) return const SizedBox.shrink();
                  return Text(
                    Formatters.formatCurrency(value).replaceAll('.00', ''),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.right,
                  );
                },
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: (totalDays / 5).ceilToDouble(),
                getTitlesWidget: (value, meta) {
                  if (value >= totalDays) return const SizedBox.shrink();
                  final date = startDate.add(Duration(days: value.toInt()));
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('MMM d').format(date),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (totalDays - 1).toDouble(),
          minY: 0,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.black,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.black.withOpacity(0.05),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) => Colors.black,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final date = startDate.add(Duration(days: spot.x.toInt()));
                  return LineTooltipItem(
                    '${DateFormat('MMM d').format(date)}\n${Formatters.formatCurrency(spot.y)}',
                    const TextStyle(color: Colors.white),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  // Duplicated from TransactionList for flexibility in the Transactions tab
  Widget _buildTransactionItem(TransactionModel transaction) {
    final isExpense = transaction.type == 'expense';
    final isTransfer = transaction.type == 'transfer';
    
    final amountColor = isExpense 
        ? Colors.black87 
        : (isTransfer ? Colors.blue.shade700 : Colors.green.shade700);
    
    final prefix = isExpense ? '-' : (isTransfer ? '' : '+');
    
    IconData iconData = Icons.attach_money;
    Color iconColor = Colors.grey;
    String title = transaction.description ?? 'Transaction';
    String subtitle = transaction.account?.name ?? 'Unknown Account';
    String dateString = DateFormat('MMM d').format(transaction.date);

    if (transaction.category != null) {
      if (isExpense) iconData = Icons.shopping_bag_outlined;
      if (!isExpense && !isTransfer) iconData = Icons.monetization_on_outlined;
      
      if (transaction.category!.color.isNotEmpty) {
        try {
          String hex = transaction.category!.color.replaceAll('#', '');
          if (hex.length == 6) hex = 'FF$hex';
          iconColor = Color(int.parse('0x$hex'));
        } catch (e) {
          // ignore
        }
      }
      
      if (transaction.description == null || transaction.description!.isEmpty) {
        title = transaction.category!.name;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(iconData, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$prefix${Formatters.formatCurrency(transaction.amount)}',
                style: TextStyle(
                  color: amountColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              Text(
                dateString,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
