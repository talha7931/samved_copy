import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/theme.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/sticky_bottom_cta.dart';
import '../../models/ticket.dart';
import '../../providers/providers.dart';
import '../../providers/ticket_providers.dart';

class ExecutionProofArgs {
  const ExecutionProofArgs({
    required this.ticketId,
    required this.roleLabel,
  });

  final String ticketId;
  final String roleLabel;
}

class ExecutionProofScreen extends ConsumerStatefulWidget {
  const ExecutionProofScreen({super.key, required this.args});

  final ExecutionProofArgs args;

  @override
  ConsumerState<ExecutionProofScreen> createState() =>
      _ExecutionProofScreenState();
}

class _ExecutionProofScreenState extends ConsumerState<ExecutionProofScreen> {
  Uint8List? _photoBytes;
  String _photoExt = '.jpg';
  bool _busy = false;
  String? _error;
  bool _camDenied = false;

  String _extensionFor(XFile x) {
    final e = p.extension(x.name);
    return e.isNotEmpty ? e : '.jpg';
  }

  Future<void> _capture() async {
    if (!kIsWeb) {
      final cam = await Permission.camera.request();
      if (!cam.isGranted) {
        setState(() => _camDenied = true);
        return;
      }
    }
    setState(() => _camDenied = false);
    final x = await ImagePicker().pickImage(
      source: kIsWeb ? ImageSource.gallery : ImageSource.camera,
      imageQuality: 85,
    );
    if (x == null) return;
    final bytes = await x.readAsBytes();
    setState(() {
      _photoBytes = bytes;
      _photoExt = _extensionFor(x);
    });
  }

