import 'package:flutter/material.dart';
import 'package:origami/app/routes.dart';
import 'package:origami/app/theme.dart';
import 'package:origami/core/state/app_state.dart';

class OrigamiApp extends StatefulWidget {
  const OrigamiApp({super.key});

  @override
  State<OrigamiApp> createState() => _OrigamiAppState();
}

class _OrigamiAppState extends State<OrigamiApp> {
  final AppState _state = AppState();

  @override
  Widget build(BuildContext context) {
    return AppStateScope(
      state: _state,
      child: MaterialApp(
        title: 'Origami',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
  }
}
