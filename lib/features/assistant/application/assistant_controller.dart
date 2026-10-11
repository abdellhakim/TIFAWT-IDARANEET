import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/localization/locale_provider.dart';
import '../../../core/storage/local_store.dart';
import '../../auth/application/auth_controller.dart';
import '../../centers/application/centers_provider.dart';
import '../../profile/application/profile_controller.dart';
import '../../progress/application/journey_controller.dart';
import '../../recommendations/application/recommendation_providers.dart';
import '../domain/assistant_provider.dart';
import '../domain/chat_message.dart';
import '../domain/rule_based_assistant.dart';

/// Local knowledge base (assistant_faq), seeded from the bundled JSON.
final faqProvider = Provider<List<FaqEntry>>(
  (ref) => [for (final raw in LocalStore.box(Boxes.knowledge).values) FaqEntry.fromJson(raw as Map)],
);

final assistantProvider = Provider<AssistantProvider>((ref) => const RuleBasedAssistant());

class ChatState {
  const ChatState({this.messages = const [], this.typing = false});
  final List<ChatMessage> messages;
  final bool typing;
}

class AssistantController extends Notifier<ChatState> {
  static const _uuid = Uuid();

  @override
  ChatState build() {
    final user = ref.watch(authProvider);
    if (user == null) return const ChatState();
    final raw = LocalStore.box(Boxes.chat).get(user.id) as List?;
    if (raw != null && raw.isNotEmpty) {
      return ChatState(messages: [for (final m in raw) ChatMessage.fromJson(m as Map)]);
    }

    final s = ref.read(stringsProvider);
    final welcome = ChatMessage(
      id: _uuid.v4(),
      fromUser: false,
      text: s.t(
        'السلام، أنا المساعد الرقمي 👋 كيفاش نقدر نعاونك اليوم',
        "Bonjour, je suis l'assistant TIFAWT. Comment puis-je vous aider aujourd'hui ?",
      ),
      at: DateTime.now(),
      suggestions: s.isAr
          ? const ['بغيت نتكون فالمعلوميات', 'بغيت نلقى خدمة', 'فين أقرب مركز؟']
          : const [
              'Je cherche une formation en informatique',
              'Je cherche un emploi',
              'Où est le centre le plus proche ?',
            ],
    );
    return ChatState(messages: [welcome]);
  }

  Future<void> send(String text) async {
    final message = text.trim();
    if (message.isEmpty || state.typing) return;

    final userMessage = ChatMessage(id: _uuid.v4(), fromUser: true, text: message, at: DateTime.now());
    state = ChatState(messages: [...state.messages, userMessage], typing: true);
    _persist();

    final context = AssistantContext(
      interfaceIsAr: ref.read(stringsProvider).isAr,
      user: ref.read(authProvider),
      profile: ref.read(profileProvider),
      ranked: ref.read(rankedProvider),
      centers: ref.read(centersProvider),
      progress: ref.read(journeyProgressProvider),
      faq: ref.read(faqProvider),
    );

    // Short pause so the exchange reads like a conversation.
    final results = await Future.wait([
      ref.read(assistantProvider).reply(message, context),
      Future<void>.delayed(const Duration(milliseconds: 650)),
    ]);
    final reply = results.first as AssistantReply;

    final botMessage = ChatMessage(
      id: _uuid.v4(),
      fromUser: false,
      text: reply.text,
      at: DateTime.now(),
      understood: reply.understood,
      results: [for (final r in reply.results) (r.opportunity.id, r.score)],
      suggestions: reply.suggestions,
      actionLabel: reply.actionLabel,
      actionRoute: reply.actionRoute,
    );
    state = ChatState(messages: [...state.messages, botMessage]);
    _persist();

    if (reply.results.isNotEmpty && reply.understood.isNotEmpty) {
      await ref.read(journeyProvider.notifier).recordOrientation();
    }
  }

  void _persist() {
    final user = ref.read(authProvider);
    if (user == null) return;
    LocalStore.box(Boxes.chat).put(user.id, [for (final m in state.messages) m.toJson()]);
  }
}

final chatProvider = NotifierProvider<AssistantController, ChatState>(AssistantController.new);
