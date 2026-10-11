import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../shared/components/choices.dart';
import '../../../shared/components/language_toggle.dart';
import '../../../shared/components/ui.dart';
import '../../../shared/constants/communes.dart';
import '../../../shared/constants/enum_icons.dart';
import '../../../shared/models/profile_enums.dart';
import '../../../shared/models/user_profile.dart';
import '../../auth/application/auth_controller.dart';
import '../application/profile_controller.dart';

/// The questionnaire, in five short steps.
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key, this.onboarding = false});

  /// First completion right after login (vs. editing from "Mon profil").
  final bool onboarding;

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  static const _steps = 5;
  int _step = 0;
  late UserProfile _p;
  late final bool _isDraft;
  late final TextEditingController _vocational;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final existing = ref.read(profileProvider);
    _isDraft = existing != null && !existing.completed;
    _p = existing ?? UserProfile.empty(ref.read(authProvider)!.id);
    if (_p.commune.isEmpty) {
      _p = _p.copyWith(commune: communesByProvince[_p.province]!.first.fr);
    }
    _vocational = TextEditingController(text: _p.vocationalTraining);
  }

  @override
  void dispose() {
    _vocational.dispose();
    super.dispose();
  }

  void _set(UserProfile next) => setState(() {
    _p = next;
    _error = null;
  });

  Future<void> _next() async {
    final s = ref.read(stringsProvider);
    if (_step == 3 && _p.interests.isEmpty) {
      setState(() => _error = s.pickAtLeastOne);
      return;
    }
    if (_step < _steps - 1) {
      setState(() => _step++);
      return;
    }
    setState(() => _saving = true);
    await ref
        .read(profileProvider.notifier)
        .save(_p.copyWith(vocationalTraining: _vocational.text.trim()), complete: true);
    if (!mounted) return;
    widget.onboarding ? context.go(Routes.home) : context.pop();
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
    } else if (!widget.onboarding) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final canGoBack = _step > 0 || !widget.onboarding;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  children: [
                    if (canGoBack) BackSquare(onTap: _back) else const SizedBox(width: 44),
                    Expanded(
                      child: Text(
                        s.stepOf(_step + 1, _steps),
                        textAlign: TextAlign.center,
                        textDirection: s.isAr ? TextDirection.rtl : TextDirection.ltr,
                        style: AppText.label(13.5, weight: FontWeight.w700),
                      ),
                    ),
                    widget.onboarding ? const LanguageToggle() : const SizedBox(width: 44),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(
                children: [
                  for (var i = 0; i < _steps; i++)
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: i <= _step ? AppColors.terracotta : AppColors.peach,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                children: [
                  Text(
                    widget.onboarding ? s.setupTitle : s.editTitle,
                    style: AppText.heading(24, color: AppColors.terracotta),
                  ),
                  Text(s.setupSteps[_step], style: AppText.title(16, color: AppColors.textMedium)),
                  if (_isDraft && _step == 0) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.oliveMist,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.edit_note_rounded, color: AppColors.oliveDark),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(s.draftNotice, style: AppText.label(13, color: AppColors.oliveDark)),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: KeyedSubtree(
                      key: ValueKey(_step),
                      child: switch (_step) {
                        0 => _general(s),
                        1 => _education(s),
                        2 => _objective(s),
                        3 => _interests(s),
                        _ => _constraints(s),
                      },
                    ),
                  ),
                  if (_error != null)
                    Text(
                      _error!,
                      style: AppText.label(13.5, color: AppColors.danger, weight: FontWeight.w700),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: ElevatedButton(
                onPressed: _saving ? null : _next,
                child: _saving
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                      )
                    : Text(
                        _step == _steps - 1 ? (widget.onboarding ? s.finishSetup : s.saveChanges) : s.next,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _wrap(List<Widget> children) => Wrap(spacing: 8, runSpacing: 8, children: children);

  Widget _general(AppStrings s) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      FieldBlock(
        label: s.sex,
        child: Row(
          children: [
            for (final sex in Sex.values) ...[
              Expanded(
                child: PillChoice(
                  label: sex.label(s.isAr),
                  icon: sex == Sex.female ? Icons.female_rounded : Icons.male_rounded,
                  selected: _p.sex == sex,
                  color: AppColors.terracotta,
                  onTap: () => _set(_p.copyWith(sex: sex)),
                ),
              ),
              if (sex != Sex.values.last) const SizedBox(width: 10),
            ],
          ],
        ),
      ),
      FieldBlock(
        label: s.age,
        child: AppCard(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 4),
          child: Column(
            children: [
              Text(s.yearsOld(_p.age), style: AppText.heading(26, color: AppColors.terracotta)),
              Slider(
                value: _p.age.toDouble(),
                min: 15,
                max: 34,
                divisions: 19,
                label: '${_p.age}',
                onChanged: (v) => _set(_p.copyWith(age: v.round())),
              ),
            ],
          ),
        ),
      ),
      FieldBlock(
        label: s.province,
        child: Row(
          children: [
            for (final province in Province.values) ...[
              Expanded(
                child: RegionCard(
                  province: province,
                  selected: _p.province == province,
                  onTap: () =>
                      _set(_p.copyWith(province: province, commune: communesByProvince[province]!.first.fr)),
                ),
              ),
              if (province != Province.values.last) const SizedBox(width: 10),
            ],
          ],
        ),
      ),
      FieldBlock(
        label: s.commune,
        child: _wrap([
          for (final c in communesByProvince[_p.province]!)
            PillChoice(
              label: c.of(s.isAr),
              selected: _p.commune == c.fr,
              onTap: () => _set(_p.copyWith(commune: c.fr)),
            ),
        ]),
      ),
    ],
  );

  Widget _education(AppStrings s) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      FieldBlock(
        label: s.situation,
        child: Column(
          children: [
            for (final sit in CurrentSituation.values)
              ChoiceTile(
                label: sit.label(s.isAr),
                icon: situationIcon(sit),
                selected: _p.situation == sit,
                onTap: () => _set(_p.copyWith(situation: sit)),
              ),
          ],
        ),
      ),
      FieldBlock(
        label: s.education,
        child: _wrap([
          for (final level in EducationLevel.values)
            PillChoice(
              label: level.label(s.isAr),
              selected: _p.education == level,
              onTap: () => _set(_p.copyWith(education: level)),
            ),
        ]),
      ),
      FieldBlock(
        label: s.lastDiploma,
        child: _wrap([
          for (final d in Diploma.values)
            PillChoice(
              label: d.label(s.isAr),
              selected: _p.lastDiploma == d,
              color: AppColors.terracotta,
              onTap: () => _set(_p.copyWith(lastDiploma: d)),
            ),
        ]),
      ),
      FieldBlock(
        label: s.vocational,
        child: TextField(
          controller: _vocational,
          decoration: InputDecoration(hintText: s.vocationalHint),
        ),
      ),
    ],
  );

  Widget _objective(AppStrings s) => FieldBlock(
    label: s.objective,
    child: Column(
      children: [
        for (final o in Objective.values)
          ChoiceTile(
            label: o.label(s.isAr),
            icon: objectiveIcon(o),
            selected: _p.objective == o,
            onTap: () => _set(_p.copyWith(objective: o)),
          ),
      ],
    ),
  );

  Widget _interests(AppStrings s) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      FieldBlock(
        label: s.interests,
        hint: s.multiHint,
        child: _wrap([
          for (final i in Interest.values)
            PillChoice(
              label: i.label(s.isAr),
              icon: interestIcon(i),
              selected: _p.interests.contains(i),
              onTap: () => _set(
                _p.copyWith(
                  interests: _p.interests.contains(i)
                      ? (List.of(_p.interests)..remove(i))
                      : [..._p.interests, i],
                ),
              ),
            ),
        ]),
      ),
      FieldBlock(
        label: s.skills,
        hint: s.multiHint,
        child: _wrap([
          for (final sk in Skill.values)
            PillChoice(
              label: sk.label(s.isAr),
              icon: skillIcon(sk),
              color: AppColors.terracotta,
              selected: _p.skills.contains(sk),
              onTap: () => _set(
                _p.copyWith(
                  skills: _p.skills.contains(sk) ? (List.of(_p.skills)..remove(sk)) : [..._p.skills, sk],
                ),
              ),
            ),
        ]),
      ),
    ],
  );

  Widget _constraints(AppStrings s) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      FieldBlock(
        label: s.mobility,
        child: _wrap([
          for (final m in Mobility.values)
            PillChoice(
              label: m.label(s.isAr),
              icon: Icons.directions_walk_rounded,
              selected: _p.mobility == m,
              onTap: () => _set(_p.copyWith(mobility: m)),
            ),
        ]),
      ),
      FieldBlock(
        label: s.internet,
        child: _wrap([
          for (final a in InternetAccess.values)
            PillChoice(
              label: a.label(s.isAr),
              selected: _p.internetAccess == a,
              onTap: () => _set(_p.copyWith(internetAccess: a)),
            ),
        ]),
      ),
      FieldBlock(
        label: s.connection,
        child: _wrap([
          for (final c in ConnectionType.values)
            PillChoice(
              label: c.label(s.isAr),
              selected: _p.connectionType == c,
              onTap: () => _set(_p.copyWith(connectionType: c)),
            ),
        ]),
      ),
      FieldBlock(
        label: s.availability,
        child: _wrap([
          for (final a in Availability.values)
            PillChoice(
              label: a.label(s.isAr),
              selected: _p.availability == a,
              onTap: () => _set(_p.copyWith(availability: a)),
            ),
        ]),
      ),
      FieldBlock(
        label: s.modalityPref,
        child: _wrap([
          for (final m in ModalityPreference.values)
            PillChoice(
              label: m.label(s.isAr),
              selected: _p.modality == m,
              onTap: () => _set(_p.copyWith(modality: m)),
            ),
        ]),
      ),
    ],
  );
}
