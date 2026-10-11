import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';

/// White rounded square with a soft shadow (back, search, settings).
class SquareIconButton extends StatelessWidget {
  const SquareIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.color = AppColors.terracotta,
    this.tooltip,
    this.size = 44,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final String? tooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    final button = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 14, offset: Offset(0, 4))],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: SizedBox.square(
            dimension: size,
            child: Icon(icon, size: 21, color: color),
          ),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

/// Back button. Like in the design it sits on the physical left with a
/// "<" in both languages.
class BackSquare extends StatelessWidget {
  const BackSquare({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: SquareIconButton(
      icon: Icons.chevron_left_rounded,
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      onTap: onTap ?? () => Navigator.of(context).maybePop(),
    ),
  );
}

/// Header: back on the left, optional action on the right, centred title.
class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, this.action, this.onBack});

  final String title;
  final Widget? action;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final appDirection = Directionality.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          children: [
            BackSquare(onTap: onBack),
            Expanded(
              child: Directionality(
                textDirection: appDirection,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.heading(19),
                ),
              ),
            ),
            action ?? const SizedBox(width: 44),
          ],
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing, this.size = 19});
  final String text;
  final Widget? trailing;
  final double size;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(text, style: AppText.heading(size))),
      ?trailing,
    ],
  );
}

/// White card with the hairline border and soft shadow of the design.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = Colors.white,
    this.radius = 18,
    this.onTap,
    this.borderColor = AppColors.cardBorder,
    this.shadow = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final double radius;
  final VoidCallback? onTap;
  final Color borderColor;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: borderColor),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadow
            ? const [BoxShadow(color: Color(0x0F000000), blurRadius: 18, offset: Offset(0, 6))]
            : null,
      ),
      child: Material(
        color: color,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

enum TagTone { olive, rose, sand, amber, neutral }

/// Small rounded tag ("بلا دبلوم", "6 شهور", "مجاني").
class Tag extends StatelessWidget {
  const Tag(this.label, {super.key, this.tone = TagTone.olive, this.icon});
  final String label;
  final TagTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      TagTone.olive => (AppColors.oliveTag, AppColors.oliveTagText),
      TagTone.rose => (AppColors.roseTag, AppColors.terracotta),
      TagTone.sand => (AppColors.sand, AppColors.sandText),
      TagTone.amber => (AppColors.amberLight, const Color(0xFF9A6413)),
      TagTone.neutral => (AppColors.track, AppColors.textMedium),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 13, color: fg), const SizedBox(width: 4)],
          Text(
            label,
            style: AppText.label(12, color: fg, weight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// User picture placeholder: initial in a framed rounded square, like the
/// photo frame of the design.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.name, this.size = 50, this.framed = true});
  final String name;
  final double size;
  final bool framed;

  static const _palette = [AppColors.olive, AppColors.terracottaDark, Color(0xFF8A5A2B), AppColors.oliveDark];

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final initial = trimmed.isEmpty ? '؟' : trimmed.characters.first.toUpperCase();
    final color = _palette[trimmed.hashCode.abs() % _palette.length];
    final radius = size * .26;
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(framed ? size * .07 : 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: framed
            ? const [BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 4))]
            : null,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius * .8),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withValues(alpha: .85), color],
          ),
        ),
        alignment: Alignment.center,
        child: Text(initial, style: AppText.heading(size * .4, color: Colors.white).copyWith(height: 1.1)),
      ),
    );
  }
}

/// Dashed rounded border ("زيد وثيقة" tile).
class DashedBorder extends StatelessWidget {
  const DashedBorder({super.key, required this.child, this.radius = 18, this.color = AppColors.textMuted});
  final Widget child;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _DashedPainter(radius, color), child: child);
}

class _DashedPainter extends CustomPainter {
  _DashedPainter(this.radius, this.color);
  final double radius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius((Offset.zero & size).deflate(.75), Radius.circular(radius)));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 6), paint);
        d += 11;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedPainter old) => old.color != color || old.radius != radius;
}

/// Circular compatibility gauge.
class MatchRing extends StatelessWidget {
  const MatchRing({super.key, required this.score, this.size = 54, this.label});
  final int score;
  final double size;
  final String? label;

  static Color colorFor(int score) => score >= 80
      ? AppColors.olive
      : score >= 60
      ? AppColors.amber
      : AppColors.textMuted;

  @override
  Widget build(BuildContext context) {
    final color = colorFor(score);
    return SizedBox.square(
      dimension: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: score / 100),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) => CustomPaint(
          painter: _RingPainter(value, color),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(value * 100).round()}%',
                  textDirection: TextDirection.ltr,
                  style: AppText.title(size * .26, color: AppColors.textDark).copyWith(height: 1),
                ),
                if (label != null)
                  Text(
                    label!,
                    style: AppText.label(size * .14, color: AppColors.textMuted).copyWith(height: 1.2),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value, this.color);
  final double value;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * .1;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..color = AppColors.track
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * value,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.value != value || old.color != color;
}

/// Rounded progress bar used on the timeline.
class SoftProgressBar extends StatelessWidget {
  const SoftProgressBar({super.key, required this.value, this.color = AppColors.amber, this.height = 8});
  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(height),
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0, 1)),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => LinearProgressIndicator(
        value: v,
        minHeight: height,
        backgroundColor: AppColors.track,
        valueColor: AlwaysStoppedAnimation(color),
      ),
    ),
  );
}

/// "Forward" chevron: Material mirrors it, so it points left in Arabic
/// (as in the design) and right in French.
class ForwardChevron extends StatelessWidget {
  const ForwardChevron({super.key, this.size = 20, this.color = AppColors.textDark});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Icon(Icons.chevron_right_rounded, size: size, color: color);
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.body});
  final IconData icon;
  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(color: AppColors.peach, shape: BoxShape.circle),
          child: Icon(icon, size: 32, color: AppColors.terracotta),
        ),
        const SizedBox(height: 14),
        Text(title, textAlign: TextAlign.center, style: AppText.title(16)),
        if (body != null) ...[
          const SizedBox(height: 4),
          Text(body!, textAlign: TextAlign.center, style: AppText.label(13.5)),
        ],
      ],
    ),
  );
}
