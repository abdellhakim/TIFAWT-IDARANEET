import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/locale_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/storage/demo_seed.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../shared/components/brand.dart';
import '../../../shared/components/language_toggle.dart';
import '../../../shared/components/ui.dart';
import '../../profile/application/profile_controller.dart';
import '../application/auth_controller.dart';
import '../data/auth_repository.dart';
import 'auth_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  void _fillDemo() {
    _identifier.text = DemoSeed.phone;
    _password.text = DemoSeed.password;
    setState(() => _error = null);
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authProvider.notifier).login(_identifier.text, _password.text);
      if (!mounted) return;
      final completed = ref.read(profileProvider)?.completed ?? false;
      context.go(completed ? Routes.home : Routes.onboardingProfile);
    } on AuthException {
      setState(() => _error = ref.read(stringsProvider).errWrongCredentials);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);

    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            children: [
              Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  children: [
                    BackSquare(onTap: () => context.canPop() ? context.pop() : context.go(Routes.welcome)),
                    const Spacer(),
                    const LanguageToggle(),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              const Center(child: TifawtLogo(height: 92)),
              const SizedBox(height: 18),
              Text(
                s.loginTitle,
                textAlign: TextAlign.center,
                style: AppText.heading(25, color: AppColors.terracotta),
              ),
              const SizedBox(height: 4),
              Text(s.loginSubtitle, textAlign: TextAlign.center, style: AppText.label(14.5)),
              const SizedBox(height: 24),
              _DemoCard(onTap: _fillDemo),
              const SizedBox(height: 16),
              TextFormField(
                controller: _identifier,
                keyboardType: TextInputType.emailAddress,
                textDirection: TextDirection.ltr,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: s.identifier,
                  prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.textMuted),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return s.errRequired;
                  if (!Identifier.isValid(v)) return s.errIdentifier;
                  return null;
                },
              ),
              const SizedBox(height: 12),
              PasswordField(
                controller: _password,
                hint: s.password,
                onSubmitted: (_) => _submit(),
                validator: (v) => (v == null || v.isEmpty) ? s.errRequired : null,
              ),
              AuthErrorBanner(_error),
              const SizedBox(height: 22),
              ElevatedButton(
                onPressed: _busy ? null : _submit,
                child: BusyLabel(busy: _busy, label: s.login),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(s.noAccount, style: AppText.label(14)),
                  TextButton(
                    onPressed: () => context.pushReplacement(Routes.register),
                    child: Text(s.createAccount),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DemoCard extends ConsumerWidget {
  const _DemoCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return Material(
      color: AppColors.oliveMist,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              UserAvatar(name: s.isAr ? 'شهد' : 'Chahd', size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.demoAccount, style: AppText.title(14.5, color: AppColors.oliveDark)),
                    Text(s.demoAccountHint, style: AppText.label(12.5, color: AppColors.oliveDark)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        for (final (icon, value) in const [
                          (Icons.phone_iphone_rounded, DemoSeed.phone),
                          (Icons.alternate_email_rounded, DemoSeed.email),
                          (Icons.key_rounded, DemoSeed.password),
                        ])
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              textDirection: TextDirection.ltr,
                              children: [
                                Icon(icon, size: 12, color: AppColors.olive),
                                const SizedBox(width: 3),
                                Text(
                                  value,
                                  textDirection: TextDirection.ltr,
                                  style: AppText.label(
                                    11,
                                    color: AppColors.oliveDark,
                                    weight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.touch_app_rounded, color: AppColors.olive),
            ],
          ),
        ),
      ),
    );
  }
}
