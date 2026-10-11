import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/connectivity/network_manager.dart';
import '../../../core/localization/app_language.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/router/app_router.dart';
import '../../../core/storage/demo_seed.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../shared/components/brand.dart';
import '../../../shared/components/ui.dart';
import '../../../shared/utils/dates.dart';
import '../../auth/application/auth_controller.dart';
import '../../badges/application/badge_controller.dart';
import '../../profile/application/documents_controller.dart';
import '../../profile/application/profile_controller.dart';
import '../../progress/application/journey_controller.dart';
import '../../assistant/application/assistant_controller.dart';
import '../../opportunities/application/opportunity_providers.dart';
import '../../synchronization/application/sync_manager.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final language = ref.watch(localeProvider);
    final network = ref.watch(networkProvider);
    final sync = ref.watch(syncProvider);
    final isDemo = ref.watch(authProvider.notifier).isDemoUser;
    final pending = ref.read(syncProvider.notifier).pendingOperations();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(title: s.settingsTitle),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                children: [
                  _Title(s.languageLabel),
                  AppCard(
                    padding: const EdgeInsets.all(6),
                    child: Row(
                      children: [
                        for (final lang in AppLanguage.values)
                          Expanded(
                            child: Material(
                              color: language == lang ? AppColors.terracotta : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => ref.read(localeProvider.notifier).set(lang),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  child: Text(
                                    lang.label,
                                    textAlign: TextAlign.center,
                                    style: AppText.title(
                                      14.5,
                                      color: language == lang ? Colors.white : AppColors.textMedium,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  _Title(s.syncLabel),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _KeyValue(
                          label: s.syncLabel,
                          value: !network.isOnline
                              ? s.offlineTitle
                              : (sync.pending == 0 ? s.allSynced : s.pending(sync.pending)),
                          valueColor: sync.pending == 0 && network.isOnline
                              ? AppColors.success
                              : AppColors.sandText,
                        ),
                        _KeyValue(
                          label: s.lastSyncLabel,
                          value: sync.lastSyncAt == null
                              ? s.never
                              : '${Dates.dayMonth(sync.lastSyncAt!, s.isAr)} · ${Dates.time(sync.lastSyncAt!)}',
                        ),
                        _KeyValue(
                          label: s.serverLabel,
                          value: ApiConfig.enabled ? ApiConfig.baseUrl : s.serverDemo,
                          ltr: ApiConfig.enabled,
                        ),
                        if (pending.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          for (final op in pending.take(6))
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Directionality(
                                textDirection: TextDirection.ltr,
                                child: Row(
                                  children: [
                                    const Icon(Icons.schedule_rounded, size: 14, color: AppColors.amber),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        '${op.entity} · ${op.operation}',
                                        style: AppText.label(12, color: AppColors.textDark),
                                      ),
                                    ),
                                    Text(
                                      Dates.time(op.timestamp),
                                      style: AppText.label(11.5, color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (pending.length > 6)
                            Text(
                              '+${pending.length - 6}',
                              style: AppText.label(12, color: AppColors.textMuted),
                            ),
                        ],
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.olive,
                            minimumSize: const Size.fromHeight(46),
                          ),
                          onPressed: network.isOnline ? () => ref.read(syncProvider.notifier).flush() : null,
                          icon: const Icon(Icons.sync_rounded, size: 20),
                          label: Text(s.syncNow),
                        ),
                      ],
                    ),
                  ),
                  _Title(s.demoSection),
                  AppCard(
                    padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
                    child: Column(
                      children: [
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: network.simulatedOffline,
                          onChanged: (v) => ref.read(networkProvider.notifier).setSimulatedOffline(v),
                          title: Text(s.simulateOffline, style: AppText.title(14.5)),
                          subtitle: Text(s.simulateOfflineHint, style: AppText.label(12)),
                        ),
                        if (isDemo) ...[
                          const Divider(height: 1),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.restart_alt_rounded, color: AppColors.terracotta),
                            title: Text(s.resetDemo, style: AppText.title(14.5)),
                            onTap: () => _resetDemo(context, ref, s),
                          ),
                        ],
                      ],
                    ),
                  ),
                  _Title(s.privacySection),
                  AppCard(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.visibility_outlined, color: AppColors.olive),
                          title: Text(s.viewData, style: AppText.title(14.5)),
                          onTap: () => _showData(context, ref, s),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                          title: Text(s.deleteData, style: AppText.title(14.5, color: AppColors.danger)),
                          onTap: () => _deleteData(context, ref, s),
                        ),
                        const SizedBox(height: 6),
                        Text(s.legalNote, style: AppText.label(12, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  _Title(s.aboutSection),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const TifawtLogoTile(size: 46),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('TIFAWT 1.1', style: AppText.title(15)),
                                  Text(s.tagline, style: AppText.label(12.5)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(s.aboutBody, style: AppText.label(13, color: AppColors.textDark)),
                        const SizedBox(height: 14),
                        const AmazighBand(),
                        const SizedBox(height: 12),
                        Text(s.roadmap, style: AppText.title(14)),
                        const SizedBox(height: 6),
                        for (final item in s.roadmapItems)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.radio_button_unchecked_rounded,
                                  size: 14,
                                  color: AppColors.amber,
                                ),
                                const SizedBox(width: 8),
                                Expanded(child: Text(item, style: AppText.label(13))),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger, width: 1.4),
                    ),
                    onPressed: () => _logout(context, ref, s),
                    icon: const Icon(Icons.logout_rounded),
                    label: Text(s.logout),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirm(
    BuildContext context,
    AppStrings s,
    String title,
    String body, {
    bool danger = false,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: Text(title, style: AppText.heading(18)),
          content: Text(body, style: AppText.paragraph()),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialog, false), child: Text(s.cancel)),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: danger ? AppColors.danger : AppColors.terracotta),
              onPressed: () => Navigator.pop(dialog, true),
              child: Text(s.confirm),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _resetDemo(BuildContext context, WidgetRef ref, AppStrings s) async {
    if (!await _confirm(context, s, s.resetDemo, s.resetDemoConfirm)) return;
    await DemoSeed.reset();
    ref
      ..invalidate(profileProvider)
      ..invalidate(journeyProvider)
      ..invalidate(badgesProvider)
      ..invalidate(favoritesProvider)
      ..invalidate(documentsProvider)
      ..invalidate(chatProvider);
    scaffoldMessengerKey.currentState?.showSnackBar(SnackBar(content: Text(s.resetDone)));
    if (context.mounted) context.go(Routes.onboardingProfile);
  }

  void _showData(BuildContext context, WidgetRef ref, AppStrings s) {
    final data = {
      'user': ref.read(authProvider)?.toJson(),
      'profile': ref.read(profileProvider)?.toJson(),
      'journey': ref.read(journeyProvider).toJson(),
      'badges': {for (final e in ref.read(badgesProvider).entries) e.key.code: e.value.toIso8601String()},
      'favorites': ref.read(favoritesProvider).toList(),
    };
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .7,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: [
            Text(s.viewData, style: AppText.heading(18)),
            const SizedBox(height: 10),
            Directionality(
              textDirection: TextDirection.ltr,
              child: SelectableText(
                const JsonEncoder.withIndent('  ').convert(data),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteData(BuildContext context, WidgetRef ref, AppStrings s) async {
    if (!await _confirm(context, s, s.deleteData, s.deleteDataConfirm, danger: true)) return;
    await ref.read(authProvider.notifier).deleteAccount();
    if (context.mounted) context.go(Routes.welcome);
  }

  Future<void> _logout(BuildContext context, WidgetRef ref, AppStrings s) async {
    if (!await _confirm(context, s, s.logout, s.logoutConfirm)) return;
    await ref.read(authProvider.notifier).logout();
    if (context.mounted) context.go(Routes.welcome);
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 22, bottom: 10),
    child: Text(text, style: AppText.heading(17)),
  );
}

class _KeyValue extends StatelessWidget {
  const _KeyValue({
    required this.label,
    required this.value,
    this.valueColor = AppColors.textDark,
    this.ltr = false,
  });
  final String label;
  final String value;
  final Color valueColor;
  final bool ltr;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: AppText.label(13, color: AppColors.textMuted)),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            textDirection: ltr ? TextDirection.ltr : null,
            style: AppText.title(13, color: valueColor),
          ),
        ),
      ],
    ),
  );
}
