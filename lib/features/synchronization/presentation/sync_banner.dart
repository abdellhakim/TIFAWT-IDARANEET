import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/connectivity/network_manager.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../application/sync_manager.dart';

/// Puts the connectivity / sync status above any screen:
/// Hors connexion → Connexion rétablie → Synchronisation en cours… → terminée.
class SyncBannerFrame extends ConsumerWidget {
  const SyncBannerFrame({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final online = ref.watch(isOnlineProvider);
    final sync = ref.watch(syncProvider);

    final phase = online ? sync.phase : SyncPhase.offline;
    final visible = phase != SyncPhase.idle;
    final media = MediaQuery.of(context);

    final (Color bg, Widget leading, String title, String? body) = switch (phase) {
      SyncPhase.offline => (
        const Color(0xFF8A5A2B),
        const Icon(Icons.cloud_off_rounded, color: Colors.white, size: 20),
        sync.pending > 0 ? '${s.offlineTitle} · ${s.pending(sync.pending)}' : s.offlineTitle,
        s.offlineBody,
      ),
      SyncPhase.reconnected => (
        AppColors.olive,
        const Icon(Icons.wifi_rounded, color: Colors.white, size: 20),
        s.reconnected,
        null,
      ),
      SyncPhase.syncing => (
        AppColors.olive,
        const SizedBox.square(
          dimension: 18,
          child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
        ),
        s.syncing,
        sync.inFlight > 0 ? s.syncingCount(sync.inFlight) : null,
      ),
      SyncPhase.done => (
        AppColors.success,
        const Icon(Icons.cloud_done_rounded, color: Colors.white, size: 20),
        s.syncDone,
        null,
      ),
      SyncPhase.failed => (
        AppColors.terracotta,
        const Icon(Icons.sync_problem_rounded, color: Colors.white, size: 20),
        s.syncFailed,
        null,
      ),
      SyncPhase.idle => (AppColors.olive, const SizedBox(), '', null),
    };

    return Material(
      color: AppColors.background,
      child: Column(
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            child: !visible
                ? const SizedBox(width: double.infinity)
                : AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    width: double.infinity,
                    color: bg,
                    padding: EdgeInsets.fromLTRB(16, media.padding.top + 8, 16, 10),
                    child: Semantics(
                      liveRegion: true,
                      child: Row(
                        children: [
                          leading,
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(title, style: AppText.title(13.5, color: Colors.white)),
                                if (body != null)
                                  Text(
                                    body,
                                    style: AppText.label(12, color: Colors.white.withValues(alpha: .9)),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          Expanded(
            child: MediaQuery(data: visible ? media.removePadding(removeTop: true) : media, child: child),
          ),
        ],
      ),
    );
  }
}
