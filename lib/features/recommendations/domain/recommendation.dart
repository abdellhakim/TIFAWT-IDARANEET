import '../../../shared/models/opportunity.dart';
import '../../../shared/models/profile_enums.dart';

/// Per-criterion match, each between 0 and 1.
class MatchBreakdown {
  const MatchBreakdown({
    required this.objective,
    required this.level,
    required this.interests,
    required this.skills,
    required this.proximity,
    required this.constraints,
  });

  final double objective;
  final double level;
  final double interests;
  final double skills;
  final double proximity;
  final double constraints;

  /// Weights agreed in the technical specification (sum = 100).
  static const weights = [25, 20, 20, 15, 10, 10];

  List<double> get values => [objective, level, interests, skills, proximity, constraints];

  double get weighted {
    var total = 0.0;
    for (var i = 0; i < weights.length; i++) {
      total += weights[i] * values[i];
    }
    return total;
  }
}

enum ReasonKind { objective, interests, level, zone, remote, skills, lowInternet }

class MatchReason {
  const MatchReason(
    this.kind, {
    this.objective,
    this.interests = const [],
    this.skills = const [],
    this.commune,
  });

  final ReasonKind kind;
  final Objective? objective;
  final List<Interest> interests;
  final List<Skill> skills;
  final String? commune;
}

enum WarningKind { travel, internet, level, age, deadline }

class MatchWarning {
  const MatchWarning(this.kind, {this.province, this.level, this.ageMin, this.ageMax, this.deadline});

  final WarningKind kind;
  final Province? province;
  final EducationLevel? level;
  final int? ageMin;
  final int? ageMax;
  final DateTime? deadline;
}

class Recommendation {
  const Recommendation({
    required this.opportunity,
    required this.score,
    required this.breakdown,
    required this.reasons,
    required this.warnings,
  });

  final Opportunity opportunity;

  /// Normalised compatibility, 0..100.
  final int score;
  final MatchBreakdown breakdown;
  final List<MatchReason> reasons;
  final List<MatchWarning> warnings;
}
