import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../shared/components/opportunity_cover.dart';
import '../../../shared/components/ui.dart';
import '../../../shared/constants/communes.dart';
import '../../../shared/constants/enum_icons.dart';
import '../../../shared/models/opportunity.dart';
import '../../../shared/utils/dates.dart';
import '../../profile/application/profile_controller.dart';
import '../../progress/application/journey_controller.dart';
import '../../progress/domain/journey.dart';
import '../../progress/presentation/status_sheet.dart';
import '../../recommendations/application/recommendation_providers.dart';
import '../../recommendations/presentation/match_explanation.dart';
import '../application/opportunity_providers.dart';
import 'opportunity_card.dart';

class OpportunityDetailScreen extends ConsumerWidget {
  const OpportunityDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final o = ref.watch(opportunityProvider(id));
    if (o == null) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              PageHeader(title: s.about),
              EmptyState(icon: Icons.search_off_rounded, title: s.noResults),
            ],
          ),
        ),
      );
    }
    final recommendation = ref.watch(recommendationForProvider(id));
    final saved = ref.watch(favoritesProvider).contains(id);
    final application = ref.watch(journeyProvider).applicationFor(id);
    final female = ref.watch(profileProvider)?.isFemale ?? true;

    return Scaffold(
      bottomNavigationBar: SafeArea(
        top: false,
        child: _BottomBar(
          application: application != null,
          statusLabel: application?.status.labelFor(s.isAr, female: female),
          interestedLabel: s.interested(female),
          s: s,
          onInterested: () async {
            await ref.read(journeyProvider.notifier).select(id);
            scaffoldMessengerKey.currentState
              ?..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(
                    '${s.addedToJourney}\n${s.statusLine(ApplicationStatus.interested.labelFor(s.isAr, female: female))}',
                  ),
                  action: SnackBarAction(
                    label: s.myPathTitle,
                    textColor: AppColors.amber,
                    onPressed: () => rootNavigatorKey.currentContext?.go(Routes.account),
                  ),
                ),
              );
          },
          onUpdate: () => showStatusSheet(context, id),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(
              title: o.type.label(s.isAr),
              action: SquareIconButton(
                icon: saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: AppColors.heart,
                onTap: () => ref.read(favoritesProvider.notifier).toggle(id),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  Stack(
                    children: [
                      OpportunityCover(
                        imageKey: o.imageKey,
                        height: 164,
                        borderRadius: const BorderRadius.all(Radius.circular(22)),
                      ),
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: _Pill(text: o.organization, icon: Icons.verified_rounded),
                      ),
                      Positioned(
                        left: 12,
                        bottom: 12,
                        child: _Pill(text: s.availableOffline, icon: Icons.offline_pin_rounded, muted: true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(s.l(o.title), style: AppText.heading(22)),
                  const SizedBox(height: 2),
                  Text('${o.organization} · ${s.l(o.place)}', style: AppText.label(13.5)),
                  const SizedBox(height: 10),
                  Wrap(spacing: 6, runSpacing: 6, children: opportunityTags(o, s)),
                  if (recommendation != null) ...[
                    const SizedBox(height: 18),
                    AppCard(
                      color: AppColors.oliveMist,
                      borderColor: const Color(0xFFDDE8C2),
                      shadow: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              MatchRing(score: recommendation.score, size: 58),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.compatibility,
                                      style: AppText.label(12.5, weight: FontWeight.w700),
                                    ),
                                    Text(s.whyThis, style: AppText.title(15.5)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          MatchExplanation(recommendation: recommendation, strings: s),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  _InfoGrid(o: o, s: s),
                  _Section(
                    title: s.about,
                    child: Text(s.l(o.description), style: AppText.paragraph()),
                  ),
                  if (o.accessConditions.of(s.isAr).isNotEmpty)
                    _Section(
                      title: s.accessConditions,
                      child: Column(
                        children: [
                          for (final c in o.accessConditions.of(s.isAr))
                            _Bullet(text: c, icon: Icons.task_alt_rounded),
                        ],
                      ),
                    ),
                  if (o.skills.isNotEmpty || o.interests.isNotEmpty)
                    _Section(
                      title: s.targetedSkills,
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final k in o.skills)
                            Tag(k.label(s.isAr), tone: TagTone.amber, icon: skillIcon(k)),
                          for (final i in o.interests)
                            Tag(i.label(s.isAr), tone: TagTone.neutral, icon: interestIcon(i)),
                        ],
                      ),
                    ),
                  if (o.program.of(s.isAr).isNotEmpty)
                    _Section(
                      title: s.program,
                      child: Column(
                        children: [
                          for (final (i, m) in o.program.of(s.isAr).indexed) _Module(index: i + 1, text: m),
                        ],
                      ),
                    ),
                  _Section(
                    title: s.contact,
                    child: _Contact(o: o, s: s),
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

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.icon, this.muted = false});
  final String text;
  final IconData icon;
  final bool muted;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: muted ? Colors.black.withValues(alpha: .35) : Colors.white,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: muted ? Colors.white : AppColors.olive),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppText.label(
            11.5,
            color: muted ? Colors.white : AppColors.terracottaDark,
            weight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.o, required this.s});
  final Opportunity o;
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    final commune = communeLabel(o.commune, s.isAr);
    final province = o.province?.label(s.isAr);
    final location = province == null
        ? s.online
        : (commune.isEmpty || commune == province ? province : '$commune${s.isAr ? '، ' : ', '}$province');
    final items = [
      (Icons.category_rounded, s.typeLabel, o.type.label(s.isAr)),
      (Icons.schedule_rounded, s.durationLabel, s.duration(o.durationWeeks)),
      (Icons.place_rounded, s.location, location),
      (Icons.devices_rounded, s.modalities, o.modality.label(s.isAr)),
      (
        Icons.event_rounded,
        s.deadline,
        o.deadline == null ? s.openAllYear : Dates.dayMonthYear(o.deadline!, s.isAr),
      ),
      (Icons.school_rounded, s.levelLabel, o.requiredLevel.label(s.isAr)),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final (icon, label, value) in items)
              SizedBox(
                width: width,
                child: AppCard(
                  padding: const EdgeInsets.all(12),
                  shadow: false,
                  child: Row(
                    children: [
                      Icon(icon, size: 20, color: AppColors.terracotta),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(label, style: AppText.label(11.5, color: AppColors.textMuted)),
                            Text(
                              value,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.title(13, color: AppColors.textDark),
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
      },
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [SectionTitle(title, size: 17), const SizedBox(height: 8), child],
    ),
  );
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text, required this.icon});
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.olive),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: AppText.label(14, color: AppColors.textDark)),
        ),
      ],
    ),
  );
}

