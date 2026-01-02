import 'package:flutter/material.dart';
import '../models/account_model.dart';
import '../screens/account_details_screen.dart';
import '../screens/account_edit_screen.dart';
import '../screens/account_group_screen.dart';
import '../screens/all_accounts_screen.dart';
import '../utils/formatters.dart';

class AccountDashboard extends StatelessWidget {
  final List<Account> accounts;
  final VoidCallback? onRefresh;

  const AccountDashboard({
    super.key,
    required this.accounts,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    // Group accounts by type
    final Map<String, List<Account>> groupedAccounts = {};
    Account? addAccountCard;

    for (var account in accounts) {
      if (account.type == 'add') {
        addAccountCard = account;
        continue;
      }
      if (!groupedAccounts.containsKey(account.accountType)) {
        groupedAccounts[account.accountType] = [];
      }
      groupedAccounts[account.accountType]!.add(account);
    }

    // Filter groups with non-zero total balance
    final List<MapEntry<String, List<Account>>> displayGroups = [];
    groupedAccounts.forEach((type, list) {
      double total = list.fold(0, (sum, item) => sum + (item.balance ?? 0));
      if (total != 0) {
        displayGroups.add(MapEntry(type, list));
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'List of accounts',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AllAccountsScreen(
                        accounts: accounts,
                        onRefresh: onRefresh,
                      ),
                    ),
                  );
                },
                child: const Text(
                  'View All',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Account Grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Responsive grid: 2 columns on small screens, more on larger
              int crossAxisCount = 2;
              if (constraints.maxWidth > 600) {
                crossAxisCount = 3;
              }
              if (constraints.maxWidth > 900) {
                crossAxisCount = 4;
              }

              // Total items = groups + add card (if exists)
              int itemCount = displayGroups.length + (addAccountCard != null ? 1 : 0);

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.6, // Adjust aspect ratio as needed
                ),
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  // If it's the last item and we have an add card, show it
                  if (addAccountCard != null && index == displayGroups.length) {
                    return GestureDetector(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AccountEditScreen(),
                          ),
                        );
                        if (result == true && onRefresh != null) {
                          onRefresh!();
                        }
                      },
                      child: AccountCard(
                        color: _parseColor(addAccountCard!.color),
                        type: 'add',
                      ),
                    );
                  }

                  final entry = displayGroups[index];
                  final groupName = entry.key;
                  final groupAccounts = entry.value;
                  final totalBalance = groupAccounts.fold(0.0, (sum, item) => sum + (item.balance ?? 0));
                  // Use the color of the first account in the group, or a default
                  final groupColor = groupAccounts.isNotEmpty ? _parseColor(groupAccounts.first.color) : Colors.blue;

                  return GestureDetector(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AccountGroupScreen(
                            accountType: groupName,
                            accounts: groupAccounts,
                            onRefresh: onRefresh,
                          ),
                        ),
                      );
                      if (result == true && onRefresh != null) {
                        onRefresh!();
                      }
                    },
                    child: AccountCard(
                      name: groupName,
                      balance: totalBalance,
                      color: groupColor,
                      type: 'standard',
                      isLocked: false, // Groups aren't locked
                    ),
                  );
                },
              );
            },
          ),
        ),

        const SizedBox(height: 10),
      ],
    );
  }

  Color _parseColor(String? hexColor) {
    if (hexColor == null) return Colors.grey;
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse('0x$hexColor'));
  }
}

class AccountCard extends StatelessWidget {
  final String? name;
  final double? balance;
  final Color color;
  final String type;
  final bool isLocked;

  const AccountCard({
    super.key,
    this.name,
    this.balance,
    required this.color,
    this.type = 'standard',
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    if (type == 'add') {
      return _buildAddCard();
    }
    return _buildStandardCard();
  }

  Widget _buildStandardCard() {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name ?? '',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isLocked)
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(Icons.lock, color: Colors.white70, size: 14),
                ),
            ],
          ),
          Text(
            Formatters.formatCurrency(balance ?? 0),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // Or transparent as per requirement
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color, // Using the passed color (primary blue)
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_circle_outline, color: color, size: 28),
          const SizedBox(height: 4),
          Text(
            'Add account',
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
