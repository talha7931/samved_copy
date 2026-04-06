import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/gradient_primary_button.dart';
import '../../providers/providers.dart';

class BlockedScreen extends ConsumerWidget {
  const BlockedScreen({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Cannot continue')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [cs.error, cs.error.withValues(alpha: 0.85)],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Row(
                children: [
                  const Icon(Icons.gpp_maybe_outlined, size: 40, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Access blocked for this account',
                      style: tt.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(16),
              child: Text(
                message ??
                    'This account cannot use the mobile app. Please contact support or use the web dashboard.',
                style: tt.bodyLarge,
              ),
            ),
            const Spacer(),
            GradientPrimaryButton(
              onPressed: () async {
                await ref.read(authServiceProvider).signOut();
                if (context.mounted) context.go('/login');
              },
              label: 'Sign out',
              icon: Icons.logout_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
