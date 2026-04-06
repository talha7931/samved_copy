import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/gradient_primary_button.dart';
import '../../providers/providers.dart';
import '../../providers/ticket_providers.dart';
import 'confirmation_screen.dart';

class AiResultArgs {
  const AiResultArgs({
    required this.imageBytes,
    required this.fileExtension,
    required this.latitude,
    required this.longitude,
    this.addressText,
    this.nearestLandmark,
    this.damageType,
  });

  final Uint8List imageBytes;
  final String fileExtension;
  final double latitude;
  final double longitude;
  final String? addressText;
  final String? nearestLandmark;
  final String? damageType;
}

class AiResultScreen extends ConsumerStatefulWidget {
  const AiResultScreen({super.key, required this.args});

  final AiResultArgs args;

  @override
  ConsumerState<AiResultScreen> createState() => _AiResultScreenState();
}

class _AiResultScreenState extends ConsumerState<AiResultScreen> {
  bool _submitting = false;
  String? _error;
  String? _selectedDamage;

  @override
  void initState() {
    super.initState();
    _selectedDamage = widget.args.damageType;
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final uid = ref.read(supabaseClientProvider).auth.currentUser?.id;
      if (uid == null) throw Exception('Session expired. Please login again.');
      final profile = await ref.read(authServiceProvider).fetchProfile();
      final raw = profile?.phone ?? '';
      final phoneDigits = raw.replaceAll(RegExp(r'\D'), '');
      if (phoneDigits.length < 10) {
        throw Exception('Your profile has no valid phone number.');
      }

      final url = await ref.read(storageServiceProvider).uploadTicketBeforePhoto(
            userId: uid,
            bytes: widget.args.imageBytes,
            fileExtension: widget.args.fileExtension,
          );
      final ticketService = ref.read(ticketServiceProvider);
      final ticketId = await ticketService.createCitizenTicket(
            citizenPhone: phoneDigits.length > 10
                ? phoneDigits.substring(phoneDigits.length - 10)
                : phoneDigits,
            citizenName: profile?.fullName,
            lat: widget.args.latitude,
            lng: widget.args.longitude,
            photoBeforeUrls: [url],
            addressText: widget.args.addressText,
            nearestLandmark: widget.args.nearestLandmark,
            damageType: _selectedDamage,
          );

      Map<String, dynamic>? severity;
      var ticket = await ticketService.fetchTicket(ticketId);
      try {
        final pipeline = await ticketService.runCitizenAiPipeline(ticketId);
        severity = pipeline.severity;
        ticket = pipeline.ticket ?? ticket;
        final detectEnvelope = pipeline.detect;
        final detectAi = detectEnvelope?['ai'];
        if (detectAi is Map) {
          _selectedDamage =
              (detectAi['damage_type'] as String?) ?? _selectedDamage;
        }
      } catch (_) {
        ticket = await ticketService.fetchTicket(ticketId);
      }

      final severityEnvelope = severity;
      final severityAi = severityEnvelope?['ai'];
      final slaHours =
          severityAi is Map ? severityAi['sla_hours'] as int? : null;

      ref.invalidate(citizenTicketsProvider);
      if (!mounted) return;
      context.go(
        '/citizen/confirmation',
        extra: ConfirmationArgs(
          ticketId: ticketId,
          ticketRef: ticket?.ticketRef,
          zoneId: ticket?.zoneId,
          prabhagId: ticket?.prabhagId,
          severity: ticket?.severityTier,
          epdoScore: ticket?.epdoScore,
          slaHours: slaHours,
        ),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('AI review')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                Image.memory(
                  widget.args.imageBytes,
                  height: 240,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      margin: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white70, width: 2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Secure AI analysis runs after submission',
                        style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your photo is uploaded first, then the complaint is created in Supabase, and then the new Edge Functions run detection and severity scoring on that live ticket.',
                        style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _chip(context, 'GPS', '${widget.args.latitude.toStringAsFixed(4)}, ${widget.args.longitude.toStringAsFixed(4)}'),
                          _chip(context, 'Address', widget.args.addressText ?? 'Not provided'),
                          _chip(context, 'Landmark', widget.args.nearestLandmark ?? 'Not provided'),
                        ],
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedDamage,
                        decoration: const InputDecoration(labelText: 'Type of damage'),
                        items: const [
                          DropdownMenuItem(value: 'pothole', child: Text('Pothole')),
                          DropdownMenuItem(value: 'crack', child: Text('Crack')),
                          DropdownMenuItem(value: 'flooding', child: Text('Flooding')),
                          DropdownMenuItem(value: 'surface', child: Text('Surface')),
                        ],
                        onChanged: (v) => setState(() => _selectedDamage = v),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'You can still correct the damage type before final submission. AI results will appear on the confirmation and tracker screens after the secure backend analysis finishes.',
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: TextStyle(color: cs.error)),
          ],
          const SizedBox(height: 14),
          GradientPrimaryButton(
            onPressed: _submitting ? null : _submit,
            label: 'Submit & Run AI Review',
            icon: Icons.check_circle_outline,
            loading: _submitting,
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => context.pop(),
            child: const Text('Retake Photo'),
          ),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, String label, String value) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text('$label: $value'),
    );
  }
}
