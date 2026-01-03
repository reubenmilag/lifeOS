import 'package:flutter/material.dart';

class AddBudgetScreen extends StatelessWidget {
  const AddBudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Budget'),
      ),
      body: const Center(
        child: Text('Add Budget Screen'),
      ),
    );
  }
}
