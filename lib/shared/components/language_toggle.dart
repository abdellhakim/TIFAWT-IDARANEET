import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_language.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';

/// Compact "ع | FR" switch.
class LanguageToggle extends ConsumerWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localeProvider);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (lang, label) in const [(AppLanguage.arabic, 'ع'), (AppLanguage.french, 'FR')])
              Semantics(
                button: true,
                selected: current == lang,
                label: lang.label,
                excludeSemantics: true,
                onTap: () => ref.read(localeProvider.notifier).set(lang),
                child: GestureDetector(
                  onTap: () => ref.read(localeProvider.notifier).set(lang),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: current == lang ? AppColors.terracotta : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      label,
                      style: AppText.label(
                        13,
                        color: current == lang ? Colors.white : AppColors.textMedium,
                        weight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
