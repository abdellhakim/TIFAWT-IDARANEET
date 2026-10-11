/// One entry of the conversation (ChatHistory box).
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.fromUser,
    required this.text,
    required this.at,
    this.understood = const [],
    this.results = const [],
    this.suggestions = const [],
    this.actionLabel,
    this.actionRoute,
  });

  final String id;
  final bool fromUser;
  final String text;
  final DateTime at;

  /// What the assistant extracted, shown as small chips ("Formation · Numérique").
  final List<String> understood;

  /// Opportunity ids with their compatibility score.
  final List<(String, int)> results;
  final List<String> suggestions;
  final String? actionLabel;
  final String? actionRoute;

  Map<String, dynamic> toJson() => {
    'id': id,
    'fromUser': fromUser,
    'text': text,
    'at': at.toIso8601String(),
    'understood': understood,
    'results': [
      for (final (id, score) in results) {'id': id, 'score': score},
    ],
    'suggestions': suggestions,
    'actionLabel': actionLabel,
    'actionRoute': actionRoute,
  };

  factory ChatMessage.fromJson(Map<dynamic, dynamic> json) => ChatMessage(
    id: json['id'] as String,
    fromUser: json['fromUser'] as bool,
    text: json['text'] as String,
    at: DateTime.parse(json['at'] as String),
    understood: ((json['understood'] as List?) ?? const []).cast<String>(),
    results: [
      for (final r in ((json['results'] as List?) ?? const []).cast<Map>())
        (r['id'] as String, r['score'] as int),
    ],
    suggestions: ((json['suggestions'] as List?) ?? const []).cast<String>(),
    actionLabel: json['actionLabel'] as String?,
    actionRoute: json['actionRoute'] as String?,
  );
}
