import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/locale_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../shared/components/ui.dart';
import '../../../shared/constants/communes.dart';
import '../../auth/application/auth_controller.dart';
import '../application/profile_controller.dart';

class ProfileViewScreen extends ConsumerWidget {
  const ProfileViewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final user = ref.watch(authProvider);
    final p = ref.watch(profileProvider);
    final sep = s.isAr ? '، ' : ', ';

    List<Widget> section(String title, List<(String, String)> rows) => [
      const SizedBox(height: 18),
      SectionTitle(title, size: 16.5),
      const SizedBox(height: 8),
      AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          children: [
            for (final (i, (label, value)) in rows.indexed) ...[
              if (i > 0) const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 11),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(label, style: AppText.label(13, color: AppColors.textMuted)),
                    ),
                    Expanded(
                      flex: 5,
                      child: Text(
                        value.isEmpty ? s.none : value,
                        textAlign: TextAlign.end,
                        style: AppText.title(13.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(
              title: s.myProfile,
              action: SquareIconButton(
                icon: Icons.edit_rounded,
                tooltip: s.edit,
                onTap: () => context.push(Routes.profileEdit),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                children: [
                  AppCard(
                    child: Row(
                      children: [
                        UserAvatar(name: user?.displayName(s.isAr) ?? '', size: 60),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user?.displayName(s.isAr) ?? '', style: AppText.heading(18)),
                              Text(
                                user?.email ?? user?.phone ?? '',
                                textDirection: TextDirection.ltr,
                                style: AppText.label(13, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (p != null) ...[
                    ...section(s.sectionGeneral, [
                      (s.sex, p.sex.label(s.isAr)),
                      (s.age, s.yearsOld(p.age)),
                      (s.province, p.province.label(s.isAr)),
                      (s.commune, communeLabel(p.commune, s.isAr)),
                      (s.situation, p.situation.label(s.isAr)),
                    ]),
                    ...section(s.sectionEducation, [
                      (s.education, p.education.label(s.isAr)),
                      (s.lastDiploma, p.lastDiploma.label(s.isAr)),
                      (s.vocational, p.vocationalTraining),
                    ]),
                    ...section(s.sectionObjective, [(s.objective, p.objective.label(s.isAr))]),
                    ...section(s.sectionInterests, [
                      (s.interests, [for (final i in p.interests) i.label(s.isAr)].join(sep)),
                      (s.skills, [for (final k in p.skills) k.label(s.isAr)].join(sep)),
                    ]),
                    ...section(s.sectionConstraints, [
                      (s.mobility, p.mobility.label(s.isAr)),
                      (s.internet, p.internetAccess.label(s.isAr)),
                      (s.connection, p.connectionType.label(s.isAr)),
                      (s.availability, p.availability.label(s.isAr)),
                      (s.modalityPref, p.modality.label(s.isAr)),
                    ]),
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
