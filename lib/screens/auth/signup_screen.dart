import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import '../../widgets/status_chip.dart';

/// Collects identity only (name, email, password). Creating the
/// organisation and first site happens in a separate step once a
/// session exists — see SetupOrganizationScreen — so this screen
/// works the same whether or not email confirmation is switched on
/// for the Supabase project.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _info;

  Future<void> _signUp() async {
    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });
    try {
      final res = await Supabase.instance.client.auth.signUp(
        email: _email.text.trim(),
        password: _password.text,
        data: {'full_name': _name.text.trim()},
      );
      if (res.session == null) {
        // Email confirmation is switched on for this project — there's
        // no session yet, so AuthGate can't pick this up automatically.
        setState(() => _info = 'Check your email to confirm your account, then sign in.');
      }
      // If a session came back immediately, AuthGate's stream listener
      // picks it up and routes to organisation setup on its own.
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Something went wrong. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screen,
      appBar: AppBar(backgroundColor: AppColors.screen, elevation: 0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Create your account', style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 4),
              Text("Next you'll set up your restaurant", style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 24),
              _field('Full name', _name),
              const SizedBox(height: 14),
              _field('Email', _email, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 14),
              _field('Password', _password, obscure: true),
              if (_error != null) ...[
                const SizedBox(height: 12),
                StatusChip(label: _error!, status: ComplianceStatus.danger, dense: true),
              ],
              if (_info != null) ...[
                const SizedBox(height: 12),
                StatusChip(label: _info!, status: ComplianceStatus.safe, dense: true),
              ],
              const SizedBox(height: 22),
              PillButton(
                label: _loading ? 'Creating account...' : 'Create account',
                icon: Icons.arrow_forward_rounded,
                onTap: _loading ? () {} : _signUp,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller, {bool obscure = false, TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
      ),
    );
  }
}