  Future<void> _submit() async {
    if (_photoBytes == null) {
      setState(() => _error = kIsWeb
          ? 'Choose an after photo (browser uses gallery for testing).'
          : 'Take an after photo at the site.');
      return;
    }

    final uid = ref.read(supabaseClientProvider).auth.currentUser?.id;
    if (uid == null) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final ticketService = ref.read(ticketServiceProvider);
      final ticket = await ticketService.fetchTicket(widget.args.ticketId);
      if (ticket == null) {
        setState(() => _error = 'Ticket not found.');
        return;
      }
      if (ticket.status != 'in_progress') {
        setState(() {
          _error =
              'This work order is in "${ticket.status}" state. Proof can only be submitted when work is In Progress.';
        });
        return;
      }
      final url = await ref.read(storageServiceProvider).uploadAfterPhoto(
            userId: uid,
            bytes: _photoBytes!,
            fileExtension: _photoExt,
          );

      await ticketService.submitExecutionProof(
        ticketId: widget.args.ticketId,
        afterPhotoUrl: url,
      );

      Map<String, dynamic>? verification;
      try {
        final result = await ticketService.runRepairVerification(
          widget.args.ticketId,
        );
        verification = result.verification;
      } catch (_) {
        verification = null;
      }

      if (!mounted) return;

      ref.invalidate(ticketDetailProvider(widget.args.ticketId));
      ref.invalidate(mukadamInboxProvider);
      ref.invalidate(contractorInboxProvider);

      final verificationEnvelope = verification;
      final verificationAi = verificationEnvelope?['ai'];
      final verificationPassed =
          verificationAi is Map ? verificationAi['ssim_pass'] == true : null;

      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            verificationPassed == true
                ? 'Proof submitted - AI verification passed'
                : verificationPassed == false
                    ? 'Proof submitted - AI verification recorded'
                    : 'Proof submitted - quality check pending',
          ),
        ),
      );
    } on PostgrestException catch (e) {
      setState(() {
        _error = e.message.contains('cannot change state')
            ? 'This work order is already closed. Proof upload is disabled for closed tickets.'
            : e.message;
      });
    } catch (e) {
      setState(() => _error = 'Failed to submit proof. Please retry.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _closeProofScreen() {
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
      return;
    }
    final mukadam = widget.args.roleLabel == 'Mukadam';
    context.go(mukadam ? '/mukadam/work-orders' : '/contractor/work-orders');
  }

  Widget _ticketHeaderCard(Ticket ticket, ColorScheme cs, TextTheme tt) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppDesign.cardShadow(cs),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ticket.ticketRef.isEmpty
                      ? widget.args.ticketId.substring(0, 8)
                      : ticket.ticketRef,
                  style: AppDesign.mono(
                    tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.args.roleLabel,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (ticket.addressText != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    ticket.addressText!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusBadge(status: ticket.status),
              if (ticket.primaryBeforePhoto != null) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    ticket.primaryBeforePhoto!,
                    width: 78,
                    height: 58,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  (String title, String body) _readOnlyCopy(String status) {
    switch (status) {
      case 'audit_pending':
        return (
          'Proof submitted',
          'This work order is waiting for JE review and AI quality verification. You cannot change the after photo from here.',
        );
      case 'resolved':
        return (
          'Work order closed',
          'This repair is marked resolved. Completion proof is read-only.',
        );
      case 'rejected':
        return (
          'Work order rejected',
          'This ticket was rejected. Proof upload is not available.',
        );
      default:
        return (
          'Upload not available',
          'Proof can only be submitted while the work order status is In progress (current: $status).',
        );
    }
  }

  List<Widget> _readOnlyBody(
    Ticket ticket,
    ColorScheme cs,
    TextTheme tt,
  ) {
    final copy = _readOnlyCopy(ticket.status);
    return [
      const SizedBox(height: 12),
      Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cs.primaryContainer,
              cs.surfaceContainerHighest,
            ],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              copy.$1,
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              copy.$2,
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      if (ticket.photoAfter != null) ...[
        const SizedBox(height: 16),
        Text(
          'Submitted after photo',
          style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: CachedNetworkImage(
            imageUrl: ticket.photoAfter!,
            height: 240,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              height: 240,
              color: cs.surfaceContainerHighest,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(),
            ),
            errorWidget: (_, __, ___) => Container(
              height: 120,
              alignment: Alignment.center,
              child: Text('Could not load image', style: tt.bodySmall),
            ),
          ),
        ),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final ticketAsync = ref.watch(ticketDetailProvider(widget.args.ticketId));

    return ticketAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(
          title: Text(
            'Upload Completion Proof - ${widget.args.ticketId.substring(0, 8)}',
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(
          title: Text(
            'Upload Completion Proof - ${widget.args.ticketId.substring(0, 8)}',
          ),
        ),
        body: Center(child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('$e', textAlign: TextAlign.center),
        )),
      ),
      data: (ticket) {
        if (ticket == null) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                'Upload Completion Proof - ${widget.args.ticketId.substring(0, 8)}',
              ),
            ),
            body: const Center(child: Text('Ticket not found')),
          );
        }
        final canSubmit = ticket.status == 'in_progress';

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Upload Completion Proof - ${widget.args.ticketId.substring(0, 8)}',
            ),
          ),
          body: ListView(
            padding: EdgeInsets.fromLTRB(20, 20, 20, canSubmit ? 120 : 32),
            children: [
              _ticketHeaderCard(ticket, cs, tt),
              if (canSubmit) ...[
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppDesign.primaryNavy,
                        AppDesign.primaryContainerNavy
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Completion proof upload',
                        style: tt.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${widget.args.roleLabel}: capture one clear after photo showing repaired surface and edges.',
                        style: tt.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This will move ticket to Audit Pending for JE/AI quality verification.',
                        style: tt.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.82),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppDesign.cardShadow(cs),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Capture checklist',
                        style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '- Keep repaired patch and surrounding road in frame',
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      Text(
                        '- Avoid blur, glare, and heavy shadows',
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      Text(
                        '- Capture from close distance at site',
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (_camDenied)
                  Container(
                    decoration: BoxDecoration(
                      color: cs.errorContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'Camera permission denied.',
                      style: TextStyle(color: cs.onErrorContainer),
                    ),
                  ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: AppDesign.cardShadow(cs),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: OutlinedButton.icon(
                    onPressed: _capture,
                    icon: Icon(
                      kIsWeb
                          ? Icons.photo_library_outlined
                          : Icons.photo_camera_outlined,
                    ),
                    label: Text(
                      _photoBytes == null
                          ? (kIsWeb ? 'Choose after photo' : 'Take after photo')
                          : (kIsWeb ? 'Change photo' : 'Retake'),
                    ),
                  ),
                ),
                if (_photoBytes != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.memory(
                        _photoBytes!,
                        height: 240,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: cs.error)),
                ],
                const SizedBox(height: 12),
                Text(
                  'Photo will be submitted for JE and AI verification.',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ] else
                ..._readOnlyBody(ticket, cs, tt),
            ],
          ),
          bottomNavigationBar: canSubmit
              ? StickyBottomCta(
                  primaryLabel: 'Submit for quality check',
                  onPrimaryTap: _busy ? null : _submit,
                )
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: FilledButton(
                      onPressed: _closeProofScreen,
                      child: const Text('Back'),
                    ),
                  ),
                ),
        );
      },
    );
  }
}
