import 'package:flutter/material.dart';

import 'app_colors.dart';

/// One family for both scripts: IBM Plex Sans Arabic ships matching Arabic
/// and Latin glyphs, designed for interfaces and legible at small sizes.
abstract final class AppText {
  static const family = 'IBMPlexSansArabic';
  static const body = family;
  static const display = family;

  static TextStyle heading(double size, {Color color = AppColors.textDark}) =>
      TextStyle(fontFamily: display, fontSize: size, fontWeight: FontWeight.w700, color: color, height: 1.4);

  static TextStyle title(double size, {Color color = AppColors.textDark}) =>
      TextStyle(fontFamily: body, fontSize: size, fontWeight: FontWeight.w600, color: color, height: 1.4);

  static TextStyle label(
    double size, {
    Color color = AppColors.textMedium,
    FontWeight weight = FontWeight.w500,
  }) => TextStyle(fontFamily: body, fontSize: size, fontWeight: weight, color: color, height: 1.45);

  static TextStyle paragraph({Color color = AppColors.textMedium}) =>
      TextStyle(fontFamily: body, fontSize: 14.5, fontWeight: FontWeight.w400, color: color, height: 1.7);
}
