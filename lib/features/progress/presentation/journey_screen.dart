import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/connectivity/network_manager.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../shared/components/opportunity_cover.dart';
import '../../../shared/components/ui.dart';
import '../../../shared/utils/dates.dart';
import '../../auth/application/auth_controller.dart';
import '../../badges/application/badge_controller.dart';
import '../../badges/domain/badge.dart';
import '../../badges/presentation/badge_widgets.dart';
import '../../opportunities/application/opportunity_providers.dart';
import '../../profile/application/documents_controller.dart';
import '../../profile/application/profile_controller.dart';
import '../../profile/domain/document_item.dart';
import '../../synchronization/application/sync_manager.dart';
import '../application/journey_controller.dart';
import '../domain/journey.dart';
import 'status_sheet.dart';

/// "المسار ديالي" — progression, badges, documents.
class JourneyScreen extends ConsumerWidget {
  const JourneyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final progress = ref.watch(journeyProgressProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(s.myPathTitle, style: AppText.heading(24, color: AppColors.terracotta)),
                ),
                SquareIconButton(
                  icon: Icons.settings_rounded,
                  color: AppColors.textDark,
                  tooltip: s.settingsTitle,
                  onTap: () => context.push(Routes.settings),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _IdentityCard(progress: progress),
            const SizedBox(height: 16),
            _ProgressCard(progress: progress),
            const SizedBox(height: 26),
            SectionTitle(s.timeline),
            const SizedBox(height: 12),
            _Timeline(progress: progress),
            const SizedBox(height: 26),
            SectionTitle(s.myOpportunity),
            const SizedBox(height: 12),
            const _MyOpportunity(),
            const SizedBox(height: 26),
            SectionTitle(s.badges),
            const SizedBox(height: 12),
            const _Badges(),
            const SizedBox(height: 26),
            SectionTitle(s.documents),
            const SizedBox(height: 4),
            Text(s.docHint, style: AppText.label(12.5, color: AppColors.textMuted)),
            const SizedBox(height: 12),
            const _Documents(),
          ],
        ),
      ),
    );
  }
}

class _IdentityCard extends ConsumerWidget {
  const _IdentityCard({required this.progress});
  final JourneyProgress progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final user = ref.watch(authProvider);
    final profile = ref.watch(profileProvider);
    final saved = ref.watch(favoritesProvider).length;
    final badges = ref.watch(badgesProvider).length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFBF4E26), AppColors.terracotta],
        ),
        boxShadow: const [BoxShadow(color: Color(0x33B5452C), blurRadius: 18, offset: Offset(0, 8))],
      ),
      child: Row(
        children: [
          UserAvatar(name: user?.displayName(s.isAr) ?? '', size: 82),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user?.displayName(s.isAr) ?? '', style: AppText.heading(19, color: Colors.white)),
                if (profile != null)
                  Text(
                    '${s.yearsOld(profile.age)} . ${profile.province.label(s.isAr)}',
                    style: AppText.label(13, color: Colors.white.withValues(alpha: .88)),
                  ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _Stat(value: s.percent(progress.percent), label: s.statProgress),
                    const SizedBox(width: 6),
                    _Stat(value: '$saved', label: s.statSaved),
                    const SizedBox(width: 6),
                    _Stat(value: '$badges', label: s.statBadges),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .17),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(value, style: AppText.title(14, color: Colors.white).copyWith(height: 1.2)),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.label(10, color: Colors.white.withValues(alpha: .9)),
          ),
        ],
      ),
    ),
  );
}

class _ProgressCard extends ConsumerWidget {
  const _ProgressCard({required this.progress});
  final JourneyProgress progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final sync = ref.watch(syncProvider);
    final online = ref.watch(isOnlineProvider);

