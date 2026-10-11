import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_store.dart';
import '../../../shared/models/opportunity.dart';
import '../../auth/application/auth_controller.dart';
import '../../synchronization/application/sync_manager.dart';
import '../../synchronization/domain/sync_operation.dart';
import '../data/opportunity_repository.dart';

final opportunityRepositoryProvider = Provider<OpportunityRepository>((ref) => OpportunityRepository());

/// Bumped after a catalog refresh so dependants rebuild.
final catalogVersionProvider = StateProvider<int>((ref) => 0);

final catalogProvider = Provider<List<Opportunity>>((ref) {
  ref.watch(catalogVersionProvider);
  return ref.watch(opportunityRepositoryProvider).all();
});

final opportunityProvider = Provider.family<Opportunity?, String>((ref, id) {
  for (final o in ref.watch(catalogProvider)) {
    if (o.id == id) return o;
  }
  return null;
});

/// Saved opportunities (heart).
class FavoritesController extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    final user = ref.watch(authProvider);
    if (user == null) return const {};
    final raw = LocalStore.box(Boxes.favorites).get(user.id) as List?;
    return {...?raw?.cast<String>()};
  }

  Future<void> toggle(String opportunityId) async {
    final user = ref.read(authProvider);
    if (user == null) return;
    final adding = !state.contains(opportunityId);
    state = adding ? {...state, opportunityId} : ({...state}..remove(opportunityId));
    await LocalStore.box(Boxes.favorites).put(user.id, state.toList());
    await ref
        .read(syncProvider.notifier)
        .enqueue(
          userId: user.id,
          entity: SyncEntity.favorite,
          operation: adding ? SyncOp.create : SyncOp.delete,
          payload: {'opportunityId': opportunityId},
        );
  }
}

final favoritesProvider = NotifierProvider<FavoritesController, Set<String>>(FavoritesController.new);