class _Module extends StatelessWidget {
  const _Module({required this.index, required this.text});
  final int index;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: AppColors.peach, shape: BoxShape.circle),
          child: Text('$index', style: AppText.title(13, color: AppColors.terracotta)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: AppText.label(14, color: AppColors.textDark)),
        ),
      ],
    ),
  );
}

class _Contact extends StatelessWidget {
  const _Contact({required this.o, required this.s});
  final Opportunity o;
  final AppStrings s;

  Future<void> _open(Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication).catchError((_) => false);
    if (!ok) {
      scaffoldMessengerKey.currentState?.showSnackBar(SnackBar(content: Text(s.cannotOpenLink)));
    }
  }

  @override
  Widget build(BuildContext context) => AppCard(
    shadow: false,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.textMuted),
            const SizedBox(width: 8),
            Expanded(child: Text(s.officialNote, style: AppText.label(13))),
          ],
        ),
        if (o.contactPhone != null || o.externalUrl != null) const SizedBox(height: 12),
        Row(
          children: [
            if (o.contactPhone != null)
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
                  onPressed: () => _open(Uri(scheme: 'tel', path: o.contactPhone)),
                  icon: const Icon(Icons.call_rounded, size: 18),
                  label: Text(s.call),
                ),
              ),
            if (o.contactPhone != null && o.externalUrl != null) const SizedBox(width: 10),
            if (o.externalUrl != null)
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    foregroundColor: AppColors.olive,
                    side: const BorderSide(color: AppColors.olive, width: 1.4),
                  ),
                  onPressed: () => _open(Uri.parse(o.externalUrl!)),
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: Text(s.officialSite, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ),
          ],
        ),
      ],
    ),
  );
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.application,
    required this.statusLabel,
    required this.interestedLabel,
    required this.s,
    required this.onInterested,
    required this.onUpdate,
  });

  final bool application;
  final String? statusLabel;
  final String interestedLabel;
  final AppStrings s;
  final VoidCallback onInterested;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
    decoration: const BoxDecoration(
      color: Colors.white,
      boxShadow: [BoxShadow(color: Color(0x10000000), blurRadius: 16, offset: Offset(0, -4))],
    ),
    child: AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: !application
          ? ElevatedButton.icon(
              key: const ValueKey('cta'),
              onPressed: onInterested,
              icon: const Icon(Icons.favorite_rounded, size: 20),
              label: Text(interestedLabel),
            )
          : Row(
              key: const ValueKey('status'),
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(s.inYourJourney, style: AppText.label(12, color: AppColors.textMuted)),
                      Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: AppColors.olive, size: 18),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              statusLabel ?? '',
                              style: AppText.title(15.5, color: AppColors.oliveDark),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.olive,
                    minimumSize: const Size(0, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                  ),
                  onPressed: onUpdate,
                  child: Text(s.updateStatus),
                ),
              ],
            ),
    ),
  );
}
