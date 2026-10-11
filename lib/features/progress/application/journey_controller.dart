import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/storage/local_store.dart';
import '../../auth/application/auth_controller.dart';
import '../../badges/application/badge_controller.dart';
import '../../badges/domain/badge.dart';
import '../../profile/application/profile_controller.dart';
import '../../synchronization/application/sync_manager.dart';
import '../../synchronization/domain/sync_operation.dart';
import '../domain/journey.dart';

class JourneyController extends Notifier<JourneyData> {
  static const _uuid = Uuid();

  @override
  JourneyData build() {
    final user = ref.watch(authProvider);
    if (user == null) return const JourneyData();
    final raw = LocalStore.box(Boxes.journey).get(user.id);
    return raw == null ? const JourneyData() : JourneyData.fromJson(raw as Map);
  }

  Future<void> recordProfileCompleted() async {
    if (state.events.any((e) => e.type == JourneyEventType.profileCompleted)) return;
    await _addEvent(JourneyEventType.profileCompleted);
    await ref.read(badgesProvider.notifier).award(BadgeType.profileCompleted);
  }

  /// The youth consulted personalised recommendations (screen or assistant).
  Future<void> recordOrientation() async {
    if (state.orientationDone) return;
    await _addEvent(JourneyEventType.orientation);
    await ref.read(badgesProvider.notifier).award(BadgeType.firstRecommendation);
  }

  /// "Je suis intéressée": adds the opportunity to the journey.
  Future<void> select(String opportunityId) async {
    if (state.applicationFor(opportunityId) != null) return;
    final now = DateTime.now();
    final application = OpportunityApplication(
      opportunityId: opportunityId,
      status: ApplicationStatus.interested,
      createdAt: now,
      updatedAt: now,
    );
    state = JourneyData(applications: [...state.applications, application], events: state.events);
    await _enqueueApplication(application, SyncOp.create);
    await _addEvent(
      JourneyEventType.opportunitySelected,
      opportunityId: opportunityId,
      status: ApplicationStatus.interested,
    );
    await recordOrientation();
    await ref.read(badgesProvider.notifier).award(BadgeType.firstOpportunity);
  }

  Future<void> updateStatus(String opportunityId, ApplicationStatus status) async {
    final current = state.applicationFor(opportunityId);
    if (current == null || current.status == status) return;
    final updated = current.withStatus(status, DateTime.now());
    state = JourneyData(
      applications: [for (final a in state.applications) a.opportunityId == opportunityId ? updated : a],
      events: state.events,
    );
    await _enqueueApplication(updated, SyncOp.update);
    await _addEvent(JourneyEventType.statusChanged, opportunityId: opportunityId, status: status);

    final badges = ref.read(badgesProvider.notifier);
    if (status.isAtLeast(ApplicationStatus.inTraining)) {
      await badges.award(BadgeType.trainingStarted);
    }
    if (status.isAtLeast(ApplicationStatus.completed)) {
      await badges.award(BadgeType.trainingCompleted);
    }
  }

  Future<void> _addEvent(JourneyEventType type, {String? opportunityId, ApplicationStatus? status}) async {
    final user = ref.read(authProvider);
    if (user == null) return;
    final event = JourneyEvent(
      id: _uuid.v4(),
      type: type,
      at: DateTime.now(),
      opportunityId: opportunityId,
      status: status,
    );
    state = JourneyData(applications: state.applications, events: [...state.events, event]);
    await LocalStore.box(Boxes.journey).put(user.id, state.toJson());
    await ref
        .read(syncProvider.notifier)
        .enqueue(
          userId: user.id,
          entity: SyncEntity.progressEvent,
          operation: SyncOp.create,
          payload: event.toJson(),
        );
  }

  Future<void> _enqueueApplication(OpportunityApplication a, String operation) async {
    final user = ref.read(authProvider);
    if (user == null) return;
    await LocalStore.box(Boxes.journey).put(user.id, state.toJson());
    await ref
        .read(syncProvider.notifier)
        .enqueue(userId: user.id, entity: SyncEntity.application, operation: operation, payload: a.toJson());
  }
}

final journeyProvider = NotifierProvider<JourneyController, JourneyData>(JourneyController.new);

final journeyProgressProvider = Provider<JourneyProgress>(
  (ref) => computeJourney(
    profileCompleted: ref.watch(profileProvider)?.completed ?? false,
    data: ref.watch(journeyProvider),
  ),
);
