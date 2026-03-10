// This is a basic Flutter widget test.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:skill_tracker/main.dart';

void main() {
  testWidgets('App launches and shows Login Page', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SkillTrackerApp());

    // Verify that we are on the login page
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsWidgets);
  });
}
