import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../repositories/compliance_repository.dart';
import '../repositories/org_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/status_chip.dart';
import 'manage/manage_site_screen.dart';

/// Owner/manager view: this week's compliance at a glance, plus the
/// regulator-facing report share — the differentiator none of the
/// competitors researched had built.
class DashboardScreen extends StatefulWidget {
  final MySite site;
  const DashboardScreen({super.key, required this.site});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final ComplianceRepository _repo;
  late Future<DashboardSummary> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _repo = ComplianceRepository(SupabaseConfig.isDemoMode ? SupabaseClient('https://demo.supabase.co', 'demo-key') : Supabase.instance.client);
    _summaryFuture = _repo.fetchDashboardSummary(widget.site.siteId);
  }

  Future<void> _shareReport() async {
    final link = await _repo.generateReportShare(
      siteId: widget.site.siteId,
      rangeStart: DateTime.now().subtract(const Duration(days: 7)),
      rangeEnd: DateTime.now(),
    );
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Share with your inspector', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 6),
            const Text('This link covers the last 7 days and expires in 14 days. Anyone with the link can view it — no account needed.', style: TextStyle(color: AppColors.inkSoft, fontSize: 12.5)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.paper, borderRadius: BorderRadius.circular(12)),
              child: SelectableText(link, style: AppTheme.mono(size: 13)),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: PillButton(
                    label: 'Copy link',
                    icon: Icons.copy_rounded,
                    light: true,
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: link));
                      Navigator.pop(ctx);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PillButton(
                    label: 'Share',
                    icon: Icons.ios_share_rounded,
                    onTap: () {
                      Share.share(link);
                      Navigator.pop(ctx);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screen,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: FutureBuilder<DashboardSummary>(
            future: _summaryFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator(color: AppColors.ink));
              }
              final summary = snapshot.data!;
              final percent = (summary.completionRate * 100).round();

              return ListView(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.site.siteName, style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 2),
                            Text('Last 7 days', style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ManageSiteScreen(site: widget.site))).then((_) => setState(() {
                              _summaryFuture = _repo.fetchDashboardSummary(widget.site.siteId);
                            })),
                        child: Container(
                          width: 38, height: 38,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.line), shape: BoxShape.circle),
                          child: const Icon(Icons.tune_rounded, size: 17, color: AppColors.ink),
                        ),
                      ),
                      GestureDetector(
                        onTap: _shareReport,
                        child: Container(
                          width: 38, height: 38,
                          decoration: const BoxDecoration(color: AppColors.ink, shape: BoxShape.circle),
                          child: const Icon(Icons.ios_share_rounded, size: 17, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 24),
                      children: [
                        TextSpan(text: '$percent%', style: TextStyle(color: percent >= 90 ? AppColors.safe : AppColors.warn)),
                        const TextSpan(text: ' of checks completed'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (summary.flaggedUnits.isEmpty)
                    _row(color: AppColors.safe, icon: Icons.check_rounded, title: 'All units in range', body: 'No open flags right now.')
                  else
                    ...summary.flaggedUnits.map((u) => _row(
                          color: AppColors.danger,
                          icon: Icons.warning_amber_rounded,
                          title: '${u.name} flagged',
                          body: '${u.lastReading}\u00b0C, above the legal limit of ${u.targetMax.toInt()}\u00b0C',
                        )),
                  const SizedBox(height: 24),
                  PillButton(label: 'Share with regulator', icon: Icons.ios_share_rounded, onTap: _shareReport),
                  const SizedBox(height: 100),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _row({required Color color, required IconData icon, required String title, required String body}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: Colors.white, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(body, style: const TextStyle(fontSize: 11.5, color: AppColors.inkSoft, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
