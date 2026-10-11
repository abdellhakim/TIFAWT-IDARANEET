import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/connectivity/network_manager.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../profile/application/profile_controller.dart';
import '../application/journey_controller.dart';
import '../domain/journey.dart';

/// Lets the youth move an opportunity forward (registered, in training...).
Future<void> showStatusSheet(BuildContext context, String opportunityId) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (_) => _StatusSheet(opportunityId: opportunityId),
);

class _StatusSheet extends ConsumerWidget {
  const _StatusSheet({required this.opportunityId});
  final String opportunityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final female = ref.watch(profileProvider)?.isFemale ?? true;
    final current = ref.watch(journeyProvider).applicationFor(opportunityId)?.status;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(s.updateStatus, style: AppText.heading(19)),
            const SizedBox(height: 12),
            for (final status in ApplicationStatus.values)
              _StatusRow(
                label: status.labelFor(s.isAr, female: female),
                reached: current != null && current.isAtLeast(status),
                isCurrent: current == status,
                onTap: () async {
                  Navigator.pop(context);
                  await ref.read(journeyProvider.notifier).updateStatus(opportunityId, status);
                  // Offline, the sync manager shows its own "saved offline" message.
                  if (ref.read(isOnlineProvider)) {
                    scaffoldMessengerKey.currentState?.showSnackBar(
                      SnackBar(
                        content: Text('${s.statusUpdated} · ${status.labelFor(s.isAr, female: female)}'),
                      ),
                    );
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.label,
    required this.reached,
    required this.isCurrent,
    required this.onTap,
  });
  final String label;
  final bool reached;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Material(
      color: isCurrent ? AppColors.oliveMist : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isCurrent ? AppColors.olive : AppColors.cardBorder),
          ),
          child: Row(
            children: [
              Icon(
                reached ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                color: reached ? AppColors.olive : AppColors.textMuted,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: AppText.title(15))),
            ],
          ),
        ),
      ),
    ),
  );
}
