import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/supabase_config.dart';
import '../../models/models.dart';
import '../../repositories/compliance_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/status_chip.dart';

/// The single most important setup screen in the app — without a unit,
/// nothing else (Today, induction, readings, dashboard) has anything
/// to show.
class AddUnitScreen extends StatefulWidget {
  final String siteId;
  const AddUnitScreen({super.key, required this.siteId});

  @override
  State<AddUnitScreen> createState() => _AddUnitScreenState();
}

class _AddUnitScreenState extends State<AddUnitScreen> {
  final _name = TextEditingController();
  final _location = TextEditingController();
  final _target = TextEditingController();
  UnitType _type = UnitType.fridge;
  bool _saving = false;
  String? _error;

  String get _targetLabel {
    switch (_type) {
      case UnitType.hotHold:
        return 'Legal minimum (\u00b0C) \u2014 must stay at or above this';
      case UnitType.fridge:
      case UnitType.freezer:
        return 'Legal maximum (\u00b0C) \u2014 must stay at or below this';
    }
  }

  double get _suggestedDefault {
    switch (_type) {
      case UnitType.fridge:
        return 8;
      case UnitType.freezer:
        return -18;
      case UnitType.hotHold:
        return 63;
    }
  }

  @override
  void initState() {
    super.initState();
    _target.text = _suggestedDefault.toString();
  }

  Future<void> _save() async {
    final target = double.tryParse(_target.text);
    if (_name.text.trim().isEmpty || target == null) {
      setState(() => _error = 'Enter a name and a valid number for the threshold.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ComplianceRepository(SupabaseConfig.isDemoMode ? SupabaseClient('https://demo.supabase.co', 'demo-key') : Supabase.instance.client).createUnit(
        siteId: widget.siteId,
        name: _name.text.trim(),
        location: _location.text.trim(),
        type: _type,
        targetMax: target,
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
      appBar: AppBar(backgroundColor: AppColors.screen, elevation: 0, title: const Text('Add a unit')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: ListView(
            children: [
              Text('Type', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _typeChip('Fridge', UnitType.fridge),
                  _typeChip('Freezer', UnitType.freezer),
                  _typeChip('Hot holding', UnitType.hotHold),
                ],
              ),
              const SizedBox(height: 18),
              _field('Name', _name, hint: 'e.g. Fridge 2'),
              const SizedBox(height: 14),
              _field('Location', _location, hint: 'e.g. Walk-in, prep kitchen'),
              const SizedBox(height: 14),
              _field(_targetLabel, _target, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true)),
              const SizedBox(height: 6),
              Text(
                'Defaults to the standard UK legal threshold for this unit type \u2014 change it if this unit is set differently.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                StatusChip(label: _error!, status: ComplianceStatus.danger, dense: true),
              ],
              const SizedBox(height: 22),
              PillButton(label: _saving ? 'Saving...' : 'Save unit', icon: Icons.check_rounded, onTap: _saving ? () {} : _save),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeChip(String label, UnitType type) {
    final on = _type == type;
    return ChoiceChip(
      label: Text(label),
      selected: on,
      onSelected: (_) => setState(() {
        _type = type;
        _target.text = _suggestedDefault.toString();
      }),
      selectedColor: AppColors.ink,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(color: on ? Colors.white : AppColors.inkSoft, fontWeight: FontWeight.w600, fontSize: 12.5),
      side: BorderSide(color: on ? AppColors.ink : AppColors.line),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _field(String label, TextEditingController controller, {String? hint, TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
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
