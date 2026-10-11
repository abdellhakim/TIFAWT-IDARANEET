import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/locale_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../shared/components/ui.dart';
import '../../../shared/constants/enum_icons.dart';
import '../../../shared/models/opportunity.dart';
import '../../assistant/domain/intent_parser.dart';
import '../../recommendations/application/recommendation_providers.dart';
import '../../recommendations/domain/recommendation_engine.dart';
import '../application/opportunity_providers.dart';
import 'opportunity_card.dart';

enum _Filter { all, recommended, free, paid, women, saved }

class OpportunitiesScreen extends ConsumerStatefulWidget {
  const OpportunitiesScreen({super.key, this.initialQuery, this.initialType});

  /// Non-null opens the search field (empty string = just focus it).
  final String? initialQuery;
  final String? initialType;

  @override
  ConsumerState<OpportunitiesScreen> createState() => _OpportunitiesScreenState();
}

class _OpportunitiesScreenState extends ConsumerState<OpportunitiesScreen> {
  _Filter _filter = _Filter.all;
  OpportunityType? _type;
  late bool _searching = widget.initialQuery != null;
  late final _search = TextEditingController(text: widget.initialQuery ?? '');

  @override
  void initState() {
    super.initState();
    _type = OpportunityType.values.where((t) => t.name == widget.initialType).firstOrNull;
  }

  @override
  void didUpdateWidget(covariant OpportunitiesScreen old) {
    super.didUpdateWidget(old);
    if (widget.initialQuery != null && widget.initialQuery != old.initialQuery) {
      setState(() {
        _searching = true;
        _search.text = widget.initialQuery!;
      });
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matchesText(Opportunity o, String q) {
    if (q.isEmpty) return true;
    final haystack = IntentParser.normalize(
      '${o.title.ar} ${o.title.fr} ${o.summary.ar} ${o.summary.fr} ${o.organization} ${o.place.ar} ${o.place.fr} ${o.commune}',
    );
    return IntentParser.normalize(q).split(' ').every(haystack.contains);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final ranked = ref.watch(rankedProvider);
    final scores = {for (final r in ranked) r.opportunity.id: r.score};
    final favorites = ref.watch(favoritesProvider);
    final catalog = [...ref.watch(catalogProvider)]
      ..sort((a, b) => (scores[b.id] ?? -1).compareTo(scores[a.id] ?? -1));

    final visible = catalog.where((o) {
      final ok = switch (_filter) {
        _Filter.all => true,
        _Filter.recommended => (scores[o.id] ?? 0) >= RecommendationEngine.recommendedThreshold,
        _Filter.free => o.isFree,
        _Filter.paid => !o.isFree,
        _Filter.women => o.forWomen,
        _Filter.saved => favorites.contains(o.id),
      };
      return ok && (_type == null || o.type == _type) && _matchesText(o, _search.text);
    }).toList();

    final filters = [
      (_Filter.all, s.filterAll, null),
      (_Filter.recommended, s.filterRecommended, Icons.bolt_rounded),
      (_Filter.free, s.filterFree, null),
      (_Filter.paid, s.filterPaid, null),
      (_Filter.women, s.filterWomen, null),
      (_Filter.saved, s.filterSaved, Icons.favorite_rounded),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(
              title: s.opportunitiesTitle,
              onBack: () => context.go(Routes.home),
              action: SquareIconButton(
                icon: _searching ? Icons.close_rounded : Icons.search_rounded,
                onTap: () => setState(() {
                  _searching = !_searching;
                  if (!_searching) _search.clear();
                }),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: !_searching
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                      child: TextField(
                        controller: _search,
                        autofocus: true,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: s.searchHint,
                          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.terracotta),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  for (final (filter, label, icon) in filters)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: _FilterChip(
                        label: label,
                        icon: icon,
                        accent: filter == _Filter.recommended,
                        selected: _filter == filter,
                        onTap: () => setState(() => _filter = filter),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  for (final type in OpportunityType.values)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 6),
                      child: _TypeChip(
                        label: type.label(s.isAr),
                        icon: typeIcon(type),
                        selected: _type == type,
                        onTap: () => setState(() => _type = _type == type ? null : type),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: visible.isEmpty
                  ? ListView(
                      children: [
                        EmptyState(icon: Icons.search_off_rounded, title: s.noResults, body: s.noResultsHint),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                      itemCount: visible.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 16),
                      itemBuilder: (_, i) => OpportunityCard(
                        opportunity: visible[i],
                        score: scores[visible[i].id],
                        onTap: () => context.push(Routes.opportunity(visible[i].id)),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.accent = false,
  });

  final String label;
  final bool selected;
  final bool accent;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = accent ? AppColors.amber : (selected ? Colors.white : Colors.transparent);
    final fg = accent ? Colors.white : (selected ? AppColors.textDark : AppColors.textMedium);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: selected
              ? (accent ? AppColors.terracottaDark : const Color(0xFFD9D0C1))
              : AppColors.cardBorder,
          width: selected && accent ? 2 : 1,
        ),
        boxShadow: selected
            ? const [BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 3))]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(21),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: accent ? Colors.white : AppColors.heart),
                  const SizedBox(width: 4),
                ],
                Text(
                  label,
                  style: AppText.label(13.5, color: fg, weight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.label, required this.icon, required this.selected, required this.onTap});
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: selected ? AppColors.textDark : AppColors.track.withValues(alpha: .6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: selected ? Colors.white : AppColors.textMedium),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppText.label(
              12.5,
              color: selected ? Colors.white : AppColors.textMedium,
              weight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}
