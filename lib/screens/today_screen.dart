import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/models.dart';
import '../repositories/compliance_repository.dart';
import '../repositories/org_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/status_chip.dart';
import 'manage/manage_units_screen.dart';
import 'onboarding/new_starter_screen.dart';
import 'unit_detail_screen.dart';

/// The staff home screen: today's checklist, backed by real data for
/// this site. If the signed-in person hasn't completed new-starter
/// induction here yet, that's the first thing they see — not buried
/// in a menu.
class TodayScreen extends StatefulWidget {
  final MySite site;
  const TodayScreen({super.key, required this.site});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  late final ComplianceRepository _repo;
  String _filter = 'All';
  bool _loading = true;
  List<ComplianceUnit> _units = [];
  List<ComplianceTask> _tasks = [];

  @override
  void initState() {
    super.initState();
    _repo = ComplianceRepository(SupabaseConfig.isDemoMode ? SupabaseClient('https://demo.supabase.co', 'demo-key') : Supabase.instance.client);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await _repo.ensureTodayInstances(widget.site.siteId);
    final units = await _repo.fetchUnits(widget.site.siteId);
    final tasks = await _repo.fetchTodayTasks(widget.site.siteId);
    if (!mounted) return;
    setState(() {
      _units = units;
      _tasks = tasks;
      _loading = false;
    });
  }

  ComplianceUnit? get _mostUrgentFlaggedUnit {
    for (final u in _units) {
      if (u.status == ComplianceStatus.danger) return u;
    }
    return _units.isNotEmpty ? _units.first : null;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(backgroundColor: AppColors.screen, body: Center(child: CircularProgressIndicator(color: AppColors.ink)));
    }

    final flaggedUnit = _mostUrgentFlaggedUnit;
    final upNext = _tasks.where((t) => !t.done).toList();

    return Scaffold(
      backgroundColor: AppColors.screen,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Today', style: Theme.of(context).textTheme.displaySmall),
                        const SizedBox(height: 2),
                        Text(widget.site.siteName, style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              if (widget.site.needsInduction) ...[
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => NewStarterScreen(siteId: widget.site.siteId, siteName: widget.site.siteName)),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.paper, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(18)),
                    child: const Row(
                      children: [
                        Icon(Icons.waving_hand_rounded, color: AppColors.ink),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Welcome to the team', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                              Text('Complete your 5-minute induction for this site', style: TextStyle(color: AppColors.inkSoft, fontSize: 12)),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.inkMute),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              Text('What needs doing', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: ['All', 'Fridges', 'Freezers', 'Cleaning'].map((label) {
                    final on = label == _filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(label),
                        selected: on,
                        onSelected: (_) => setState(() => _filter = label),
                        selectedColor: AppColors.ink,
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(color: on ? Colors.white : AppColors.inkSoft, fontWeight: FontWeight.w600, fontSize: 12.5),
                        side: BorderSide(color: on ? AppColors.ink : AppColors.line),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              if (flaggedUnit == null)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(18)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('No units set up yet. Add your fridges and freezers to start logging.', style: TextStyle(color: AppColors.inkMute)),
                      const SizedBox(height: 12),
                      PillButton(
                        label: 'Add a unit',
                        icon: Icons.add_rounded,
                        light: true,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ManageUnitsScreen(siteId: widget.site.siteId))).then((_) => _load()),
                      ),
                    ],
                  ),
                )
              else
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UnitDetailScreen(unit: flaggedUnit, siteId: widget.site.siteId))).then((_) => _load()),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(22)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 56, height: 56,
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)),
                              child: Icon(flaggedUnit.icon, color: Colors.white70),
                            ),
                            const RoundIconButton(icon: Icons.notifications_none_rounded),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(flaggedUnit.location.toUpperCase(), style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: 0.4)),
                        Text(flaggedUnit.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 19)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            if (flaggedUnit.lastReading != null)
                              StatusChip(
                                label: '${flaggedUnit.lastReading}\u00b0C \u00b7 ${flaggedUnit.status == ComplianceStatus.danger ? 'over limit' : 'in range'}',
                                status: flaggedUnit.status,
                              )
                            else
                              const StatusChip(label: 'No reading yet', status: ComplianceStatus.warn),
                          ],
                        ),
                        const SizedBox(height: 14),
                        PillButton(
                          label: 'Log a reading',
                          icon: Icons.arrow_forward_rounded,
                          light: true,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UnitDetailScreen(unit: flaggedUnit, siteId: widget.site.siteId))).then((_) => _load()),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 20),
              Text('Up next', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              if (upNext.isEmpty)
                const Text('Nothing else due right now.', style: TextStyle(color: AppColors.inkMute))
              else
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: upNext.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      final t = upNext[i];
                      return Container(
                        width: 130,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 34, height: 34,
                              decoration: BoxDecoration(color: AppColors.paper, borderRadius: BorderRadius.circular(10)),
                              child: Icon(t.displayIcon, size: 16, color: AppColors.inkSoft),
                            ),
                            const Spacer(),
                            Text(t.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text(t.isOverdue ? 'Overdue' : 'Due soon', style: TextStyle(fontSize: 11, color: t.isOverdue ? AppColors.danger : AppColors.inkMute)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
