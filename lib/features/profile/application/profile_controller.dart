import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_store.dart';
import '../../../shared/models/user_profile.dart';
import '../../auth/application/auth_controller.dart';
import '../../progress/application/journey_controller.dart';
import '../../synchronization/application/sync_manager.dart';
import '../../synchronization/domain/sync_operation.dart';

/// The questionnaire is saved to Hive immediately — no server round-trip.
class ProfileController extends Notifier<UserProfile?> {
  @override
  UserProfile? build() {
    final user = ref.watch(authProvider);
    if (user == null) return null;
    final raw = LocalStore.box(Boxes.profiles).get(user.id);
    return raw == null ? null : UserProfile.fromJson(raw as Map);
  }

  Future<void> save(UserProfile profile, {bool complete = true}) async {
    final wasCompleted = state?.completed ?? false;
    final saved = profile.copyWith(completed: complete || wasCompleted, updatedAt: DateTime.now());
    await LocalStore.box(Boxes.profiles).put(saved.userId, saved.toJson());
    state = saved;

    await ref
        .read(syncProvider.notifier)
        .enqueue(
          userId: saved.userId,
          entity: SyncEntity.profile,
          operation: SyncOp.update,
          payload: saved.toJson(),
        );
    if (saved.completed && !wasCompleted) {
      await ref.read(journeyProvider.notifier).recordProfileCompleted();
    }
  }
}

final profileProvider = NotifierProvider<ProfileController, UserProfile?>(ProfileController.new);
