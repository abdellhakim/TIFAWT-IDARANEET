import 'localized_text.dart';
import 'profile_enums.dart';

enum OpportunityType with Labelled {
  formation('تكوين', 'Formation'),
  internship('تدريب', 'Stage'),
  job('خدمة', 'Emploi'),
  support('مواكبة', 'Accompagnement'),
  entrepreneurship('مقاولة', 'Entrepreneuriat'),
  workshop('ورشة', 'Atelier'),
  program('برنامج دعم', 'Dispositif');

  const OpportunityType(this.ar, this.fr);
  @override
  final String ar;
  @override
  final String fr;
}

/// A training, job, internship or institutional programme.
///
/// The catalog ships as `assets/data/opportunities.json` (the same file seeds
/// the backend) and is cached in Hive so it stays browsable offline.
class Opportunity {
  const Opportunity({
    required this.id,
    required this.type,
    required this.title,
    required this.summary,
    required this.description,
    required this.organization,
    required this.province,
    required this.commune,
    required this.place,
    required this.requiredLevel,
    required this.objectives,
    required this.skills,
    required this.interests,
    required this.mobilityRequired,
    required this.internetRequired,
    required this.modality,
    required this.durationWeeks,
    required this.ageMin,
    required this.ageMax,
    required this.isFree,
    required this.forWomen,
    required this.accessConditions,
    required this.program,
    this.deadline,
    this.externalUrl,
    this.contactPhone,
    this.imageKey = 'default',
  });

  final String id;
  final OpportunityType type;
  final LocalizedText title;
  final LocalizedText summary;
  final LocalizedText description;
  final String organization;

  /// Null for nationwide remote programmes.
  final Province? province;
  final String commune;
  final LocalizedText place;

  final EducationLevel requiredLevel;
  final List<Objective> objectives;
  final List<Skill> skills;
  final List<Interest> interests;
  final Mobility mobilityRequired;
  final InternetAccess internetRequired;
  final Modality modality;

  final int durationWeeks;
  final DateTime? deadline;
  final int ageMin;
  final int ageMax;
  final bool isFree;
  final bool forWomen;

  final LocalizedList accessConditions;
  final LocalizedList program;
  final String? externalUrl;
  final String? contactPhone;
  final String imageKey;

  bool get requiresDiploma => requiredLevel.index >= EducationLevel.bac.index;

  bool isOpenOn(DateTime day) => deadline == null || !day.isAfter(deadline!.add(const Duration(days: 1)));

  factory Opportunity.fromJson(Map<dynamic, dynamic> json) => Opportunity(
    id: json['id'] as String,
    type: enumByName(OpportunityType.values, json['type'], OpportunityType.formation),
    title: LocalizedText.fromJson(json['title']),
    summary: LocalizedText.fromJson(json['summary']),
    description: LocalizedText.fromJson(json['description']),
    organization: json['organization'] as String,
    province: json['province'] == null
        ? null
        : enumByName(Province.values, json['province'], Province.taroudant),
    commune: (json['commune'] as String?) ?? '',
    place: LocalizedText.fromJson(json['place']),
    requiredLevel: enumByName(EducationLevel.values, json['requiredLevel'], EducationLevel.none),
    objectives: enumListByName(Objective.values, json['objectives']),
    skills: enumListByName(Skill.values, json['skills']),
    interests: enumListByName(Interest.values, json['interests']),
    mobilityRequired: enumByName(Mobility.values, json['mobilityRequired'], Mobility.commune),
    internetRequired: enumByName(InternetAccess.values, json['internetRequired'], InternetAccess.none),
    modality: enumByName(Modality.values, json['modality'], Modality.onSite),
    durationWeeks: (json['durationWeeks'] as num?)?.toInt() ?? 0,
    deadline: DateTime.tryParse((json['deadline'] as String?) ?? ''),
    ageMin: (json['ageMin'] as num?)?.toInt() ?? 15,
    ageMax: (json['ageMax'] as num?)?.toInt() ?? 34,
    isFree: (json['isFree'] as bool?) ?? true,
    forWomen: (json['forWomen'] as bool?) ?? false,
    accessConditions: LocalizedList.fromJson(json['accessConditions']),
    program: LocalizedList.fromJson(json['program']),
    externalUrl: json['externalUrl'] as String?,
    contactPhone: json['contactPhone'] as String?,
    imageKey: (json['imageKey'] as String?) ?? 'default',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'title': title.toJson(),
    'summary': summary.toJson(),
    'description': description.toJson(),
    'organization': organization,
    'province': province?.name,
    'commune': commune,
    'place': place.toJson(),
    'requiredLevel': requiredLevel.name,
    'objectives': [for (final o in objectives) o.name],
    'skills': [for (final s in skills) s.name],
    'interests': [for (final i in interests) i.name],
    'mobilityRequired': mobilityRequired.name,
    'internetRequired': internetRequired.name,
    'modality': modality.name,
    'durationWeeks': durationWeeks,
    'deadline': deadline?.toIso8601String().substring(0, 10),
    'ageMin': ageMin,
    'ageMax': ageMax,
    'isFree': isFree,
    'forWomen': forWomen,
    'accessConditions': accessConditions.toJson(),
    'program': program.toJson(),
    'externalUrl': externalUrl,
    'contactPhone': contactPhone,
    'imageKey': imageKey,
  };
}
