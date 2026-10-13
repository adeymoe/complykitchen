import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/supabase_config.dart';
import '../../repositories/org_repository.dart';
import '../../theme/app_theme.dart';
import '../root_shell.dart';
import 'login_screen.dart';
import 'setup_organization_screen.dart';

/// The single source of truth for "what should be on screen right now":
///
/// no session          -> LoginScreen
/// session, no sites    -> SetupOrganizationScreen (multi-tenant signup)
/// session, has a site   -> RootShell (the actual app)
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Future<List<MySite>>? _sitesFuture;

  void _loadSites() {
    setState(() {
      _sitesFuture = OrgRepository(Supabase.instance.client).getMySites();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (SupabaseConfig.isDemoMode) {
      return const RootShell(
        site: MySite(
          siteId: 'demo-site',
          siteName: 'Demo Kitchen',
          nation: 'England',
          organizationId: 'demo-org',
          inductedAt: null,
        ),
      );
    }

    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;

        if (session == null) {
          return const LoginScreen();
        }

        _sitesFuture ??= OrgRepository(Supabase.instance.client).getMySites();

        return FutureBuilder<List<MySite>>(
          future: _sitesFuture,
          builder: (context, siteSnapshot) {
            if (siteSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: AppColors.screen,
                body: Center(child: CircularProgressIndicator(color: AppColors.ink)),
              );
            }
            final sites = siteSnapshot.data ?? [];
            if (sites.isEmpty) {
              return SetupOrganizationScreen(onComplete: _loadSites);
            }
            // v1 uses the first site only — a site switcher for staff
            // who work across locations is a documented follow-up.
            return RootShell(site: sites.first);
          },
        );
      },
    );
  }
}
