import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../repositories/org_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/status_chip.dart';

/// Shown once, right after a new account's first sign-in: this is the
/// multi-tenant self-registration moment. Every restaurant configures
/// its own organisation and first site here — nobody has to
/// provision anything for them.
class SetupOrganizationScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const SetupOrganizationScreen({super.key, required this.onComplete});

  @override
  State<SetupOrganizationScreen> createState() => _SetupOrganizationScreenState();
}

class _SetupOrganizationScreenState extends State<SetupOrganizationScreen> {
  final _orgName = TextEditingController();
  final _siteName = TextEditingController();
  String _nation = 'england';
  bool _loading = false;
  String? _error;

  static const _nations = {
    'england': 'England',
    'wales': 'Wales',
    'scotland': 'Scotland',
    'northern_ireland': 'Northern Ireland',
  };

  Future<void> _submit() async {
    if (_orgName.text.trim().isEmpty || _siteName.text.trim().isEmpty) {
      setState(() => _error = 'Fill in both fields to continue.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = OrgRepository(Supabase.instance.client);
      await repo.createOrganizationWithSite(
        organizationName: _orgName.text.trim(),
        siteName: _siteName.text.trim(),
        nation: _nation,
      );
      widget.onComplete();
    } catch (e) {
      setState(() => _error = "Couldn't set that up — check your connection and try again.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screen,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Set up your restaurant', style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 4),
              Text('This creates your account and your first site — you can add more sites later.', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 24),
              _field('Restaurant / business name', _orgName, hint: 'e.g. The Copper Spoon Ltd'),
              const SizedBox(height: 14),
              _field('This site\'s name', _siteName, hint: 'e.g. The Copper Spoon — Newcastle'),
              const SizedBox(height: 14),
              Text('Nation', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _nations.entries.map((e) {
                  final on = e.key == _nation;
                  return ChoiceChip(
                    label: Text(e.value),
                    selected: on,
                    onSelected: (_) => setState(() => _nation = e.key),
                    selectedColor: AppColors.ink,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(color: on ? Colors.white : AppColors.inkSoft, fontWeight: FontWeight.w600, fontSize: 12.5),
                    side: BorderSide(color: on ? AppColors.ink : AppColors.line),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  );
                }).toList(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                StatusChip(label: _error!, status: ComplianceStatus.danger, dense: true),
              ],
              const SizedBox(height: 24),
              PillButton(
                label: _loading ? 'Setting up...' : 'Create my site',
                icon: Icons.arrow_forward_rounded,
                onTap: _loading ? () {} : _submit,
              ),
            ],
          ),
        ),
      ),
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
