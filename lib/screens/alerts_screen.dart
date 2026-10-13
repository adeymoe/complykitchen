import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/models.dart';
import '../repositories/compliance_repository.dart';
import '../repositories/org_repository.dart';
import '../theme/app_theme.dart';
import 'onboarding/new_starter_screen.dart';
import 'unit_detail_screen.dart';

/// Everything that needs attention right now: flagged units, overdue
/// tasks, and — since this tab is where people look when something's
/// wrong — the induction prompt too, if it's still outstanding.
class AlertsScreen extends StatefulWidget {
  final MySite site;
  const AlertsScreen({super.key, required this.site});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  late final ComplianceRepository _repo;
  bool _loading = true;
  List<ComplianceUnit> _flaggedUnits = [];
  List<ComplianceTask> _overdueTasks = [];

  @override
  void initState() {
    super.initState();
    _repo = ComplianceRepository(SupabaseConfig.isDemoMode ? SupabaseClient('https://demo.supabase.co', 'demo-key') : Supabase.instance.client);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final units = await _repo.fetchUnits(widget.site.siteId);
    final tasks = await _repo.fetchTodayTasks(widget.site.siteId);
    if (!mounted) return;
    setState(() {
      _flaggedUnits = units.where((u) => u.status == ComplianceStatus.danger).toList();
      _overdueTasks = tasks.where((t) => t.isOverdue).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final nothingWrong = _flaggedUnits.isEmpty && _overdueTasks.isEmpty && !widget.site.needsInduction;

    return Scaffold(
      backgroundColor: AppColors.screen,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Alerts', style: Theme.of(context).textTheme.displaySmall),
              Text('Anything that needs attention', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 16),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.ink))
                    : nothingWrong
                        ? const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_outline_rounded, size: 40, color: AppColors.safe),
                                SizedBox(height: 10),
                                Text('All clear', style: TextStyle(fontWeight: FontWeight.w700)),
                                Text('No flags or overdue tasks right now.', style: TextStyle(color: AppColors.inkMute, fontSize: 12.5)),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView(
                              children: [
                                if (widget.site.needsInduction)
                                  _alertRow(
                                    color: AppColors.warn,
                                    icon: Icons.waving_hand_rounded,
                                    title: 'Induction not completed',
                                    body: 'Finish your 5-minute induction for this site.',
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NewStarterScreen(siteId: widget.site.siteId, siteName: widget.site.siteName))).then((_) => _load()),
                                  ),
                                ..._flaggedUnits.map((u) => _alertRow(
                                      color: AppColors.danger,
                                      icon: Icons.warning_amber_rounded,
                                      title: '${u.name} out of range',
                                      body: '${u.lastReading}\u00b0C \u2014 legal limit ${u.targetMax.toInt()}\u00b0C',
                                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UnitDetailScreen(unit: u, siteId: widget.site.siteId))).then((_) => _load()),
                                    )),
                                ..._overdueTasks.map((t) => _alertRow(
                                      color: AppColors.warn,
                                      icon: Icons.schedule_rounded,
                                      title: '${t.title} overdue',
                                      body: 'Was due earlier today',
                                      onTap: null,
                                    )),
                              ],
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _alertRow({required Color color, required IconData icon, required String title, required String body, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(11)),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                  Text(body, style: const TextStyle(color: AppColors.inkSoft, fontSize: 12)),
                ],
              ),
            ),
            if (onTap != null) const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: AppColors.inkMute),
          ],
        ),
      ),
    );
  }
}
