import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app_controller/app_controller.dart';
import '../../core/theme/pledge_colors.dart';
import '../../core/ui/kit/pledge_buttons.dart';
import '../../core/ui/kit/pledge_shell.dart';
import '../../services/auth/auth_controller.dart';

bool _isValidEmail(String s) {
  final t = s.trim();
  if (t.isEmpty) return false;
  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t);
}

const _minPasswordLength = 8;

class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({super.key});

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    final name = _name.text.trim();
    final email = _email.text.trim();
    final password = _password.text;
    final confirm = _confirm.text;
    if (name.isEmpty || email.isEmpty || password.isEmpty || confirm.isEmpty) {
      setState(() => _error = 'Fill in every field.');
      return;
    }
    if (!_isValidEmail(email)) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    if (password.length < _minPasswordLength) {
      setState(
        () => _error =
            'Password must be at least $_minPasswordLength characters.',
      );
      return;
    }
    if (password != confirm) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    await ref.read(authControllerProvider.notifier).signUpWithEmail(
          fullName: name,
          email: email,
          password: password,
        );
    if (!mounted) return;
    final auth = ref.read(authControllerProvider);
    if (auth.hasError) {
      setState(() => _error = auth.error.toString());
      return;
    }
    ref.invalidate(appControllerProvider);
    if (!mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(authControllerProvider).isLoading;

    return PledgePageScaffold(
      title: 'Sign up',
      showBack: true,
      padding: EdgeInsets.zero,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _error!,
                style: const TextStyle(
                  color: PledgeColors.dangerRose,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          TextField(
            controller: _name,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            decoration: const InputDecoration(
              labelText: 'Full name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _password,
            obscureText: true,
            autofillHints: const [AutofillHints.newPassword],
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _confirm,
            obscureText: true,
            autofillHints: const [AutofillHints.newPassword],
            decoration: const InputDecoration(
              labelText: 'Confirm password',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => loading ? null : _submit(),
          ),
          const SizedBox(height: 8),
          Text(
            'At least $_minPasswordLength characters.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: PledgeColors.inkMuted,
                ),
          ),
          const SizedBox(height: 24),
          PledgePrimaryButton(
            label: 'Create account',
            isLoading: loading,
            onPressed: loading ? null : _submit,
          ),
        ],
      ),
    );
  }
}