    final synced = sync.pending == 0;
    final syncText = synced
        ? (sync.lastSyncAt == null ? s.synced : '${s.synced} · ${Dates.stamp(sync.lastSyncAt!, s.isAr)}')
        : s.pending(sync.pending);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                s.percent(progress.percent),
                style: AppText.heading(30, color: AppColors.olive).copyWith(height: 1),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${s.progressLabel} · ${s.progressOf(progress.done, progress.total)}',
                  style: AppText.label(13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SoftProgressBar(value: progress.percent / 100, color: AppColors.olive, height: 10),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                synced
                    ? Icons.cloud_done_rounded
                    : (online ? Icons.cloud_sync_rounded : Icons.cloud_off_rounded),
                size: 18,
                color: synced ? AppColors.success : AppColors.amber,
              ),
              const SizedBox(width: 8),
              Text(
                s.syncLabel,
                style: AppText.label(13, color: AppColors.textDark, weight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                syncText,
                style: AppText.label(
                  12.5,
                  color: synced ? AppColors.success : AppColors.sandText,
                  weight: FontWeight.w800,
                ),
              ),
              if (synced) ...[
                const SizedBox(width: 4),
                const Icon(Icons.check_rounded, size: 16, color: AppColors.success),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Timeline extends ConsumerWidget {
  const _Timeline({required this.progress});
  final JourneyProgress progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Column(
        children: [
          for (final step in progress.steps) ...[_StepRow(step: step, s: s), const SizedBox(height: 14)],
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: () => _showHistory(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(s.seeMore),
                  const ForwardChevron(size: 18, color: AppColors.terracotta),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showHistory(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _HistorySheet(),
  );
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step, required this.s});
  final JourneyStep step;
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    final done = step.state == JourneyStepState.done;
    final current = step.state == JourneyStepState.current;
    final statusLabel = switch (step.state) {
      JourneyStepState.done => s.stepDone,
      JourneyStepState.current => s.stepCurrent,
      JourneyStepState.pending => s.stepPending,
    };

    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? AppColors.olive : Colors.white,
            border: done ? null : Border.all(color: current ? AppColors.amber : AppColors.divider, width: 2),
          ),
          child: done
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 22)
              : Center(
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: current ? AppColors.amber : AppColors.divider,
                    ),
                  ),
                ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      step.id.label(s.isAr),
                      style: AppText.title(
                        14.5,
                        color: step.state == JourneyStepState.pending
                            ? AppColors.textMuted
                            : AppColors.textDark,
                      ),
                    ),
                  ),
                  Text(
                    statusLabel,
                    style: AppText.label(11.5, color: current ? AppColors.amber : AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SoftProgressBar(value: step.fill, color: done ? AppColors.olive : AppColors.amber),
            ],
          ),
        ),
      ],
    );
  }
}

class _MyOpportunity extends ConsumerWidget {
  const _MyOpportunity();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final primary = ref.watch(journeyProvider).primary;
    final female = ref.watch(profileProvider)?.isFemale ?? true;
    final o = primary == null ? null : ref.watch(opportunityProvider(primary.opportunityId));

