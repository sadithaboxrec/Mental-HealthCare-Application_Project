import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:mental_health_support_app/core/assets/app_assets.dart';
import 'package:mental_health_support_app/core/services/auth_service.dart';
import 'package:mental_health_support_app/core/theme/app_colors.dart';
import 'package:mental_health_support_app/core/theme/app_spacing.dart';
import 'package:mental_health_support_app/core/theme/app_typography.dart';
import 'package:mental_health_support_app/presentation/components/atoms/mindcare_asset.dart';
import 'package:mental_health_support_app/presentation/components/atoms/mindcare_pill_button.dart';
import 'package:mental_health_support_app/presentation/components/atoms/mindcare_text_field.dart';
import 'package:mental_health_support_app/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  late AnimationController _blobCtrl;
  late Animation<double> _blobAnim;

  @override
  void initState() {
    super.initState();
    _blobCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
    _blobAnim = CurvedAnimation(parent: _blobCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _blobCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    if (email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Please enter email and password.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await AuthService.login(email, pass);
      if (!mounted) return;
      if (result.isSuccess) {
        ref.invalidate(currentUserDocProvider);
      } else {
        setState(() => _error = result.error);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final width = MediaQuery.of(context).size.width;
    final isWide = kIsWeb || width > 800;

    if (isWide) {
      return _WebLoginLayout(
        emailCtrl: _emailCtrl,
        passCtrl: _passCtrl,
        loading: _loading,
        error: _error,
        onSignIn: _signIn,
        animation: _blobAnim,
        reduceMotion: reduceMotion,
      );
    }

    // ── Mobile layout (unchanged) ────────────────────────────────────────────
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: AppColors.mist,
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: SizedBox(
          height: math.max(screenHeight, 600),
          child: Column(
            children: [
              Expanded(
                flex: 40,
                child: _HeroBlobSection(
                  animation: _blobAnim,
                  reduceMotion: reduceMotion,
                ),
              ),
              Expanded(
                flex: 60,
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.cloud,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(AppSpacing.radiusXl),
                    ),
                  ),
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: _LoginForm(
                    emailCtrl: _emailCtrl,
                    passCtrl: _passCtrl,
                    loading: _loading,
                    error: _error,
                    onSignIn: _signIn,
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

// ── Web two-column layout ───────────────────────────────────────────────────────
class _WebLoginLayout extends StatelessWidget {
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final bool loading;
  final String? error;
  final VoidCallback onSignIn;
  final Animation<double> animation;
  final bool reduceMotion;

  const _WebLoginLayout({
    required this.emailCtrl,
    required this.passCtrl,
    required this.loading,
    required this.error,
    required this.onSignIn,
    required this.animation,
    required this.reduceMotion,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // ── Left panel: hero ───────────────────────────────────────────────
          Expanded(
            flex: 55,
            child: _WebHeroPanel(
              animation: animation,
              reduceMotion: reduceMotion,
            ),
          ),
          // ── Right panel: form ──────────────────────────────────────────────
          Expanded(
            flex: 45,
            child: Container(
              color: AppColors.cloud,
              child: Center(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                        vertical: AppSpacing.xxxl,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppColors.cloud,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusMd,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.lavenderDeep.withValues(
                                    alpha: 0.25,
                                  ),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: const Padding(
                              padding: EdgeInsets.all(5),
                              child: MindCareAsset(
                                asset: AppAssets.logo,
                                fallbackIcon: PhosphorIconsDuotone.heartbeat,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          Text(
                            'Welcome back',
                            style: AppTypography.headline2.copyWith(
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Sign in to your MindCare account',
                            style: AppTypography.body.copyWith(
                              color: AppColors.slate,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxxl),
                          _LoginForm(
                            emailCtrl: emailCtrl,
                            passCtrl: passCtrl,
                            loading: loading,
                            error: error,
                            onSignIn: onSignIn,
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          Center(
                            child: Text(
                              'Access is managed by your healthcare provider',
                              style: AppTypography.caption,
                              textAlign: TextAlign.center,
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
}

class _WebHeroPanel extends StatelessWidget {
  final Animation<double> animation;
  final bool reduceMotion;

  const _WebHeroPanel({required this.animation, required this.reduceMotion});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            final t = reduceMotion ? 0.5 : animation.value;
            return CustomPaint(painter: _BlobPainter(t: t));
          },
        ),
        // Content
        Padding(
          padding: const EdgeInsets.all(AppSpacing.max),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const MindCareAsset(
                asset: AppAssets.loginHero,
                width: 260,
                height: 220,
                fallbackIcon: PhosphorIconsDuotone.brain,
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'MindCare',
                style: AppTypography.headline1.copyWith(
                  color: AppColors.ink,
                  fontSize: 52,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Clinical intelligence for\nbetter mental health outcomes.',
                style: AppTypography.headline4.copyWith(
                  color: AppColors.inkLight,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              // Feature pills
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: const [
                  _FeaturePill(
                    icon: PhosphorIconsDuotone.brain,
                    label: 'X-AI Analysis',
                  ),
                  _FeaturePill(
                    icon: PhosphorIconsDuotone.shieldCheck,
                    label: 'Secure & Private',
                  ),
                  _FeaturePill(
                    icon: PhosphorIconsDuotone.chartLine,
                    label: 'Digital Phenotyping',
                  ),
                  _FeaturePill(
                    icon: PhosphorIconsDuotone.heartbeat,
                    label: 'Real-Time Monitoring',
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeaturePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.cloud.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: AppColors.cloud.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: AppColors.lavender.withValues(alpha: 0.15),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PhosphorIcon(icon, size: 16, color: AppColors.lavenderDeep),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(color: AppColors.inkLight),
          ),
        ],
      ),
    );
  }
}

// ── Shared login form (mobile + web) ─────────────────────────────────────────
class _LoginForm extends StatelessWidget {
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final bool loading;
  final String? error;
  final VoidCallback onSignIn;

  const _LoginForm({
    required this.emailCtrl,
    required this.passCtrl,
    required this.loading,
    required this.error,
    required this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: 'Email address input',
          textField: true,
          child: MindCareTextField(
            controller: emailCtrl,
            hint: 'your@email.com',
            label: 'Email',
            prefixIcon: PhosphorIcons.envelope(PhosphorIconsStyle.duotone),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Semantics(
          label: 'Password input',
          textField: true,
          child: MindCareTextField(
            controller: passCtrl,
            hint: '••••••••',
            label: 'Password',
            prefixIcon: PhosphorIcons.lock(PhosphorIconsStyle.duotone),
            isPassword: true,
            textInputAction: TextInputAction.done,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (error != null) ...[
          Semantics(
            liveRegion: true,
            child: Text(
              error!,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.criticalDeep,
              ),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        MindCarePillButton(
          label: 'Sign In',
          onPressed: loading ? null : onSignIn,
          isLoading: loading,
          width: double.infinity,
          hero: true,
          color: AppColors.lavenderDeep,
          semanticLabel: loading ? 'Signing in, please wait' : 'Sign In',
        ),
      ],
    );
  }
}

// ── Animated blob hero section (mobile) ────────────────────────────────────────
class _HeroBlobSection extends StatelessWidget {
  final Animation<double> animation;
  final bool reduceMotion;

  const _HeroBlobSection({required this.animation, required this.reduceMotion});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            final t = reduceMotion ? 0.5 : animation.value;
            return CustomPaint(painter: _BlobPainter(t: t));
          },
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cloud.withValues(alpha: 0.25),
                border: Border.all(
                  color: AppColors.cloud.withValues(alpha: 0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.lavenderDeep.withValues(alpha: 0.3),
                    blurRadius: 32,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              alignment: Alignment.center,
              clipBehavior: Clip.antiAlias,
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: MindCareAsset(
                  asset: AppAssets.logo,
                  fallbackIcon: PhosphorIconsDuotone.heartbeat,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.base),
            Text(
              'MindCare',
              style: AppTypography.headline1.copyWith(color: AppColors.ink),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Your mental wellness companion',
              style: AppTypography.body.copyWith(color: AppColors.slate),
            ),
          ],
        ),
      ],
    );
  }
}

class _BlobPainter extends CustomPainter {
  final double t;
  _BlobPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final lavenderPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.lavender.withValues(alpha: 0.55),
          AppColors.sky.withValues(alpha: 0.30),
          AppColors.mist.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final skyPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.sky.withValues(alpha: 0.45),
          AppColors.lavenderMist.withValues(alpha: 0.25),
          AppColors.mist.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final cx1 = size.width * (0.3 + 0.1 * math.sin(t * math.pi));
    final cy1 = size.height * (0.35 + 0.08 * math.cos(t * math.pi));
    final r1 = size.width * (0.55 + 0.05 * t);
    canvas.drawCircle(Offset(cx1, cy1), r1, lavenderPaint);

    final cx2 = size.width * (0.75 - 0.08 * math.cos(t * math.pi));
    final cy2 = size.height * (0.55 + 0.1 * math.sin(t * math.pi));
    final r2 = size.width * (0.45 + 0.04 * t);
    canvas.drawCircle(Offset(cx2, cy2), r2, skyPaint);
  }

  @override
  bool shouldRepaint(_BlobPainter old) => old.t != t;
}
