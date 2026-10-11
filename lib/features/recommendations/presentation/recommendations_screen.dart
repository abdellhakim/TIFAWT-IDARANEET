import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../shared/components/opportunity_cover.dart';
import '../../../shared/components/ui.dart';
import '../../../shared/constants/communes.dart';
import '../../../shared/utils/dates.dart';
import '../../auth/application/auth_controller.dart';
import '../../profile/application/profile_controller.dart';
import '../../progress/application/journey_controller.dart';
import '../application/recommendation_providers.dart';
import '../domain/opportunity_query.dart';
import '../domain/recommendation.dart';
import 'match_explanation.dart';

class RecommendationsScreen extends ConsumerStatefulWidget {
  const RecommendationsScreen({super.key, this.query = const OpportunityQuery()});
  final OpportunityQuery query;

  @override
  ConsumerState<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends ConsumerState<RecommendationsScreen> {
  late OpportunityQuery _query = widget.query;
  bool _showWeights = false;
  DateTime? _computedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final user = ref.read(authProvider);
      if (user == null) return;
      await RecommendationCache.store(user.id, ref.read(recommendationsProvider));
      if (mounted) setState(() => _computedAt = RecommendationCache.computedAt(user.id));
      await ref.read(journeyProvider.notifier).recordOrientation();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final profile = ref.watch(profileProvider);
    final items = _query.isEmpty || profile == null
        ? ref.watch(recommendationsProvider)
        : [
            for (final r in ref.watch(rankedProvider))
              if (r.score >= 40 && _query.matches(r, profile)) r,
          ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(
              title: s.recoTitle,
              action: SquareIconButton(
                icon: Icons.tune_rounded,
                tooltip: s.howComputed,
                onTap: () => setState(() => _showWeights = !_showWeights),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                children: [
                  Row(
                    children: [
                      const Icon(Icons.offline_bolt_rounded, size: 16, color: AppColors.olive),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _computedAt == null
                              ? s.recoSubtitle
                              : '${s.recoSubtitle} · ${s.recoUpdated('${Dates.dayMonth(_computedAt!, s.isAr)} ${Dates.time(_computedAt!)}')}',
                          style: AppText.label(12.5),
                        ),
                      ),
                    ],
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    child: _showWeights ? _WeightsPanel(s: s) : const SizedBox(width: double.infinity),
                  ),
                  if (!_query.isEmpty) ...[
                    const SizedBox(height: 12),
                    _QueryBar(
                      query: _query,
                      s: s,
                      onClear: () => setState(() => _query = const OpportunityQuery()),
                    ),
                  ],
                  const SizedBox(height: 14),
                  if (items.isEmpty)
                    EmptyState(icon: Icons.travel_explore_rounded, title: s.noRecommendations)
                  else
                    for (final (i, r) in items.indexed) ...[
                      _RecommendationTile(recommendation: r, s: s, initiallyOpen: i == 0),
                      const SizedBox(height: 14),
                    ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeightsPanel extends StatelessWidget {
  const _WeightsPanel({required this.s});
  final AppStrings s;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: AppCard(
      shadow: false,
      color: AppColors.sand.withValues(alpha: .5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.howComputed, style: AppText.title(15)),
          const SizedBox(height: 4),
          Text(s.howComputedBody, style: AppText.label(13)),
          const SizedBox(height: 12),
          for (final (i, label) in s.weightLabels.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                children: [
                  SizedBox(
                    width: 92,
                    child: Text(label, style: AppText.label(13, color: AppColors.textDark)),
                  ),
                  Expanded(
                    child: SoftProgressBar(
                      value: MatchBreakdown.weights[i] / 25,
                      color: AppColors.terracotta,
                      height: 7,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    s.percent(MatchBreakdown.weights[i]),
                    style: AppText.title(13, color: AppColors.terracotta),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}

class _QueryBar extends StatelessWidget {
  const _QueryBar({required this.query, required this.s, required this.onClear});
  final OpportunityQuery query;
  final AppStrings s;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final chips = [
      if (query.scope != QueryScope.all) query.scope.chipType?.label(s.isAr) ?? query.scope.label(s.isAr),
      if (query.interest != null) query.interest!.label(s.isAr),
      if (query.nearOnly) s.nearYou,
      if (query.freeOnly) s.free,
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
      decoration: BoxDecoration(color: AppColors.oliveMist, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          const Icon(Icons.chat_bubble_rounded, size: 16, color: AppColors.olive),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${s.fromYourQuestion} : ${chips.join(' · ')}',
              style: AppText.label(13, color: AppColors.oliveDark, weight: FontWeight.w700),
            ),
          ),
          TextButton(onPressed: onClear, child: Text(s.showAll)),
        ],
      ),
    );
  }
}

class _RecommendationTile extends StatefulWidget {
  const _RecommendationTile({required this.recommendation, required this.s, required this.initiallyOpen});
  final Recommendation recommendation;
  final AppStrings s;
  final bool initiallyOpen;

  @override
  State<_RecommendationTile> createState() => _RecommendationTileState();
}

class _RecommendationTileState extends State<_RecommendationTile> {
  late bool _open = widget.initiallyOpen;

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final r = widget.recommendation;
    final o = r.opportunity;
    final place = o.province == null ? s.online : communeLabel(o.commune, s.isAr);

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 58,
                child: OpportunityCover(
                  imageKey: o.imageKey,
                  height: 58,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.l(o.title), style: AppText.heading(15.5)),
                    Text(o.organization, style: AppText.label(12.5, color: AppColors.textMuted)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              MatchRing(score: r.score, size: 54),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _Fact(icon: Icons.place_rounded, label: s.placeLabel, value: place),
              _Fact(icon: Icons.school_rounded, label: s.levelLabel, value: o.requiredLevel.label(s.isAr)),
              _Fact(icon: Icons.category_rounded, label: s.typeLabel, value: o.type.label(s.isAr)),
              _Fact(icon: Icons.schedule_rounded, label: s.durationLabel, value: s.duration(o.durationWeeks)),
            ],
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () => setState(() => _open = !_open),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Text(s.whyThis, style: AppText.title(14, color: AppColors.olive)),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: _open ? .5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.expand_more_rounded, color: AppColors.olive, size: 20),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            child: _open
                ? MatchExplanation(recommendation: r, strings: s, dense: true)
                : const SizedBox(width: double.infinity),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
            onPressed: () => context.push(Routes.opportunity(o.id)),
            child: Text(s.viewOpportunity),
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 15, color: AppColors.terracotta),
      const SizedBox(width: 4),
      Text('$label : ', style: AppText.label(12.5, color: AppColors.textMuted)),
      Text(
        value,
        style: AppText.label(12.5, color: AppColors.textDark, weight: FontWeight.w800),
      ),
    ],
  );
}
