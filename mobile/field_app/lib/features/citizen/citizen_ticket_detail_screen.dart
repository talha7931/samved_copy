import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/status_labels.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../../core/widgets/sticky_bottom_cta.dart';
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
      appBar: AppBar(
        title: const Text('Complaint status'),
        actions: [
          IconButton(
            onPressed: () async {
              final uri = Uri(
                scheme: 'sms',
                queryParameters: {'body': 'Road Nirman complaint $ticketId'},
              );
              await launchUrl(uri);
            },
            icon: const Icon(Icons.share_outlined),
          ),
        ],
      ),
      body: asyncTicket.when(
        loading: () => const ShimmerList(),
        error: (e, _) => ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(ticketDetailProvider(ticketId)),
        ),
        data: (ticket) {
          if (ticket == null) return const Center(child: Text('Ticket not found'));
          final lookupAsync = ref.watch(ticketLookupProvider(ticket));
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: AppDesign.navyGradient,
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reference ID',
                        style: tt.labelLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ticket.ticketRef.isEmpty ? 'Reference pending' : ticket.ticketRef,
                        style: AppDesign.mono(
                          tt.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            ticketStatusLabel(ticket.status),
                            style: tt.titleMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Updated ${_timeAgo(ticket.updatedAt)}',
                            style: tt.labelMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                lookupAsync.when(
                  data: (lookup) => Container(
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppDesign.cardShadow(cs),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Expanded(child: _metaTile(context, 'Zone', lookup.zoneName ?? '-')),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _metaTile(context, 'Prabhag', lookup.prabhagName ?? '-'),
                        ),
                      ],
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 14),
                Container(
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: AppDesign.cardShadow(cs),
                  ),
                  padding: const EdgeInsets.all(18),
                  child: _StatusStepper(status: ticket.status),
                ),
                const SizedBox(height: 16),
                if (ticket.primaryBeforePhoto != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: AspectRatio(
                      aspectRatio: 16 / 10,
                      child: CachedNetworkImage(
                        imageUrl: ticket.primaryBeforePhoto!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const SizedBox(
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 14),
                if (ticket.aiConfidence != null ||
                    ticket.totalPotholes != null ||
                    ticket.epdoScore != null)
                  Container(
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: AppDesign.cardShadow(cs),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Expanded(child: _metric(context, 'Potholes', '${ticket.totalPotholes ?? '-'}')),
                        Expanded(
                          child: _metric(
                            context,
                            'Confidence',
                            ticket.aiConfidence == null
                                ? '-'
                                : '${(ticket.aiConfidence! * 100).toStringAsFixed(0)}%',
                          ),
                        ),
                        Expanded(
                          child: _metric(
                            context,
                            'EPDO',
                            ticket.epdoScore?.toStringAsFixed(1) ?? '-',
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 14),
                if (ticket.addressText != null || ticket.nearestLandmark != null)
                  Container(
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: AppDesign.cardShadow(cs),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (ticket.addressText != null)
                          Text(
                            ticket.addressText!,
                            style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        if (ticket.nearestLandmark != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Nearest landmark: ${ticket.nearestLandmark}',
                            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: 14),
                Container(
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border(left: BorderSide(color: cs.tertiary, width: 4)),
                    boxShadow: AppDesign.cardShadow(cs),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Latest update: ${ticketStatusLabel(ticket.status)} by zone field team.',
                    style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: StickyBottomCta(
        primaryLabel: 'Contact Zone Office',
        onPrimaryTap: () => launchUrl(Uri.parse('tel:1800123456')),
        secondaryLabel: 'Back to my reports',
        onSecondaryTap: () => Navigator.of(context).maybePop(),
      ),
    );
  }

  Widget _metric(BuildContext context, String label, String value) {
    final tt = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(label.toUpperCase(), style: tt.labelSmall),
        const SizedBox(height: 6),
        Text(value, style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _metaTile(BuildContext context, String label, String value) {
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: tt.labelSmall),
        const SizedBox(height: 4),
        Text(value, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }

  String _timeAgo(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return 'recently';
    final diff = DateTime.now().difference(dt.toLocal());
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
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
