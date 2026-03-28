import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_controller/app_controller.dart';
import '../../core/theme/pledge_colors.dart';
import '../../core/ui/kit/pledge_buttons.dart';
import '../../core/ui/kit/pledge_shell.dart';

/// Mock appeals form — POST to appeals API when backend exists.
class AppealsPage extends ConsumerStatefulWidget {
  const AppealsPage({super.key});

  @override
  ConsumerState<AppealsPage> createState() => _AppealsPageState();
}

class _AppealsPageState extends ConsumerState<AppealsPage> {
  final _refCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _refCtrl.dispose();
    _reasonCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PledgePageScaffold(
      title: 'Appeals',
      showBack: true,
      padding: EdgeInsets.zero,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          Text(
            'Appeal a penalty or challenge outcome. Submissions are stored locally for this build only.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: PledgeColors.inkMuted,
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _refCtrl,
            decoration: const InputDecoration(
              labelText: 'Challenge reference or date',
              hintText: 'e.g. challenge_abc or Mar 15, 2026',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _reasonCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Appeal reason',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _notesCtrl,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Optional notes',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 28),
          PledgePrimaryButton(
            label: 'Submit appeal',
            isLoading: _submitting,
            onPressed: () async {
              if (_refCtrl.text.trim().isEmpty ||
                  _reasonCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Add a reference and a reason to submit.'),
                  ),
                );
                return;
              }
              setState(() => _submitting = true);
              await ref.read(appControllerProvider.notifier).submitAppealMock(
                    challengeRef: _refCtrl.text.trim(),
                    reason: _reasonCtrl.text.trim(),
                    notes: _notesCtrl.text.trim(),
                  );
              if (!context.mounted) return;
              setState(() => _submitting = false);
              _refCtrl.clear();
              _reasonCtrl.clear();
              _notesCtrl.clear();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Appeal submitted (mock). We’ll follow up by email.'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
