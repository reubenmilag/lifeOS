import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

class HealthScreen extends StatelessWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FScaffold(
      header: FHeader(
        title: const Text('Health'),
      ),
      content: const Center(
        child: Text('Health Screen Placeholder'),
      ),
    );
  }
}
