import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';

class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.hint,
    this.validator,
    this.onSubmitted,
  });
  final TextEditingController controller;
  final String hint;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onSubmitted;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: widget.controller,
    obscureText: _obscure,
    validator: widget.validator,
    onFieldSubmitted: widget.onSubmitted,
    textInputAction: TextInputAction.done,
    decoration: InputDecoration(
      hintText: widget.hint,
      prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textMuted),
      suffixIcon: IconButton(
        onPressed: () => setState(() => _obscure = !_obscure),
        icon: Icon(
          _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: AppColors.textMuted,
        ),
      ),
    ),
  );
}

class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner(this.message, {super.key});
  final String? message;

  @override
  Widget build(BuildContext context) => AnimatedSize(
    duration: const Duration(milliseconds: 200),
    child: message == null
        ? const SizedBox(width: double.infinity)
        : Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 14),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: AppColors.roseTag, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message!,
                    style: AppText.label(13.5, color: AppColors.danger, weight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
  );
}

class BusyLabel extends StatelessWidget {
  const BusyLabel({super.key, required this.busy, required this.label});
  final bool busy;
  final String label;

  @override
  Widget build(BuildContext context) => busy
      ? const SizedBox.square(
          dimension: 22,
          child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
        )
      : Text(label);
}
