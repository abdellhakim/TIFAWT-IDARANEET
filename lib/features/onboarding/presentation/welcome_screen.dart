import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/locale_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../shared/components/brand.dart';
import '../../../shared/components/language_toggle.dart';

/// Welcome: what TIFAWT is, then "Se connecter" / "Créer un compte".
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final _pages = PageController();
  int _page = 0;
  Timer? _auto;

  @override
  void initState() {
    super.initState();
    _auto = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_pages.hasClients) return;
      _pages.animateToPage(
        (_page + 1) % 3,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _auto?.cancel();
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final slides = s.welcomeSlides;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Column(
          children: [
            Expanded(
              flex: 12,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.terracotta,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                ),
                child: const SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(20, 10, 20, 0),
                        child: Align(alignment: AlignmentDirectional.centerEnd, child: LanguageToggle()),
                      ),
                      Expanded(
                        child: Center(child: TifawtLogo(height: 150, color: Colors.white)),
                      ),
                      SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 10,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 16),
                  child: Column(
                    children: [
                      Text(
                        s.tagline,
                        textAlign: TextAlign.center,
                        style: AppText.heading(19, color: AppColors.textDark),
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: PageView.builder(
                          controller: _pages,
                          itemCount: slides.length,
                          onPageChanged: (i) => setState(() => _page = i),
                          itemBuilder: (_, i) => Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(slides[i].$1, textAlign: TextAlign.center, style: AppText.title(16)),
                              const SizedBox(height: 6),
                              Text(slides[i].$2, textAlign: TextAlign.center, style: AppText.paragraph()),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < slides.length; i++)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: i == _page ? 22 : 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: i == _page ? AppColors.terracotta : AppColors.peach,
                                borderRadius: BorderRadius.circular(7),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton(onPressed: () => context.push(Routes.login), child: Text(s.login)),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: () => context.push(Routes.register),
                        child: Text(s.createAccount),
                      ),
                    ],
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
