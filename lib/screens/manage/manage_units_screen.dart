import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/supabase_config.dart';
import '../../models/models.dart';
import '../../repositories/compliance_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/status_chip.dart';
import 'add_unit_screen.dart';

class ManageUnitsScreen extends StatefulWidget {
  final String siteId;
  const ManageUnitsScreen({super.key, required this.siteId});

  @override
  State<ManageUnitsScreen> createState() => _ManageUnitsScreenState();
}

class _ManageUnitsScreenState extends State<ManageUnitsScreen> {
  late Future<List<ComplianceUnit>> _unitsFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() => _unitsFuture = ComplianceRepository(SupabaseConfig.isDemoMode ? SupabaseClient('https://demo.supabase.co', 'demo-key') : Supabase.instance.client).fetchUnits(widget.siteId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screen,
      appBar: AppBar(backgroundColor: AppColors.screen, elevation: 0, title: const Text('Units')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            children: [
              Expanded(
                child: FutureBuilder<List<ComplianceUnit>>(
                  future: _unitsFuture,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator(color: AppColors.ink));
                    }
                    final units = snapshot.data!;
                    if (units.isEmpty) {
                      return const Center(
                        child: Text('No units yet \u2014 add your first fridge or freezer below.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.inkMute)),
                      );
                    }
                    return ListView.separated(
                      itemCount: units.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final u = units[i];
                        return Container(
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
                                    Text(
                                      u.type == UnitType.hotHold ? 'At or above ${u.targetMax.toInt()}\u00b0C' : 'At or below ${u.targetMax.toInt()}\u00b0C',
                                      style: const TextStyle(color: AppColors.inkSoft, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              PillButton(
                label: 'Add a unit',
                icon: Icons.add_rounded,
                onTap: () async {
                  final added = await Navigator.push(context, MaterialPageRoute(builder: (_) => AddUnitScreen(siteId: widget.siteId)));
                  if (added == true) _load();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
