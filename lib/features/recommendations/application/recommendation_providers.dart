import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_store.dart';
import '../../opportunities/application/opportunity_providers.dart';
import '../../profile/application/profile_controller.dart';
import '../domain/recommendation.dart';
import '../domain/recommendation_engine.dart';

final recommendationEngineProvider = Provider<RecommendationEngine>((ref) => const RecommendationEngine());

/// Every open opportunity scored against the current profile, best first.
final rankedProvider = Provider<List<Recommendation>>((ref) {
  final profile = ref.watch(profileProvider);
  if (profile == null) return const [];
  return ref.watch(recommendationEngineProvider).rank(ref.watch(catalogProvider), profile);
});

/// Above the recommendation threshold.
final recommendationsProvider = Provider<List<Recommendation>>(
  (ref) => [
    for (final r in ref.watch(rankedProvider))
      if (r.score >= RecommendationEngine.recommendedThreshold) r,
  ],
);

final recommendationForProvider = Provider.family<Recommendation?, String>((ref, id) {
  for (final r in ref.watch(rankedProvider)) {
    if (r.opportunity.id == id) return r;
  }
  return null;
});

/// RecommendationCache: the last computed list, kept so the youth can see
/// when recommendations were produced and what they were, even offline.
abstract final class RecommendationCache {
  static Future<void> store(String userId, List<Recommendation> items) =>
      LocalStore.box(Boxes.recommendations).put(userId, {
        'computedAt': DateTime.now().toIso8601String(),
        'items': [
          for (final r in items) {'id': r.opportunity.id, 'score': r.score},
        ],
      });

  static DateTime? computedAt(String userId) {
    final raw = LocalStore.box(Boxes.recommendations).get(userId) as Map?;
    return raw == null ? null : DateTime.tryParse(raw['computedAt'] as String);
  }
}
