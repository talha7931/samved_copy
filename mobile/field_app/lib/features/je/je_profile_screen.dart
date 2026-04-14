import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/theme.dart';
import '../../providers/providers.dart';

class JeProfileScreen extends ConsumerStatefulWidget {
  const JeProfileScreen({super.key});

  @override
  ConsumerState<JeProfileScreen> createState() => _JeProfileScreenState();
}

class _JeProfileScreenState extends ConsumerState<JeProfileScreen> {
  bool _mr = false;
  bool _notifTicket = true;
  bool _notifEscalation = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _mr = p.getBool('je_lang_mr') ?? false;
      _notifTicket = p.getBool('je_notif_ticket') ?? true;
      _notifEscalation = p.getBool('je_notif_escalation') ?? true;
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
        title: const Text('JE Profile'),
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
                Text(profile?.fullName ?? 'JE', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                Text(profile?.email ?? profile?.phone ?? '-'),
                Text('Zone ${profile?.zoneId ?? '-'}'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _tileCard(
            context,
            child: SwitchListTile(
            title: const Text('Language: Marathi'),
            value: _mr,
            onChanged: (v) {
              setState(() => _mr = v);
              _save('je_lang_mr', v);
            },
          )),
          _tileCard(
            context,
            child: SwitchListTile(
            title: const Text('New ticket alerts'),
            value: _notifTicket,
            onChanged: (v) {
              setState(() => _notifTicket = v);
              _save('je_notif_ticket', v);
            },
          )),
          _tileCard(
            context,
            child: SwitchListTile(
            title: const Text('Escalation alerts'),
            value: _notifEscalation,
            onChanged: (v) {
              setState(() => _notifEscalation = v);
              _save('je_notif_escalation', v);
            },
          )),
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
