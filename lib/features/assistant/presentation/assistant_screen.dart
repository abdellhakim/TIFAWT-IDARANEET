import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../shared/components/brand.dart';
import '../../../shared/components/ui.dart';
import '../../../shared/utils/dates.dart';
import '../../opportunities/application/opportunity_providers.dart';
import '../application/assistant_controller.dart';
import '../domain/chat_message.dart';

class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key});

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _toBottom(animate: false));
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _toBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final target = _scroll.position.maxScrollExtent;
      animate
          ? _scroll.animateTo(target, duration: const Duration(milliseconds: 320), curve: Curves.easeOut)
          : _scroll.jumpTo(target);
    });
  }

  Future<void> _send([String? text]) async {
    final message = text ?? _input.text;
    if (message.trim().isEmpty) return;
    _input.clear();
    final pending = ref.read(chatProvider.notifier).send(message);
    _toBottom();
    await pending;
    _toBottom();
  }

  void _voiceSoon(AppStrings s) => showModalBottomSheet<void>(
    context: context,
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(color: AppColors.oliveMist, shape: BoxShape.circle),
              child: const Icon(Icons.mic_rounded, color: AppColors.olive, size: 30),
            ),
            const SizedBox(height: 14),
            Text(s.voiceSoonTitle, style: AppText.heading(19)),
            const SizedBox(height: 8),
            Text(s.voiceSoonBody, textAlign: TextAlign.center, style: AppText.paragraph()),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final chat = ref.watch(chatProvider);
    final messages = chat.messages;
    final lastBot = messages.lastWhere((m) => !m.fromUser, orElse: () => messages.first);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
              // Back stays on the left in both languages, like every header.
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  const BotAvatar(size: 48),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: s.isAr ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                      children: [
                        Text(s.assistantTitle, style: AppText.heading(17)),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(s.alwaysOnline, style: AppText.label(12, color: AppColors.textMuted)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  BackSquare(onTap: () => context.canPop() ? context.pop() : context.go(Routes.home)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                children: [
                  Center(
                    child: Text(
                      Dates.long(messages.isEmpty ? DateTime.now() : messages.first.at, s.isAr),
                      style: AppText.label(12, color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: 14),
                  for (final m in messages) ...[
                    m.fromUser
                        ? _UserBubble(text: m.text)
                        : _BotMessage(
                            message: m,
                            s: s,
                            showSuggestions: identical(m, lastBot) && !chat.typing,
                            onSuggestion: _send,
                          ),
                    const SizedBox(height: 14),
                  ],
                  if (chat.typing) const _Typing(),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Color(0x0D000000), blurRadius: 14, offset: Offset(0, -4))],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: s.typeMessage,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        suffixIcon: IconButton(
                          tooltip: s.voiceSoonTitle,
                          onPressed: () => _voiceSoon(s),
                          icon: const Icon(Icons.mic_none_rounded, color: AppColors.textMuted),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Material(
                    color: AppColors.olive,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: chat.typing ? null : _send,
                      child: const SizedBox.square(
                        dimension: 48,
                        child: Icon(Icons.send_rounded, color: Colors.white, size: 21),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final _arabic = RegExp('[؀-ۿ]');

/// Messages keep the direction of their own language (a French question
/// inside the Arabic interface must not get its punctuation flipped).
TextDirection _directionOf(String text) => _arabic.hasMatch(text) ? TextDirection.rtl : TextDirection.ltr;

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerEnd,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .74),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: AppColors.olive,
          borderRadius: BorderRadiusDirectional.only(
            topStart: Radius.circular(20),
            topEnd: Radius.circular(20),
            bottomStart: Radius.circular(20),
            bottomEnd: Radius.circular(6),
          ),
        ),
        child: Text(
          text,
          textDirection: _directionOf(text),
          style: AppText.label(14.5, color: Colors.white, weight: FontWeight.w500).copyWith(height: 1.6),
        ),
      ),
    ),
  );
}

class _BotMessage extends ConsumerWidget {
  const _BotMessage({
    required this.message,
    required this.s,
    required this.showSuggestions,
    required this.onSuggestion,
  });

  final ChatMessage message;
  final AppStrings s;
  final bool showSuggestions;
  final ValueChanged<String> onSuggestion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width * .76;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BotAvatar(size: 30, filled: false),
        const SizedBox(width: 8),
        Flexible(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: width),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: AppColors.oliveMist,
                    borderRadius: BorderRadiusDirectional.only(
                      topStart: Radius.circular(6),
                      topEnd: Radius.circular(20),
                      bottomStart: Radius.circular(20),
                      bottomEnd: Radius.circular(20),
                    ),
                  ),
                  child: Directionality(
                    textDirection: _directionOf(message.text),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (message.understood.isNotEmpty) ...[
                          Text(
                            '${_directionOf(message.text) == TextDirection.rtl ? 'فهمت' : 'Compris'} : ${message.understood.join(' · ')}',
                            style: AppText.label(11.5, color: AppColors.olive, weight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                        ],
                        Text(
                          message.text,
                          style: AppText.label(
                            14.5,
                            color: AppColors.textDark,
                            weight: FontWeight.w500,
                          ).copyWith(height: 1.6),
                        ),
                      ],
                    ),
                  ),
                ),
                for (final (id, score) in message.results) _ResultCard(id: id, score: score),
                if (message.actionRoute != null && message.actionLabel != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.olive,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        textStyle: AppText.title(13.5),
                      ),
                      onPressed: () => context.openRoute(message.actionRoute!),
                      icon: const ForwardChevron(size: 18, color: Colors.white),
                      label: Text(message.actionLabel!),
                    ),
                  ),
                if (showSuggestions && message.suggestions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final suggestion in message.suggestions)
                          ActionChip(
                            label: Text(suggestion),
                            onPressed: () => onSuggestion(suggestion),
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: AppColors.olive),
                            labelStyle: AppText.label(
                              12.5,
                              color: AppColors.oliveDark,
                              weight: FontWeight.w700,
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ResultCard extends ConsumerWidget {
  const _ResultCard({required this.id, required this.score});
  final String id;
  final int score;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final o = ref.watch(opportunityProvider(id));
    if (o == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: AppCard(
        padding: const EdgeInsets.all(10),
        radius: 14,
        onTap: () => context.push(Routes.opportunity(id)),
        child: Row(
          children: [
            MatchRing(score: score, size: 42),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.l(o.title),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.title(13.5),
                  ),
                  Text(
                    '${o.organization} · ${s.duration(o.durationWeeks)}',
                    style: AppText.label(11.5, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const ForwardChevron(size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _Typing extends StatefulWidget {
  const _Typing();

  @override
  State<_Typing> createState() => _TypingState();
}

class _TypingState extends State<_Typing> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const BotAvatar(size: 30, filled: false),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: AppColors.oliveMist, borderRadius: BorderRadius.circular(18)),
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++)
                Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.olive.withValues(
                      alpha: .3 + .7 * (1 - ((_c.value * 3 - i) % 3).clamp(0, 1).toDouble()),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ],
  );
}
