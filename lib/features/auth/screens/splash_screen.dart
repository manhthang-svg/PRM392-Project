import 'package:flutter/material.dart';

import 'package:origami/app/routes.dart';
import 'package:origami/app/theme.dart';
import 'package:origami/core/auth/auth_session.dart';
import 'package:origami/core/widgets/common.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openInitialRoute());
  }

  Future<void> _openInitialRoute() async {
    final session = AuthScope.of(context, listen: false);
    await Future.wait([
      session.initialize(),
      Future<void>.delayed(const Duration(milliseconds: 1200)),
    ]);
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(
      session.isAuthenticated ? AppRoutes.newsfeed : AppRoutes.login,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FadeTransition(
          opacity: _opacity,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const OrigamiMark(),
                const SizedBox(height: 28),
                Text('Origami', style: serifTitle(34)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
