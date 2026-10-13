import 'package:supabase_flutter/supabase_flutter.dart';

/// A site the current user belongs to, plus their induction status
/// there — the turnover-proof onboarding differentiator lives on this
/// join, not buried in a settings screen.
class MySite {
  final String siteId;
  final String siteName;
  final String nation;
  final String organizationId;
  final DateTime? inductedAt;

  const MySite({
    required this.siteId,
    required this.siteName,
    required this.nation,
    required this.organizationId,
    required this.inductedAt,
  });

  bool get needsInduction => inductedAt == null;
}

/// Handles organisation/site creation on signup, and looking up which
/// sites the current user can access. This is the multi-tenant
/// self-registration flow: anyone can sign up and spin up their own
/// organisation + first site without an admin provisioning anything.
class OrgRepository {
  final SupabaseClient _client;
  OrgRepository(this._client);

  /// Creates a brand-new organisation with one site, makes the current
  /// user its owner, and marks them as already inducted at that site
  /// (an owner setting up their own restaurant doesn't need a
  /// new-starter induction flow for themselves).
  Future<String> createOrganizationWithSite({
    required String organizationName,
    required String siteName,
    required String nation,
  }) async {
    final userId = _client.auth.currentUser!.id;

    final org = await _client
        .from('organizations')
        .insert({'name': organizationName})
        .select()
        .single();
    final orgId = org['id'] as String;

    await _client.from('memberships').insert({
      'organization_id': orgId,
      'user_id': userId,
      'role': 'owner',
    });

    final site = await _client
        .from('sites')
        .insert({
          'organization_id': orgId,
          'name': siteName,
          'nation': nation,
        })
        .select()
        .single();
    final siteId = site['id'] as String;

    await _client.from('site_memberships').insert({
      'site_id': siteId,
      'user_id': userId,
      'inducted_at': DateTime.now().toIso8601String(),
    });

    return siteId;
  }

  /// Sites the current user has access to, with their induction status
  /// at each. In v1 the app just uses the first result — multi-site
  /// switching in the UI is a documented follow-up, not built yet.
  Future<List<MySite>> getMySites() async {
    final userId = _client.auth.currentUser!.id;
    final rows = await _client
        .from('site_memberships')
        .select('inducted_at, sites(id, name, nation, organization_id)')
        .eq('user_id', userId);

    return (rows as List).map((row) {
      final site = row['sites'] as Map<String, dynamic>;
      return MySite(
        siteId: site['id'] as String,
        siteName: site['name'] as String,
        nation: site['nation'] as String,
        organizationId: site['organization_id'] as String,
        inductedAt: row['inducted_at'] == null
            ? null
            : DateTime.parse(row['inducted_at'] as String),
      );
    }).toList();
  }

  /// Marks the current user as having completed new-starter induction
  /// at this site. Called from the induction screen's "I've read this"
  /// confirmation.
  Future<void> markInducted(String siteId) async {
    final userId = _client.auth.currentUser!.id;
    await _client
        .from('site_memberships')
        .update({'inducted_at': DateTime.now().toIso8601String()})
        .eq('site_id', siteId)
        .eq('user_id', userId);
  }

  // ---------------------------------------------------------------
  // Team management
  // ---------------------------------------------------------------

  /// Everyone with access to this site, and whether they've completed
  /// induction here — the manager-facing view of the same data the
  /// staff-facing induction banner is built on.
  Future<List<TeamMember>> listSiteMembers(String siteId) async {
    final rows = await _client
        .from('site_memberships')
        .select('inducted_at, profiles(id, full_name)')
        .eq('site_id', siteId);

    return (rows as List).map((row) {
      final profile = row['profiles'] as Map<String, dynamic>?;
      return TeamMember(
        userId: profile?['id'] as String? ?? '',
        fullName: (profile?['full_name'] as String?) ?? 'Team member',
        inductedAt: row['inducted_at'] == null ? null : DateTime.parse(row['inducted_at'] as String),
      );
    }).toList();
  }

  /// Invites an existing ComplyKitchen user to this site by email.
  ///
  /// This only works if that person already has an account — this
  /// client-side MVP has no way to create an account or send an email
  /// invite on someone else's behalf (that needs the Supabase admin
  /// API via a server-side Edge Function, which is a real next step,
  /// not built here). Returns false if no account exists for that
  /// email, so the caller can show a clear "ask them to sign up first"
  /// message rather than fail silently.
  Future<bool> inviteStaffByEmail({
    required String organizationId,
    required String siteId,
    required String email,
  }) async {
    final userId = await _client.rpc('find_user_id_by_email', params: {'lookup_email': email.trim()});
    if (userId == null) return false;

    await _client.from('memberships').upsert({
      'organization_id': organizationId,
      'user_id': userId,
      'role': 'staff',
    }, onConflict: 'organization_id,user_id');

    await _client.from('site_memberships').upsert({
      'site_id': siteId,
      'user_id': userId,
    }, onConflict: 'site_id,user_id');

    return true;
  }
}

class TeamMember {
  final String userId;
  final String fullName;
  final DateTime? inductedAt;
  const TeamMember({required this.userId, required this.fullName, required this.inductedAt});

  bool get isInducted => inductedAt != null;
}
