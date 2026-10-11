import '../../../shared/models/profile_enums.dart';

/// Light gamification: badges mark real progress, nothing more.
enum BadgeType with Labelled {
  profileCompleted('PROFILE_COMPLETED', 'الملف كامل', 'Profil complété'),
  firstRecommendation('FIRST_RECOMMENDATION', 'أول توصية', 'Première recommandation'),
  firstOpportunity('FIRST_OPPORTUNITY', 'أول فرصة مختارة', 'Première opportunité sélectionnée'),
  trainingStarted('TRAINING_STARTED', 'بديت التكوين', 'Formation commencée'),
  trainingCompleted('TRAINING_COMPLETED', 'كملت التكوين', 'Formation terminée');

  const BadgeType(this.code, this.ar, this.fr);

  /// Code shared with the API.
  final String code;
  @override
  final String ar;
  @override
  final String fr;

  static BadgeType? fromCode(String code) {
    for (final b in values) {
      if (b.code == code) return b;
    }
    return null;
  }
}
