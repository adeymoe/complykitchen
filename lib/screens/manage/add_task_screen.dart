import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/supabase_config.dart';
import '../../models/models.dart';
import '../../repositories/compliance_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/status_chip.dart';

/// Creates a recurring task template — the thing that turns into a
/// real checklist item on Today/Tasks every day via
/// ComplianceRepository.ensureTodayInstances.
class AddTaskScreen extends StatefulWidget {
  final String siteId;
  const AddTaskScreen({super.key, required this.siteId});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _title = TextEditingController();
  String _category = 'general';
  String _recurrence = 'daily';
  bool _requiresReading = false;
  String? _selectedUnitId;
  List<ComplianceUnit> _units = [];
  bool _saving = false;
  bool _loadingUnits = true;
  String? _error;

  static const _categories = {'general': 'General', 'fridge': 'Fridges', 'freezer': 'Freezers', 'cleaning': 'Cleaning', 'delivery': 'Delivery'};
  static const _recurrences = {'daily': 'Once daily', 'twice_daily': 'Twice daily', 'weekly': 'Weekly'};

  @override
  void initState() {
    super.initState();
    final repo = ComplianceRepository(SupabaseConfig.isDemoMode ? SupabaseClient('https://demo.supabase.co', 'demo-key') : Supabase.instance.client);
    repo.fetchUnits(widget.siteId).then((units) {
      if (mounted) setState(() { _units = units; _loadingUnits = false; });
    });
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) {
      setState(() => _error = 'Give the task a name.');
      return;
    }
    setState(() { _saving = true; _error = null; });
    try {
      await ComplianceRepository(Supabase.instance.client).createTaskTemplate(
        siteId: widget.siteId,
        title: _title.text.trim(),
        category: _category,
        unitId: _selectedUnitId,
        requiresReading: _requiresReading,
        recurrence: _recurrence,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = "Couldn't save that \u2014 check your connection and try again.");
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screen,
      appBar: AppBar(backgroundColor: AppColors.screen, elevation: 0, title: const Text('Add a task')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: ListView(
            children: [
              _field('Task name', _title, hint: 'e.g. Check Fridge 2, Weekly deep clean'),
              const SizedBox(height: 18),
              Text('Category', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: _categories.entries.map((e) => _choice(e.value, e.key == _category, () => setState(() => _category = e.key))).toList()),
              const SizedBox(height: 18),
              Text('How often', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: _recurrences.entries.map((e) => _choice(e.value, e.key == _recurrence, () => setState(() => _recurrence = e.key))).toList()),
              const SizedBox(height: 18),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Requires a temperature reading', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                subtitle: const Text('Turn this on for fridge/freezer/hot-hold checks', style: TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                value: _requiresReading,
                activeThumbColor: AppColors.ink,
                onChanged: (v) => setState(() => _requiresReading = v),
              ),
              if (_requiresReading) ...[
                const SizedBox(height: 8),
                Text('Which unit?', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (_loadingUnits)
                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: CircularProgressIndicator(color: AppColors.ink))
                else if (_units.isEmpty)
                  const Text('No units yet \u2014 add a fridge or freezer first.', style: TextStyle(color: AppColors.inkMute, fontSize: 12.5))
                else
                  Wrap(
                    spacing: 8,
                    children: _units.map((u) => _choice(u.name, u.id == _selectedUnitId, () => setState(() => _selectedUnitId = u.id))).toList(),
                  ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 14),
                StatusChip(label: _error!, status: ComplianceStatus.danger, dense: true),
              ],
              const SizedBox(height: 22),
              PillButton(label: _saving ? 'Saving...' : 'Save task', icon: Icons.check_rounded, onTap: _saving ? () {} : _save),
            ],
          ),
        ),
      ),
    );
  }

  Widget _choice(String label, bool on, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: on,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.ink,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(color: on ? Colors.white : AppColors.inkSoft, fontWeight: FontWeight.w600, fontSize: 12.5),
      side: BorderSide(color: on ? AppColors.ink : AppColors.line),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _field(String label, TextEditingController controller, {String? hint}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
      ),
    );
  }
}
