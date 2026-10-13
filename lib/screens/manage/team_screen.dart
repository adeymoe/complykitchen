import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/supabase_config.dart';
import '../../repositories/org_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/status_chip.dart';

class TeamScreen extends StatefulWidget {
  final String organizationId;
  final String siteId;
  const TeamScreen({super.key, required this.organizationId, required this.siteId});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  final _email = TextEditingController();
  late Future<List<TeamMember>> _membersFuture;
  bool _inviting = false;
  String? _message;
  bool _messageIsError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() => _membersFuture = OrgRepository(SupabaseConfig.isDemoMode ? SupabaseClient('https://demo.supabase.co', 'demo-key') : Supabase.instance.client).listSiteMembers(widget.siteId));
  }

  Future<void> _invite() async {
    final email = _email.text.trim();
    if (email.isEmpty) return;
    setState(() {
      _inviting = true;
      _message = null;
    });
    try {
      final found = await OrgRepository(SupabaseConfig.isDemoMode ? SupabaseClient('https://demo.supabase.co', 'demo-key') : Supabase.instance.client).inviteStaffByEmail(
        organizationId: widget.organizationId,
        siteId: widget.siteId,
        email: email,
      );
      if (found) {
        setState(() {
          _message = 'Added \u2014 they\'ll see this site next time they sign in.';
          _messageIsError = false;
        });
        _email.clear();
        _load();
      } else {
        setState(() {
          _message = "No ComplyKitchen account found for that email yet. Ask them to sign up first, then invite them again.";
          _messageIsError = true;
        });
      }
    } catch (e) {
      setState(() {
        _message = "Couldn't send that invite \u2014 check your connection and try again.";
        _messageIsError = true;
      });
    } finally {
      if (mounted) setState(() => _inviting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screen,
      appBar: AppBar(backgroundColor: AppColors.screen, elevation: 0, title: const Text('Team')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: FutureBuilder<List<TeamMember>>(
                  future: _membersFuture,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator(color: AppColors.ink));
                    }
                    final members = snapshot.data!;
                    return ListView.separated(
                      itemCount: members.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final m = members[i];
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(14)),
                          child: Row(
                            children: [
                              CircleAvatar(radius: 18, backgroundColor: AppColors.paper, child: Text(m.fullName.isNotEmpty ? m.fullName[0].toUpperCase() : '?', style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700))),
                              const SizedBox(width: 12),
                              Expanded(child: Text(m.fullName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5))),
                              StatusChip(
                                label: m.isInducted ? 'Inducted' : 'Needs induction',
                                status: m.isInducted ? ComplianceStatus.safe : ComplianceStatus.warn,
                                dense: true,
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              Text('Invite someone', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text('They need a ComplyKitchen account already \u2014 ask them to sign up, then invite their email here.', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 10),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
                ),
              ),
              if (_message != null) ...[
                const SizedBox(height: 10),
                StatusChip(label: _message!, status: _messageIsError ? ComplianceStatus.warn : ComplianceStatus.safe, dense: true),
              ],
              const SizedBox(height: 12),
              PillButton(label: _inviting ? 'Adding...' : 'Add to this site', icon: Icons.person_add_alt_1_rounded, onTap: _inviting ? () {} : _invite),
            ],
          ),
        ),
      ),
    );
  }
}
