import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/models.dart';
import '../repositories/compliance_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/status_chip.dart';

/// Detail + logging screen for a single fridge/freezer/hot-hold unit.
/// Readings logged here write straight to Supabase — this is the
/// audit-critical path, so it stays simple and hard to get wrong.
class UnitDetailScreen extends StatefulWidget {
  final ComplianceUnit unit;
  final String siteId;
  const UnitDetailScreen({super.key, required this.unit, required this.siteId});

  @override
  State<UnitDetailScreen> createState() => _UnitDetailScreenState();
}

class _UnitDetailScreenState extends State<UnitDetailScreen> {
  late final ComplianceRepository _repo;
  late Future<List<Reading>> _readingsFuture;

  @override
  void initState() {
    super.initState();
    _repo = ComplianceRepository(SupabaseConfig.isDemoMode ? SupabaseClient('https://demo.supabase.co', 'demo-key') : Supabase.instance.client);
    _readingsFuture = _repo.fetchRecentReadings(widget.unit.id);
  }

  void _reload() {
    setState(() => _readingsFuture = _repo.fetchRecentReadings(widget.unit.id));
  }

  @override
  Widget build(BuildContext context) {
    final unit = widget.unit;

    return Scaffold(
      backgroundColor: AppColors.screen,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              child: ListView(
                children: [
                  Row(
                    children: [
                      RoundIconButton(icon: Icons.arrow_back_ios_new_rounded, onTap: () => Navigator.pop(context)),
                      const Spacer(),
                      const RoundIconButton(icon: Icons.notifications_none_rounded),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 26),
                    decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(22)),
                    child: Column(
                      children: [
                        Container(
                          width: 118,
                          height: 118,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: unit.status.bg, width: 5),
                          ),
                          child: Center(
                            child: Text(
                              unit.lastReading != null ? '${unit.lastReading}\u00b0' : '\u2014',
                              style: AppTheme.mono(size: 26, weight: FontWeight.w700, color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text('${unit.name} \u00b7 ${unit.location}',
                            style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.w600, fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(unit.name, style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 2),
                            Text('${unit.location} \u00b7 checked twice daily', style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: AppColors.paper, borderRadius: BorderRadius.circular(14)),
                        child: Text(
                          unit.type == UnitType.hotHold ? 'Legal min ${unit.targetMax.toInt()}\u00b0C' : 'Legal max ${unit.targetMax.toInt()}\u00b0C',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.inkSoft),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text('Recent readings', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  FutureBuilder<List<Reading>>(
                    future: _readingsFuture,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Center(child: CircularProgressIndicator(color: AppColors.ink)));
                      }
                      final readings = snapshot.data!;
                      if (readings.isEmpty) {
                        return const Text('No readings logged yet.', style: TextStyle(color: AppColors.inkMute));
                      }
                      return SizedBox(
                        height: 92,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: readings.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (context, i) {
                            final r = readings[i];
                            return Container(
                              width: 128,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(16)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  StatusChip(label: '${r.value}\u00b0C', status: r.status, dense: true),
                                  const Spacer(),
                                  Text(DateFormat('MMM d, HH:mm').format(r.takenAt), style: const TextStyle(fontSize: 11, color: AppColors.inkMute)),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 12,
              child: SafeArea(
                top: false,
                child: PillButton(label: 'Log new reading', icon: Icons.add_rounded, onTap: () => _showLogSheet(context)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogSheet(BuildContext context) {
    final valueController = TextEditingController();
    final actionController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final value = double.tryParse(valueController.text);
            final inRange = value == null
                ? true
                : (widget.unit.type == UnitType.hotHold ? value >= widget.unit.targetMax : value <= widget.unit.targetMax);

            return Padding(
              padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Log a reading \u2014 ${widget.unit.name}', style: Theme.of(ctx).textTheme.titleLarge),
                  const SizedBox(height: 14),
                  TextField(
                    controller: valueController,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    onChanged: (_) => setSheetState(() {}),
                    style: AppTheme.mono(size: 18),
                    decoration: InputDecoration(
                      labelText: 'Temperature (\u00b0C)',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  if (value != null && !inRange) ...[
                    const SizedBox(height: 12),
                    const StatusChip(label: 'Out of range \u2014 a corrective action is required', status: ComplianceStatus.danger, dense: true),
                    const SizedBox(height: 10),
                    TextField(
                      controller: actionController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'What did you do about it?',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  PillButton(
                    label: 'Save reading',
                    icon: Icons.check_rounded,
                    onTap: () async {
                      if (value == null) return;
                      if (!inRange && actionController.text.trim().isEmpty) {
                        setSheetState(() {}); // nudge — keep the sheet open and the warning visible
                        return;
                      }
                      await _repo.logReading(
                        siteId: widget.siteId,
                        unitId: widget.unit.id,
                        value: value,
                        targetMax: widget.unit.targetMax,
                        unitType: widget.unit.type,
                        correctiveAction: inRange ? null : actionController.text.trim(),
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                      _reload();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
