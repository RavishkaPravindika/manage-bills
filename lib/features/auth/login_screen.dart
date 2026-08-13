import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manage_bills/app/theme.dart';
import 'package:manage_bills/features/auth/auth_provider.dart';
import 'package:manage_bills/models/user_role.dart';

// ============================================================
// Login Screen — Glassmorphism design with Google + Email auth
// ============================================================

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  // ── Form
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _showEmailForm = false;

  // ── State
  bool _googleLoading = false;
  bool _emailLoading = false;
  String? _errorMessage;

  // ── Animations
  late final AnimationController _bgCtrl;
  late final AnimationController _cardCtrl;
  late final Animation<double> _cardFade;
  late final Animation<Offset> _cardSlide;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _cardCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _cardFade = CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut);
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut));

    _cardCtrl.forward();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _cardCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ── Google Sign-In ─────────────────────────────────────────

  Future<void> _signInWithGoogle() async {
    setState(() {
      _googleLoading = true;
      _errorMessage = null;
    });
    try {
      await AuthService.signInWithGoogle();
      final role = await ref.read(userRoleProvider.future);
      if (mounted) {
        if (role.isSuperAdmin) {
          context.go('/super-admin');
        } else if (role.canManage) {
          context.go('/admin/bills');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Signed in! Account is pending Super Admin approval.',
              ),
            ),
          );
          context.go('/search');
        }
      }
    } catch (e) {
      setState(() => _errorMessage = _friendlyError(e.toString()));
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  // ── Email Sign-In ─────────────────────────────────────────

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _emailLoading = true;
      _errorMessage = null;
    });
    try {
      await AuthService.signInWithEmail(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      final role = await ref.read(userRoleProvider.future);
      if (mounted) {
        if (role.isSuperAdmin) {
          context.go('/super-admin');
        } else if (role.canManage) {
          context.go('/admin/bills');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Signed in! Account is pending Super Admin approval.',
              ),
            ),
          );
          context.go('/search');
        }
      }
    } catch (e) {
      setState(() => _errorMessage = _friendlyError(e.toString()));
    } finally {
      if (mounted) setState(() => _emailLoading = false);
    }
  }

  String _friendlyError(String raw) {
    debugPrint('Auth Error: $raw');
    if (raw.contains('wrong-password') ||
        raw.contains('invalid-credential') ||
        raw.contains('INVALID_LOGIN_CREDENTIALS')) {
      return 'Invalid email or password.';
    }
    if (raw.contains('user-not-found')) return 'No account with that email.';
    if (raw.contains('too-many-requests')) {
      return 'Too many attempts. Try again later.';
    }
    if (raw.contains('cancelled')) return 'Sign-in was cancelled.';
    if (raw.contains('network')) return 'Check your internet connection.';
    return 'Sign-in failed: ${raw.replaceAll(RegExp(r'^Exception:\s*'), '')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // ── Animated gradient background ────────────────────
          _AnimatedBackground(controller: _bgCtrl, isDark: isDark),

          // ── Content ─────────────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: FadeTransition(
                    opacity: _cardFade,
                    child: SlideTransition(
                      position: _cardSlide,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // App icon + title
                          _buildHeader(isDark),
                          const SizedBox(height: 32),

                          // Glass card
                          _GlassCard(
                            isDark: isDark,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Google button
                                _GoogleSignInButton(
                                  loading: _googleLoading,
                                  onPressed: _signInWithGoogle,
                                ),
                                const SizedBox(height: 20),

                                // Divider
                                _OrDivider(isDark: isDark),
                                const SizedBox(height: 20),

                                // Toggle email form
                                AnimatedCrossFade(
                                  duration: const Duration(milliseconds: 300),
                                  crossFadeState: _showEmailForm
                                      ? CrossFadeState.showSecond
                                      : CrossFadeState.showFirst,
                                  firstChild: _buildEmailToggleButton(isDark),
                                  secondChild:
                                      _buildEmailForm(isDark),
                                ),

                                // Error
                                if (_errorMessage != null) ...[
                                  const SizedBox(height: 16),
                                  _ErrorBanner(message: _errorMessage!),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Guest link
                          TextButton(
                            key: const Key('login_guest_button'),
                            onPressed: () => context.go('/search'),
                            child: Text(
                              'Continue as Guest →',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white54
                                    : Colors.black45,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4F46E5).withValues(alpha: 0.4),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.receipt_long_rounded,
            color: Colors.white,
            size: 36,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Manage Bills',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF111827),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Sign in to continue',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailToggleButton(bool isDark) {
    return OutlinedButton(
      key: const Key('show_email_login_button'),
      onPressed: () => setState(() => _showEmailForm = true),
      style: OutlinedButton.styleFrom(
        foregroundColor: isDark ? Colors.white70 : const Color(0xFF374151),
        side: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.black12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.email_outlined, size: 18),
          SizedBox(width: 10),
          Text('Continue with Email'),
        ],
      ),
    );
  }

  Widget _buildEmailForm(bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            key: const Key('login_email_field'),
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Enter your email';
              if (!v.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('login_password_field'),
            controller: _passwordCtrl,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Enter your password' : null,
            onFieldSubmitted: (_) => _signInWithEmail(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              key: const Key('login_email_submit_button'),
              onPressed: _emailLoading ? null : _signInWithEmail,
              child: _emailLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Sign In'),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => setState(() => _showEmailForm = false),
            child: const Text('← Back', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

// ── Animated gradient background ─────────────────────────────

class _AnimatedBackground extends StatelessWidget {
  const _AnimatedBackground({
    required this.controller,
    required this.isDark,
  });

  final AnimationController controller;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = controller.value;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1 + t * 0.6, -1 + t * 0.4),
              end: Alignment(1 - t * 0.3, 1 - t * 0.2),
              colors: isDark
                  ? const [
                      Color(0xFF0A0E1A),
                      Color(0xFF1a1040),
                      Color(0xFF0e1a3a),
                    ]
                  : const [
                      Color(0xFFEEF2FF),
                      Color(0xFFF5F3FF),
                      Color(0xFFE0F2FE),
                    ],
            ),
          ),
          child: Stack(
            children: [
              // Glow orbs
              _Orb(
                offset: Offset(
                  -80 + math.sin(t * math.pi) * 40,
                  -60 + math.cos(t * math.pi) * 30,
                ),
                color: isDark
                    ? const Color(0xFF4F46E5).withValues(alpha: 0.25)
                    : const Color(0xFF4F46E5).withValues(alpha: 0.12),
                size: 280,
              ),
              _Orb(
                offset: Offset(
                  MediaQuery.sizeOf(context).width - 120 + math.cos(t * math.pi) * 40,
                  MediaQuery.sizeOf(context).height / 2 + math.sin(t * math.pi) * 50,
                ),
                color: isDark
                    ? const Color(0xFF06B6D4).withValues(alpha: 0.15)
                    : const Color(0xFF06B6D4).withValues(alpha: 0.08),
                size: 220,
              ),
              _Orb(
                offset: Offset(
                  MediaQuery.sizeOf(context).width / 3,
                  MediaQuery.sizeOf(context).height - 180 + math.sin(t * math.pi * 1.5) * 30,
                ),
                color: isDark
                    ? const Color(0xFF7C3AED).withValues(alpha: 0.2)
                    : const Color(0xFF7C3AED).withValues(alpha: 0.08),
                size: 240,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.offset, required this.color, required this.size});
  final Offset offset;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}

// ── Glass card ────────────────────────────────────────────────

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child, required this.isDark});
  final Widget child;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.8),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ── Google Sign-In button ─────────────────────────────────────

class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton({
    required this.loading,
    required this.onPressed,
  });
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? const Color(0xFF1F2937) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        key: const Key('google_signin_button'),
        borderRadius: BorderRadius.circular(12),
        onTap: loading ? null : onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
            ),
          ),
          child: loading
              ? const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _GoogleLogo(),
                    const SizedBox(width: 12),
                    Text(
                      'Continue with Google',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF374151),
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final center = rect.center;
    final r = size.width / 2;

    // Draw the 4 colored quadrants of the Google 'G'
    final paint = Paint()..style = PaintingStyle.fill;
    const gap = 0.05;

    final segments = [
      (const Color(0xFF4285F4), -math.pi / 2 + gap, math.pi / 2 - gap * 2),
      (const Color(0xFF34A853), 0.0 + gap, math.pi / 2 - gap * 2),
      (const Color(0xFFFBBC05), math.pi / 2 + gap, math.pi / 2 - gap * 2),
      (const Color(0xFFEA4335), math.pi + gap, math.pi / 2 - gap * 2),
    ];

    for (final (color, start, sweep) in segments) {
      paint.color = color;
      canvas.drawArc(rect, start, sweep, true, paint);
    }

    // White center circle
    paint.color = Colors.white;
    canvas.drawCircle(center, r * 0.56, paint);

    // Blue right bar of the G
    paint.color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(center.dx, center.dy - r * 0.22, r, r * 0.44),
      paint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Or divider ────────────────────────────────────────────────

class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final color = isDark ? Colors.white24 : Colors.black12;
    return Row(
      children: [
        Expanded(child: Divider(color: color, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ),
        Expanded(child: Divider(color: color, height: 1)),
      ],
    );
  }
}

// ── Error banner ──────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.errorContainer.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 16, color: cs.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: cs.onErrorContainer, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
