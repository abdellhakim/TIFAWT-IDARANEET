import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/locale_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../shared/components/brand.dart';
import '../../../shared/components/choices.dart';
import '../../../shared/components/ui.dart';
import '../../../shared/constants/communes.dart';
import '../../../shared/models/profile_enums.dart';
import '../../auth/application/auth_controller.dart';
import '../../profile/application/profile_controller.dart';
import '../../progress/application/journey_controller.dart';
import '../../recommendations/application/recommendation_providers.dart';

/// Dashboard: "Que souhaitez-vous faire aujourd'hui ?"
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final user = ref.watch(authProvider);
    final profile = ref.watch(profileProvider);
    final recommendations = ref.watch(recommendationsProvider);
    final journey = ref.watch(journeyProgressProvider);
    final name = user?.firstName(s.isAr) ?? '';

    final cards = [
      _Action(
        title: s.cardAssistant,
        secondary: s.isAr ? 'Assistant' : null,
        subtitle: s.cardAssistantSub,
        color: AppColors.olive,
        leading: const BotAvatar(size: 30, filled: false),
        onTap: () => context.push(Routes.assistantFrom(Routes.home)),
      ),
      _Action(
        title: s.cardRecommendations,
        secondary: s.isAr ? 'Recommandations' : null,
        subtitle: recommendations.isEmpty
            ? s.recoSubtitle
            : s.cardRecommendationsSub(recommendations.length, recommendations.first.score),
        color: AppColors.terracotta,
        icon: Icons.gps_fixed_rounded,
        onTap: () => context.push(Routes.recommendations),
      ),
      _Action(
        title: s.cardOpportunities,
        secondary: s.isAr ? 'Opportunités' : null,
        subtitle: s.cardOpportunitiesSub,
        color: AppColors.amber,
        icon: Icons.work_rounded,
        onTap: () => context.go(Routes.opportunities),
      ),
      _Action(
        title: s.cardProgress,
        secondary: s.isAr ? 'Progression' : null,
        subtitle: s.cardProgressSub(journey.percent, journey.current?.id.label(s.isAr) ?? '✓'),
        color: AppColors.oliveDark,
        icon: Icons.timeline_rounded,
        onTap: () => context.go(Routes.account),
      ),
      _Action(
        title: s.cardProfile,
        secondary: s.isAr ? 'Profil' : null,
        subtitle: s.cardProfileSub,
        color: const Color(0xFF8A5A2B),
        icon: Icons.person_rounded,
        onTap: () => context.push(Routes.profile),
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SALAM',
                        style: AppText.label(
                          11.5,
                          color: AppColors.textMedium,
                          weight: FontWeight.w800,
                        ).copyWith(letterSpacing: 2),
                      ),
                      Text(s.greeting(name), style: AppText.heading(21, color: AppColors.terracotta)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => context.go(Routes.account),
                  child: UserAvatar(name: user?.displayName(s.isAr) ?? '', size: 50),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _SearchBar(hint: s.searchHint, onTap: () => context.go('${Routes.opportunities}?q=')),
            const SizedBox(height: 26),
            SectionTitle(s.yourProvince),
            const SizedBox(height: 12),
            Row(
              children: [
                for (final province in Province.values) ...[
                  Expanded(
                    child: RegionCard(
                      province: province,
                      selected: (profile?.province ?? Province.taroudant) == province,
                      onTap: () {
                        if (profile == null || profile.province == province) return;
                        ref
                            .read(profileProvider.notifier)
                            .save(
                              profile.copyWith(
                                province: province,
                                commune: communesByProvince[province]!.first.fr,
                              ),
                              complete: profile.completed,
                            );
                      },
                    ),
                  ),
                  if (province != Province.values.last) const SizedBox(width: 10),
                ],
              ],
            ),
            const SizedBox(height: 28),
            SectionTitle(s.whatToday),
            const SizedBox(height: 12),
            for (final card in cards) ...[_ActionCard(action: card), const SizedBox(height: 12)],
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.hint, required this.onTap});
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AppCard(
    onTap: onTap,
    radius: 16,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    child: Row(
      children: [
        const Icon(Icons.search_rounded, color: AppColors.terracotta, size: 22),
        const SizedBox(width: 10),
        Text(hint, style: AppText.label(13.5, color: AppColors.textMuted)),
      ],
    ),
  );
}

class _Action {
  const _Action({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.secondary,
    this.icon,
    this.leading,
  });

  final String title;
  final String? secondary;
  final String subtitle;
  final Color color;
  final IconData? icon;
  final Widget? leading;
  final VoidCallback onTap;
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.action});
  final _Action action;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: action.onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(color: action.color, borderRadius: BorderRadius.circular(13)),
            alignment: Alignment.center,
            child: action.leading ?? Icon(action.icon, color: Colors.white, size: 25),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(action.title, style: AppText.title(15.5)),
                    if (action.secondary != null)
                      Flexible(
                        child: Text(
                          ' . ${action.secondary}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.label(12.5, color: AppColors.textMedium, weight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  action.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.label(12.5, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(color: AppColors.peach, shape: BoxShape.circle),
            child: const ForwardChevron(size: 22),
          ),
        ],
      ),
    );
  }
}
