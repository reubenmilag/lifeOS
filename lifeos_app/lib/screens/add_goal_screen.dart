import 'package:flutter/material.dart';

class AddGoalScreen extends StatelessWidget {
  const AddGoalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Goal'),
      ),
      body: const Center(
        child: Text('Add Goal Screen'),
      ),
    );
  }
}
