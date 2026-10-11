import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/locale_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../shared/components/brand.dart';
import '../../../shared/components/language_toggle.dart';
import '../../../shared/components/ui.dart';
import '../application/auth_controller.dart';
import '../data/auth_repository.dart';
import 'auth_widgets.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  bool _consent = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final s = ref.read(stringsProvider);
    if (!_form.currentState!.validate()) return;
    if (!_consent) {
      setState(() => _error = s.errConsent);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(authProvider.notifier)
          .register(name: _name.text, identifier: _identifier.text, password: _password.text);
      if (mounted) context.go(Routes.onboardingProfile);
    } on AuthException {
      setState(() => _error = s.errAccountExists);
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
              const SizedBox(height: 20),
              const Align(alignment: AlignmentDirectional.centerStart, child: TifawtLogo(height: 76)),
              const SizedBox(height: 16),
              Text(s.registerTitle, style: AppText.heading(26, color: AppColors.terracotta)),
              Text(s.registerSubtitle, style: AppText.label(14.5)),
              const SizedBox(height: 26),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: s.fullName,
                  prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.textMuted),
                ),
                validator: (v) => (v == null || v.trim().length < 2) ? s.errRequired : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _identifier,
                keyboardType: TextInputType.emailAddress,
                textDirection: TextDirection.ltr,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: s.identifier,
                  prefixIcon: const Icon(Icons.alternate_email_rounded, color: AppColors.textMuted),
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
                validator: (v) {
                  if (v == null || v.isEmpty) return s.errRequired;
                  if (v.length < 6) return s.errPasswordShort;
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => setState(() => _consent = !_consent),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _consent,
                        activeColor: AppColors.olive,
                        onChanged: (v) => setState(() => _consent = v ?? false),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(s.consent, style: AppText.label(13)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AuthErrorBanner(_error),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _busy ? null : _submit,
                child: BusyLabel(busy: _busy, label: s.createAccount),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(s.haveAccount, style: AppText.label(14)),
                  TextButton(onPressed: () => context.pushReplacement(Routes.login), child: Text(s.login)),
                ],
              ),
              const SizedBox(height: 8),
              const _PrivacyLine(),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrivacyLine extends ConsumerWidget {
  const _PrivacyLine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.lock_rounded, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            s.t('المعطيات ديالك مشفرة فالتيليفون', 'Vos données sont chiffrées sur le téléphone'),
            style: AppText.label(12, color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }
}
