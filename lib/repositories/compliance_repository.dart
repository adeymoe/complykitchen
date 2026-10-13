import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../config/supabase_config.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

/// Everything the app needs for day-to-day compliance data, backed by
/// real Supabase tables. This replaces the MockData used in the first
/// prototype — the UI models (ComplianceUnit, ComplianceTask, Reading)
/// are unchanged, only where they come from has changed.
class ComplianceRepository {
  final SupabaseClient _client;
  ComplianceRepository(this._client);

  bool get _useDemoData => SupabaseConfig.isDemoMode;

  // ---------------------------------------------------------------
  // Units
  // ---------------------------------------------------------------

  Future<List<ComplianceUnit>> fetchUnits(String siteId) async {
    if (_useDemoData) {
      return [
        const ComplianceUnit(
          id: 'demo-fridge',
          name: 'Fridge 1',
          location: 'Main kitchen',
          type: UnitType.fridge,
          targetMax: 8,
          lastReading: 5,
          lastReadingAt: null,
          lastReadingBy: 'Demo',
        ),
        const ComplianceUnit(
          id: 'demo-freezer',
          name: 'Freezer 1',
          location: 'Back prep',
          type: UnitType.freezer,
          targetMax: -18,
          lastReading: -16,
          lastReadingAt: null,
          lastReadingBy: 'Demo',
        ),
      ];
    }

    final rows = await _client
        .from('units')
        .select()
        .eq('site_id', siteId)
        .eq('active', true)
        .order('name');

    final units = <ComplianceUnit>[];
    for (final row in rows as List) {
      final latest = await _client
          .from('readings')
          .select()
          .eq('unit_id', row['id'] as String)
          .order('taken_at', ascending: false)
          .limit(1)
          .maybeSingle();

      units.add(_mapUnit(row, latest));
    }
    return units;
  }

  ComplianceUnit _mapUnit(Map<String, dynamic> row, Map<String, dynamic>? latestReading) {
    return ComplianceUnit(
      id: row['id'] as String,
      name: row['name'] as String,
      location: (row['location'] as String?) ?? '',
      type: _unitTypeFromString(row['type'] as String),
      targetMax: (row['target_max'] as num).toDouble(),
      lastReading: latestReading == null ? null : (latestReading['value'] as num).toDouble(),
      lastReadingAt: latestReading == null ? null : DateTime.parse(latestReading['taken_at'] as String),
      lastReadingBy: null, // resolving to a display name needs a profiles join; add when staff lists exist
    );
  }

  UnitType _unitTypeFromString(String value) {
    switch (value) {
      case 'freezer':
        return UnitType.freezer;
      case 'hot_hold':
        return UnitType.hotHold;
      default:
        return UnitType.fridge;
    }
  }

  // ---------------------------------------------------------------
  // Tasks
  // ---------------------------------------------------------------

