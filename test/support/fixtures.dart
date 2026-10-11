import 'dart:convert';
import 'dart:io';

import 'package:tifawt/features/assistant/domain/assistant_provider.dart';
import 'package:tifawt/shared/models/opportunity.dart';
import 'package:tifawt/shared/models/profile_enums.dart';
import 'package:tifawt/shared/models/support_center.dart';
import 'package:tifawt/shared/models/user_profile.dart';

/// The jury persona from the "parcours nominal".
const chahd = UserProfile(
  userId: 'demo-chahd',
  age: 21,
  sex: Sex.female,
  province: Province.taroudant,
  commune: 'Taroudant',
  situation: CurrentSituation.trainingSeeking,
  education: EducationLevel.bac,
  lastDiploma: Diploma.bac,
  vocationalTraining: '',
  objective: Objective.training,
  interests: [Interest.digital, Interest.commerce],
  skills: [Skill.communication, Skill.languages],
  mobility: Mobility.commune,
  internetAccess: InternetAccess.occasional,
  connectionType: ConnectionType.mobile3g,
  availability: Availability.fullTime,
  modality: ModalityPreference.any,
  completed: true,
);

/// Reference date for deterministic deadline checks.
final today = DateTime(2026, 10, 10);

Map<String, dynamic> _json(String path) => jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

List<Opportunity> loadCatalog() => [
  for (final item in (_json('assets/data/opportunities.json')['items'] as List))
    Opportunity.fromJson(item as Map),
];

List<SupportCenter> loadCenters() => [
  for (final item in (_json('assets/data/centers.json')['items'] as List))
    SupportCenter.fromJson(item as Map),
];

List<FaqEntry> loadFaq() => [
  for (final item in (_json('assets/data/assistant_knowledge.json')['faq'] as List))
    FaqEntry.fromJson(item as Map),
];
