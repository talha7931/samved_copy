import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

import '../../core/theme/theme.dart';
import '../../core/utils/image_source_sheet.dart';
import '../../core/widgets/gradient_primary_button.dart';
import '../../providers/providers.dart';
import 'ai_result_screen.dart';

class ReportDamageScreen extends ConsumerStatefulWidget {
  const ReportDamageScreen({super.key});

  @override
  ConsumerState<ReportDamageScreen> createState() => _ReportDamageScreenState();
}

class _ReportDamageScreenState extends ConsumerState<ReportDamageScreen> {
  final _address = TextEditingController();
  final _landmark = TextEditingController();
  String? _damageType;
  Uint8List? _photoBytes;
  String _photoExt = '.jpg';
  double? _lat;
  double? _lng;
  bool _loading = false;
  String? _error;
  bool _cameraDenied = false;
  bool _locationDenied = false;

  // Keep in sync with AI service standard damage_type values.
  static const _damageTypes = [
    'pothole',
    'crack',
    'surface_failure',
  ];

  @override
  void dispose() {
    _address.dispose();
    _landmark.dispose();
    super.dispose();
  }

  String _extensionFor(XFile x) {
    final e = p.extension(x.name);
    return e.isNotEmpty ? e : '.jpg';
  }

  Future<void> _pickPhotoFrom(ImageSource source) async {
    if (!kIsWeb && source == ImageSource.camera) {
      final cam = await Permission.camera.request();
      if (!cam.isGranted) {
        setState(() => _cameraDenied = true);
        return;
      }
    }
    setState(() {
      _cameraDenied = false;
      _error = null;
    });
    final x = await ImagePicker().pickImage(source: source, imageQuality: 85);
    if (x == null) return;
    final bytes = await x.readAsBytes();
    setState(() {
      _photoBytes = bytes;
      _photoExt = _extensionFor(x);
    });
  }

  Future<void> _pickPhoto() async {
    final source = kIsWeb
        ? ImageSource.gallery
        : await pickImageSourceForNative(context);
    if (source == null) return;
    await _pickPhotoFrom(source);
  }

  Future<void> _getLocation() async {
    final loc = ref.read(locationServiceProvider);
    final ok = await loc.ensureLocationPermission();
    if (!ok) {
      setState(() => _locationDenied = true);
      return;
    }
    setState(() => _locationDenied = false);
    final pos = await loc.currentPosition();
    if (pos != null) {
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
      });
    }
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _loading = true;
    });
    if (_photoBytes == null) {
      setState(() {
        _error = kIsWeb
            ? 'Choose a photo for the damage (browser testing uses gallery).'
            : 'Take or choose a photo of the damage.';
        _loading = false;
      });
      return;
    }
    if (_lat == null || _lng == null) {
      setState(() {
        _error = 'GPS location is required.';
        _loading = false;
      });
      return;
    }

    try {
      if (!mounted) return;
      context.push(
        '/citizen/ai-result',
        extra: AiResultArgs(
          imageBytes: _photoBytes!,
          fileExtension: _photoExt,
          latitude: _lat!,
          longitude: _lng!,
          addressText: _address.text.trim().isEmpty ? null : _address.text.trim(),
          nearestLandmark: _landmark.text.trim().isEmpty ? null : _landmark.text.trim(),
          damageType: _damageType,
        ),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report damage'),
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppDesign.navyGradient),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: const [
                  AppDesign.primaryNavy,
                  AppDesign.primaryContainerNavy,
                ],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Citizen report',
                  style: tt.labelLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Capture damage, attach GPS, and submit instantly.',
                  style: tt.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_cameraDenied) ...[
            _errorCard(
              context,
              'Camera permission denied. Enable it in Settings to capture evidence.',
            ),
            const SizedBox(height: 12),
          ],
          if (_locationDenied) ...[
            _errorCard(
              context,
              'Location permission denied. GPS is mandatory for report routing.',
            ),
            const SizedBox(height: 12),
          ],
          _surfaceCard(
            context,
            child: Column(
              children: [
                OutlinedButton.icon(
                  onPressed: _pickPhoto,
                  icon: Icon(
                    kIsWeb
                        ? Icons.photo_library_outlined
                        : Icons.photo_camera_outlined,
                  ),
                  label: Text(
                    _photoBytes == null
                        ? (kIsWeb ? 'Choose photo' : 'Take photo')
                        : (kIsWeb ? 'Change photo' : 'Retake photo'),
                  ),
                ),
                if (_photoBytes != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.memory(
                        _photoBytes!,
                        height: 210,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _surfaceCard(
            context,
            child: OutlinedButton.icon(
              onPressed: _getLocation,
              icon: const Icon(Icons.my_location_outlined),
              label: Text(
                _lat == null
                    ? 'Get GPS location'
                    : 'GPS: ${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}',
              ),
            ),
          ),
          const SizedBox(height: 12),
          _surfaceCard(
            context,
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Damage type'),
                  items: _damageTypes
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(e.replaceAll('_', ' ')),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _damageType = v),
                  initialValue: _damageType,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _address,
                  decoration: const InputDecoration(labelText: 'Address / area'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _landmark,
                  decoration: const InputDecoration(labelText: 'Nearest landmark'),
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: cs.error)),
          ],
          const SizedBox(height: 24),
          GradientPrimaryButton(
            onPressed: _loading ? null : _submit,
            label: 'Continue to AI review',
            icon: Icons.arrow_forward_rounded,
            loading: _loading,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _surfaceCard(BuildContext context, {required Widget child}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          ...AppDesign.cardShadow(cs),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  Widget _errorCard(BuildContext context, String text) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: TextStyle(color: cs.onErrorContainer, fontWeight: FontWeight.w600),
      ),
    );
  }
}
