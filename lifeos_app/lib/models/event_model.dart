import 'package:flutter/material.dart';

class PlannerEvent {
  final String? id;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String? notes;
  final String color;
  final bool isAllDay;

  PlannerEvent({
    this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.notes,
    this.color = '#18181B', // Zinc-900 like
    this.isAllDay = false,
  });

  factory PlannerEvent.fromJson(Map<String, dynamic> json) {
    return PlannerEvent(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      title: json['title'],
      startTime: DateTime.parse(json['startTime']).toLocal(),
      endTime: DateTime.parse(json['endTime']).toLocal(),
      notes: json['notes'],
      color: json['color'] ?? '#18181B',
      isAllDay: json['isAllDay'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'startTime': startTime.toUtc().toIso8601String(),
      'endTime': endTime.toUtc().toIso8601String(),
      'notes': notes,
      'color': color,
      'isAllDay': isAllDay,
    };
  }

  // Helper to get color object
  Color get colorObj {
    var hexColor = color.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse('0x$hexColor'));
  }
}
