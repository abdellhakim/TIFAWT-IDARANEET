import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../shared/components/opportunity_cover.dart';
import '../../../shared/components/ui.dart';
import '../../../shared/models/opportunity.dart';
import '../../../shared/models/profile_enums.dart';
import '../../recommendations/domain/recommendation_engine.dart';
import '../application/opportunity_providers.dart';

/// Tags shown under an opportunity: level, duration, price.
List<Widget> opportunityTags(Opportunity o, AppStrings s) => [
  Tag(
    o.requiredLevel == EducationLevel.none ? s.noDiploma : o.requiredLevel.label(s.isAr),
    tone: TagTone.olive,
  ),
  Tag(s.duration(o.durationWeeks), tone: TagTone.rose),
  Tag(o.isFree ? s.free : s.paid, tone: TagTone.sand),
  if (o.forWomen) Tag(s.filterWomen, tone: TagTone.amber),
];

class OpportunityCard extends ConsumerWidget {
  const OpportunityCard({super.key, required this.opportunity, required this.score, required this.onTap});

  final Opportunity opportunity;
  final int? score;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final saved = ref.watch(favoritesProvider).contains(opportunity.id);
    final recommended = (score ?? 0) >= RecommendationEngine.recommendedThreshold;

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              OpportunityCover(
                imageKey: opportunity.imageKey,
                height: 98,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: _HeartButton(
                  saved: saved,
                  onTap: () => ref.read(favoritesProvider.notifier).toggle(opportunity.id),
                ),
              ),
              Positioned(
                right: 10,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    textDirection: TextDirection.ltr,
                    children: [
                      Text(
                        opportunity.organization,
                        style: AppText.label(11.5, color: AppColors.terracottaDark, weight: FontWeight.w800),
                      ),
                      if (recommended) ...[
                        const SizedBox(width: 3),
                        const Icon(Icons.bolt_rounded, size: 15, color: AppColors.danger),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.l(opportunity.title), style: AppText.heading(16.5)),
                const SizedBox(height: 2),
                Text(
                  s.l(opportunity.summary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.label(12.5, color: AppColors.textMuted),
                ),
                const SizedBox(height: 10),
                Wrap(spacing: 6, runSpacing: 6, children: opportunityTags(opportunity, s)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeartButton extends StatelessWidget {
  const _HeartButton({required this.saved, required this.onTap});
  final bool saved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(10),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: SizedBox.square(
        dimension: 34,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
          child: Icon(
            saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            key: ValueKey(saved),
            color: AppColors.heart,
            size: 20,
          ),
        ),
      ),
    ),
  );
}
