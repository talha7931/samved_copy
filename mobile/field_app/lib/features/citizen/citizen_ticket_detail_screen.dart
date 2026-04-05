import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/status_labels.dart';
import '../../core/widgets/gradient_primary_button.dart';
import '../../providers/ticket_providers.dart';

class CitizenTicketDetailScreen extends ConsumerWidget {
  const CitizenTicketDetailScreen({super.key, required this.ticketId});

  final String ticketId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTicket = ref.watch(ticketDetailProvider(ticketId));
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Complaint status')),
      body: asyncTicket.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (ticket) {
          if (ticket == null) {
            return const Center(child: Text('Ticket not found'));
          }
          return SingleChildScrollView(
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
                      colors: [cs.primary, cs.primaryContainer],
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Application number',
                        style: tt.labelLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ticket.ticketRef.isEmpty
                            ? 'Reference pending'
                            : ticket.ticketRef,
                        style: tt.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        ticketStatusLabel(ticket.status),
                        style: tt.titleMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1A1C1E).withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(18),
                  child: _StatusStepper(status: ticket.status),
                ),
                const SizedBox(height: 24),
                if (ticket.primaryBeforePhoto != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: CachedNetworkImage(
                      imageUrl: ticket.primaryBeforePhoto!,
                      height: 230,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const SizedBox(
                        height: 230,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                if (ticket.addressText != null || ticket.nearestLandmark != null)
                  Container(
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (ticket.addressText != null)
                          Text(
                            ticket.addressText!,
                            style: tt.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        if (ticket.nearestLandmark != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Nearest landmark: ${ticket.nearestLandmark}',
                            style: tt.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                GradientPrimaryButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  label: 'Back to my reports',
                  icon: Icons.arrow_back_rounded,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatusStepper extends StatelessWidget {
  const _StatusStepper({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final idx = kCitizenStatusOrder.indexOf(status);
    final activeIndex = idx < 0 ? 0 : idx;
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progress tracker',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < kCitizenStatusOrder.length; i++) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i <= activeIndex ? cs.primary : cs.surfaceContainerHighest,
                    ),
                    child: Icon(
                      i < activeIndex ? Icons.check : Icons.circle,
                      size: i < activeIndex ? 16 : 8,
                      color: i <= activeIndex ? cs.onPrimary : cs.outline,
                    ),
                  ),
                  if (i < kCitizenStatusOrder.length - 1)
                    Container(
                      width: 2,
                      height: 24,
                      color: i < activeIndex ? cs.primary : cs.outlineVariant,
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    ticketStatusLabel(kCitizenStatusOrder[i]),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: i == activeIndex
                              ? FontWeight.w800
                              : FontWeight.w500,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