    if (primary == null || o == null) {
      return AppCard(
        child: Column(
          children: [
            Text(s.noOpportunityYet, textAlign: TextAlign.center, style: AppText.label(14)),
            const SizedBox(height: 12),
            OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
              onPressed: () => context.push(Routes.recommendations),
              child: Text(s.cardRecommendations),
            ),
          ],
        ),
      );
    }

    return AppCard(
      onTap: () => context.push(Routes.opportunity(o.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SizedBox(
                width: 56,
                child: OpportunityCover(
                  imageKey: o.imageKey,
                  height: 56,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.l(o.title), style: AppText.heading(15)),
                    Text(o.organization, style: AppText.label(12.5, color: AppColors.textMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Tag(
                s.statusLine(primary.status.labelFor(s.isAr, female: female)),
                tone: TagTone.olive,
                icon: Icons.flag_rounded,
              ),
              const Spacer(),
              Text(
                Dates.stamp(primary.updatedAt, s.isAr),
                style: AppText.label(11.5, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.olive,
              minimumSize: const Size.fromHeight(46),
            ),
            onPressed: () => showStatusSheet(context, o.id),
            icon: const Icon(Icons.update_rounded, size: 20),
            label: Text(s.updateStatus),
          ),
        ],
      ),
    );
  }
}

class _Badges extends ConsumerWidget {
  const _Badges();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final earned = ref.watch(badgesProvider);
    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: BadgeType.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 4),
        itemBuilder: (_, i) {
          final badge = BadgeType.values[i];
          final has = earned.containsKey(badge);
          return SizedBox(
            width: 96,
            child: Column(
              children: [
                BadgeMedal(badge: badge, earned: has, size: 50),
                const SizedBox(height: 4),
                Text(
                  badge.label(s.isAr),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: AppText.label(
                    11,
                    color: has ? AppColors.textDark : AppColors.textMuted,
                    weight: FontWeight.w700,
                  ).copyWith(height: 1.25),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Documents extends ConsumerWidget {
  const _Documents();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final docs = ref.watch(documentsProvider);
    final missing = DocumentType.values.where((t) => !docs.any((d) => d.type == t)).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 20) / 3;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final (i, d) in docs.indexed)
              SizedBox(
                width: width,
                child: _DocTile(
                  item: d,
                  s: s,
                  tint: i.isEven ? AppColors.amberLight : AppColors.terracottaSoft,
                  onTap: () => ref.read(documentsProvider.notifier).toggle(d.type),
                ),
              ),
            if (missing.isNotEmpty)
              SizedBox(
                width: width,
                height: 118,
                child: DashedBorder(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => _pick(context, ref, missing, s),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_rounded, size: 34, color: AppColors.textDark),
                        const SizedBox(height: 6),
                        Text(
                          s.addDocument,
                          style: AppText.label(12, color: AppColors.textDark, weight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _pick(BuildContext context, WidgetRef ref, List<DocumentType> types, AppStrings s) =>
      showModalBottomSheet<void>(
        context: context,
        builder: (sheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(s.addDocument, style: AppText.heading(18)),
                const SizedBox(height: 8),
                for (final t in types)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.description_outlined, color: AppColors.terracotta),
                    title: Text(t.label(s.isAr), style: AppText.title(15)),
                    onTap: () {
                      Navigator.pop(sheet);
                      ref.read(documentsProvider.notifier).add(t);
                    },
                  ),
              ],
            ),
          ),
        ),
      );
}

class _DocTile extends StatelessWidget {
  const _DocTile({required this.item, required this.s, required this.tint, required this.onTap});
  final DocumentItem item;
  final AppStrings s;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: tint,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 118,
        child: Stack(
          children: [
            PositionedDirectional(
              top: 8,
              end: 8,
              child: Icon(
                item.ready ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                size: 18,
                color: item.ready ? AppColors.olive : AppColors.textMuted,
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.type == DocumentType.cin ? Icons.image_outlined : Icons.description_outlined,
                      size: 28,
                      color: AppColors.terracottaDark,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.type.label(s.isAr),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: AppText.label(
                        12,
                        color: AppColors.textDark,
                        weight: FontWeight.w800,
                      ).copyWith(height: 1.25),
                    ),
                    Text(
                      item.ready ? s.docReady : s.docToPrepare,
                      style: AppText.label(
                        10.5,
                        color: item.ready ? AppColors.oliveDark : AppColors.sandText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _HistorySheet extends ConsumerWidget {
  const _HistorySheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final journey = ref.watch(journeyProvider);
    final badges = ref.watch(badgesProvider);
    final female = ref.watch(profileProvider)?.isFemale ?? true;

    String title(String? id) {
      if (id == null) return '';
      final o = ref.read(opportunityProvider(id));
      return o == null ? '' : s.l(o.title);
    }

    final entries = <(DateTime, IconData, String)>[
      for (final e in journey.events)
        (
          e.at,
          switch (e.type) {
            JourneyEventType.profileCompleted => Icons.person_rounded,
            JourneyEventType.orientation => Icons.explore_rounded,
            JourneyEventType.opportunitySelected => Icons.flag_rounded,
            JourneyEventType.statusChanged => Icons.update_rounded,
          },
          switch (e.type) {
            JourneyEventType.profileCompleted => JourneyStepId.profile.label(s.isAr),
            JourneyEventType.orientation => s.t('شفتي التوصيات ديالك', 'Recommandations consultées'),
            JourneyEventType.opportunitySelected =>
              '${JourneyStepId.selection.label(s.isAr)} : ${title(e.opportunityId)}',
            JourneyEventType.statusChanged =>
              '${title(e.opportunityId)} → ${e.status?.labelFor(s.isAr, female: female) ?? ''}',
          },
        ),
      for (final MapEntry(key: badge, value: at) in badges.entries)
        (at, Icons.military_tech_rounded, '${s.badgeUnlocked} : ${badge.label(s.isAr)}'),
    ]..sort((a, b) => b.$1.compareTo(a.$1));

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .6,
      maxChildSize: .9,
      builder: (_, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        children: [
          Text(s.history, style: AppText.heading(19)),
          const SizedBox(height: 10),
          if (entries.isEmpty) EmptyState(icon: Icons.history_rounded, title: s.historyEmpty),
          for (final (at, icon, text) in entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(color: AppColors.peach, shape: BoxShape.circle),
                    child: Icon(icon, size: 18, color: AppColors.terracotta),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(text, style: AppText.label(13.5, color: AppColors.textDark)),
                  ),
                  const SizedBox(width: 8),
                  Text(Dates.stamp(at, s.isAr), style: AppText.label(11.5, color: AppColors.textMuted)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
