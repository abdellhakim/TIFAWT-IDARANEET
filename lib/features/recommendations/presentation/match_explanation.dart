import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../shared/constants/communes.dart';
import '../../../shared/utils/dates.dart';
import '../domain/recommendation.dart';

String reasonText(MatchReason r, AppStrings s) {
  final sep = s.isAr ? '، ' : ', ';
  return switch (r.kind) {
    ReasonKind.objective => s.reasonObjective(r.objective!),
    ReasonKind.interests => s.reasonInterests([for (final i in r.interests) i.label(s.isAr)].join(sep)),
    ReasonKind.level => s.reasonLevel,
    ReasonKind.zone => s.reasonZone(communeLabel(r.commune ?? '', s.isAr)),
    ReasonKind.remote => s.reasonRemote,
    ReasonKind.skills => s.reasonSkills([for (final k in r.skills) k.label(s.isAr)].join(sep)),
    ReasonKind.lowInternet => s.reasonLowInternet,
  };
}

String warningText(MatchWarning w, AppStrings s) => switch (w.kind) {
  WarningKind.travel => s.warnTravel(w.province!.label(s.isAr)),
  WarningKind.internet => s.warnInternet,
  WarningKind.level => s.warnLevel(w.level!.label(s.isAr)),
  WarningKind.age => s.warnAge(w.ageMin!, w.ageMax!),
  WarningKind.deadline => s.warnDeadline(Dates.dayMonth(w.deadline!, s.isAr)),
};

/// Bullet list of reasons (✓) and points of attention (!).
class MatchExplanation extends StatelessWidget {
  const MatchExplanation({
    super.key,
    required this.recommendation,
    required this.strings,
    this.dense = false,
  });
  final Recommendation recommendation;
  final AppStrings strings;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final s = strings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final r in recommendation.reasons)
          _Line(
            icon: Icons.check_circle_rounded,
            color: AppColors.olive,
            text: reasonText(r, s),
            dense: dense,
          ),
        if (recommendation.warnings.isNotEmpty) ...[
          SizedBox(height: dense ? 4 : 8),
          Text(
            s.toNote,
            style: AppText.label(12, color: AppColors.textMuted, weight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          for (final w in recommendation.warnings)
            _Line(icon: Icons.error_rounded, color: AppColors.amber, text: warningText(w, s), dense: dense),
        ],
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.color, required this.text, required this.dense});
  final IconData icon;
  final Color color;
  final String text;
  final bool dense;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: dense ? 2 : 3.5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 17, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: AppText.label(dense ? 13 : 14, color: AppColors.textDark)),
        ),
      ],
    ),
  );
}