  /// Makes sure today has a task_instance for every active template at
  /// this site. A proper production setup would generate these on a
  /// schedule (a Supabase Edge Function on pg_cron); doing it lazily
  /// on load is the pragmatic v1 shortcut so the app works without
  /// standing up serverless infra yet.
  Future<void> ensureTodayInstances(String siteId) async {
    if (_useDemoData) return;

    final templates = await _client
        .from('task_templates')
        .select()
        .eq('site_id', siteId)
        .eq('active', true);

    final startOfDay = DateTime.now().toUtc();
    final dayStart = DateTime.utc(startOfDay.year, startOfDay.month, startOfDay.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    for (final template in templates as List) {
      final existing = await _client
          .from('task_instances')
          .select('id')
          .eq('template_id', template['id'] as String)
          .gte('due_at', dayStart.toIso8601String())
          .lt('due_at', dayEnd.toIso8601String())
          .maybeSingle();

      if (existing == null) {
        await _client.from('task_instances').insert({
          'site_id': siteId,
          'template_id': template['id'],
          'title': template['title'],
          'unit_id': template['unit_id'],
          'requires_reading': template['requires_reading'],
          'due_at': DateTime.now().add(const Duration(hours: 2)).toIso8601String(),
        });
      }
    }
  }

  Future<List<ComplianceTask>> fetchTodayTasks(String siteId) async {
    if (_useDemoData) {
      return [
        ComplianceTask(
          id: 'demo-task-1',
          title: 'Check Fridge 1',
          subtitle: 'Temperature check',
          dueAt: DateTime.now().add(const Duration(hours: 2)),
          requiresReading: true,
          linkedUnitId: 'demo-fridge',
        ),
        ComplianceTask(
          id: 'demo-task-2',
          title: 'Check Freezer 1',
          subtitle: 'Temperature check',
          dueAt: DateTime.now().add(const Duration(hours: 4)),
          requiresReading: true,
          linkedUnitId: 'demo-freezer',
        ),
      ];
    }

    final startOfDay = DateTime.now().toUtc();
    final dayStart = DateTime.utc(startOfDay.year, startOfDay.month, startOfDay.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final rows = await _client
        .from('task_instances')
        .select()
        .eq('site_id', siteId)
        .gte('due_at', dayStart.toIso8601String())
        .lt('due_at', dayEnd.toIso8601String())
        .order('due_at');

    return (rows as List).map((row) {
      return ComplianceTask(
        id: row['id'] as String,
        title: row['title'] as String,
        subtitle: '',
        icon: null,
        dueAt: DateTime.parse(row['due_at'] as String),
        requiresReading: row['requires_reading'] as bool,
        linkedUnitId: row['unit_id'] as String?,
        done: row['done'] as bool,
      );
    }).toList();
  }

  Future<void> markTaskDone(String taskId) async {
    if (_useDemoData) return;

    final userId = _client.auth.currentUser!.id;
    await _client.from('task_instances').update({
      'done': true,
      'done_at': DateTime.now().toIso8601String(),
      'done_by': userId,
    }).eq('id', taskId);
  }

  // ---------------------------------------------------------------
  // Readings
  // ---------------------------------------------------------------

  Future<List<Reading>> fetchRecentReadings(String unitId, {int limit = 10}) async {
    if (_useDemoData) {
      return [
        Reading(
          unitId: unitId,
          value: 5,
          takenAt: DateTime.now().subtract(const Duration(hours: 2)),
          takenBy: 'Demo',
          status: ComplianceStatus.safe,
        ),
      ];
    }

    final rows = await _client
        .from('readings')
        .select()
        .eq('unit_id', unitId)
        .order('taken_at', ascending: false)
        .limit(limit);

    return (rows as List).map((row) {
      return Reading(
        unitId: unitId,
        value: (row['value'] as num).toDouble(),
        takenAt: DateTime.parse(row['taken_at'] as String),
        takenBy: 'Team member', // resolve to a real name once a staff directory screen exists
        status: _statusFromString(row['status'] as String),
        correctiveAction: row['corrective_action'] as String?,
      );
    }).toList();
  }

  ComplianceStatus _statusFromString(String value) {
    switch (value) {
      case 'danger':
        return ComplianceStatus.danger;
      case 'warn':
        return ComplianceStatus.warn;
      default:
        return ComplianceStatus.safe;
    }
  }

  /// Logs a reading and works out compliance status from the unit's
  /// own threshold, so the "safe/warn/danger" colour always matches
  /// the legal limit that specific unit was configured with.
  Future<void> logReading({
    required String siteId,
    required String unitId,
    required double value,
    required double targetMax,
    required UnitType unitType,
    String? taskInstanceId,
    String? correctiveAction,
  }) async {
    if (_useDemoData) return;

    final userId = _client.auth.currentUser!.id;
    final inRange = unitType == UnitType.hotHold ? value >= targetMax : value <= targetMax;

    await _client.from('readings').insert({
      'site_id': siteId,
      'unit_id': unitId,
      'task_instance_id': taskInstanceId,
      'value': value,
      'status': inRange ? 'safe' : 'danger',
      'taken_by': userId,
      'corrective_action': correctiveAction,
    });

    if (taskInstanceId != null) {
      await markTaskDone(taskInstanceId);
    }
  }

  // ---------------------------------------------------------------
  // Dashboard
  // ---------------------------------------------------------------

  Future<DashboardSummary> fetchDashboardSummary(String siteId) async {
    if (_useDemoData) {
      return const DashboardSummary(
        completionRate: 0.8,
        flaggedUnits: [],
      );
    }

    final weekAgo = DateTime.now().subtract(const Duration(days: 7)).toIso8601String();

    final instances = await _client
        .from('task_instances')
        .select('done')
        .eq('site_id', siteId)
        .gte('created_at', weekAgo);

    final total = (instances as List).length;
    final completed = instances.where((i) => i['done'] == true).length;
    final completionRate = total == 0 ? 1.0 : completed / total;

    final units = await fetchUnits(siteId);
    final flagged = units.where((u) => u.status == ComplianceStatus.danger).toList();

    return DashboardSummary(completionRate: completionRate, flaggedUnits: flagged);
  }

  // ---------------------------------------------------------------
  // Regulator-facing report sharing (the differentiator)
  // ---------------------------------------------------------------

  /// Creates a scoped, time-limited share token for a date range of
  /// records. Returns a shareable URL.
  ///
  /// IMPORTANT: this generates the token, but there's no public
  /// viewer page behind it yet — an EHO opening this link today would
  /// hit nothing. Building that viewer (a simple public web page or a
  /// Supabase Edge Function reading by token, bypassing RLS
  /// deliberately and narrowly) is the next real milestone for this
  /// feature, not a v1 nice-to-have to skip.
  Future<String> generateReportShare({
    required String siteId,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) async {
    if (_useDemoData) {
      return 'https://complykitchen.app/demo-report';
    }

    final userId = _client.auth.currentUser!.id;
    final token = const Uuid().v4();

    await _client.from('report_shares').insert({
      'site_id': siteId,
      'token': token,
      'range_start': rangeStart.toIso8601String().split('T').first,
      'range_end': rangeEnd.toIso8601String().split('T').first,
      'created_by': userId,
    });

    return 'https://complykitchen.app/r/$token';
  }

  // ---------------------------------------------------------------
  // Setup: units and task templates
  // ---------------------------------------------------------------

  /// Adds a new monitored unit (fridge/freezer/hot-hold) to a site.
  /// This is the single most important piece of setup UI in the app —
  /// nothing else works for a fresh site until at least one unit exists.
  Future<void> createUnit({
    required String siteId,
    required String name,
    required String location,
    required UnitType type,
    required double targetMax,
  }) async {
    if (_useDemoData) return;

    await _client.from('units').insert({
      'site_id': siteId,
      'name': name,
      'location': location,
      'type': _unitTypeToString(type),
      'target_max': targetMax,
    });
  }

  String _unitTypeToString(UnitType type) {
    switch (type) {
      case UnitType.freezer:
        return 'freezer';
      case UnitType.hotHold:
        return 'hot_hold';
      case UnitType.fridge:
        return 'fridge';
    }
  }

  /// Creates a recurring task template. `ensureTodayInstances` (above)
  /// turns these into actual task_instances staff see on Today/Tasks.
  Future<void> createTaskTemplate({
    required String siteId,
    required String title,
    required String category,
    String? unitId,
    required bool requiresReading,
    required String recurrence,
  }) async {
    if (_useDemoData) return;

    await _client.from('task_templates').insert({
      'site_id': siteId,
      'title': title,
      'category': category,
      'unit_id': unitId,
      'requires_reading': requiresReading,
      'recurrence': recurrence,
    });
  }

  Future<List<Map<String, dynamic>>> fetchTaskTemplates(String siteId) async {
    if (_useDemoData) {
      return [
        {
          'id': 'demo-template',
          'title': 'Check Fridge 1',
          'category': 'fridge',
          'unit_id': 'demo-fridge',
          'requires_reading': true,
          'recurrence': 'daily',
        }
      ];
    }

    final rows = await _client
        .from('task_templates')
        .select()
        .eq('site_id', siteId)
        .eq('active', true)
        .order('created_at');
    return List<Map<String, dynamic>>.from(rows as List);
  }
}

class DashboardSummary {
  final double completionRate;
  final List<ComplianceUnit> flaggedUnits;
  const DashboardSummary({required this.completionRate, required this.flaggedUnits});
}
