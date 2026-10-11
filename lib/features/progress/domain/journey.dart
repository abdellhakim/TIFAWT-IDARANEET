import '../../../shared/models/profile_enums.dart';

/// Where the youth stands with a selected opportunity.
/// Ordered: each status implies the previous ones.
enum ApplicationStatus with Labelled {
  interested('مهتمة', 'Intéressée'),
  registered('التسجيل تدار', 'Inscription effectuée'),
  inTraining('فالتكوين', 'En formation'),
  completed('التكوين سالا', 'Formation terminée'),
  certified('خديت الشهادة', 'Certification obtenue');

  const ApplicationStatus(this.ar, this.fr);
  @override
  final String ar;
  @override
  final String fr;

  /// Masculine forms where Darija/French differ.
  String labelFor(bool isAr, {required bool female}) {
    if (this == interested && !female) return isAr ? 'مهتم' : 'Intéressé';
    if (this == certified && !female && isAr) return 'خديت الشهادة';
    return label(isAr);
  }

  bool isAtLeast(ApplicationStatus other) => index >= other.index;
}

class OpportunityApplication {
  const OpportunityApplication({
    required this.opportunityId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String opportunityId;
  final ApplicationStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  OpportunityApplication withStatus(ApplicationStatus next, DateTime at) =>
      OpportunityApplication(opportunityId: opportunityId, status: next, createdAt: createdAt, updatedAt: at);

  Map<String, dynamic> toJson() => {
    'opportunityId': opportunityId,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory OpportunityApplication.fromJson(Map<dynamic, dynamic> json) => OpportunityApplication(
    opportunityId: json['opportunityId'] as String,
    status: enumByName(ApplicationStatus.values, json['status'], ApplicationStatus.interested),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}

enum JourneyEventType { profileCompleted, orientation, opportunitySelected, statusChanged }

/// Append-only history of the youth's progress ("progress" table on the API).
class JourneyEvent {
  const JourneyEvent({
    required this.id,
    required this.type,
    required this.at,
    this.opportunityId,
    this.status,
  });

  final String id;
  final JourneyEventType type;
  final DateTime at;
  final String? opportunityId;
  final ApplicationStatus? status;

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'at': at.toIso8601String(),
    'opportunityId': opportunityId,
    'status': status?.name,
  };

  factory JourneyEvent.fromJson(Map<dynamic, dynamic> json) => JourneyEvent(
    id: json['id'] as String,
    type: enumByName(JourneyEventType.values, json['type'], JourneyEventType.orientation),
    at: DateTime.parse(json['at'] as String),
    opportunityId: json['opportunityId'] as String?,
    status: json['status'] == null
        ? null
        : enumByName(ApplicationStatus.values, json['status'], ApplicationStatus.interested),
  );
}

class JourneyData {
  const JourneyData({this.applications = const [], this.events = const []});

  final List<OpportunityApplication> applications;
  final List<JourneyEvent> events;

  bool get orientationDone => events.any((e) => e.type == JourneyEventType.orientation);

  /// The application furthest along drives the journey.
  OpportunityApplication? get primary {
    if (applications.isEmpty) return null;
    return applications.reduce((a, b) {
      if (a.status.index != b.status.index) {
        return a.status.index > b.status.index ? a : b;
      }
      return a.updatedAt.isAfter(b.updatedAt) ? a : b;
    });
  }

  OpportunityApplication? applicationFor(String opportunityId) {
    for (final a in applications) {
      if (a.opportunityId == opportunityId) return a;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'applications': [for (final a in applications) a.toJson()],
    'events': [for (final e in events) e.toJson()],
  };

  factory JourneyData.fromJson(Map<dynamic, dynamic> json) => JourneyData(
    applications: [
      for (final a in (json['applications'] as List? ?? const [])) OpportunityApplication.fromJson(a as Map),
    ],
    events: [for (final e in (json['events'] as List? ?? const [])) JourneyEvent.fromJson(e as Map)],
  );
}

enum JourneyStepId with Labelled {
  profile('الملف كامل', 'Profil complété'),
  orientation('التوجيه', 'Orientation'),
  selection('اختيار الفرصة', 'Opportunité sélectionnée'),
  registration('التسجيل', 'Inscription'),
  training('التكوين', 'Formation'),
  certification('الشهادة', 'Certification');

  const JourneyStepId(this.ar, this.fr);
  @override
  final String ar;
  @override
  final String fr;
}

enum JourneyStepState { done, current, pending }

class JourneyStep {
  const JourneyStep(this.id, this.state, this.fill);
  final JourneyStepId id;
  final JourneyStepState state;

  /// 0..1, drives the small progress bar under the step.
  final double fill;
}

class JourneyProgress {
  const JourneyProgress(this.steps);
  final List<JourneyStep> steps;

  int get done => steps.where((s) => s.state == JourneyStepState.done).length;
  int get total => steps.length;
  int get percent => total == 0 ? 0 : (done * 100 / total).round();

  JourneyStep? get current {
    for (final s in steps) {
      if (s.state == JourneyStepState.current) return s;
    }
    return null;
  }

  bool isDone(JourneyStepId id) => steps.any((s) => s.id == id && s.state == JourneyStepState.done);
}

/// Derives the six steps from what actually happened — nothing is
/// hard-coded, so the progress always reflects the youth's real actions.
JourneyProgress computeJourney({required bool profileCompleted, required JourneyData data}) {
  final status = data.primary?.status;
  final reached = <JourneyStepId, bool>{
    JourneyStepId.profile: profileCompleted,
    JourneyStepId.orientation: data.orientationDone || status != null,
    JourneyStepId.selection: status != null,
    JourneyStepId.registration: status?.isAtLeast(ApplicationStatus.registered) ?? false,
    JourneyStepId.training: status?.isAtLeast(ApplicationStatus.completed) ?? false,
    JourneyStepId.certification: status == ApplicationStatus.certified,
  };

  var currentAssigned = false;
  final steps = <JourneyStep>[];
  for (final id in JourneyStepId.values) {
    if (reached[id]!) {
      steps.add(JourneyStep(id, JourneyStepState.done, 1));
    } else if (!currentAssigned) {
      currentAssigned = true;
      final fill = switch (id) {
        JourneyStepId.training when status == ApplicationStatus.inTraining => .5,
        _ => .15,
      };
      steps.add(JourneyStep(id, JourneyStepState.current, fill));
    } else {
      steps.add(JourneyStep(id, JourneyStepState.pending, 0));
    }
  }
  return JourneyProgress(steps);
}
