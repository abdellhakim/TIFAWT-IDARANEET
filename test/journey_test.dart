import 'package:flutter_test/flutter_test.dart';
import 'package:tifawt/features/progress/domain/journey.dart';

void main() {
  final t0 = DateTime(2026, 10, 10, 10);

  JourneyData withStatus(ApplicationStatus status) => JourneyData(
    applications: [
      OpportunityApplication(
        opportunityId: 'op_numerique_init',
        status: status,
        createdAt: t0,
        updatedAt: t0,
      ),
    ],
  );

  test('fresh account: profile is the current step', () {
    final p = computeJourney(profileCompleted: false, data: const JourneyData());
    expect(p.percent, 0);
    expect(p.current?.id, JourneyStepId.profile);
  });

  test('parcours §8: after "Je suis intéressée" → ✓✓✓ ● ○ ○ and 50 %', () {
    final p = computeJourney(profileCompleted: true, data: withStatus(ApplicationStatus.interested));
    expect(p.steps.map((s) => s.state), [
      JourneyStepState.done,
      JourneyStepState.done,
      JourneyStepState.done,
      JourneyStepState.current,
      JourneyStepState.pending,
      JourneyStepState.pending,
    ]);
    expect(p.percent, 50);
    expect(p.current?.id, JourneyStepId.registration);
  });

  test('offline step: "Inscription effectuée" moves the journey forward', () {
    final p = computeJourney(profileCompleted: true, data: withStatus(ApplicationStatus.registered));
    expect(p.done, 4);
    expect(p.current?.id, JourneyStepId.training);
  });

  test('certification completes the journey', () {
    final p = computeJourney(profileCompleted: true, data: withStatus(ApplicationStatus.certified));
    expect(p.percent, 100);
    expect(p.current, isNull);
  });

  test('the most advanced application drives the journey', () {
    final data = JourneyData(
      applications: [
        OpportunityApplication(
          opportunityId: 'a',
          status: ApplicationStatus.interested,
          createdAt: t0,
          updatedAt: t0,
        ),
        OpportunityApplication(
          opportunityId: 'b',
          status: ApplicationStatus.inTraining,
          createdAt: t0,
          updatedAt: t0,
        ),
      ],
    );
    expect(data.primary?.opportunityId, 'b');
  });

  test('history survives serialisation', () {
    final data = JourneyData(
      applications: withStatus(ApplicationStatus.registered).applications,
      events: [JourneyEvent(id: 'e1', type: JourneyEventType.orientation, at: t0)],
    );
    final copy = JourneyData.fromJson(data.toJson());
    expect(copy.primary?.status, ApplicationStatus.registered);
    expect(copy.orientationDone, isTrue);
  });
}
