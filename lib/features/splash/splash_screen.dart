import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Video ─────────────────────────────────────────────────────────────────
  late VideoPlayerController _videoController;

  // ── Phase tracking ────────────────────────────────────────────────────────
  // Phase 1: Video playing
  // Phase 2: After video ends – loading indicator + "READY TO PLAY"
  bool _videoEnded = false;
  bool _navigated = false;

  // ── Bottom "READY TO PLAY" animations ────────────────────────────────────
  late AnimationController _bottomController;
  late Animation<double> _bottomFade;
  late Animation<double> _lineWidth;

  // ── Loading dot animation ─────────────────────────────────────────────────
  late AnimationController _loadingController;
  late Animation<double> _loadingFade;

  // Dot bounce controllers
  late List<AnimationController> _dotControllers;
  late List<Animation<double>> _dotAnims;

  @override
  void initState() {
    super.initState();

    // ── Bottom bar controller ─────────────────────────────────────────────
    _bottomController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _bottomFade = CurvedAnimation(
      parent: _bottomController,
      curve: Curves.easeOut,
    );
    _lineWidth = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _bottomController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    // ── Loading overlay controller ────────────────────────────────────────
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _loadingFade = CurvedAnimation(
      parent: _loadingController,
      curve: Curves.easeIn,
    );

    // ── Bouncing dot controllers (3 dots, staggered) ──────────────────────
    _dotControllers = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      ),
    );
    _dotAnims = _dotControllers.map((c) {
      return Tween<double>(begin: 0, end: -10).animate(
        CurvedAnimation(parent: c, curve: Curves.easeInOut),
      );
    }).toList();

    // Stagger the dots
    void startDots() {
      for (int i = 0; i < _dotControllers.length; i++) {
        Future.delayed(Duration(milliseconds: i * 160), () {
          if (mounted) {
            _dotControllers[i].repeat(reverse: true);
          }
        });
      }
    }

    // ── Video setup ───────────────────────────────────────────────────────
    _videoController = VideoPlayerController.asset(
      'assets/images/Splash-screen-1.mp4',
    );

    _videoController.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
      _videoController.setLooping(false);
      _videoController.setVolume(0); // muted
      _videoController.play();

      // Listen for video completion
      _videoController.addListener(() {
        if (!mounted) return;
        final pos = _videoController.value.position;
        final dur = _videoController.value.duration;
        if (dur.inMilliseconds > 0 &&
            pos.inMilliseconds >= dur.inMilliseconds - 100 &&
            !_videoEnded) {
          setState(() => _videoEnded = true);
          _bottomController.forward();
          _loadingController.forward();
          startDots();

          // Navigate after a minimum 2.5s loading phase
          Future.delayed(const Duration(milliseconds: 2500), () {
            if (mounted && !_navigated) {
              _navigated = true;
              context.go('/home');
            }
          });
        }
      });
    }).catchError((_) {
      // Fallback: if video fails, navigate after 4s
      if (mounted && !_navigated) {
        Future.delayed(const Duration(seconds: 4), () {
          if (mounted && !_navigated) {
            _navigated = true;
            context.go('/home');
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _videoController.dispose();
    _bottomController.dispose();
    _loadingController.dispose();
    for (final c in _dotControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isInit = _videoController.value.isInitialized;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── 1. Video fill ──────────────────────────────────────────────────
          if (isInit)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController.value.size.width,
                  height: _videoController.value.size.height,
                  child: VideoPlayer(_videoController),
                ),
              ),
            )
          else
            // Pre-init: solid dark background
            Container(color: const Color(0xFF050D12)),

          // ── 2. Post-video overlay (loading phase) ─────────────────────────
          if (_videoEnded)
            FadeTransition(
              opacity: _loadingFade,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xAA050D12),
                      Color(0x55050D12),
                      Color(0xCC050D12),
                      Color(0xFF050D12),
                    ],
                    stops: [0.0, 0.4, 0.7, 1.0],
                  ),
                ),
              ),
            ),

          // ── 3. Bottom section: "READY TO PLAY" + loading dots ─────────────
          if (_videoEnded)
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 48),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // READY TO PLAY label
                      FadeTransition(
                        opacity: _bottomFade,
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
                            // Expanding glowing line
                            AnimatedBuilder(
                              animation: _lineWidth,
                              builder: (_, _) {
                                return Container(
                                  width: _lineWidth.value *
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
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Bouncing loading dots
                      FadeTransition(
                        opacity: _loadingFade,
                        child: _buildBouncingDots(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBouncingDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _dotAnims[i],
          builder: (_, _) {
            return Transform.translate(
              offset: Offset(0, _dotAnims[i].value),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color.lerp(
                    const Color(0xFF4ADE80),
                    Colors.white,
                    (i / 3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4ADE80).withValues(alpha: 0.6),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
