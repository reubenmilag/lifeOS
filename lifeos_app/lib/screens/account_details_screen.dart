import 'package:flutter/material.dart';
import '../models/account_model.dart';
import '../services/api_service.dart';
import 'account_edit_screen.dart';

class AccountDetailsScreen extends StatelessWidget {
  final Account account;
  final ApiService _apiService = ApiService();

  AccountDetailsScreen({super.key, required this.account});

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
          account.name ?? 'Account Details',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false, // Left aligned
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _showDeleteConfirmation(context),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.black),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AccountEditScreen(account: account),
                ),
              );
              
              if (result == true && context.mounted) {
                // Since this is a stateless widget, we should probably pop back to refresh
                // or convert to stateful to refresh data. 
                // For now, let's pop back to the dashboard which will refresh.
                Navigator.of(context).pop(true);
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: _parseColor(account.color),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Balance',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${account.balance?.toStringAsFixed(2) ?? '0.00'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: Text('Are you sure you want to delete "${account.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        if (account.id != null) {
          await _apiService.deleteAccount(account.id!);
          if (context.mounted) {
            Navigator.of(context).pop(true); // Return true to trigger refresh
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting account: $e')),
          );
        }
      }
    }
  }

  Color _parseColor(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse('0x$hexColor'));
  }
}
