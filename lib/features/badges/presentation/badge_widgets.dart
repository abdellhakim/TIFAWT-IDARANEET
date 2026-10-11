import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../domain/badge.dart';

IconData badgeIcon(BadgeType badge) => switch (badge) {
  BadgeType.profileCompleted => Icons.person_rounded,
  BadgeType.firstRecommendation => Icons.explore_rounded,
  BadgeType.firstOpportunity => Icons.flag_rounded,
  BadgeType.trainingStarted => Icons.school_rounded,
  BadgeType.trainingCompleted => Icons.workspace_premium_rounded,
};

/// Rosette medal; greyed out until earned.
class BadgeMedal extends StatelessWidget {
  const BadgeMedal({super.key, required this.badge, required this.earned, this.size = 56});
  final BadgeType badge;
  final bool earned;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size * 1.15,
    child: CustomPaint(
      painter: _MedalPainter(earned),
      child: Align(
        alignment: const Alignment(0, -.32),
        child: Icon(badgeIcon(badge), size: size * .36, color: earned ? Colors.white : AppColors.textMuted),
      ),
    ),
  );
}

class _MedalPainter extends CustomPainter {
  _MedalPainter(this.earned);
  final bool earned;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final center = Offset(r, r);
    final ribbon = earned ? AppColors.terracotta : AppColors.divider;
    for (final dx in [-.35, .35]) {
      final path = Path()
        ..moveTo(center.dx + dx * r - r * .18, center.dy + r * .5)
        ..lineTo(center.dx + dx * r + r * .18, center.dy + r * .5)
        ..lineTo(center.dx + dx * r * 1.25 + r * .18, size.height)
        ..lineTo(center.dx + dx * r * 1.25, size.height - r * .16)
        ..lineTo(center.dx + dx * r * 1.25 - r * .18, size.height)
        ..close();
      canvas.drawPath(path, Paint()..color = ribbon);
    }

    // Scalloped rosette.
    final rosette = Path();
    const petals = 14;
    for (var i = 0; i <= petals * 2; i++) {
      final angle = i * math.pi / petals - math.pi / 2;
      final radius = i.isEven ? r * .98 : r * .86;
      final p = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      i == 0 ? rosette.moveTo(p.dx, p.dy) : rosette.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(rosette, Paint()..color = earned ? AppColors.amber : AppColors.track);
    canvas.drawCircle(
      center,
      r * .7,
      Paint()..color = earned ? const Color(0xFFC97F1D) : const Color(0xFFE2DDD2),
    );
    canvas.drawCircle(
      center,
      r * .62,
      Paint()
        ..color = Colors.white.withValues(alpha: earned ? .35 : .6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(_MedalPainter old) => old.earned != earned;
}

/// Slide-in banner shown when a badge is unlocked.
void showBadgeToast(OverlayState overlay, BadgeType badge, AppStrings s) {
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _BadgeToast(badge: badge, strings: s, onDone: () => entry.remove()),
  );
  overlay.insert(entry);
}

class _BadgeToast extends StatefulWidget {
  const _BadgeToast({required this.badge, required this.strings, required this.onDone});
  final BadgeType badge;
  final AppStrings strings;
  final VoidCallback onDone;

  @override
  State<_BadgeToast> createState() => _BadgeToastState();
}

class _BadgeToastState extends State<_BadgeToast> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _timer = Timer(const Duration(milliseconds: 3200), () async {
      if (!mounted) return;
      await _controller.reverse();
      widget.onDone();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 10,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, -1.4),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack)),
        child: Directionality(
          textDirection: s.isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              decoration: BoxDecoration(
                color: AppColors.textDark,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 20, offset: Offset(0, 8))],
              ),
              child: Row(
                children: [
                  BadgeMedal(badge: widget.badge, earned: true, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          s.badgeUnlocked,
                          style: AppText.label(12, color: AppColors.amber, weight: FontWeight.w700),
                        ),
                        Text(widget.badge.label(s.isAr), style: AppText.title(15, color: Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
