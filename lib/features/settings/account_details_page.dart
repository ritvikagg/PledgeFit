import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_controller/app_controller.dart';
import '../../services/auth/auth_controller.dart';
import '../../core/theme/pledge_colors.dart';
import '../../core/ui/kit/pledge_buttons.dart';
import '../../core/ui/kit/pledge_shell.dart';
import '../../data/models/user_profile.dart';

/// Local-only profile — replace with authenticated user + remote sync later.
class AccountDetailsPage extends ConsumerStatefulWidget {
  const AccountDetailsPage({super.key});

  @override
  ConsumerState<AccountDetailsPage> createState() =>
      _AccountDetailsPageState();
}

class _AccountDetailsPageState extends ConsumerState<AccountDetailsPage> {
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  bool _saving = false;
  String? _hydratedUserId;

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _email.dispose();
    super.dispose();
  }

  void _hydrateFrom(AppModel model) {
    if (_hydratedUserId == model.user.id) return;
    _hydratedUserId = model.user.id;
    final p = model.profile;
    _name.text = p.fullName;
    _username.text = p.username;
    _email.text = p.email;
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appControllerProvider);

    return app.when(
      loading: () => const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: Text('Error: $e')),
      ),
      data: (model) {
        _hydrateFrom(model);
        final profile = model.profile;
        final session = ref.watch(authControllerProvider).asData?.value;

        return PledgePageScaffold(
          title: 'Account',
          showBack: true,
          padding: EdgeInsets.zero,
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              if (session != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    session.authProvider == 'google'
                        ? 'Signed in with Google · ${session.email}'
                        : 'Signed in with email · ${session.email}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: PledgeColors.inkMuted,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              Center(
                child: Container(
                  width: 88,
                  height: 88,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: PledgeColors.card,
                    shape: BoxShape.circle,
                    border: Border.all(color: PledgeColors.border),
                  ),
                  child: Text(
                    profile.avatarEmoji.isEmpty ? '👤' : profile.avatarEmoji,
                    style: const TextStyle(fontSize: 40),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Photo upload coming later',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: PledgeColors.inkMuted,
                      ),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _name,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _username,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 28),
              PledgePrimaryButton(
                label: 'Save',
                isLoading: _saving,
                onPressed: () async {
                  setState(() => _saving = true);
                  await ref.read(appControllerProvider.notifier).saveUserProfile(
                        UserProfile(
                          fullName: _name.text.trim(),
                          username: _username.text.trim(),
                          email: _email.text.trim(),
                          avatarEmoji: profile.avatarEmoji.isEmpty
                              ? '👤'
                              : profile.avatarEmoji,
                        ),
                      );
                  if (!context.mounted) return;
                  setState(() => _saving = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile saved locally.')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
