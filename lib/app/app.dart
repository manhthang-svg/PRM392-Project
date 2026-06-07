import 'package:flutter/material.dart';
import 'package:origami/app/routes.dart';
import 'package:origami/app/theme.dart';

/// Widget gốc của ứng dụng Origami
class OrigamiApp extends StatelessWidget {
  const OrigamiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Origami',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,
    );
  }
}
