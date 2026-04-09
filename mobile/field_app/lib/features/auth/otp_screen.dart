import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/theme.dart';
import '../../core/widgets/auth_brand_header.dart';
import '../../core/widgets/gradient_primary_button.dart';
import '../../providers/providers.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.phoneE164});

  final String phoneE164;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _code = TextEditingController();
  final _otpFocus = FocusNode();
  bool _loading = false;
  String? _error;
  bool _cardVisible = false;
  int _resendLeft = 30;
  bool _verifying = false;

  @override
  void initState() {
    super.initState();
    _otpFocus.addListener(() => setState(() {}));
    _startResendTimer();
    _code.addListener(_onCodeChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _cardVisible = true);
    });
  }

  @override
  void dispose() {
    _code.removeListener(_onCodeChanged);
    _code.dispose();
    _otpFocus.dispose();
    super.dispose();
  }

  void _onCodeChanged() {
    if (_code.text.trim().length == 6 && !_loading && !_verifying) {
      _verify();
    }
  }

  void _startResendTimer() {
    Future.doWhile(() async {
      if (!mounted) return false;
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      if (_resendLeft <= 0) return false;
      setState(() => _resendLeft -= 1);
      return _resendLeft > 0;
    });
  }

  Future<void> _verify() async {
    if (_verifying) return;
    setState(() {
      _error = null;
      _loading = true;
      _verifying = true;
    });
    final token = _code.text.trim();
    if (token.length < 6) {
      setState(() {
        _error = 'Enter the 6-digit code from SMS.';
        _loading = false;
      });
      return;
    }
    try {
      await ref.read(authServiceProvider).verifyOtp(
            phoneE164: widget.phoneE164,
            token: token,
          );
      if (!mounted) return;
      context.go('/splash');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _verifying = false;
        });
      }
    }
  }

  Future<void> _resendOtp() async {
    if (_resendLeft > 0 || _loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(authServiceProvider)
          .signInWithOtp(phoneE164: widget.phoneE164);
      if (!mounted) return;
      setState(() => _resendLeft = 30);
      _startResendTimer();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String get _maskedPhone {
    final p = widget.phoneE164.replaceFirst('+91', '');
    if (p.length >= 10) {
      return '+91 ${p.substring(0, 5)} ${p.substring(5)}';
    }
    return widget.phoneE164;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AuthBrandHeader(
                    bottomPadding: 56,
                    compactLogo: true,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: AnimatedSlide(
                      offset: _cardVisible ? Offset.zero : const Offset(0, 0.08),
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutCubic,
                      child: AnimatedOpacity(
                        opacity: _cardVisible ? 1 : 0,
                        duration: const Duration(milliseconds: 260),
                        child: Material(
                          color: cs.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                            side: BorderSide(
                              color: cs.outlineVariant.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              color: cs.surface,
                              boxShadow: AppDesign.cardShadow(cs),
                            ),
                            padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Enter OTP',
                                  style: tt.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: cs.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Code sent to $_maskedPhone',
                                  style: tt.bodyMedium?.copyWith(
                                    color: cs.onSurfaceVariant.withValues(
                                      alpha: 0.85,
                                    ),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 28),
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      decoration: BoxDecoration(
                                        color: _otpFocus.hasFocus
                                            ? cs.surface
                                            : cs.surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: _otpFocus.hasFocus
                                            ? [
                                                BoxShadow(
                                                  color: cs.primary.withValues(
                                                    alpha: 0.12,
                                                  ),
                                                  blurRadius: 0,
                                                  spreadRadius: 2,
                                                ),
                                              ]
                                            : null,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 8,
                                      ),
                                      child: TextField(
                                        controller: _code,
                                        focusNode: _otpFocus,
                                        keyboardType: TextInputType.number,
                                        maxLength: 8,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly,
                                        ],
                                        textAlign: TextAlign.center,
                                        style: tt.headlineSmall?.copyWith(
                                          letterSpacing: 12,
                                          fontWeight: FontWeight.w800,
                                          color: cs.onSurface,
                                        ),
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          counterText: '',
                                          hintText: '• • • • • •',
                                          hintStyle: tt.headlineSmall?.copyWith(
                                            letterSpacing: 8,
                                            color: cs.onSurfaceVariant
                                                .withValues(alpha: 0.25),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: 20,
                                      right: 20,
                                      bottom: -2,
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 280),
                                        curve: Curves.easeOutCubic,
                                        height: _otpFocus.hasFocus ? 3 : 0,
                                        decoration: BoxDecoration(
                                          color: cs.onTertiaryContainer,
                                          borderRadius:
                                              BorderRadius.circular(99),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (_error != null) ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    _error!,
                                    style: TextStyle(
                                      color: cs.error,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 28),
                                GradientPrimaryButton(
                                  onPressed: _loading ? null : _verify,
                                  label: 'Verify & continue',
                                  icon: Icons.check_rounded,
                                  loading: _loading,
                                ),
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed:
                                      (_resendLeft == 0 && !_loading)
                                          ? _resendOtp
                                          : null,
                                  child: Text(
                                    _resendLeft == 0
                                        ? 'Resend OTP'
                                        : 'Resend OTP in ${_resendLeft}s',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_rounded),
                color: Colors.white,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
