import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import '../models/goal_model.dart';
import '../utils/icon_utils.dart';
import 'add_goal_screen.dart';

class GoalDetailsScreen extends StatelessWidget {
  final Goal goal;

  const GoalDetailsScreen({super.key, required this.goal});

  Color _hexToColor(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse('0x$hexColor'));
  }

  @override
  Widget build(BuildContext context) {
    final progress = goal.progress;
    final color = _hexToColor(goal.color);

    return FScaffold(
      header: FHeader(
        title: const Text('Goal Details'),
        actions: [
          FButton.icon(
            onPress: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AddGoalScreen(goal: goal),
                ),
              );
              if (result == true) {
                Navigator.of(context).pop(true); // Return true to refresh list
              }
            },
            child: FIcon(FAssets.icons.pencil),
          ),
        ],
      ),
      content: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  IconUtils.getIcon(goal.icon),
                  size: 40,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                goal.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 32),
            _buildInfoRow(
              context,
              'Target Amount',
              '\$${goal.target.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              context,
              'Amount Saved',
              '\$${goal.saved.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              context,
              'Completion Date',
              DateFormat.yMMMd().format(goal.deadline),
            ),
            const SizedBox(height: 32),
            const Text(
              'Progress',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: context.theme.colorScheme.secondary,
              color: color,
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
            ),
            const SizedBox(height: 8),
            Text(
              '${(progress * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                color: context.theme.colorScheme.mutedForeground,
              ),
            ),
            if (goal.note != null && goal.note!.isNotEmpty) ...[
              const SizedBox(height: 32),
              const Text(
                'Note',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                goal.note!,
                style: TextStyle(
                  color: context.theme.colorScheme.mutedForeground,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: context.theme.colorScheme.mutedForeground,
            fontSize: 16,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
