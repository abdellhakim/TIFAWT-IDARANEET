// Builds every launcher icon, the Android launch logo and the Windows .ico
// from the official logo masks (see tool/extract_logo_test.dart).
// Run with: flutter test tool/generate_icons_test.dart
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

const terracotta = ui.Color(0xFFB5452C);

Future<ui.Image> _load(String path) async {
  final codec = await ui.instantiateImageCodec(File(path).readAsBytesSync());
  return (await codec.getNextFrame()).image;
}

Future<Uint8List> _png(ui.Picture picture, int w, int h) async {
  final image = await picture.toImage(w, h);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return bytes!.buffer.asUint8List();
}

/// [bold] (in pixels) thickens the strokes by stamping the art around a
/// small circle, so the line art survives being shrunk to launcher sizes.
void _drawCentered(
  ui.Canvas canvas,
  ui.Image art,
  double boxW,
  double boxH,
  double width, {
  double bold = 0,
}) {
  final height = width * art.height / art.width;
  final dst = ui.Rect.fromLTWH((boxW - width) / 2, (boxH - height) / 2, width, height);
  final src = ui.Rect.fromLTWH(0, 0, art.width.toDouble(), art.height.toDouble());
  final paint = ui.Paint()..filterQuality = ui.FilterQuality.high;
  final offsets = bold == 0
      ? const [ui.Offset.zero]
      : [for (var i = 0; i < 8; i++) ui.Offset.fromDirection(i * math.pi / 4, bold)];
  for (final o in offsets) {
    canvas.drawImageRect(art, src, dst.shift(o), paint);
  }
}

/// Terracotta tile with the white mountains, as on the printed logo.
Future<Uint8List> _icon(ui.Image mountains, int size, {double cornerFactor = .22}) {
  final s = size.toDouble();
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  final tile = ui.Paint()..color = terracotta;
  if (cornerFactor == 0) {
    canvas.drawRect(ui.Rect.fromLTWH(0, 0, s, s), tile);
  } else {
    canvas.drawRRect(ui.RRect.fromLTRBR(0, 0, s, s, ui.Radius.circular(s * cornerFactor)), tile);
  }
  // Thin line art disappears at favicon sizes: give it more room there.
  final bold = size <= 48 ? .45 : (size <= 192 ? .6 : (size <= 512 ? 1.0 : 1.6));
  _drawCentered(canvas, mountains, s, s, s * (size <= 48 ? .78 : .64), bold: bold);
  return _png(recorder.endRecording(), size, size);
}

Future<void> _write(String path, Future<Uint8List> bytes) async {
  final file = File(path);
  if (!file.parent.existsSync()) return; // platform folder not present
  file.writeAsBytesSync(await bytes);
}

/// ICO container holding PNG frames (supported since Windows Vista).
Uint8List _ico(List<(int, Uint8List)> frames) {
  final header = BytesBuilder()..add([0, 0, 1, 0, frames.length & 0xff, frames.length >> 8]);
  final body = BytesBuilder();
  var offset = 6 + 16 * frames.length;
  for (final (size, png) in frames) {
    final entry = ByteData(16)
      ..setUint8(0, size >= 256 ? 0 : size)
      ..setUint8(1, size >= 256 ? 0 : size)
      ..setUint16(4, 1, Endian.little)
      ..setUint16(6, 32, Endian.little)
      ..setUint32(8, png.length, Endian.little)
      ..setUint32(12, offset, Endian.little);
    header.add(entry.buffer.asUint8List());
    body.add(png);
    offset += png.length;
  }
  return (header..add(body.takeBytes())).takeBytes();
}

void main() {
  test('generate launcher icons', () async {
    final mountains = await _load('assets/images/brand/mountains_mask.png');
    final logo = await _load('assets/images/brand/logo_mask.png');

    const android = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192};
    for (final MapEntry(:key, :value) in android.entries) {
      await _write('android/app/src/main/res/mipmap-$key/ic_launcher.png', _icon(mountains, value));
    }

    // Android launch screen: the white logo, 150 dp wide, on the terracotta
    // window background (drawable/launch_background.xml).
    const launchScale = {'mdpi': 1.0, 'hdpi': 1.5, 'xhdpi': 2.0, 'xxhdpi': 3.0, 'xxxhdpi': 4.0};
    if (Directory('android/app/src/main/res').existsSync()) {
      for (final MapEntry(:key, :value) in launchScale.entries) {
        final w = (150 * value).round();
        final h = (w * logo.height / logo.width).round();
        final recorder = ui.PictureRecorder();
        _drawCentered(ui.Canvas(recorder), logo, w.toDouble(), h.toDouble(), w.toDouble());
        final dir = Directory('android/app/src/main/res/drawable-$key')..createSync();
        File('${dir.path}/launch_logo.png').writeAsBytesSync(await _png(recorder.endRecording(), w, h));
      }
    }

    // iOS rejects transparency: full-bleed square, the system rounds it.
    const ios = {
      '20x20@1x': 20,
      '20x20@2x': 40,
      '20x20@3x': 60,
      '29x29@1x': 29,
      '29x29@2x': 58,
      '29x29@3x': 87,
      '40x40@1x': 40,
      '40x40@2x': 80,
      '40x40@3x': 120,
      '60x60@2x': 120,
      '60x60@3x': 180,
      '76x76@1x': 76,
      '76x76@2x': 152,
      '83.5x83.5@2x': 167,
      '1024x1024@1x': 1024,
    };
    for (final MapEntry(:key, :value) in ios.entries) {
      await _write(
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-$key.png',
        _icon(mountains, value, cornerFactor: 0),
      );
    }

    for (final size in [16, 32, 64, 128, 256, 512, 1024]) {
      await _write(
        'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_$size.png',
        _icon(mountains, size),
      );
    }

    await _write('web/favicon.png', _icon(mountains, 32));
    await _write('web/icons/Icon-192.png', _icon(mountains, 192));
    await _write('web/icons/Icon-512.png', _icon(mountains, 512));
    await _write('web/icons/Icon-maskable-192.png', _icon(mountains, 192, cornerFactor: 0));
    await _write('web/icons/Icon-maskable-512.png', _icon(mountains, 512, cornerFactor: 0));

    if (File('windows/runner/resources/app_icon.ico').existsSync()) {
      final frames = [
        for (final size in [16, 24, 32, 48, 64, 256]) (size, await _icon(mountains, size)),
      ];
      File('windows/runner/resources/app_icon.ico').writeAsBytesSync(_ico(frames));
    }

    Directory('build').createSync(recursive: true);
    File('build/icon_preview_512.png').writeAsBytesSync(await _icon(mountains, 512));
  });
}
