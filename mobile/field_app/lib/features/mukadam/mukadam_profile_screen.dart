import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/theme.dart';
import '../../providers/providers.dart';
import '../../providers/ticket_providers.dart';

class MukadamProfileScreen extends ConsumerStatefulWidget {
  const MukadamProfileScreen({super.key});

  @override
  ConsumerState<MukadamProfileScreen> createState() => _MukadamProfileScreenState();
}

class _MukadamProfileScreenState extends ConsumerState<MukadamProfileScreen> {
  bool _mr = false;
  bool _notif = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _mr = p.getBool('mukadam_lang_mr') ?? false;
      _notif = p.getBool('mukadam_notif') ?? true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).value;
    final completed = ref.watch(mukadamInboxProvider).valueOrNull
            ?.where((t) => t.status == 'audit_pending' || t.status == 'resolved')
            .length ??
        0;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mukadam Profile'),
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppDesign.navyGradient),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppDesign.cardShadow(Theme.of(context).colorScheme),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(profile?.fullName ?? 'Mukadam', style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text('Zone: ${profile?.zoneId ?? '-'}'),
                  const Text('Gang Size: 8 Workers'),
                  const Text('Department: Roads Dept'),
                  Text('This week completed: $completed'),
                ],
              ),
            ),
          ),
          _tileCard(
            context,
            child: SwitchListTile(
            title: const Text('Language: Marathi'),
            value: _mr,
            onChanged: (v) async {
              final p = await SharedPreferences.getInstance();
              await p.setBool('mukadam_lang_mr', v);
              setState(() => _mr = v);
            },
          )),
          _tileCard(
            context,
            child: SwitchListTile(
            title: const Text('Notifications'),
            value: _notif,
            onChanged: (v) async {
              final p = await SharedPreferences.getInstance();
              await p.setBool('mukadam_notif', v);
              setState(() => _notif = v);
            },
          )),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
              if (!context.mounted) return;
              context.go('/login');
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  Widget _tileCard(BuildContext context, {required Widget child}) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppDesign.cardShadow(cs),
        ),
        child: child,
      ),
    );
  }
}
