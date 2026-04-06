import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/role_config.dart';
import '../../core/widgets/auth_brand_header.dart';
import '../../core/widgets/gradient_primary_button.dart';
import '../../providers/providers.dart';

class OfficialLoginScreen extends ConsumerStatefulWidget {
  const OfficialLoginScreen({super.key});

  @override
  ConsumerState<OfficialLoginScreen> createState() => _OfficialLoginScreenState();
}

class _OfficialLoginScreenState extends ConsumerState<OfficialLoginScreen> {
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {
      _error = null;
      _loading = true;
    });

    final id = _identifier.text.trim();
    final pwd = _password.text;
    if (id.isEmpty || pwd.isEmpty) {
      setState(() {
        _error = 'Enter email/mobile and password.';
        _loading = false;
      });
      return;
    }

    try {
      await ref.read(authServiceProvider).signInOfficial(
            identifier: id,
            password: pwd,
          );
      final profile = await ref.read(authServiceProvider).fetchProfile();
      if (!mounted) return;

      if (profile == null) {
        context.go('/blocked', extra: 'No profile row for this account.');
        return;
      }
      if (!profile.isActive) {
        context.go('/blocked', extra: 'This account is inactive.');
        return;
      }
      if (profile.role == 'citizen') {
        await ref.read(authServiceProvider).signOut();
        if (!mounted) return;
        setState(() {
          _error = 'Citizen accounts should use mobile OTP login.';
          _loading = false;
        });
        return;
      }
      if (!isMobileRole(profile.role) && !isWebHandoffRole(profile.role)) {
        context.go('/blocked', extra: 'Unknown role: ${profile.role}');
        return;
      }
      context.go('/splash');
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
      backgroundColor: cs.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AuthBrandHeader(bottomPadding: 60, compactLogo: true),
              Transform.translate(
                offset: const Offset(0, -40),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: cs.surface,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1A1C1E).withValues(alpha: 0.06),
                          blurRadius: 32,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Official sign in',
                          style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'For JE, Mukadam, Contractor and other official roles.',
                          style: tt.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          controller: _identifier,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email or mobile number',
                            hintText: 'name@domain.com or 9876543210',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _password,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            suffixIcon: IconButton(
                              onPressed: () => setState(() => _obscure = !_obscure),
                              icon: Icon(
                                _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            style: TextStyle(
                              color: cs.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        GradientPrimaryButton(
                          onPressed: _loading ? null : _signIn,
                          label: 'Sign in',
                          icon: Icons.login_rounded,
                          loading: _loading,
                        ),
                        const SizedBox(height: 10),
                        TextButton.icon(
                          onPressed: () => context.go('/login'),
                          icon: const Icon(Icons.arrow_back_rounded),
                          label: const Text('Back to citizen OTP login'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
