import '../../../shared/models/opportunity.dart';
import '../../../shared/models/profile_enums.dart';
import '../../../shared/models/user_profile.dart';
import 'recommendation.dart';

/// Weighted, explainable rule-based scoring.
///
/// Score = 25% objective + 20% level + 20% interests + 15% skills
///       + 10% proximity + 10% constraints, normalised to 0..100.
///
/// Pure Dart, no I/O: runs offline in a few milliseconds and is mirrored
/// one-to-one by `backend/app/recommendation.py`.
class RecommendationEngine {
  const RecommendationEngine();

  static const recommendedThreshold = 60;

  /// Objectives that naturally lead to each other score half.
  static const _related = {
    Objective.training: {Objective.skills, Objective.employment, Objective.studies},
    Objective.skills: {Objective.training, Objective.entrepreneurship},
    Objective.employment: {Objective.training},
    Objective.studies: {Objective.training},
    Objective.entrepreneurship: {Objective.skills},
  };

  Recommendation evaluate(Opportunity o, UserProfile p, {DateTime? now}) {
    final breakdown = MatchBreakdown(
      objective: _objective(o, p),
      level: _level(o, p),
      interests: _interests(o, p),
      skills: _skills(o, p),
      proximity: _proximity(o, p),
      constraints: _constraints(o, p),
    );
    return Recommendation(
      opportunity: o,
      score: breakdown.weighted.round().clamp(0, 100),
      breakdown: breakdown,
      reasons: _reasons(o, p, breakdown),
      warnings: _warnings(o, p, breakdown, now ?? DateTime.now()),
    );
  }

  /// Open opportunities, best match first.
  List<Recommendation> rank(List<Opportunity> catalog, UserProfile profile, {DateTime? now}) {
    final today = now ?? DateTime.now();
    return [
      for (final o in catalog)
        if (o.isOpenOn(today)) evaluate(o, profile, now: today),
    ]..sort((a, b) => b.score.compareTo(a.score));
  }

  double _objective(Opportunity o, UserProfile p) {
    if (o.objectives.isEmpty) return .5;
    if (o.objectives.contains(p.objective)) return 1;
    final related = _related[p.objective] ?? const {};
    return o.objectives.any(related.contains) ? .5 : 0;
  }

  double _level(Opportunity o, UserProfile p) {
    final gap = p.education.index - o.requiredLevel.index;
    if (gap == 0) return 1;
    if (gap == 1) return .9;
    if (gap > 1) return .75; // eligible, a bit below the youth's level
    return gap == -1 ? .4 : 0;
  }

  double _interests(Opportunity o, UserProfile p) {
    if (o.interests.isEmpty) return .5;
    final overlap = o.interests.where(p.interests.contains).length;
    if (overlap == 0) return 0;
    return .6 + .4 * overlap / o.interests.length;
  }

  double _skills(Opportunity o, UserProfile p) {
    if (o.skills.isEmpty) return .6;
    final overlap = o.skills.where(p.skills.contains).length;
    return .4 + .6 * overlap / o.skills.length;
  }

  double _proximity(Opportunity o, UserProfile p) {
    if (o.province == null || o.modality == Modality.remote) return 1;
    if (o.province == p.province && o.commune == p.commune) return 1;
    if (o.province == p.province) {
      return p.mobility.index >= Mobility.province.index ? .9 : .6;
    }
    // The three provinces belong to the Souss-Massa region.
    if (p.mobility.index >= Mobility.region.index) return .7;
    return p.mobility == Mobility.province ? .3 : .1;
  }

  double _constraints(Opportunity o, UserProfile p) {
    final checks = <double>[
      p.internetAccess.index >= o.internetRequired.index ? 1 : 0,
      p.mobility.index >= o.mobilityRequired.index ? 1 : .4,
      switch ((p.modality, o.modality)) {
        (ModalityPreference.any, _) || (_, Modality.hybrid) => 1,
        (ModalityPreference.onSite, Modality.onSite) => 1,
        (ModalityPreference.remote, Modality.remote) => 1,
        _ => .5,
      },
      p.age >= o.ageMin && p.age <= o.ageMax ? 1 : 0,
      p.availability == Availability.weekends && o.type != OpportunityType.workshop ? .5 : 1,
    ];
    return checks.reduce((a, b) => a + b) / checks.length;
  }

  List<MatchReason> _reasons(Opportunity o, UserProfile p, MatchBreakdown b) {
    final remote = o.province == null || o.modality == Modality.remote;
    return [
      if (b.objective == 1) MatchReason(ReasonKind.objective, objective: p.objective),
      if (b.interests >= .6)
        MatchReason(ReasonKind.interests, interests: o.interests.where(p.interests.contains).toList()),
      if (b.level >= .9) const MatchReason(ReasonKind.level),
      if (remote)
        const MatchReason(ReasonKind.remote)
      else if (b.proximity >= .9)
        MatchReason(ReasonKind.zone, commune: o.commune),
      if (b.skills >= .8) MatchReason(ReasonKind.skills, skills: o.skills.where(p.skills.contains).toList()),
      if (o.internetRequired == InternetAccess.none &&
          p.internetAccess != InternetAccess.regular &&
          b.objective < 1)
        const MatchReason(ReasonKind.lowInternet),
    ];
  }

  List<MatchWarning> _warnings(Opportunity o, UserProfile p, MatchBreakdown b, DateTime now) {
    return [
      if (o.province != null && b.proximity < .7) MatchWarning(WarningKind.travel, province: o.province),
      if (p.internetAccess.index < o.internetRequired.index) const MatchWarning(WarningKind.internet),
      if (p.education.index < o.requiredLevel.index) MatchWarning(WarningKind.level, level: o.requiredLevel),
      if (p.age < o.ageMin || p.age > o.ageMax)
        MatchWarning(WarningKind.age, ageMin: o.ageMin, ageMax: o.ageMax),
      if (o.deadline != null && o.deadline!.difference(now).inDays <= 21)
        MatchWarning(WarningKind.deadline, deadline: o.deadline),
    ];
  }
}
