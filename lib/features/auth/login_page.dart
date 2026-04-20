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

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Enter email and password.');
      return;
    }
    if (!_isValidEmail(email)) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    await ref.read(authControllerProvider.notifier).signInWithEmail(
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
      title: 'Log in',
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
            autofillHints: const [AutofillHints.password],
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => loading ? null : _submit(),
          ),
          const SizedBox(height: 24),
          PledgePrimaryButton(
            label: 'Log in',
            isLoading: loading,
            onPressed: loading ? null : _submit,
          ),
        ],
      ),
    );
  }
}
