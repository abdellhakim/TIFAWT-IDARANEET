import '../../../shared/models/opportunity.dart';
import '../../../shared/models/profile_enums.dart';
import '../../../shared/models/user_profile.dart';
import 'recommendation.dart';

enum QueryScope with Labelled {
  all('فرص', 'opportunités'),
  training('تكوينات', 'formations'),
  job('خدمات', "offres d'emploi"),
  internship('تدريبات', 'stages'),
  entrepreneurship('برامج المواكبة', 'accompagnements'),
  support('برامج الدعم', "dispositifs d'aide"),
  studies('برامج القراية', "programmes de reprise d'études");

  const QueryScope(this.ar, this.fr);
  @override
  final String ar;
  @override
  final String fr;

  OpportunityType? get chipType => switch (this) {
    training => OpportunityType.formation,
    job => OpportunityType.job,
    internship => OpportunityType.internship,
    entrepreneurship => OpportunityType.entrepreneurship,
    support => OpportunityType.program,
    _ => null,
  };
}

/// A filter over ranked opportunities, shared by the assistant and the
/// recommendations screen (it travels in the route's query string).
class OpportunityQuery {
  const OpportunityQuery({
    this.scope = QueryScope.all,
    this.interest,
    this.nearOnly = false,
    this.freeOnly = false,
  });

  final QueryScope scope;
  final Interest? interest;
  final bool nearOnly;
  final bool freeOnly;

  bool get isEmpty => scope == QueryScope.all && interest == null && !nearOnly && !freeOnly;

  bool matches(Recommendation r, UserProfile profile) {
    final o = r.opportunity;
    final inScope = switch (scope) {
      QueryScope.all => true,
      QueryScope.training => o.type == OpportunityType.formation || o.type == OpportunityType.workshop,
      QueryScope.job => o.type == OpportunityType.job || o.type == OpportunityType.program,
      QueryScope.internship => o.type == OpportunityType.internship,
      QueryScope.entrepreneurship =>
        o.type == OpportunityType.entrepreneurship || o.objectives.contains(Objective.entrepreneurship),
      QueryScope.support =>
        o.type == OpportunityType.program ||
            o.type == OpportunityType.support ||
            o.type == OpportunityType.entrepreneurship,
      QueryScope.studies => o.objectives.contains(Objective.studies),
    };
    if (!inScope) return false;
    if (interest != null && !o.interests.contains(interest)) return false;
    if (freeOnly && !o.isFree) return false;
    if (nearOnly) {
      // Reachable = close enough to attend, or followable from home with
      // the connection the youth actually has.
      final internetOk = profile.internetAccess.index >= o.internetRequired.index;
      final local = o.province != null && o.modality != Modality.remote && r.breakdown.proximity >= .9;
      final fromHome = o.modality != Modality.onSite && internetOk;
      if (!local && !fromHome) return false;
    }
    return true;
  }

  Map<String, String> toParams() => {
    if (scope != QueryScope.all) 'scope': scope.name,
    if (interest != null) 'interest': interest!.name,
    if (nearOnly) 'near': '1',
    if (freeOnly) 'free': '1',
  };

  factory OpportunityQuery.fromParams(Map<String, String> params) => OpportunityQuery(
    scope: enumByName(QueryScope.values, params['scope'], QueryScope.all),
    interest: params['interest'] == null
        ? null
        : enumByName(Interest.values, params['interest'], Interest.digital),
    nearOnly: params['near'] == '1',
    freeOnly: params['free'] == '1',
  );

  String route() =>
      Uri(path: '/recommendations', queryParameters: toParams().isEmpty ? null : toParams()).toString();
}
