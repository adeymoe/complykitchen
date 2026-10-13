import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/supabase_config.dart';
import '../../models/models.dart';
import '../../repositories/compliance_repository.dart';
import '../../repositories/org_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/status_chip.dart';

/// The turnover-proof onboarding differentiator, made concrete: a new
/// starter gets this site's actual unit thresholds — not a generic
/// induction PDF — plus the handful of rules that matter most, and
/// confirms they've read it. That confirmation is what
/// `site_memberships.inducted_at` records.
class NewStarterScreen extends StatefulWidget {
  final String siteId;
  final String siteName;
  const NewStarterScreen({super.key, required this.siteId, required this.siteName});

  @override
  State<NewStarterScreen> createState() => _NewStarterScreenState();
}

class _NewStarterScreenState extends State<NewStarterScreen> {
  late Future<List<ComplianceUnit>> _unitsFuture;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _unitsFuture = ComplianceRepository(SupabaseConfig.isDemoMode ? SupabaseClient('https://demo.supabase.co', 'demo-key') : Supabase.instance.client).fetchUnits(widget.siteId);
  }

  Future<void> _confirm() async {
    setState(() => _saving = true);
    try {
      await OrgRepository(SupabaseConfig.isDemoMode ? SupabaseClient('https://demo.supabase.co', 'demo-key') : Supabase.instance.client).markInducted(widget.siteId);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screen,
      appBar: AppBar(backgroundColor: AppColors.screen, elevation: 0, title: const Text('Welcome to the team')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.siteName, style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 4),
              Text('Five minutes, then you\'re set for your first shift.', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  children: [
                    Text('Your fridges and freezers', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    FutureBuilder<List<ComplianceUnit>>(
                      future: _unitsFuture,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(child: CircularProgressIndicator(color: AppColors.ink)),
                          );
                        }
                        final units = snapshot.data!;
                        if (units.isEmpty) {
                          return const Text('No units set up yet — ask a manager to add your fridges and freezers.', style: TextStyle(color: AppColors.inkMute));
                        }
                        return Column(
                          children: units.map((u) {
                            final limitLabel = u.type == UnitType.hotHold
                                ? 'Keep at or above ${u.targetMax.toInt()}\u00b0C'
                                : 'Keep at or below ${u.targetMax.toInt()}\u00b0C';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(14)),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40, height: 40,
                                    decoration: BoxDecoration(color: AppColors.paper, borderRadius: BorderRadius.circular(10)),
                                    child: Icon(u.icon, size: 18, color: AppColors.inkSoft),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('${u.name} \u00b7 ${u.location}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                                        Text(limitLabel, style: const TextStyle(color: AppColors.inkSoft, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 22),
                    Text('The rules that matter most', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    _rule('If a reading is out of range, log it anyway', 'Never skip a bad reading — write down what you did about it. That record is what protects the business.'),
                    _rule('First in, first out', 'Older stock goes to the front. New deliveries go to the back.'),
                    _rule('Not sure? Ask before you serve', "If something looks or smells off, or you're unsure about an allergen, check with a manager first."),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              PillButton(
                label: _saving ? 'Saving...' : "I've read this",
                icon: Icons.check_rounded,
                onTap: _saving ? () {} : _confirm,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rule(String title, String body) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
          const SizedBox(height: 4),
          Text(body, style: const TextStyle(color: AppColors.inkSoft, fontSize: 12.5, height: 1.4)),
        ],
      ),
    );
  }
}
