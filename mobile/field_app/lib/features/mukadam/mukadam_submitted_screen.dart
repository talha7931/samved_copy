import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MukadamSubmittedScreen extends StatelessWidget {
  const MukadamSubmittedScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
              'Work Completion Recorded',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('PENDING JE REVIEW', style: TextStyle(fontWeight: FontWeight.w700)),
                    SizedBox(height: 8),
                    Text('1. JE Site Verification'),
                    Text('2. Quality Assessment'),
                    Text('3. Work Order Closed in system'),
                  ],
                ),
              ),
            ),
            const Spacer(),
            FilledButton(
              onPressed: () => context.go('/mukadam/work-orders'),
              child: const Text('Return to Work Orders'),
            ),
          ],
        ),
      ),
    );
  }
}
