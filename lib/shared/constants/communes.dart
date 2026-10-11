import '../models/localized_text.dart';
import '../models/profile_enums.dart';

/// Main communes per province, used by the questionnaire.
const communesByProvince = <Province, List<LocalizedText>>{
  Province.taroudant: [
    LocalizedText('تارودانت', 'Taroudant'),
    LocalizedText('أولاد تايمة', 'Ouled Teima'),
    LocalizedText('آيت إيعزة', 'Aït Iaaza'),
    LocalizedText('أولاد برحيل', 'Oulad Berhil'),
    LocalizedText('تالوين', 'Taliouine'),
    LocalizedText('تفنكولت', 'Tafingoult'),
    LocalizedText('إغرم', 'Igherm'),
  ],
  Province.agadir: [
    LocalizedText('أكادير', 'Agadir'),
    LocalizedText('الدراركة', 'Drarga'),
    LocalizedText('أورير', 'Aourir'),
    LocalizedText('تامري', 'Tamri'),
    LocalizedText('إموزار إداوتنان', 'Imouzzer Ida Outanane'),
  ],
  Province.tata: [
    LocalizedText('طاطا', 'Tata'),
    LocalizedText('أقا', 'Akka'),
    LocalizedText('فم زكيد', 'Foum Zguid'),
    LocalizedText('فم الحصن', 'Fam El Hisn'),
    LocalizedText('تيسينت', 'Tissint'),
  ],
};

/// Communes are stored by their French name; this returns the label in the
/// interface language.
String communeLabel(String commune, bool isAr) {
  for (final list in communesByProvince.values) {
    for (final c in list) {
      if (c.fr == commune) return c.of(isAr);
    }
  }
  return commune;
}
