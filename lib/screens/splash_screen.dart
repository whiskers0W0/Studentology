import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:studentology/core/navigation/slide_route.dart';
import 'package:studentology/core/theme/app_theme.dart';
import 'package:studentology/screens/auth/login_screen.dart';
import 'package:studentology/screens/home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // One-shot intro (1 400 ms)
  late final AnimationController _introCtrl;
  // Continuous idle float (2 200 ms, looping)
  late final AnimationController _floatCtrl;

  // ── Intro animations ────────────────────────────────────────────────────────
  late final Animation<double> _bgFade;

  late final Animation<double> _logoSlide; // drops in from above
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;

  late final Animation<double> _titleSlide; // rises from below
  late final Animation<double> _titleFade;

  late final Animation<double> _taglineFade;
  late final Animation<double> _taglineSpacing; // letter-spacing collapses in

  // ── Idle animations (loop) ──────────────────────────────────────────────────
  late final Animation<double> _float;      // ±5 px vertical bob
  late final Animation<double> _glowPulse;  // background opacity pulse

  @override
  void initState() {
    super.initState();

    _introCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    // Background blooms first
    _bgFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introCtrl,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    // Logo: drops from -60 px, scales from 0.6, fades in — all with spring feel
    _logoSlide = Tween<double>(begin: -60.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _introCtrl,
        curve: const Interval(0.0, 0.58, curve: Curves.easeOutBack),
      ),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introCtrl,
        curve: const Interval(0.0, 0.28, curve: Curves.easeOut),
      ),
    );
    _logoScale = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(
        parent: _introCtrl,
        curve: const Interval(0.0, 0.52, curve: Curves.easeOutBack),
      ),
    );

    // Title rises from below, staggered after logo
    _titleSlide = Tween<double>(begin: 28.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _introCtrl,
        curve: const Interval(0.38, 0.74, curve: Curves.easeOutCubic),
      ),
    );
    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introCtrl,
        curve: const Interval(0.38, 0.70, curve: Curves.easeOut),
      ),
    );

    // Tagline fades in with letter-spacing contracting (wide → tight)
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introCtrl,
        curve: const Interval(0.60, 0.90, curve: Curves.easeOut),
      ),
    );
    _taglineSpacing = Tween<double>(begin: 5.0, end: 0.4).animate(
      CurvedAnimation(
        parent: _introCtrl,
        curve: const Interval(0.60, 0.98, curve: Curves.easeOut),
      ),
    );

    // Idle float & glow pulse
    _float = Tween<double>(begin: -5.0, end: 5.0).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );
    _glowPulse = Tween<double>(begin: 0.10, end: 0.26).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );

    _introCtrl.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.wait<void>([
      Future.delayed(const Duration(milliseconds: 2800)),
      FirebaseAuth.instance.authStateChanges().first,
    ]);
    if (!mounted) return;
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    Navigator.of(context).pushReplacement(
      slideRoute(isLoggedIn ? const HomeScreen() : const LoginScreen()),
    );
  }

  @override
  void dispose() {
    _introCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Pulsing background blobs ─────────────────────────────────────
          AnimatedBuilder(
            animation: Listenable.merge([_bgFade, _glowPulse]),
            builder: (context, _) => Opacity(
              opacity: _bgFade.value,
              child: Stack(
                children: [
                  Positioned(
                    top: -130,
                    right: -130,
                    child: _GlowBlob(
                      size: 400,
                      color: AppTheme.primaryAccent
                          .withValues(alpha: _glowPulse.value),
                    ),
                  ),
                  Positioned(
                    bottom: -90,
                    left: -90,
                    child: _GlowBlob(
                      size: 280,
                      color: AppTheme.secondaryAccent
                          .withValues(alpha: _glowPulse.value * 0.55),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Logo + text ──────────────────────────────────────────────────
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_introCtrl, _floatCtrl]),
              builder: (context, _) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo: drop-in + idle float
                  Transform.translate(
                    offset: Offset(0, _logoSlide.value + _float.value),
                    child: Opacity(
                      opacity: _logoFade.value,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: Hero(
                          tag: 'app-logo',
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: 120,
                            height: 120,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // App name — slides up
                  Transform.translate(
                    offset: Offset(0, _titleSlide.value),
                    child: Opacity(
                      opacity: _titleFade.value,
                      child: Text(
                        'Studentology',
                        style: GoogleFonts.ultra(
                          fontSize: 34,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Tagline — fades in with letter-spacing compression
                  Opacity(
                    opacity: _taglineFade.value,
                    child: Text(
                      'Your Academic Companion',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primaryAccent,
                        letterSpacing: _taglineSpacing.value,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────────

class _GlowBlob extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowBlob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
        ),
      ),
    );
  }
}
