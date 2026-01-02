import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../utils/formatters.dart';

class TransactionList extends StatelessWidget {
  final List<TransactionModel> transactions;
  final VoidCallback onViewAll;

  const TransactionList({
    super.key,
    required this.transactions,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Transactions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              TextButton(
                onPressed: onViewAll,
                child: const Text('View All'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (transactions.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                'No transactions yet',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              return _buildTransactionItem(transaction);
            },
          ),
      ],
    );
  }

  Widget _buildTransactionItem(TransactionModel transaction) {
    final isExpense = transaction.type == 'expense';
    final isTransfer = transaction.type == 'transfer';
    
    // Modern color palette
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
    } else if (isTransfer) {
      iconData = Icons.swap_horiz;
      iconColor = Colors.blue;
      title = 'Transfer';
      if (transaction.toAccount != null) {
        subtitle = '${transaction.account?.name ?? "Unknown"} -> ${transaction.toAccount?.name ?? "Unknown"}';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(iconData, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 11,
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
                '$prefix${Formatters.formatCurrency(transaction.amount)}', // Removed decimals for compactness
                style: TextStyle(
                  color: amountColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                dateString,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
