import 'dart:ui';

enum AppLanguage {
  arabic('ar', 'العربية'),
  french('fr', 'Français');

  const AppLanguage(this.code, this.label);
  final String code;
  final String label;

  Locale get locale => Locale(code);
  bool get isArabic => this == AppLanguage.arabic;

  static AppLanguage fromCode(String? code) => code == 'fr' ? AppLanguage.french : AppLanguage.arabic;
}
