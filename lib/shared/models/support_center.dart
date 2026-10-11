import 'localized_text.dart';
import 'profile_enums.dart';

enum CenterKind with Labelled {
  youthCenter('دار الشباب', 'Maison de jeunes'),
  association('جمعية', 'Association'),
  agency('وكالة', 'Agence'),
  trainingCenter('مركز التكوين', 'Centre de formation');

  const CenterKind(this.ar, this.fr);
  @override
  final String ar;
  @override
  final String fr;
}

/// A local support structure. Demo data is fictional and flagged as such
/// in the interface.
class SupportCenter {
  const SupportCenter({
    required this.id,
    required this.kind,
    required this.name,
    required this.province,
    required this.commune,
    required this.address,
    required this.distanceKm,
    required this.opensAt,
    required this.closesAt,
    required this.openDays,
    required this.services,
    required this.phone,
    required this.lat,
    required this.lng,
    required this.pinX,
    required this.pinY,
    this.isHome = false,
  });

  final String id;
  final CenterKind kind;
  final LocalizedText name;
  final Province province;
  final String commune;
  final LocalizedText address;
  final double distanceKm;

  /// 24h "HH:mm".
  final String opensAt;
  final String closesAt;

  /// ISO weekdays (1 = Monday).
  final List<int> openDays;
  final LocalizedList services;
  final String phone;
  final double lat;
  final double lng;

  /// Position on the stylised map, 0..1.
  final double pinX;
  final double pinY;

  /// The youth's reference structure (green pin).
  final bool isHome;

  bool isOpenAt(DateTime now) {
    if (!openDays.contains(now.weekday)) return false;
    final minutes = now.hour * 60 + now.minute;
    return minutes >= _toMinutes(opensAt) && minutes < _toMinutes(closesAt);
  }

  static int _toMinutes(String hhmm) {
    final parts = hhmm.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  factory SupportCenter.fromJson(Map<dynamic, dynamic> json) => SupportCenter(
    id: json['id'] as String,
    kind: enumByName(CenterKind.values, json['kind'], CenterKind.youthCenter),
    name: LocalizedText.fromJson(json['name']),
    province: enumByName(Province.values, json['province'], Province.taroudant),
    commune: (json['commune'] as String?) ?? '',
    address: LocalizedText.fromJson(json['address']),
    distanceKm: (json['distanceKm'] as num).toDouble(),
    opensAt: json['opensAt'] as String,
    closesAt: json['closesAt'] as String,
    openDays: ((json['openDays'] as List?) ?? const [1, 2, 3, 4, 5, 6]).cast<int>(),
    services: LocalizedList.fromJson(json['services']),
    phone: json['phone'] as String,
    lat: (json['lat'] as num).toDouble(),
    lng: (json['lng'] as num).toDouble(),
    pinX: (json['pinX'] as num).toDouble(),
    pinY: (json['pinY'] as num).toDouble(),
    isHome: (json['isHome'] as bool?) ?? false,
  );
}
