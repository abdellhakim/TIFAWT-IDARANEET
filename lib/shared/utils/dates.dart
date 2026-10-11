/// Date formatting with Moroccan month names (ماي، يوليوز، غشت...),
/// independent of the platform locale data.
abstract final class Dates {
  static const _monthsAr = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'ماي',
    'يونيو',
    'يوليوز',
    'غشت',
    'شتنبر',
    'أكتوبر',
    'نونبر',
    'دجنبر',
  ];
  static const _monthsFr = [
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre',
  ];
  static const _daysAr = ['الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
  static const _daysFr = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'];

  /// "الجمعة 22 ماي 2026" / "vendredi 22 mai 2026"
  static String long(DateTime d, bool isAr) {
    final day = (isAr ? _daysAr : _daysFr)[d.weekday - 1];
    final month = (isAr ? _monthsAr : _monthsFr)[d.month - 1];
    return '$day ${d.day} $month ${d.year}';
  }

  /// "22 ماي" / "22 mai"
  static String dayMonth(DateTime d, bool isAr) => '${d.day} ${(isAr ? _monthsAr : _monthsFr)[d.month - 1]}';

  /// "22 ماي 2026"
  static String dayMonthYear(DateTime d, bool isAr) => '${dayMonth(d, isAr)} ${d.year}';

  static String time(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  /// Short relative stamp for histories: today → time, otherwise date.
  static String stamp(DateTime d, bool isAr, {DateTime? now}) {
    final ref = now ?? DateTime.now();
    final sameDay = d.year == ref.year && d.month == ref.month && d.day == ref.day;
    return sameDay ? time(d) : '${dayMonth(d, isAr)} · ${time(d)}';
  }
}
