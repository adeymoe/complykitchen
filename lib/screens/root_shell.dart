import 'package:flutter/material.dart';
import '../repositories/org_repository.dart';
import '../theme/app_theme.dart';
import 'alerts_screen.dart';
import 'dashboard_screen.dart';
import 'tasks_screen.dart';
import 'today_screen.dart';

/// Bottom-nav shell with the floating pill nav bar from the design.
/// Takes a real site (from Supabase) rather than mock data — this is
/// the actual app now, not a demo of it.
class RootShell extends StatefulWidget {
  final MySite site;
  const RootShell({super.key, required this.site});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      TodayScreen(site: widget.site),
      TasksScreen(site: widget.site),
      AlertsScreen(site: widget.site),
      DashboardScreen(site: widget.site),
    ];

    return Scaffold(
      backgroundColor: AppColors.screen,
      body: Stack(
        children: [
          screens[_index],
          Positioned(
            left: 20,
            right: 20,
            bottom: 18,
            child: SafeArea(
              top: false,
              child: Container(
                height: 60,
                decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(30)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _navIcon(Icons.home_rounded, 0),
                    _navIcon(Icons.checklist_rounded, 1),
                    _navIcon(Icons.notifications_none_rounded, 2, badge: widget.site.needsInduction),
                    _navIcon(Icons.bar_chart_rounded, 3),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navIcon(IconData icon, int index, {bool badge = false}) {
    final on = _index == index;
    return GestureDetector(
      onTap: () => setState(() => _index = index),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: on ? Colors.white : Colors.transparent, shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: on ? AppColors.ink : Colors.white),
          ),
          if (badge)
            Positioned(
              top: 6, right: 6,
              child: Container(
                width: 7, height: 7,
                decoration: BoxDecoration(color: AppColors.danger, shape: BoxShape.circle, border: Border.all(color: AppColors.ink, width: 1.5)),
              ),
            ),
        ],
      ),
    );
  }
}
