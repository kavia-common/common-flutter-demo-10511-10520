import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_frontend/main.dart';

void main() {
  testWidgets('App generation message displayed', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // The status text starts with the legacy scaffold message (kept for compatibility).
    expect(find.text('flutter_frontend App is being generated...'), findsOneWidget);

    // The app uses a spinner as part of the minimal placeholder UI.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('App bar has correct title', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('flutter_frontend'), findsOneWidget);
  });
}
