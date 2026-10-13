import 'package:flutter/material.dart';
import '../../repositories/org_repository.dart';
import '../../theme/app_theme.dart';
import 'add_task_screen.dart';
import 'manage_units_screen.dart';
import 'team_screen.dart';

/// Setup hub: everything an owner needs to configure before staff can
/// actually use the app for real, in one place instead of scattered
/// across screens.
class ManageSiteScreen extends StatelessWidget {
  final MySite site;
  const ManageSiteScreen({super.key, required this.site});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screen,
      appBar: AppBar(backgroundColor: AppColors.screen, elevation: 0, title: Text('Manage ${site.siteName}')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            children: [
              _row(
                context,
                icon: Icons.kitchen_outlined,
                title: 'Units',
                subtitle: 'Fridges, freezers, hot-hold points',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ManageUnitsScreen(siteId: site.siteId))),
              ),
              const SizedBox(height: 10),
              _row(
                context,
                icon: Icons.checklist_rounded,
                title: 'Tasks',
                subtitle: 'What gets checked, and how often',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddTaskScreen(siteId: site.siteId))),
              ),
              const SizedBox(height: 10),
              _row(
                context,
                icon: Icons.people_outline_rounded,
                title: 'Team',
                subtitle: 'Who has access, and their induction status',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TeamScreen(organizationId: site.organizationId, siteId: site.siteId))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, {required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: AppColors.paper, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: AppColors.ink),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                  Text(subtitle, style: const TextStyle(color: AppColors.inkSoft, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.inkMute),
          ],
        ),
      ),
    );
  }
}
