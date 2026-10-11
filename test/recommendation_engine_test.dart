import 'package:flutter_test/flutter_test.dart';
import 'package:tifawt/features/recommendations/domain/opportunity_query.dart';
import 'package:tifawt/features/recommendations/domain/recommendation.dart';
import 'package:tifawt/features/recommendations/domain/recommendation_engine.dart';
import 'package:tifawt/shared/models/profile_enums.dart';

import 'support/fixtures.dart';

void main() {
  const engine = RecommendationEngine();
  final catalog = loadCatalog();
  final digital = catalog.firstWhere((o) => o.id == 'op_numerique_init');

  test('weights from the specification add up to 100', () {
    expect(MatchBreakdown.weights, [25, 20, 20, 15, 10, 10]);
    expect(MatchBreakdown.weights.reduce((a, b) => a + b), 100);
  });

  test('parcours nominal: Chahd gets 92% for the digital initiation training', () {
    final r = engine.evaluate(digital, chahd, now: today);
    expect(r.score, 92);
  });

  test('the explanation matches the four reasons of the parcours', () {
    final r = engine.evaluate(digital, chahd, now: today);
    expect(r.reasons.map((x) => x.kind), [
      ReasonKind.objective,
      ReasonKind.interests,
      ReasonKind.level,
      ReasonKind.zone,
    ]);
    expect(r.reasons.first.objective, Objective.training);
    expect(r.reasons[1].interests, [Interest.digital]);
    expect(r.warnings, isEmpty);
  });

  test('it is her top recommendation', () {
    final ranked = engine.rank(catalog, chahd, now: today);
    expect(ranked.first.opportunity.id, 'op_numerique_init');
  });

  test('scores are normalised and sorted best first', () {
    final ranked = engine.rank(catalog, chahd, now: today);
    for (final r in ranked) {
      expect(r.score, inInclusiveRange(0, 100));
    }
    for (var i = 1; i < ranked.length; i++) {
      expect(ranked[i - 1].score, greaterThanOrEqualTo(ranked[i].score));
    }
  });

  test('constraints are explained, not hidden', () {
    final remote = catalog.firstWhere((o) => o.id == 'op_marketing_distance');
    final r = engine.evaluate(remote, chahd, now: today);
    expect(r.warnings.map((w) => w.kind), contains(WarningKind.internet));

    final agadir = catalog.firstWhere((o) => o.id == 'op_stage_hotel');
    final far = engine.evaluate(agadir, chahd, now: today);
    expect(far.warnings.map((w) => w.kind), contains(WarningKind.travel));
    expect(far.score, lessThan(r.score));
  });

  test('closed opportunities are not recommended', () {
    final afterSaffronDeadline = DateTime(2026, 11, 5);
    final ranked = engine.rank(catalog, chahd, now: afterSaffronDeadline);
    expect(ranked.map((r) => r.opportunity.id), isNot(contains('op_safran')));
  });

  test('a diploma-gated offer is penalised for a youth without the level', () {
    final dropout = chahd.copyWith(education: EducationLevel.primary);
    expect(
      engine.evaluate(digital, dropout, now: today).score,
      lessThan(engine.evaluate(digital, chahd, now: today).score),
    );
  });

  test('"near me" query keeps reachable opportunities only', () {
    const query = OpportunityQuery(scope: QueryScope.training, interest: Interest.digital, nearOnly: true);
    final ids = [
      for (final r in engine.rank(catalog, chahd, now: today))
        if (query.matches(r, chahd)) r.opportunity.id,
    ];
    expect(ids.first, 'op_numerique_init');
    expect(ids, isNot(contains('op_alpha')));
    expect(ids, isNot(contains('op_marketing_distance')));
  });

  test('query survives a round trip through the route', () {
    const query = OpportunityQuery(scope: QueryScope.training, interest: Interest.digital, nearOnly: true);
    final uri = Uri.parse(query.route());
    final back = OpportunityQuery.fromParams(uri.queryParameters);
    expect(uri.path, '/recommendations');
    expect(back.scope, QueryScope.training);
    expect(back.interest, Interest.digital);
    expect(back.nearOnly, isTrue);
  });
}
