import '../../../shared/models/app_user.dart';
import '../../../shared/models/localized_text.dart';
import '../../../shared/models/support_center.dart';
import '../../../shared/models/user_profile.dart';
import '../../progress/domain/journey.dart';
import '../../recommendations/domain/recommendation.dart';

class FaqEntry {
  const FaqEntry({
    required this.id,
    required this.keywords,
    required this.answer,
    required this.suggestions,
    this.route,
    this.opportunityId,
  });

  final String id;
  final List<String> keywords;
  final LocalizedText answer;
  final LocalizedList suggestions;
  final String? route;
  final String? opportunityId;

  factory FaqEntry.fromJson(Map<dynamic, dynamic> json) => FaqEntry(
    id: json['id'] as String,
    keywords: ((json['keywords'] as List?) ?? const []).cast<String>(),
    answer: LocalizedText.fromJson(json['answer']),
    suggestions: LocalizedList.fromJson(json['suggestions']),
    route: json['route'] as String?,
    opportunityId: json['opportunityId'] as String?,
  );
}

/// Everything the assistant may use to answer — only local data, so it
/// cannot invent an opportunity that does not exist.
class AssistantContext {
  const AssistantContext({
    required this.interfaceIsAr,
    required this.user,
    required this.profile,
    required this.ranked,
    required this.centers,
    required this.progress,
    required this.faq,
  });

  final bool interfaceIsAr;
  final AppUser? user;
  final UserProfile? profile;
  final List<Recommendation> ranked;
  final List<SupportCenter> centers;
  final JourneyProgress progress;
  final List<FaqEntry> faq;
}

class AssistantReply {
  const AssistantReply({
    required this.text,
    this.understood = const [],
    this.results = const [],
    this.suggestions = const [],
    this.actionLabel,
    this.actionRoute,
  });

  final String text;
  final List<String> understood;
  final List<Recommendation> results;
  final List<String> suggestions;
  final String? actionLabel;
  final String? actionRoute;
}

/// Swappable answer engine. The MVP ships [RuleBasedAssistant], which works
/// offline. A retrieval-augmented LLM provider (OpenAI or a sovereign model)
/// is planned server-side, behind POST /api/assistant/message, so no model
/// key ever lives in the mobile app.
abstract interface class AssistantProvider {
  String get id;
  Future<AssistantReply> reply(String message, AssistantContext context);
}
