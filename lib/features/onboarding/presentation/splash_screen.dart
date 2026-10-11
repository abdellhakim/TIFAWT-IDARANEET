import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../shared/components/brand.dart';
import '../../auth/application/auth_controller.dart';
import '../../profile/application/profile_controller.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
    ..forward();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1700), _route);
  }

  void _route() {
    if (!mounted) return;
    if (ref.read(authProvider) == null) {
      context.go(Routes.welcome);
    } else if (!(ref.read(profileProvider)?.completed ?? false)) {
      context.go(Routes.onboardingProfile);
    } else {
      context.go(Routes.home);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rise = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    final fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(.4, 1, curve: Curves.easeOut),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.terracotta,
        body: Stack(
          children: [
            Center(
              child: FadeTransition(
                opacity: rise,
                child: ScaleTransition(
                  scale: Tween(begin: .92, end: 1.0).animate(rise),
                  child: const TifawtLogo(height: 150, color: Colors.white),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 28 + MediaQuery.paddingOf(context).bottom,
              child: FadeTransition(
                opacity: fade,
                child: Text(
                  'IDARANEET · Souss-Massa',
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.ltr,
                  style: AppText.label(
                    12,
                    color: Colors.white.withValues(alpha: .75),
                  ).copyWith(letterSpacing: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
