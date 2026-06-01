import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Controllers ──────────────────────────────────────────────────────────
  late AnimationController _logoController;
  late AnimationController _bottomController;
  late AnimationController _pulseController;
  late AnimationController _glowController;

  // ── Logo animations ───────────────────────────────────────────────────────
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<Offset> _logoSlide;

  // ── Bottom bar animations ─────────────────────────────────────────────────
  late Animation<double> _bottomFade;
  late Animation<double> _lineWidth;

  // ── Continuous animations ─────────────────────────────────────────────────
  late Animation<double> _pulse;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _bottomController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    // Logo
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _logoScale = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.8, curve: Curves.elasticOut),
      ),
    );
    _logoSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _logoController,
            curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
          ),
        );

    // Bottom bar
    _bottomFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bottomController, curve: Curves.easeOut),
    );
    _lineWidth = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _bottomController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    // Pulse & glow
    _pulse = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _glow = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Sequence
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) _bottomController.forward();
    });

    // Navigate directly to home after 6.5s
    Future.delayed(const Duration(milliseconds: 6500), () {
      if (mounted) context.go('/home');
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _bottomController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF050D12),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── 1. Stadium Background ─────────────────────────────────────────
          Image.asset(
            'assets/images/stadium_bg.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),

          // ── 2. Dark gradient overlay ──────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xCC050D12),
                  Color(0x55050D12),
                  Color(0x33050D12),
                  Color(0x55050D12),
                  Color(0xDD050D12),
                  Color(0xFF050D12),
                ],
                stops: [0.0, 0.2, 0.42, 0.58, 0.78, 1.0],
              ),
            ),
          ),

          // ── 3. Radial glow behind logo ────────────────────────────────────
          AnimatedBuilder(
            animation: _glowController,
            builder: (_, _) {
              return Center(
                child: Transform.translate(
                  offset: const Offset(0, -40),
                  child: Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Color.lerp(
                            const Color(0x22F4A429),
                            const Color(0x44F4A429),
                            _glow.value,
                          )!,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // ── 4. Main content ───────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),

                // Animated logo
                AnimatedBuilder(
                  animation: Listenable.merge([
                    _logoController,
                    _pulseController,
                  ]),
                  builder: (_, _) {
                    return FadeTransition(
                      opacity: _logoFade,
                      child: SlideTransition(
                        position: _logoSlide,
                        child: Transform.scale(
                          scale: _logoScale.value * _pulse.value,
                          child: _buildLogo(),
                        ),
                      ),
                    );
                  },
                ),

                const Spacer(flex: 4),

                // READY TO PLAY + expanding line
                AnimatedBuilder(
                  animation: _bottomController,
                  builder: (_, _) {
                    return FadeTransition(
                      opacity: _bottomFade,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 48),
                        child: Column(
                          children: [
                            const Text(
                              'READY TO PLAY',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF4ADE80),
                                letterSpacing: 4.0,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              width:
                                  _lineWidth.value *
                                  math.min(screenWidth * 0.45, 200),
                              height: 2.5,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                gradient: const LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Color(0xFF4ADE80),
                                    Colors.transparent,
                                  ],
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x884ADE80),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (_, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color.lerp(
                  const Color(0x44F4A429),
                  const Color(0x88F4A429),
                  _glow.value,
                )!,
                blurRadius: 60,
                spreadRadius: 10,
              ),
              BoxShadow(
                color: Color.lerp(
                  const Color(0x22FFD700),
                  const Color(0x55FFD700),
                  _glow.value,
                )!,
                blurRadius: 30,
                spreadRadius: 4,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Image.asset(
        'assets/images/scorely_logo.png',
        width: 200,
        height: 200,
        fit: BoxFit.contain,
      ),
    );
  }
}
