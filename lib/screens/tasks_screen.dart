import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/models.dart';
import '../repositories/compliance_repository.dart';
import '../repositories/org_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/status_chip.dart';
import 'manage/manage_site_screen.dart';
import 'unit_detail_screen.dart';

/// Every task due today, in one list — replaces the earlier
/// placeholder tab. Reading-required tasks route to the unit's
/// logging screen; simple checklist tasks can be marked done directly.
class TasksScreen extends StatefulWidget {
  final MySite site;
  const TasksScreen({super.key, required this.site});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  late final ComplianceRepository _repo;
  bool _loading = true;
  List<ComplianceTask> _tasks = [];
  List<ComplianceUnit> _units = [];

  @override
  void initState() {
    super.initState();
    _repo = ComplianceRepository(SupabaseConfig.isDemoMode ? SupabaseClient('https://demo.supabase.co', 'demo-key') : Supabase.instance.client);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await _repo.ensureTodayInstances(widget.site.siteId);
    final tasks = await _repo.fetchTodayTasks(widget.site.siteId);
    final units = await _repo.fetchUnits(widget.site.siteId);
    if (!mounted) return;
    setState(() {
      _tasks = tasks;
      _units = units;
      _loading = false;
    });
  }

  ComplianceUnit? _unitFor(String? unitId) {
    if (unitId == null) return null;
    for (final u in _units) {
      if (u.id == unitId) return u;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screen,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tasks', style: Theme.of(context).textTheme.displaySmall),
                        Text('Everything due today', style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ManageSiteScreen(site: widget.site))).then((_) => _load()),
                    child: Container(
                      width: 38, height: 38,
                      decoration: const BoxDecoration(color: AppColors.ink, shape: BoxShape.circle),
                      child: const Icon(Icons.tune_rounded, size: 17, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.ink))
                    : _tasks.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('No tasks set up yet.', style: TextStyle(color: AppColors.inkMute)),
                                const SizedBox(height: 10),
                                PillButton(
                                  label: 'Add your first task',
                                  icon: Icons.add_rounded,
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ManageSiteScreen(site: widget.site))).then((_) => _load()),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.separated(
                              itemCount: _tasks.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, i) {
                                final t = _tasks[i];
                                final unit = _unitFor(t.linkedUnitId);
                                return GestureDetector(
                                  onTap: () async {
                                    if (t.requiresReading && unit != null) {
                                      await Navigator.push(context, MaterialPageRoute(builder: (_) => UnitDetailScreen(unit: unit, siteId: widget.site.siteId)));
                                      _load();
                                    } else if (!t.done) {
                                      await _repo.markTaskDone(t.id);
                                      _load();
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(14)),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 26, height: 26,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: t.done ? AppColors.safe : Colors.transparent,
                                            border: Border.all(color: t.done ? AppColors.safe : AppColors.line, width: 2),
                                          ),
                                          child: t.done ? const Icon(Icons.check, size: 15, color: Colors.white) : null,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(t.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                                              Text(
                                                t.done ? 'Done' : (t.isOverdue ? 'Overdue' : 'Due ${DateFormat.Hm().format(t.dueAt)}'),
                                                style: TextStyle(fontSize: 12, color: t.isOverdue && !t.done ? AppColors.danger : AppColors.inkMute),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(t.displayIcon, size: 18, color: AppColors.inkMute),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
