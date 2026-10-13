import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Small rounded chip showing a temperature reading and its compliance
/// status. Used anywhere a reading needs to be shown at a glance.
class StatusChip extends StatelessWidget {
  final String label;
  final ComplianceStatus status;
  final bool dense;

  const StatusChip({super.key, required this.label, required this.status, this.dense = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 8 : 10, vertical: dense ? 4 : 6),
      decoration: BoxDecoration(
        color: status.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(color: status.fg, shape: BoxShape.circle),
          ),
          Text(
            label,
            style: TextStyle(
              color: status.fg,
              fontWeight: FontWeight.w700,
              fontSize: dense ? 12 : 13,
            ),
          ),
        ],
      ),
    );
  }
}

/// A round icon button matching the reference design's floating circular
/// controls (back button, alert toggle, filter button).
class RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool dark;

  const RoundIconButton({super.key, required this.icon, this.onTap, this.dark = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: dark ? AppColors.ink : Colors.white,
          boxShadow: dark
              ? null
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 1))],
        ),
        child: Icon(icon, size: 18, color: dark ? Colors.white : AppColors.ink),
      ),
    );
  }
}

/// The black pill CTA button used throughout (log reading, export report).
class PillButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool light;

  const PillButton({super.key, required this.label, required this.icon, required this.onTap, this.light = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(light ? 16 : 18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: light ? Colors.white : AppColors.ink,
          borderRadius: BorderRadius.circular(light ? 16 : 18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: light ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: light ? AppColors.ink : Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, size: 16, color: light ? AppColors.ink : Colors.white),
          ],
        ),
      ),
    );
  }
}
