import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/theme.dart';
import '../../providers/providers.dart';

class ContractorProfileScreen extends ConsumerStatefulWidget {
  const ContractorProfileScreen({super.key});

  @override
  ConsumerState<ContractorProfileScreen> createState() =>
      _ContractorProfileScreenState();
}

class _ContractorProfileScreenState extends ConsumerState<ContractorProfileScreen> {
  bool _notifJobs = true;
  bool _notifPayment = true;
  bool _notifSla = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _notifJobs = p.getBool('contractor_notif_jobs') ?? true;
      _notifPayment = p.getBool('contractor_notif_payment') ?? true;
      _notifSla = p.getBool('contractor_notif_sla') ?? true;
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
        title: const Text('Contractor Profile'),
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
                  Text(profile?.fullName ?? 'Contractor', style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text(profile?.email ?? profile?.phone ?? '-'),
                  Text('Zone ${profile?.zoneId ?? '-'}'),
                  const SizedBox(height: 6),
                  const Text('Contract #: DEMO-CONTRACT'),
                  const Text('GST: DEMO-GST'),
                  const Text('PAN: DEMO-PAN'),
                ],
              ),
            ),
          ),
          _tileCard(
            context,
            child: SwitchListTile(
            title: const Text('New Job Assignments'),
            value: _notifJobs,
            onChanged: (v) {
              setState(() => _notifJobs = v);
              _save('contractor_notif_jobs', v);
            },
          )),
          _tileCard(
            context,
            child: SwitchListTile(
            title: const Text('Payment Status Updates'),
            value: _notifPayment,
            onChanged: (v) {
              setState(() => _notifPayment = v);
              _save('contractor_notif_payment', v);
            },
          )),
          _tileCard(
            context,
            child: SwitchListTile(
            title: const Text('SLA Breach Alerts'),
            value: _notifSla,
            onChanged: (v) {
              setState(() => _notifSla = v);
              _save('contractor_notif_sla', v);
            },
          )),
          const SizedBox(height: 14),
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
