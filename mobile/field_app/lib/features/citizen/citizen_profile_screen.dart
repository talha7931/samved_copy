import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/theme.dart';
import '../../providers/providers.dart';

class CitizenProfileScreen extends ConsumerStatefulWidget {
  const CitizenProfileScreen({super.key});

  @override
  ConsumerState<CitizenProfileScreen> createState() => _CitizenProfileScreenState();
}

class _CitizenProfileScreenState extends ConsumerState<CitizenProfileScreen> {
  bool _marathi = false;
  bool _notifStatus = true;
  bool _notifDispatch = true;
  bool _notifResolved = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _marathi = p.getBool('citizen_lang_mr') ?? false;
      _notifStatus = p.getBool('citizen_notif_status') ?? true;
      _notifDispatch = p.getBool('citizen_notif_dispatch') ?? true;
      _notifResolved = p.getBool('citizen_notif_resolved') ?? true;
    });
  }

  Future<void> _save(String key, bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).value;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppDesign.navyGradient),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppDesign.cardShadow(Theme.of(context).colorScheme),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile?.fullName ?? 'Citizen', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                const SizedBox(height: 4),
                Text(profile?.phone ?? '-'),
                Text('Citizen · Zone ${profile?.zoneId ?? '-'}'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _tileCard(
            context,
            child: SwitchListTile(
              title: const Text('Language: Marathi'),
              value: _marathi,
              onChanged: (v) {
                setState(() => _marathi = v);
                _save('citizen_lang_mr', v);
              },
            ),
          ),
          _tileCard(
            context,
            child: SwitchListTile(
              title: const Text('Status updates'),
              value: _notifStatus,
              onChanged: (v) {
                setState(() => _notifStatus = v);
                _save('citizen_notif_status', v);
              },
            ),
          ),
          _tileCard(
            context,
            child: SwitchListTile(
              title: const Text('JE dispatched alerts'),
              value: _notifDispatch,
              onChanged: (v) {
                setState(() => _notifDispatch = v);
                _save('citizen_notif_dispatch', v);
              },
            ),
          ),
          _tileCard(
            context,
            child: SwitchListTile(
              title: const Text('Complaint resolved alerts'),
              value: _notifResolved,
              onChanged: (v) {
                setState(() => _notifResolved = v);
                _save('citizen_notif_resolved', v);
              },
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: () {},
            child: const Text('How to report'),
          ),
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: () {},
            child: const Text('Contact Zone Office'),
          ),
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: () {},
            child: const Text('Privacy Policy'),
          ),
          const SizedBox(height: 16),
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
