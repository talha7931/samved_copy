import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ContractorSubmittedScreen extends StatelessWidget {
  const ContractorSubmittedScreen({super.key, this.data});

  final Map<String, dynamic>? data;

  @override
  Widget build(BuildContext context) {
    final hash = data?['hash'] as String?;
    final ssim = data?['ssim'] as double?;
    return Scaffold(
      appBar: AppBar(title: const Text('Submission Complete')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            const Icon(Icons.verified_rounded, size: 64),
            const SizedBox(height: 12),
            const Text(
              'Repair Verified',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SSIM Score: ${ssim?.toStringAsFixed(2) ?? '-'}'),
                    Text('SHA-256: ${hash == null ? '-' : '${hash.substring(0, 12)}...'}'),
                    const SizedBox(height: 8),
                    const Text('Billing pipeline', style: TextStyle(fontWeight: FontWeight.w700)),
                    const Text('1. Proof Submitted'),
                    const Text('2. JE Quality Verification'),
                    const Text('3. Accounts Review'),
                    const Text('4. Payment Released'),
                  ],
                ),
              ),
            ),
            const Spacer(),
            OutlinedButton(
              onPressed: () {},
              child: const Text('Download Receipt PDF'),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => context.go('/contractor/work-orders'),
              child: const Text('Return to Work Orders'),
            ),
          ],
        ),
      ),
    );
  }
}
