import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../shared/components/brand.dart';
import '../../../shared/components/ui.dart';
import '../../../shared/constants/communes.dart';
import '../../../shared/models/support_center.dart';
import '../../assistant/domain/intent_parser.dart';
import '../application/centers_provider.dart';

class CentersScreen extends ConsumerStatefulWidget {
  const CentersScreen({super.key});

  @override
  ConsumerState<CentersScreen> createState() => _CentersScreenState();
}

class _CentersScreenState extends ConsumerState<CentersScreen> {
  bool _searching = false;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final all = ref.watch(centersProvider);
    final numbered = [
      for (final c in all)
        if (!c.isHome) c,
    ];
    final home = all.where((c) => c.isHome).firstOrNull;
    final q = IntentParser.normalize(_query);
    final listed = [?home, ...numbered]
        .where(
          (c) => q.isEmpty || IntentParser.normalize('${c.name.ar} ${c.name.fr} ${c.commune}').contains(q),
        )
        .toList();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            PageHeader(
              title: s.placesTitle,
              onBack: () => context.go(Routes.home),
              action: SquareIconButton(
                icon: _searching ? Icons.close_rounded : Icons.search_rounded,
                onTap: () => setState(() {
                  _searching = !_searching;
                  _query = '';
                }),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_searching) ...[
                    TextField(
                      autofocus: true,
                      onChanged: (v) => setState(() => _query = v),
                      decoration: InputDecoration(
                        hintText: s.searchHint,
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.terracotta),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  _CentersMap(home: home, numbered: numbered, onTap: (c) => _showCenter(context, c, s)),
                  const SizedBox(height: 10),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Tag(s.demoData, tone: TagTone.neutral, icon: Icons.info_outline_rounded),
                  ),
                  const SizedBox(height: 12),
                  for (final c in listed) ...[
                    _CenterCard(
                      center: c,
                      number: c.isHome ? null : numbered.indexOf(c) + 1,
                      s: s,
                      onTap: () => _showCenter(context, c, s),
                    ),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.cell_tower_rounded, size: 16, color: AppColors.textMuted),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(s.antennasNote, style: AppText.label(12, color: AppColors.textMuted)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _AskAssistant(s: s),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCenter(BuildContext context, SupportCenter c, AppStrings s) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _CenterSheet(center: c, s: s),
  );
}

class _CentersMap extends StatelessWidget {
  const _CentersMap({required this.home, required this.numbered, required this.onTap});
  final SupportCenter? home;
  final List<SupportCenter> numbered;
  final ValueChanged<SupportCenter> onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Container(
        height: 196,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE6D6B5)),
          borderRadius: BorderRadius.circular(26),
        ),
        child: LayoutBuilder(
          builder: (context, box) {
            final w = box.maxWidth;
            final h = box.maxHeight;
            return Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: _MapPainter())),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const CustomPaint(painter: _CompassPainter()),
                  ),
                ),
                for (final (i, c) in numbered.indexed)
                  Positioned(
                    left: c.pinX * w - 17,
                    top: c.pinY * h - 42,
                    child: GestureDetector(
                      onTap: () => onTap(c),
                      child: _Pin(label: '${i + 1}'),
                    ),
                  ),
                if (home != null)
                  Positioned(
                    left: home!.pinX * w - 22,
                    top: home!.pinY * h - 52,
                    child: GestureDetector(onTap: () => onTap(home!), child: const _Pin(home: true)),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Pin extends StatelessWidget {
  const _Pin({this.label, this.home = false});
  final String? label;
  final bool home;

  @override
  Widget build(BuildContext context) {
    final size = home ? 44.0 : 34.0;
    return SizedBox(
      width: size,
      height: size * 1.22,
      child: CustomPaint(
        painter: _PinPainter(home ? AppColors.olive : AppColors.terracotta),
        child: Align(
          alignment: const Alignment(0, -.38),
          child: home
              ? const Icon(Icons.star_rounded, color: Colors.white, size: 22)
              : Text(label ?? '', style: AppText.title(14, color: Colors.white).copyWith(height: 1)),
        ),
      ),
    );
  }
}

class _PinPainter extends CustomPainter {
  _PinPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final path = Path()
      ..moveTo(r, size.height)
      ..quadraticBezierTo(size.width * .18, size.height * .62, 0, r)
      ..arcToPoint(Offset(size.width, r), radius: Radius.circular(r))
      ..quadraticBezierTo(size.width * .82, size.height * .62, r, size.height)
      ..close();
    canvas.drawShadow(path, Colors.black, 3, false);
    canvas.drawPath(path, Paint()..color = Colors.white);
    canvas.save();
    canvas.translate(size.width * .09, size.width * .09);
    canvas.scale(.82);
    canvas.drawPath(path, Paint()..color = color);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PinPainter old) => old.color != color;
}

