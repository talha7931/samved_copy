import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/widgets/auth_brand_header.dart';
import '../../core/widgets/gradient_primary_button.dart';
import '../../providers/providers.dart';

class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final _page = PageController();
  final _phone = TextEditingController();
  final _otp = TextEditingController();
  final _name = TextEditingController();
  bool _accept = false;
  bool _busy = false;
  String? _error;
  int _step = 0;
  int _resendLeft = 0;

  String get _e164 => '+91${_phone.text.replaceAll(RegExp(r'\D'), '')}';

  @override
  void dispose() {
    _page.dispose();
    _phone.dispose();
    _otp.dispose();
    _name.dispose();
    super.dispose();
  }

  void _startCountdown() {
    setState(() => _resendLeft = 30);
    Future.doWhile(() async {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      if (_resendLeft <= 0) return false;
      setState(() => _resendLeft -= 1);
      return _resendLeft > 0;
    });
  }

  Future<void> _sendOtp() async {
    final d = _phone.text.replaceAll(RegExp(r'\D'), '');
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(d)) {
      setState(() => _error = 'Enter a valid 10-digit mobile number starting with 6/7/8/9.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authServiceProvider).signInWithOtp(phoneE164: _e164);
      if (!mounted) return;
      _startCountdown();
      setState(() => _step = 1);
      _page.animateToPage(1, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verifyOtp() async {
    final token = _otp.text.trim();
    if (token.length != 6) {
      setState(() => _error = 'Enter 6-digit OTP.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authServiceProvider).verifyOtp(phoneE164: _e164, token: token);
      final profile = await ref.read(authServiceProvider).fetchProfile();
      if (!mounted) return;
      if (profile != null && profile.fullName.trim().isNotEmpty) {
        context.go('/splash');
        return;
      }
      setState(() => _step = 2);
      _page.animateToPage(2, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    if (_resendLeft > 0) return;
    await _sendOtp();
  }

  Future<void> _createAccount() async {
    final name = _name.text.trim();
    if (name.length < 2) {
      setState(() => _error = 'Enter full name (minimum 2 characters).');
      return;
    }
    if (!_accept) {
      setState(() => _error = 'Please accept terms to continue.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) {
        throw Exception('Session expired. Please register again.');
      }
      await Supabase.instance.client.from('profiles').update({
        'full_name': name,
        'phone': _e164,
        'role': 'citizen',
        'is_active': true,
      }).eq('id', uid);
      if (!mounted) return;
      context.go('/splash');
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        await ref.read(authServiceProvider).signOut();
        if (!mounted) return;
        context.go('/login');
        return;
      }
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const AuthBrandHeader(compactLogo: true, bottomPadding: 40),
            Expanded(
              child: PageView(
                controller: _page,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _StepWrap(
                    title: 'Register - Mobile Number',
                    child: Column(
                      children: [
                        TextField(
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(
                            labelText: 'Mobile number',
                            prefixText: '+91 ',
                            counterText: '',
                          ),
                        ),
                        const SizedBox(height: 12),
                        GradientPrimaryButton(
                          onPressed: _busy ? null : _sendOtp,
                          label: 'Send OTP',
                          loading: _busy,
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: () => context.go('/login'),
                          child: const Text('Already registered? Sign In'),
                        ),
                      ],
                    ),
                  ),
                  _StepWrap(
                    title: 'Verify OTP',
                    child: Column(
                      children: [
                        TextField(
                          controller: _otp,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          onChanged: (v) {
                            if (v.length == 6 && !_busy) _verifyOtp();
                          },
                          decoration: const InputDecoration(
                            labelText: '6-digit OTP',
                            counterText: '',
                          ),
                        ),
                        const SizedBox(height: 12),
                        GradientPrimaryButton(
                          onPressed: _busy ? null : _verifyOtp,
                          label: 'Verify OTP',
                          loading: _busy,
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: (_resendLeft == 0 && !_busy) ? _resend : null,
                          child: Text(
                            _resendLeft == 0
                                ? 'Resend OTP'
                                : 'Resend OTP in ${_resendLeft}s',
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StepWrap(
                    title: 'Personal Details',
                    child: Column(
                      children: [
                        TextField(
                          controller: _name,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(labelText: 'Full name'),
                        ),
                        CheckboxListTile(
                          value: _accept,
                          onChanged: (v) => setState(() => _accept = v ?? false),
                          contentPadding: EdgeInsets.zero,
                          title: const Text('I accept terms and privacy policy'),
                        ),
                        const SizedBox(height: 10),
                        GradientPrimaryButton(
                          onPressed: (_busy || !_accept) ? null : _createAccount,
                          label: 'Create Account',
                          loading: _busy,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Text(
                  _error!,
                  style: TextStyle(color: cs.error, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text('Step ${_step + 1} of 3'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepWrap extends StatelessWidget {
  const _StepWrap({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}
