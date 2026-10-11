import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../models/profile_enums.dart';

/// Province card with the corner check of the design.
class RegionCard extends StatelessWidget {
  const RegionCard({super.key, required this.province, required this.selected, required this.onTap});
  final Province province;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      height: 72,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: selected
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFC0532B), AppColors.terracottaDark],
              )
            : null,
        color: selected ? null : Colors.white,
        border: Border.all(color: selected ? AppColors.terracotta : AppColors.divider),
        boxShadow: selected
            ? const [BoxShadow(color: Color(0x33B5452C), blurRadius: 14, offset: Offset(0, 6))]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              Positioned(
                top: 7,
                left: 7,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? AppColors.amber : Colors.transparent,
                    border: selected ? null : Border.all(color: AppColors.textMuted.withValues(alpha: .5)),
                  ),
                  child: selected ? const Icon(Icons.check_rounded, size: 11, color: Colors.white) : null,
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      province.ar,
                      style: AppText.heading(
                        17,
                        color: selected ? Colors.white : AppColors.textDark,
                      ).copyWith(height: 1.2),
                    ),
                    Text(
                      province.fr.toUpperCase(),
                      style: AppText.label(
                        9.5,
                        color: selected ? Colors.white.withValues(alpha: .85) : AppColors.textMuted,
                        weight: FontWeight.w800,
                      ).copyWith(letterSpacing: 1.2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-width single choice with an icon (situation, objective...).
class ChoiceTile extends StatelessWidget {
  const ChoiceTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.subtitle,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: selected ? AppColors.terracottaSoft : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? AppColors.terracotta : AppColors.cardBorder,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                if (icon != null) ...[
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.terracotta : AppColors.peach,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(icon, size: 20, color: selected ? Colors.white : AppColors.terracotta),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: AppText.title(15)),
                      if (subtitle != null) Text(subtitle!, style: AppText.label(12.5)),
                    ],
                  ),
                ),
                Icon(
                  selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                  color: selected ? AppColors.terracotta : AppColors.textMuted,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pill chip for single or multiple choice.
class PillChoice extends StatelessWidget {
  const PillChoice({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.color = AppColors.olive,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: selected ? color : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: selected ? color : AppColors.cardBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 17, color: selected ? Colors.white : color),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: AppText.label(
                    13.5,
                    color: selected ? Colors.white : AppColors.textDark,
                    weight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Label + content block used by the questionnaire.
class FieldBlock extends StatelessWidget {
  const FieldBlock({super.key, required this.label, required this.child, this.hint});
  final String label;
  final String? hint;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: AppText.title(15.5))),
            if (hint != null) Text(hint!, style: AppText.label(12, color: AppColors.textMuted)),
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    ),
  );
}
