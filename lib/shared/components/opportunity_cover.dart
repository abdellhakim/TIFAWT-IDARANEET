import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Real photos can be dropped in `assets/images/opportunities/<imageKey>.jpg`
/// (or .png/.webp); otherwise a painted cover is used.
abstract final class OpportunityPhotos {
  static Set<String> _assets = const {};

  static Future<void> load() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      _assets = manifest.listAssets().where((a) => a.startsWith('assets/images/opportunities/')).toSet();
    } catch (_) {
      _assets = const {};
    }
  }

  static String? pathFor(String key) {
    for (final ext in const ['jpg', 'jpeg', 'png', 'webp']) {
      final path = 'assets/images/opportunities/$key.$ext';
      if (_assets.contains(path)) return path;
    }
    return null;
  }
}

class OpportunityCover extends StatelessWidget {
  const OpportunityCover({
    super.key,
    required this.imageKey,
    this.height = 112,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
  });

  final String imageKey;
  final double height;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final photo = OpportunityPhotos.pathFor(imageKey);
    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: photo != null
            ? Image.asset(photo, fit: BoxFit.cover)
            : CustomPaint(painter: _CoverPainter(_styles[imageKey] ?? _styles['default']!)),
      ),
    );
  }

  static const _styles = <String, _CoverStyle>{
    'digital': _CoverStyle(Color(0xFF3D4A57), Color(0xFF6A7F93), Icons.laptop_mac_rounded),
    'digital2': _CoverStyle(Color(0xFF4E5D3A), Color(0xFF7F925A), Icons.phone_android_rounded),
    'electric': _CoverStyle(Color(0xFF4A3B2C), Color(0xFF8E6E46), Icons.electrical_services_rounded),
    'sewing': _CoverStyle(Color(0xFF7A3E2E), Color(0xFFB46A4F), Icons.content_cut_rounded),
    'argan': _CoverStyle(Color(0xFF5C4A22), Color(0xFF9C7C3A), Icons.spa_rounded),
    'agri': _CoverStyle(Color(0xFF55663A), Color(0xFF93A662), Icons.grass_rounded),
    'solar': _CoverStyle(Color(0xFF8E5A12), Color(0xFFE59A2F), Icons.solar_power_rounded),
    'tourism': _CoverStyle(Color(0xFF2F5E6E), Color(0xFF5E92A0), Icons.luggage_rounded),
    'logistics': _CoverStyle(Color(0xFF5A4636), Color(0xFF8C7056), Icons.local_shipping_rounded),
    'sales': _CoverStyle(Color(0xFF7C3A22), Color(0xFFB5452C), Icons.storefront_rounded),
    'awrach': _CoverStyle(Color(0xFF6B5E2E), Color(0xFFA38F48), Icons.engineering_rounded),
    'aid': _CoverStyle(Color(0xFF8E3315), Color(0xFFC86A3A), Icons.volunteer_activism_rounded),
    'orientation': _CoverStyle(Color(0xFF55663A), Color(0xFF6C7F46), Icons.explore_rounded),
    'alpha': _CoverStyle(Color(0xFF3F5E78), Color(0xFF6F8FA8), Icons.menu_book_rounded),
    'cooking': _CoverStyle(Color(0xFF7A4A22), Color(0xFFB98140), Icons.restaurant_rounded),
    'care': _CoverStyle(Color(0xFF6E4A5E), Color(0xFFA0708C), Icons.healing_rounded),
    'marketing': _CoverStyle(Color(0xFF4D3F6B), Color(0xFF7C6BA0), Icons.campaign_rounded),
    'default': _CoverStyle(Color(0xFF6B5E4C), Color(0xFF9A8A6E), Icons.work_outline_rounded),
  };
}

class _CoverStyle {
  const _CoverStyle(this.dark, this.light, this.icon);
  final Color dark;
  final Color light;
  final IconData icon;
}

class _CoverPainter extends CustomPainter {
  _CoverPainter(this.style);
  final _CoverStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [style.light, style.dark],
        ).createShader(Offset.zero & size),
    );

    // Amazigh lozenge lattice.
    final lattice = Paint()
      ..color = Colors.white.withValues(alpha: .07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    const cell = 26.0;
    for (var x = -h; x < w + h; x += cell) {
      canvas.drawLine(Offset(x, 0), Offset(x + h, h), lattice);
      canvas.drawLine(Offset(x + h, 0), Offset(x, h), lattice);
    }

    canvas.drawCircle(Offset(w * .82, h * .3), h * .5, Paint()..color = Colors.white.withValues(alpha: .08));

    final hill = Path()
      ..moveTo(0, h * .82)
      ..quadraticBezierTo(w * .35, h * .62, w * .7, h * .8)
      ..quadraticBezierTo(w * .85, h * .88, w, h * .76)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(hill, Paint()..color = Colors.black.withValues(alpha: .12));

    _icon(canvas, Offset(w * .5, h * .46), h * .42, Colors.white.withValues(alpha: .92));
    _icon(canvas, Offset(w * .14, h * .78), h * .9, Colors.white.withValues(alpha: .06));
  }

  void _icon(Canvas canvas, Offset center, double size, Color color) {
    final painter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(style.icon.codePoint),
        style: TextStyle(
          fontFamily: style.icon.fontFamily,
          package: style.icon.fontPackage,
          fontSize: size,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, center - Offset(painter.width / 2, painter.height / 2));
  }

  @override
  bool shouldRepaint(_CoverPainter old) => old.style != style;
}
