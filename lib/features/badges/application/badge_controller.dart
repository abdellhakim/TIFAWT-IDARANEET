import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_store.dart';
import '../../auth/application/auth_controller.dart';
import '../../synchronization/application/sync_manager.dart';
import '../../synchronization/domain/sync_operation.dart';
import '../domain/badge.dart';

class BadgeController extends Notifier<Map<BadgeType, DateTime>> {
  final _earned = StreamController<BadgeType>.broadcast();

  /// Emits each badge the moment it is unlocked (for the toast).
  Stream<BadgeType> get unlocked => _earned.stream;

  @override
  Map<BadgeType, DateTime> build() {
    final user = ref.watch(authProvider);
    if (user == null) return const {};
    final raw = (LocalStore.box(Boxes.badges).get(user.id) as Map?) ?? const {};
    final earned = <BadgeType, DateTime>{};
    for (final MapEntry(:key, :value) in raw.entries) {
      final badge = BadgeType.fromCode(key as String);
      if (badge != null) earned[badge] = DateTime.parse(value as String);
    }
    return earned;
  }

  Future<void> award(BadgeType badge) async {
    final user = ref.read(authProvider);
    if (user == null || state.containsKey(badge)) return;

    final now = DateTime.now();
    state = {...state, badge: now};
    await LocalStore.box(
      Boxes.badges,
    ).put(user.id, {for (final MapEntry(:key, :value) in state.entries) key.code: value.toIso8601String()});
    _earned.add(badge);
    await ref
        .read(syncProvider.notifier)
        .enqueue(
          userId: user.id,
          entity: SyncEntity.badge,
          operation: SyncOp.create,
          payload: {'code': badge.code, 'earnedAt': now.toUtc().toIso8601String()},
        );
  }
}

final badgesProvider = NotifierProvider<BadgeController, Map<BadgeType, DateTime>>(BadgeController.new);
