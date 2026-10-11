import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/connectivity/network_manager.dart';
import 'core/localization/locale_provider.dart';
import 'core/network/api_client.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/badges/application/badge_controller.dart';
import 'features/badges/domain/badge.dart';
import 'features/badges/presentation/badge_widgets.dart';
import 'features/opportunities/application/opportunity_providers.dart';
import 'features/synchronization/application/sync_manager.dart';
import 'features/synchronization/presentation/sync_banner.dart';

class TifawtApp extends ConsumerWidget {
  const TifawtApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(localeProvider);
    return MaterialApp.router(
      title: 'TIFAWT',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: ref.watch(routerProvider),
      scaffoldMessengerKey: scaffoldMessengerKey,
      locale: language.locale,
      supportedLocales: const [Locale('ar'), Locale('fr')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => _AppFrame(child: child ?? const SizedBox()),
    );
  }
}

/// Wraps every screen: connectivity/sync banner on top, offline snackbars
/// and badge toasts.
class _AppFrame extends ConsumerStatefulWidget {
  const _AppFrame({required this.child});
  final Widget child;

  @override
  ConsumerState<_AppFrame> createState() => _AppFrameState();
}

class _AppFrameState extends ConsumerState<_AppFrame> {
  final _subs = <StreamSubscription<Object>>[];

  @override
  void initState() {
    super.initState();
    _subs.add(ref.read(syncProvider.notifier).notices.listen(_onNotice));
    _subs.add(ref.read(badgesProvider.notifier).unlocked.listen(_onBadge));
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }

  void _onNotice(SyncNotice notice) {
    final s = ref.read(stringsProvider);
    scaffoldMessengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 4),
          content: Row(
            children: [
              const Icon(Icons.cloud_off_rounded, color: Color(0xFFE59A2F), size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${s.savedOffline}\n',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      TextSpan(text: s.savedOfflineBody),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  void _onBadge(BadgeType badge) {
    // Let the action's own feedback show first.
    Future.delayed(const Duration(milliseconds: 900), () {
      final overlay = rootNavigatorKey.currentState?.overlay;
      if (overlay != null && mounted) showBadgeToast(overlay, badge, ref.read(stringsProvider));
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);

    // Pull a fresher catalog after each successful sync with the real API.
    ref.listen(syncProvider.select((st) => st.phase), (previous, phase) async {
      if (phase == SyncPhase.done && ApiConfig.enabled && ref.read(isOnlineProvider)) {
        final ok = await ref.read(opportunityRepositoryProvider).refresh(ApiClient(ApiConfig.baseUrl));
        if (ok) ref.read(catalogVersionProvider.notifier).state++;
      }
    });

    return Directionality(
      textDirection: s.isAr ? TextDirection.rtl : TextDirection.ltr,
      child: SyncBannerFrame(child: widget.child),
    );
  }
}
