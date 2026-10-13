import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A physical monitored unit at a site: a fridge, freezer, or hot-hold point.
class ComplianceUnit {
  final String id;
  final String name;
  final String location;
  final UnitType type;
  final double targetMax; // legal / target ceiling in Celsius (or floor for hot hold)
  final double? lastReading;
  final DateTime? lastReadingAt;
  final String? lastReadingBy;

  const ComplianceUnit({
    required this.id,
    required this.name,
    required this.location,
    required this.type,
    required this.targetMax,
    this.lastReading,
    this.lastReadingAt,
    this.lastReadingBy,
  });

  ComplianceStatus get status {
    if (lastReading == null) return ComplianceStatus.warn;
    switch (type) {
      case UnitType.hotHold:
        // Hot holding: must stay AT or ABOVE the threshold.
        return lastReading! >= targetMax ? ComplianceStatus.safe : ComplianceStatus.danger;
      case UnitType.fridge:
      case UnitType.freezer:
        return lastReading! <= targetMax ? ComplianceStatus.safe : ComplianceStatus.danger;
    }
  }

  IconData get icon {
    switch (type) {
      case UnitType.freezer:
        return Icons.ac_unit_outlined;
      case UnitType.hotHold:
        return Icons.local_fire_department_outlined;
      case UnitType.fridge:
        return Icons.kitchen_outlined;
    }
  }
}

enum UnitType { fridge, freezer, hotHold }

/// A single logged reading against a unit, with the mandatory audit fields:
/// who, when, what, and — if out of range — what was done about it.
class Reading {
  final String unitId;
  final double value;
  final DateTime takenAt;
  final String takenBy;
  final ComplianceStatus status;
  final String? correctiveAction;

  const Reading({
    required this.unitId,
    required this.value,
    required this.takenAt,
    required this.takenBy,
    required this.status,
    this.correctiveAction,
  });
}

/// A recurring or one-off task on a shift's checklist (temperature check,
/// delivery check, cleaning task). Not every task has a numeric reading —
/// cleaning tasks are just done/not-done with optional photo evidence.
///
/// `icon` is nullable because real task_instance rows from Supabase don't
/// store one — the UI falls back to a category-based default via
/// `displayIcon` below rather than requiring every caller to know that.
class ComplianceTask {
  final String id;
  final String title;
  final String subtitle;
  final IconData? icon;
  final DateTime dueAt;
  final bool requiresReading;
  final String? linkedUnitId;
  bool done;

  ComplianceTask({
    required this.id,
    required this.title,
    required this.subtitle,
    this.icon,
    required this.dueAt,
    this.requiresReading = false,
    this.linkedUnitId,
    this.done = false,
  });

  bool get isOverdue => !done && DateTime.now().isAfter(dueAt);

  IconData get displayIcon => icon ?? (requiresReading ? Icons.thermostat_outlined : Icons.checklist_rounded);
}
