// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:origami/app/app.dart';
import 'package:origami/core/auth/auth_session.dart';
import 'package:origami/core/auth/token_storage.dart';
import 'package:origami/features/auth/screens/login_screen.dart';

void main() {
  testWidgets('shows splash screen and opens login', (tester) async {
    final session = AuthSession(tokenStorage: MemoryTokenStorage());
    addTearDown(session.dispose);
    await tester.pumpWidget(OrigamiApp(authSession: session));

    expect(find.text('Origami'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2300));
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);

    await tester.ensureVisible(find.text('Sign Up'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();
    expect(find.text('Join Origami'), findsOneWidget);
    expect(find.text('Send verification code'), findsOneWidget);
  });

  testWidgets('login screen does not overflow on a narrow viewport', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(180, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final session = AuthSession(tokenStorage: MemoryTokenStorage());
    addTearDown(session.dispose);
    await tester.pumpWidget(
      AuthScope(
        session: session,
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Or continue with'), findsOneWidget);
    expect(find.text('Google'), findsOneWidget);
    expect(find.text('Apple'), findsOneWidget);
  });
}
