import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      appBar: AppBar(title: const Text('Mukadam Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
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
          SwitchListTile(
            title: const Text('Language: Marathi'),
            value: _mr,
            onChanged: (v) async {
              final p = await SharedPreferences.getInstance();
              await p.setBool('mukadam_lang_mr', v);
              setState(() => _mr = v);
            },
          ),
          SwitchListTile(
            title: const Text('Notifications'),
            value: _notif,
            onChanged: (v) async {
              final p = await SharedPreferences.getInstance();
              await p.setBool('mukadam_notif', v);
              setState(() => _notif = v);
            },
          ),
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
}