class _CompassPainter extends CustomPainter {
  const _CompassPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final north = Path()
      ..moveTo(c.dx, c.dy - 11)
      ..lineTo(c.dx + 4, c.dy)
      ..lineTo(c.dx - 4, c.dy)
      ..close();
    final south = Path()
      ..moveTo(c.dx, c.dy + 11)
      ..lineTo(c.dx + 4, c.dy)
      ..lineTo(c.dx - 4, c.dy)
      ..close();
    canvas.drawPath(north, Paint()..color = AppColors.danger);
    canvas.drawPath(south, Paint()..color = AppColors.textMuted);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Hand-drawn map of the area — no tiles, works offline.
class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFEFE2C6));

    final grid = Paint()
      ..color = Colors.white.withValues(alpha: .45)
      ..strokeWidth = 1;
    for (var x = 0.0; x < w; x += 14) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), grid);
    }
    for (var y = 0.0; y < h; y += 14) {
      canvas.drawLine(Offset(0, y), Offset(w, y), grid);
    }

    canvas.drawCircle(
      Offset(w * .28, h * .3),
      h * .32,
      Paint()..color = const Color(0xFFDCD7AE).withValues(alpha: .8),
    );
    canvas.drawCircle(
      Offset(w * .62, h * .78),
      h * .3,
      Paint()..color = const Color(0xFFF3CF9B).withValues(alpha: .75),
    );

    void road(Path p, Color c, double width) => canvas.drawPath(
      p,
      Paint()
        ..color = c
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round,
    );

    road(
      Path()
        ..moveTo(0, h * .48)
        ..cubicTo(w * .3, h * .3, w * .55, h * .62, w, h * .36),
      const Color(0xFFE29A80),
      3.2,
    );
    road(
      Path()
        ..moveTo(w * .2, 0)
        ..cubicTo(w * .34, h * .4, w * .24, h * .72, w * .42, h),
      const Color(0xFFE3A68E).withValues(alpha: .8),
      2.4,
    );
    road(
      Path()
        ..moveTo(w * .55, 0)
        ..cubicTo(w * .6, h * .3, w * .78, h * .55, w * .74, h),
      const Color(0xFFB9C08A),
      2.4,
    );
    road(
      Path()
        ..moveTo(0, h * .86)
        ..cubicTo(w * .4, h * .7, w * .7, h * .92, w, h * .74),
      const Color(0xFFCDB98F),
      2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CenterCard extends StatelessWidget {
  const _CenterCard({required this.center, required this.number, required this.s, required this.onTap});
  final SupportCenter center;
  final int? number;
  final AppStrings s;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final open = center.isOpenAt(DateTime.now());
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: center.isHome ? AppColors.olive : AppColors.terracotta,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              center.isHome ? Icons.star_rounded : Icons.apartment_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (center.isHome)
                  Text(
                    s.yourCenter,
                    style: AppText.label(11, color: AppColors.olive, weight: FontWeight.w800),
                  ),
                Text('${number == null ? '' : '$number. '}${s.l(center.name)}', style: AppText.heading(14.5)),
                const SizedBox(height: 2),
                Text(
                  '${s.km(center.distanceKm)}     ${s.hours(center.opensAt, center.closesAt)}',
                  style: AppText.label(12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Tag(open ? s.openNow : s.closedNow, tone: open ? TagTone.olive : TagTone.rose, icon: Icons.circle),
        ],
      ),
    );
  }
}

class _AskAssistant extends StatelessWidget {
  const _AskAssistant({required this.s});
  final AppStrings s;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.olive,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => context.push(Routes.assistantFrom(Routes.places)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(color: AppColors.oliveDark, borderRadius: BorderRadius.circular(12)),
              alignment: Alignment.center,
              child: const BotAvatar(size: 36, filled: false),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(s.askAssistantCta, style: AppText.heading(15, color: Colors.white)),
            ),
          ],
        ),
      ),
    ),
  );
}

class _CenterSheet extends StatelessWidget {
  const _CenterSheet({required this.center, required this.s});
  final SupportCenter center;
  final AppStrings s;

  Future<void> _open(Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication).catchError((_) => false);
    if (!ok) scaffoldMessengerKey.currentState?.showSnackBar(SnackBar(content: Text(s.cannotOpenLink)));
  }

  @override
  Widget build(BuildContext context) {
    final open = center.isOpenAt(DateTime.now());
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Tag(center.kind.label(s.isAr), tone: TagTone.sand),
                const SizedBox(width: 6),
                Tag(open ? s.openNow : s.closedNow, tone: open ? TagTone.olive : TagTone.rose),
                const Spacer(),
                Tag(s.demoData, tone: TagTone.neutral),
              ],
            ),
            const SizedBox(height: 10),
            Text(s.l(center.name), style: AppText.heading(20)),
            const SizedBox(height: 6),
            _Row(
              icon: Icons.place_rounded,
              text:
                  '${s.l(center.address)} · ${communeLabel(center.commune, s.isAr)} · ${s.km(center.distanceKm)}',
            ),
            _Row(icon: Icons.schedule_rounded, text: s.hours(center.opensAt, center.closesAt)),
            _Row(icon: Icons.call_rounded, text: center.phone, ltr: true),
            const SizedBox(height: 12),
            Text(s.services, style: AppText.title(15)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [for (final service in center.services.of(s.isAr)) Tag(service, tone: TagTone.olive)],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _open(Uri(scheme: 'tel', path: center.phone)),
                    icon: const Icon(Icons.call_rounded, size: 19),
                    label: Text(s.call),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _open(
                      Uri.parse(
                        'https://www.google.com/maps/search/?api=1&query=${center.lat},${center.lng}',
                      ),
                    ),
                    icon: const Icon(Icons.directions_rounded, size: 19),
                    label: Text(s.itinerary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.text, this.ltr = false});
  final IconData icon;
  final String text;
  final bool ltr;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Icon(icon, size: 17, color: AppColors.terracotta),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            textDirection: ltr ? TextDirection.ltr : null,
            textAlign: TextAlign.start,
            style: AppText.label(13.5, color: AppColors.textDark),
          ),
        ),
      ],
    ),
  );
}
