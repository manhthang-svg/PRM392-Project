import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:origami/app/routes.dart';
import 'package:origami/app/theme.dart';

/// Màn hình Splash Screen với animation đẹp cho ứng dụng Origami
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Controllers cho các animation
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _particleController;
  late AnimationController _shimmerController;
  late AnimationController _progressController;

  // Logo animations
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _logoRotate;

  // Text animations
  late Animation<double> _titleOpacity;
  late Animation<Offset> _titleSlide;
  late Animation<double> _subtitleOpacity;
  late Animation<Offset> _subtitleSlide;

  // Shimmer
  late Animation<double> _shimmerAnim;

  // Progress bar
  late Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimationSequence();
  }

  void _setupAnimations() {
    // Logo controller
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    _logoRotate = Tween<double>(begin: -0.5, end: 0.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );

    // Text controller
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _subtitleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _subtitleSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    // Particle controller (looping)
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Shimmer controller (looping)
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _shimmerAnim = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.linear),
    );

    // Progress controller
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _progressAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
  }

  void _startAnimationSequence() async {
    // Bước 1: Logo xuất hiện
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _logoController.forward();

    // Bước 2: Text xuất hiện
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    _textController.forward();

    // Bước 3: Progress bar
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    _progressController.forward();

    // Bước 4: Chuyển sang màn hình tiếp theo
    await Future.delayed(const Duration(milliseconds: 3200));
    if (!mounted) return;
    _navigateNext();
  }

  void _navigateNext() {
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _particleController.dispose();
    _shimmerController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFF0F5), // Rose white
              Color(0xFFFCE4EC), // Pastel pink light
              Color(0xFFF8BBD0), // Pastel pink
              Color(0xFFF48FB1), // Pastel pink deep
            ],
            stops: [0.0, 0.35, 0.65, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Background floating origami cranes particles
            _buildParticles(size),

            // Background decorative circles
            _buildDecorativeCircles(size),

            // Main content
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  // Logo
                  _buildLogo(),

                  const SizedBox(height: 40),

                  // Title & Subtitle
                  _buildTexts(),

                  const Spacer(flex: 2),

                  // Progress bar & version
                  _buildBottomSection(),

                  const SizedBox(height: 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecorativeCircles(Size size) {
    return Stack(
      children: [
        // Top left circle
        Positioned(
          top: -size.width * 0.25,
          left: -size.width * 0.2,
          child: AnimatedBuilder(
            animation: _particleController,
            builder: (_, __) {
              return Transform.scale(
                scale: 1.0 + 0.05 * math.sin(_particleController.value * 2 * math.pi),
                child: Container(
                  width: size.width * 0.65,
                  height: size.width * 0.65,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.15),
                  ),
                ),
              );
            },
          ),
        ),
        // Bottom right circle
        Positioned(
          bottom: -size.width * 0.2,
          right: -size.width * 0.15,
          child: AnimatedBuilder(
            animation: _particleController,
            builder: (_, __) {
              return Transform.scale(
                scale: 1.0 + 0.05 * math.sin(_particleController.value * 2 * math.pi + math.pi),
                child: Container(
                  width: size.width * 0.55,
                  height: size.width * 0.55,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.12),
                  ),
                ),
              );
            },
          ),
        ),
        // Middle accent circle
        Positioned(
          top: size.height * 0.3,
          right: -size.width * 0.1,
          child: Container(
            width: size.width * 0.3,
            height: size.width * 0.3,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildParticles(Size size) {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (_, __) {
        return CustomPaint(
          size: size,
          painter: _OrigamiParticlePainter(
            progress: _particleController.value,
          ),
        );
      },
    );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _logoController,
      builder: (_, __) {
        return FadeTransition(
          opacity: _logoOpacity,
          child: Transform.scale(
            scale: _logoScale.value,
            child: Transform.rotate(
              angle: _logoRotate.value,
              child: _buildLogoContainer(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogoContainer() {
    return AnimatedBuilder(
      animation: _shimmerAnim,
      builder: (_, __) {
        return Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Color(0xFFFCE4EC),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE8A0BF).withOpacity(0.5),
                blurRadius: 30,
                spreadRadius: 5,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.8),
                blurRadius: 20,
                offset: const Offset(-5, -5),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Shimmer overlay
              ClipOval(
                child: ShaderMask(
                  shaderCallback: (rect) {
                    return LinearGradient(
                      begin: Alignment(_shimmerAnim.value - 0.5, 0),
                      end: Alignment(_shimmerAnim.value + 0.5, 0),
                      colors: [
                        Colors.transparent,
                        Colors.white.withOpacity(0.4),
                        Colors.transparent,
                      ],
                    ).createShader(rect);
                  },
                  child: Container(
                    width: 130,
                    height: 130,
                    color: Colors.white,
                  ),
                ),
              ),
              // Origami crane icon (custom painted)
              CustomPaint(
                size: const Size(72, 72),
                painter: _OrigamiCranePainter(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTexts() {
    return Column(
      children: [
        // App name
        AnimatedBuilder(
          animation: _textController,
          builder: (_, __) {
            return FadeTransition(
              opacity: _titleOpacity,
              child: SlideTransition(
                position: _titleSlide,
                child: ShaderMask(
                  shaderCallback: (rect) {
                    return const LinearGradient(
                      colors: [
                        Color(0xFF8B2252),
                        Color(0xFFD45A7A),
                        Color(0xFF8B2252),
                      ],
                    ).createShader(rect);
                  },
                  child: Text(
                    'Origami',
                    style: TextStyle(
                      fontFamily: 'Playfair Display',
                      fontSize: 52,
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // masked by ShaderMask
                      letterSpacing: 3,
                      shadows: [
                        Shadow(
                          color: Colors.white.withOpacity(0.5),
                          offset: const Offset(2, 2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 12),

        // Tagline
        AnimatedBuilder(
          animation: _textController,
          builder: (_, __) {
            return FadeTransition(
              opacity: _subtitleOpacity,
              child: SlideTransition(
                position: _subtitleSlide,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'Fold your creativity',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF6D1B45),
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 24),

        // Decorative dots
        AnimatedBuilder(
          animation: _textController,
          builder: (_, __) {
            return FadeTransition(
              opacity: _subtitleOpacity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == 2 ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == 2
                          ? const Color(0xFF8B2252)
                          : const Color(0xFFD4A5C9),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBottomSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        children: [
          // Progress bar
          AnimatedBuilder(
            animation: _progressAnim,
            builder: (_, __) {
              return Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _progressAnim.value,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: const AlwaysStoppedAnimation(
                        Color(0xFF8B2252),
                      ),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'v1.0.0',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: const Color(0xFF8B2252).withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Custom Painter: Origami Crane Logo
// ──────────────────────────────────────────────
class _OrigamiCranePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..isAntiAlias = true
      ..color = const Color(0xFFD45A7A).withOpacity(0.4);

    final w = size.width;
    final h = size.height;

    // Body (main diamond shape)
    final bodyGradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFF48FB1), Color(0xFFE8A0BF)],
    );
    paint.shader = bodyGradient.createShader(Rect.fromLTWH(0, 0, w, h));

    final bodyPath = Path()
      ..moveTo(w * 0.5, h * 0.1)   // top
      ..lineTo(w * 0.85, h * 0.45)  // right
      ..lineTo(w * 0.5, h * 0.78)  // bottom
      ..lineTo(w * 0.15, h * 0.45)  // left
      ..close();

    canvas.drawPath(bodyPath, paint);
    canvas.drawPath(bodyPath, strokePaint);

    // Left wing
    final wingGradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFF8BBD0), Color(0xFFE8A0BF)],
    );
    paint.shader = wingGradient.createShader(Rect.fromLTWH(0, 0, w, h));

    final leftWingPath = Path()
      ..moveTo(w * 0.15, h * 0.45)
      ..lineTo(w * 0.0, h * 0.25)
      ..lineTo(w * 0.35, h * 0.55)
      ..close();

    canvas.drawPath(leftWingPath, paint);
    canvas.drawPath(leftWingPath, strokePaint);

    // Right wing
    final rightWingPath = Path()
      ..moveTo(w * 0.85, h * 0.45)
      ..lineTo(w * 1.0, h * 0.25)
      ..lineTo(w * 0.65, h * 0.55)
      ..close();

    canvas.drawPath(rightWingPath, paint);
    canvas.drawPath(rightWingPath, strokePaint);

    // Head
    final headPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFD45A7A)
      ..isAntiAlias = true;

    final headPath = Path()
      ..moveTo(w * 0.5, h * 0.1)
      ..lineTo(w * 0.42, h * 0.0)
      ..lineTo(w * 0.38, h * 0.12)
      ..lineTo(w * 0.44, h * 0.22)
      ..close();

    canvas.drawPath(headPath, headPaint);

    // Tail
    final tailPath = Path()
      ..moveTo(w * 0.5, h * 0.78)
      ..lineTo(w * 0.44, h * 0.95)
      ..lineTo(w * 0.56, h * 0.88)
      ..close();

    canvas.drawPath(tailPath, headPaint);

    // Center fold line
    final foldPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white.withOpacity(0.6);

    canvas.drawLine(
      Offset(w * 0.5, h * 0.1),
      Offset(w * 0.5, h * 0.78),
      foldPaint,
    );
    canvas.drawLine(
      Offset(w * 0.15, h * 0.45),
      Offset(w * 0.85, h * 0.45),
      foldPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ──────────────────────────────────────────────
// Custom Painter: Floating Origami Particles
// ──────────────────────────────────────────────
class _OrigamiParticlePainter extends CustomPainter {
  final double progress;

  const _OrigamiParticlePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final particles = [
      _Particle(0.1, 0.8, 0.0, 18),
      _Particle(0.25, 0.7, 0.2, 12),
      _Particle(0.8, 0.15, 0.5, 22),
      _Particle(0.9, 0.5, 0.1, 14),
      _Particle(0.05, 0.3, 0.7, 10),
      _Particle(0.7, 0.85, 0.3, 16),
      _Particle(0.5, 0.05, 0.6, 20),
      _Particle(0.4, 0.6, 0.9, 8),
      _Particle(0.6, 0.4, 0.4, 13),
    ];

    for (final p in particles) {
      final phase = (progress + p.phase) % 1.0;
      final floatY = math.sin(phase * 2 * math.pi) * 20;
      final x = p.xFraction * size.width;
      final y = p.yFraction * size.height + floatY;
      final opacity = 0.15 + 0.15 * math.sin(phase * 2 * math.pi);

      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.white.withOpacity(opacity);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(phase * 2 * math.pi * 0.3);

      _drawMiniCrane(canvas, p.size, paint);
      canvas.restore();
    }
  }

  void _drawMiniCrane(Canvas canvas, double size, Paint paint) {
    final path = Path()
      ..moveTo(0, -size * 0.5)
      ..lineTo(size * 0.4, 0)
      ..lineTo(0, size * 0.4)
      ..lineTo(-size * 0.4, 0)
      ..close();

    canvas.drawPath(path, paint);

    // Wings
    final wingPath = Path()
      ..moveTo(-size * 0.4, 0)
      ..lineTo(-size * 0.7, -size * 0.2)
      ..lineTo(-size * 0.1, size * 0.15)
      ..close();

    canvas.drawPath(wingPath, paint);

    final wingPath2 = Path()
      ..moveTo(size * 0.4, 0)
      ..lineTo(size * 0.7, -size * 0.2)
      ..lineTo(size * 0.1, size * 0.15)
      ..close();

    canvas.drawPath(wingPath2, paint);
  }

  @override
  bool shouldRepaint(covariant _OrigamiParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _Particle {
  final double xFraction;
  final double yFraction;
  final double phase;
  final double size;

  const _Particle(this.xFraction, this.yFraction, this.phase, this.size);
}
