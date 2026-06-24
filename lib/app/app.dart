import 'package:flutter/material.dart';
import 'package:origami/app/routes.dart';
import 'package:origami/app/theme.dart';
import 'package:origami/core/auth/auth_session.dart';
import 'package:origami/core/state/app_state.dart';

class OrigamiApp extends StatefulWidget {
  const OrigamiApp({super.key, this.authSession});

  final AuthSession? authSession;

  @override
  State<OrigamiApp> createState() => _OrigamiAppState();
}

class _OrigamiAppState extends State<OrigamiApp> {
  final AppState _state = AppState();
  late final AuthSession _authSession;
  late final bool _ownsAuthSession;
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _ownsAuthSession = widget.authSession == null;
    _authSession = widget.authSession ?? AuthSession();
    _authSession.addListener(_handleAuthChange);
  }

  void _handleAuthChange() {
    if (!_authSession.requiresLogin) return;
    _authSession.consumeLoginRequirement();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigatorKey.currentState?.pushNamedAndRemoveUntil(
        AppRoutes.login,
        (route) => false,
      );
    });
  }

  @override
  void dispose() {
    _authSession.removeListener(_handleAuthChange);
    if (_ownsAuthSession) _authSession.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      session: _authSession,
      child: AppStateScope(
        state: _state,
        child: MaterialApp(
          navigatorKey: _navigatorKey,
          title: 'Origami',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          initialRoute: AppRoutes.splash,
          onGenerateRoute: AppRouter.onGenerateRoute,
        ),
      ),
    );
  }
}
