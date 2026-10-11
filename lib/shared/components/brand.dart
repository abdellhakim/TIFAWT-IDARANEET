import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// The official TIFAWT logo. The artwork ships as white-on-transparent masks
/// (extracted from design/brand by tool/extract_logo_test.dart) and is tinted
/// here: white on terracotta, terracotta on the cream background.
class TifawtLogo extends StatelessWidget {
  const TifawtLogo({
    super.key,
    this.height = 96,
    this.color = AppColors.terracotta,
    this.mountainsOnly = false,
  });

  final double height;
  final Color color;

  /// Just the mountains, for small spaces where the wordmark would be unreadable.
  final bool mountainsOnly;

  static const fullAsset = 'assets/images/brand/logo_mask.png';
  static const mountainsAsset = 'assets/images/brand/mountains_mask.png';

  @override
  Widget build(BuildContext context) => Image.asset(
    mountainsOnly ? mountainsAsset : fullAsset,
    height: height,
    color: color,
    colorBlendMode: BlendMode.srcIn,
    filterQuality: FilterQuality.medium,
    semanticLabel: 'TIFAWT',
  );
}

/// App-icon style tile: white mountains on terracotta.
class TifawtLogoTile extends StatelessWidget {
  const TifawtLogoTile({super.key, this.size = 48});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: AppColors.terracotta, borderRadius: BorderRadius.circular(size * .24)),
    alignment: Alignment.center,
    child: TifawtLogo(mountainsOnly: true, color: Colors.white, height: size * .4),
  );
}

/// Thin Amazigh-inspired zigzag used as a decorative divider.
class AmazighBand extends StatelessWidget {
  const AmazighBand({super.key, this.color = AppColors.peach, this.height = 10});
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    width: double.infinity,
    child: CustomPaint(painter: _BandPainter(color)),
  );
}

class _BandPainter extends CustomPainter {
  _BandPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final step = size.height * 1.2;
    final path = Path()..moveTo(0, size.height);
    for (var x = 0.0; x < size.width; x += step) {
      path
        ..lineTo(x + step / 2, 0)
        ..lineTo(x + step, size.height);
    }
    canvas.drawPath(path, paint);
    for (var x = step / 2; x < size.width; x += step * 2) {
      canvas.drawCircle(Offset(x, size.height * .62), 1.4, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_BandPainter old) => old.color != color;
}

/// The assistant's face: a friendly round character, not a robot icon.
class BotAvatar extends StatelessWidget {
  const BotAvatar({super.key, this.size = 40, this.filled = true});
  final double size;

  /// Filled olive disc (header) or light disc (next to chat bubbles).
  final bool filled;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _BotPainter(filled)),
  );
}

class _BotPainter extends CustomPainter {
  _BotPainter(this.filled);
  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final c = Offset(s / 2, s / 2);
    canvas.drawCircle(c, s / 2, Paint()..color = filled ? AppColors.olive : AppColors.oliveMist);

    final faceColor = filled ? const Color(0xFFF6F1E3) : Colors.white;
    final line = filled ? AppColors.oliveDark : AppColors.olive;

    final face = Rect.fromCenter(center: c.translate(0, s * .04), width: s * .56, height: s * .5);
    canvas.drawRRect(RRect.fromRectAndRadius(face, Radius.circular(s * .2)), Paint()..color = faceColor);
    canvas.drawRRect(
      RRect.fromRectAndRadius(face, Radius.circular(s * .2)),
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * .045,
    );
    // Hair / headscarf fold.
    final hair = Path()
      ..moveTo(face.left, face.top + face.height * .38)
      ..quadraticBezierTo(face.left + face.width * .2, face.top - s * .06, face.center.dx, face.top + s * .02)
      ..quadraticBezierTo(
        face.right - face.width * .15,
        face.top - s * .08,
        face.right,
        face.top + face.height * .35,
      )
      ..quadraticBezierTo(
        face.center.dx + s * .04,
        face.top + face.height * .18,
        face.left,
        face.top + face.height * .38,
      )
      ..close();
    canvas.drawPath(hair, Paint()..color = line);

    final eye = Paint()..color = AppColors.textDark;
    canvas.drawCircle(face.center.translate(-s * .1, s * .04), s * .035, eye);
    canvas.drawCircle(face.center.translate(s * .1, s * .04), s * .035, eye);
    final smile = Path()
      ..moveTo(face.center.dx - s * .07, face.center.dy + s * .12)
      ..quadraticBezierTo(
        face.center.dx,
        face.center.dy + s * .18,
        face.center.dx + s * .07,
        face.center.dy + s * .12,
      );
    canvas.drawPath(
      smile,
      Paint()
        ..color = AppColors.textDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * .035
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_BotPainter old) => old.filled != filled;
}
