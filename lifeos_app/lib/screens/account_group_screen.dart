import 'package:flutter/material.dart';
import '../models/account_model.dart';
import 'account_details_screen.dart';
import '../utils/formatters.dart';

class AccountGroupScreen extends StatelessWidget {
  final String accountType;
  final List<Account> accounts;
  final VoidCallback? onRefresh;

  const AccountGroupScreen({
    super.key,
    required this.accountType,
    required this.accounts,
    this.onRefresh,
  });

  Color _parseColor(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse('0x$hexColor'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          accountType,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: accounts.length,
        itemBuilder: (context, index) {
          final account = accounts[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: _parseColor(account.color).withOpacity(0.2),
                child: Icon(Icons.account_balance_wallet, color: _parseColor(account.color)),
              ),
              title: Text(
                account.name ?? 'Unnamed Account',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(account.accountType),
              trailing: Text(
                Formatters.formatCurrency(account.balance ?? 0),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AccountDetailsScreen(account: account),
                  ),
                );
                if (result == true && onRefresh != null) {
                  onRefresh!();
                  Navigator.of(context).pop(true); // Go back to refresh dashboard
                }
              },
            ),
          );
        },
      ),
    );
  }
}
