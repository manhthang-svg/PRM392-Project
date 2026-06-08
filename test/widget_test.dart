import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origami/app/app.dart';

void main() {
  testWidgets('App smoke test — renders OrigamiApp', (WidgetTester tester) async {
    await tester.pumpWidget(const OrigamiApp());
    // Chỉ kiểm tra app render không crash
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
