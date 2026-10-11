// Turns the official logo (white artwork on terracotta) into transparent
// white masks the app can tint: the full logo and the mountains alone.
// Run with: flutter test tool/extract_logo_test.dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

const source = 'design/brand/tifawt_logo_864.webp';

Future<(Uint8List, int, int)> _decode(String path) async {
  final codec = await ui.instantiateImageCodec(File(path).readAsBytesSync());
  final image = (await codec.getNextFrame()).image;
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  return (data!.buffer.asUint8List(), image.width, image.height);
}

Future<void> _writePng(String path, Uint8List rgba, int w, int h) async {
  final buffer = await ui.ImmutableBuffer.fromUint8List(rgba);
  final descriptor = ui.ImageDescriptor.raw(
    buffer,
    width: w,
    height: h,
    pixelFormat: ui.PixelFormat.rgba8888,
  );
  final image = (await (await descriptor.instantiateCodec()).getNextFrame()).image;
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path).writeAsBytesSync(png!.buffer.asUint8List());
}

void main() {
  test('extract logo masks', () async {
    final (px, w, h) = await _decode(source);

    // Background colour: average of the four corners.
    var r = 0.0, g = 0.0, b = 0.0;
    for (final (x, y) in [(4, 4), (w - 5, 4), (4, h - 5), (w - 5, h - 5)]) {
      final i = (y * w + x) * 4;
      r += px[i];
      g += px[i + 1];
      b += px[i + 2];
    }
    r /= 4;
    g /= 4;
    b /= 4;
    // ignore: avoid_print
    print('background ≈ #${[r, g, b].map((c) => c.round().toRadixString(16).padLeft(2, '0')).join()}');

    // Alpha = how far each pixel moved from the background towards white.
    // The soft glow behind the artwork stays below the cut-off.
    final (dr, dg, db) = (255 - r, 255 - g, 255 - b);
    final norm = dr * dr + dg * dg + db * db;
    const low = .28, high = .82;
    final alpha = Uint8List(w * h);
    for (var p = 0; p < w * h; p++) {
      final i = p * 4;
      final t = ((px[i] - r) * dr + (px[i + 1] - g) * dg + (px[i + 2] - b) * db) / norm;
      final a = ((t - low) / (high - low)).clamp(0.0, 1.0);
      alpha[p] = (a * 255).round();
    }

    // Bounding box of the artwork and the empty band between mountains and text.
    bool rowHasInk(int y) {
      for (var x = 0; x < w; x++) {
        if (alpha[y * w + x] > 128) return true;
      }
      return false;
    }

    final inkRows = [for (var y = 0; y < h; y++) rowHasInk(y)];
    final top = inkRows.indexOf(true);
    final bottom = inkRows.lastIndexOf(true);
    var gapStart = top;
    while (inkRows[gapStart]) {
      gapStart++;
    }
    var left = w, right = 0;
    for (var y = top; y <= bottom; y++) {
      for (var x = 0; x < w; x++) {
        if (alpha[y * w + x] > 128) {
          if (x < left) left = x;
          if (x > right) right = x;
        }
      }
    }

    Future<void> export(String path, int x0, int y0, int x1, int y1) async {
      const pad = 6;
      x0 = (x0 - pad).clamp(0, w - 1);
      y0 = (y0 - pad).clamp(0, h - 1);
      x1 = (x1 + pad).clamp(0, w - 1);
      y1 = (y1 + pad).clamp(0, h - 1);
      final cw = x1 - x0 + 1, ch = y1 - y0 + 1;
      final out = Uint8List(cw * ch * 4);
      for (var y = 0; y < ch; y++) {
        for (var x = 0; x < cw; x++) {
          final o = (y * cw + x) * 4;
          out[o] = out[o + 1] = out[o + 2] = 255;
          out[o + 3] = alpha[(y + y0) * w + (x + x0)];
        }
      }
      await _writePng(path, out, cw, ch);
      // ignore: avoid_print
      print('$path  ${cw}x$ch');
    }

    await export('assets/images/brand/logo_mask.png', left, top, right, bottom);

    // Mountains only: rows above the first gap, with their own horizontal extent.
    var mLeft = w, mRight = 0;
    for (var y = top; y < gapStart; y++) {
      for (var x = 0; x < w; x++) {
        if (alpha[y * w + x] > 128) {
          if (x < mLeft) mLeft = x;
          if (x > mRight) mRight = x;
        }
      }
    }
    await export('assets/images/brand/mountains_mask.png', mLeft, top, mRight, gapStart - 1);

    // Visual check: the mask tinted on both brand backgrounds.
    for (final (name, bg, ink) in const [
      ('on_terracotta', ui.Color(0xFFB5452C), ui.Color(0xFFFFFFFF)),
      ('on_cream', ui.Color(0xFFFCF8F0), ui.Color(0xFFB5452C)),
    ]) {
      final (mask, mw, mh) = await _decode('assets/images/brand/logo_mask.png');
      final buffer = await ui.ImmutableBuffer.fromUint8List(mask);
      final descriptor = ui.ImageDescriptor.raw(
        buffer,
        width: mw,
        height: mh,
        pixelFormat: ui.PixelFormat.rgba8888,
      );
      final maskImage = (await (await descriptor.instantiateCodec()).getNextFrame()).image;
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawRect(ui.Rect.fromLTWH(0, 0, mw + 80.0, mh + 80.0), ui.Paint()..color = bg);
      canvas.drawImage(
        maskImage,
        const ui.Offset(40, 40),
        ui.Paint()..colorFilter = ui.ColorFilter.mode(ink, ui.BlendMode.srcIn),
      );
      final preview = await recorder.endRecording().toImage(mw + 80, mh + 80);
      final png = await preview.toByteData(format: ui.ImageByteFormat.png);
      Directory('build').createSync(recursive: true);
      File('build/logo_preview_$name.png').writeAsBytesSync(png!.buffer.asUint8List());
    }
  });
}
