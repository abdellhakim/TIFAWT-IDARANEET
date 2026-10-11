/// Shared vocabulary between the youth profile and the opportunity catalog.
///
/// The `name` of each value is the wire format used in Hive, in the JSON
/// catalog and by the REST API, so values must never be renamed.
library;

mixin Labelled {
  String get ar;
  String get fr;
  String label(bool isAr) => isAr ? ar : fr;
}

T enumByName<T extends Enum>(List<T> values, Object? name, T fallback) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}

List<T> enumListByName<T extends Enum>(List<T> values, Object? names) {
  if (names is! List) return [];
  return [
    for (final n in names)
      for (final v in values)
        if (v.name == n) v,
  ];
}

enum Sex with Labelled {
  female('أنثى', 'Femme'),
  male('ذكر', 'Homme');

  const Sex(this.ar, this.fr);
  @override
  final String ar;
  @override
  final String fr;
}

enum Province with Labelled {
  taroudant('تارودانت', 'Taroudant'),
  agadir('أكادير', 'Agadir'),
  tata('طاطا', 'Tata');

  const Province(this.ar, this.fr);
  @override
  final String ar;
  @override
  final String fr;
}

enum CurrentSituation with Labelled {
  jobSeeking('كنقلب على خدمة', "En recherche d'emploi"),
  trainingSeeking('كنقلب على تكوين', 'En recherche de formation'),
  schoolDropout('حبست القراية', 'Décrochage scolaire'),
  inactive('بلا نشاط دابا', 'Sans activité');

  const CurrentSituation(this.ar, this.fr);
  @override
  final String ar;
  @override
  final String fr;
}

/// Ordered from lowest to highest: the engine compares indexes.
enum EducationLevel with Labelled {
  none('ما قريتش', 'Non scolarisé'),
  primary('الابتدائي', 'Primaire'),
  middle('الإعدادي', 'Collège'),
  bac('الباكالوريا', 'Bac'),
  higher('بعد الباك', 'Bac+');

  const EducationLevel(this.ar, this.fr);
  @override
  final String ar;
  @override
  final String fr;
}

enum Diploma with Labelled {
  none('بلا شهادة', 'Aucun'),
  primaryCertificate('شهادة الدروس الابتدائية', "Certificat d'études primaires"),
  brevet('شهادة الإعدادي', 'Brevet'),
  bac('الباكالوريا', 'Baccalauréat'),
  qualification('دبلوم التأهيل المهني', 'Diplôme de qualification'),
  technician('دبلوم تقني', 'Diplôme de technicien'),
  licence('الإجازة', 'Licence');

  const Diploma(this.ar, this.fr);
  @override
  final String ar;
  @override
  final String fr;
}

enum Objective with Labelled {
  employment('نلقى خدمة', 'Trouver un emploi'),
  training('نتكون', 'Me former'),
  studies('نكمل القراية', 'Reprendre les études'),
  entrepreneurship('نبدا مشروع', 'Créer mon activité'),
  skills('نطور المهارات', 'Développer mes compétences');

  const Objective(this.ar, this.fr);
  @override
  final String ar;
  @override
  final String fr;
}

enum Interest with Labelled {
  digital('الرقميات', 'Numérique'),
  agriculture('الفلاحة', 'Agriculture'),
  tourism('السياحة', 'Tourisme'),
  commerce('التجارة', 'Commerce'),
  marketing('التسويق', 'Marketing'),
  crafts('الصناعة التقليدية', 'Artisanat'),
  renewableEnergy('الطاقات المتجددة', 'Énergie renouvelable'),
  logistics('اللوجستيك', 'Logistique'),
  foodProcessing('الصناعة الغذائية', 'Agroalimentaire'),
  care('المساعدة و الرعاية', 'Aide à la personne');

  const Interest(this.ar, this.fr);
  @override
  final String ar;
  @override
  final String fr;
}

enum Skill with Labelled {
  computing('المعلوميات', 'Informatique'),
  communication('التواصل', 'Communication'),
  sales('البيع', 'Vente'),
  languages('اللغات', 'Langues'),
  programming('البرمجة', 'Programmation'),
  management('التسيير', 'Gestion'),
  farming('الفلاحة', 'Agriculture'),
  manualWork('الخدمة باليدين', 'Travail manuel');

  const Skill(this.ar, this.fr);
  @override
  final String ar;
  @override
  final String fr;
}

/// How far the youth can travel. Ordered: the engine compares indexes.
enum Mobility with Labelled {
  commune('غير فالجماعة ديالي', 'Ma commune seulement'),
  province('فالإقليم', 'Ma province'),
  region('فجهة سوس ماسة', 'La région Souss-Massa'),
  anywhere('فأي بلاصة', "N'importe où");

  const Mobility(this.ar, this.fr);
  @override
  final String ar;
  @override
  final String fr;
}

/// Ordered: none < occasional < regular.
enum InternetAccess with Labelled {
  none('ما عنديش', 'Aucun'),
  occasional('شي مرات', 'Occasionnel'),
  regular('ديما', 'Régulier');

  const InternetAccess(this.ar, this.fr);
  @override
  final String ar;
  @override
  final String fr;
}

enum ConnectionType with Labelled {
  none('والو', 'Aucune'),
  mobile3g('3G فالتيليفون', 'Mobile 3G'),
  mobile4g('4G فالتيليفون', 'Mobile 4G'),
  wifi('ويفي', 'Wi-Fi');

  const ConnectionType(this.ar, this.fr);
  @override
  final String ar;
  @override
  final String fr;
}

enum Availability with Labelled {
  fullTime('النهار كامل', 'Temps plein'),
  partTime('نص النهار', 'Temps partiel'),
  weekends('غير فالويكاند', 'Week-ends');

  const Availability(this.ar, this.fr);
  @override
  final String ar;
  @override
  final String fr;
}

enum ModalityPreference with Labelled {
  onSite('حضوري', 'Présentiel'),
  remote('عن بعد', 'À distance'),
  any('كيفما كان', 'Peu importe');

  const ModalityPreference(this.ar, this.fr);
  @override
  final String ar;
  @override
  final String fr;
}

/// How an opportunity is delivered.
enum Modality with Labelled {
  onSite('حضوري', 'Présentiel'),
  remote('عن بعد', 'À distance'),
  hybrid('حضوري و عن بعد', 'Hybride');

  const Modality(this.ar, this.fr);
  @override
  final String ar;
  @override
  final String fr;
}
