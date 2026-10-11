import 'profile_enums.dart';

/// The youth questionnaire — the base of all personalisation.
class UserProfile {
  const UserProfile({
    required this.userId,
    required this.age,
    required this.sex,
    required this.province,
    required this.commune,
    required this.situation,
    required this.education,
    required this.lastDiploma,
    required this.vocationalTraining,
    required this.objective,
    required this.interests,
    required this.skills,
    required this.mobility,
    required this.internetAccess,
    required this.connectionType,
    required this.availability,
    required this.modality,
    this.completed = false,
    this.updatedAt,
  });

  final String userId;

  // General information
  final int age;
  final Sex sex;
  final Province province;
  final String commune;
  final CurrentSituation situation;

  // Education
  final EducationLevel education;
  final Diploma lastDiploma;
  final String vocationalTraining;

  final Objective objective;
  final List<Interest> interests;
  final List<Skill> skills;

  // Constraints
  final Mobility mobility;
  final InternetAccess internetAccess;
  final ConnectionType connectionType;
  final Availability availability;
  final ModalityPreference modality;

  /// False while the questionnaire is only a draft.
  final bool completed;
  final DateTime? updatedAt;

  bool get isFemale => sex == Sex.female;

  factory UserProfile.empty(String userId) => UserProfile(
    userId: userId,
    age: 20,
    sex: Sex.female,
    province: Province.taroudant,
    commune: '',
    situation: CurrentSituation.trainingSeeking,
    education: EducationLevel.middle,
    lastDiploma: Diploma.none,
    vocationalTraining: '',
    objective: Objective.training,
    interests: const [],
    skills: const [],
    mobility: Mobility.province,
    internetAccess: InternetAccess.occasional,
    connectionType: ConnectionType.mobile3g,
    availability: Availability.fullTime,
    modality: ModalityPreference.any,
  );

  UserProfile copyWith({
    int? age,
    Sex? sex,
    Province? province,
    String? commune,
    CurrentSituation? situation,
    EducationLevel? education,
    Diploma? lastDiploma,
    String? vocationalTraining,
    Objective? objective,
    List<Interest>? interests,
    List<Skill>? skills,
    Mobility? mobility,
    InternetAccess? internetAccess,
    ConnectionType? connectionType,
    Availability? availability,
    ModalityPreference? modality,
    bool? completed,
    DateTime? updatedAt,
  }) => UserProfile(
    userId: userId,
    age: age ?? this.age,
    sex: sex ?? this.sex,
    province: province ?? this.province,
    commune: commune ?? this.commune,
    situation: situation ?? this.situation,
    education: education ?? this.education,
    lastDiploma: lastDiploma ?? this.lastDiploma,
    vocationalTraining: vocationalTraining ?? this.vocationalTraining,
    objective: objective ?? this.objective,
    interests: interests ?? this.interests,
    skills: skills ?? this.skills,
    mobility: mobility ?? this.mobility,
    internetAccess: internetAccess ?? this.internetAccess,
    connectionType: connectionType ?? this.connectionType,
    availability: availability ?? this.availability,
    modality: modality ?? this.modality,
    completed: completed ?? this.completed,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'age': age,
    'sex': sex.name,
    'province': province.name,
    'commune': commune,
    'situation': situation.name,
    'education': education.name,
    'lastDiploma': lastDiploma.name,
    'vocationalTraining': vocationalTraining,
    'objective': objective.name,
    'interests': [for (final i in interests) i.name],
    'skills': [for (final s in skills) s.name],
    'mobility': mobility.name,
    'internetAccess': internetAccess.name,
    'connectionType': connectionType.name,
    'availability': availability.name,
    'modality': modality.name,
    'completed': completed,
    'updatedAt': updatedAt?.toIso8601String(),
  };

  factory UserProfile.fromJson(Map<dynamic, dynamic> json) => UserProfile(
    userId: json['userId'] as String,
    age: (json['age'] as num?)?.toInt() ?? 20,
    sex: enumByName(Sex.values, json['sex'], Sex.female),
    province: enumByName(Province.values, json['province'], Province.taroudant),
    commune: (json['commune'] as String?) ?? '',
    situation: enumByName(CurrentSituation.values, json['situation'], CurrentSituation.trainingSeeking),
    education: enumByName(EducationLevel.values, json['education'], EducationLevel.middle),
    lastDiploma: enumByName(Diploma.values, json['lastDiploma'], Diploma.none),
    vocationalTraining: (json['vocationalTraining'] as String?) ?? '',
    objective: enumByName(Objective.values, json['objective'], Objective.training),
    interests: enumListByName(Interest.values, json['interests']),
    skills: enumListByName(Skill.values, json['skills']),
    mobility: enumByName(Mobility.values, json['mobility'], Mobility.province),
    internetAccess: enumByName(InternetAccess.values, json['internetAccess'], InternetAccess.occasional),
    connectionType: enumByName(ConnectionType.values, json['connectionType'], ConnectionType.mobile3g),
    availability: enumByName(Availability.values, json['availability'], Availability.fullTime),
    modality: enumByName(ModalityPreference.values, json['modality'], ModalityPreference.any),
    completed: (json['completed'] as bool?) ?? false,
    updatedAt: DateTime.tryParse((json['updatedAt'] as String?) ?? ''),
  );
}
