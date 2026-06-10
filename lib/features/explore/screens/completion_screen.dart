import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:origami/app/routes.dart';
import 'package:origami/app/theme.dart';
import 'package:origami/core/state/app_state.dart';
import 'package:origami/core/widgets/common.dart';

const _resultImage =
    'https://images.unsplash.com/photo-1616680214084-22670a2a9e34?w=900&h=900&fit=crop';

class CompletionScreen extends StatefulWidget {
  const CompletionScreen({super.key});

  @override
  State<CompletionScreen> createState() => _CompletionScreenState();
}

class _CompletionScreenState extends State<CompletionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _photoTaken = false;
  bool _historySaved = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (_, _) => CustomPaint(
                  painter: _CelebrationPainter(_controller.value),
                ),
              ),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
              children: [
                ScaleTransition(
                  scale: CurvedAnimation(
                    parent: _controller,
                    curve: Curves.elasticOut,
                  ),
                  child: Center(
                    child: Container(
                      width: 116,
                      height: 116,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.celebration_outlined,
                        color: Colors.white,
                        size: 56,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Congratulations!',
                  textAlign: TextAlign.center,
                  style: serifTitle(33),
                ),
                const SizedBox(height: 7),
                const Text(
                  "You've completed the Classic Red Crane tutorial",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.mutedText),
                ),
                const SizedBox(height: 27),
                AspectRatio(
                  aspectRatio: 1,
                  child: _photoTaken
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            AppNetworkImage(
                              url: _resultImage,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            Positioned(
                              right: 12,
                              bottom: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 11,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: .9),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Classic Red Crane',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'Origami',
                                      style: TextStyle(
                                        color: AppColors.mutedText,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.accent, Color(0x55F5B8C5)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt_outlined,
                                color: AppColors.primaryDark,
                                size: 60,
                              ),
                              SizedBox(height: 12),
                              Text('Capture your creation'),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(19),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '+50 XP',
                        style: serifTitle(29, color: AppColors.primaryDark),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Achievement Unlocked!',
                        style: TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (!_photoTaken)
                  PrimaryButton(
                    label: 'Take Photo',
                    icon: Icons.camera_alt_outlined,
                    onPressed: () => setState(() => _photoTaken = true),
                  )
                else ...[
                  PrimaryButton(
                    label: _historySaved
                        ? 'Saved to History'
                        : 'Save to History',
                    icon: _historySaved ? Icons.check : Icons.save_outlined,
                    onPressed: _historySaved
                        ? null
                        : () {
                            AppStateScope.of(
                              context,
                              listen: false,
                            ).addCompletedFold(
                              title: 'Classic Red Crane',
                              image: _resultImage,
                              difficulty: 'Easy',
                              duration: '25 min',
                            );
                            setState(() => _historySaved = true);
                            showAppMessage(context, 'Saved to your history');
                          },
                  ),
                  const SizedBox(height: 10),
                  OutlineAppButton(
                    label: 'Share to Feed',
                    icon: Icons.ios_share_outlined,
                    onPressed: () =>
                        showAppMessage(context, 'Shared to your feed'),
                  ),
                ],
                const SizedBox(height: 10),
                OutlineAppButton(
                  label: 'Browse More Tutorials',
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.library,
                    (route) => false,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CelebrationPainter extends CustomPainter {
  const _CelebrationPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);
    for (var i = 0; i < 45; i++) {
      final x = random.nextDouble() * size.width;
      final startY = random.nextDouble() * size.height * .25;
      final y =
          startY + progress * (size.height * .7 + random.nextDouble() * 80);
      final paint = Paint()
        ..color = i.isEven
            ? AppColors.primary.withValues(alpha: 1 - progress * .65)
            : AppColors.accent.withValues(alpha: 1 - progress * .55);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * math.pi * (i.isEven ? 2 : -2));
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: 5 + random.nextDouble() * 5,
          height: 9 + random.nextDouble() * 7,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _CelebrationPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
