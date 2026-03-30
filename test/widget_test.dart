// This is a basic Flutter widget test.
//
// YIO Recipe App test - verifies app initialization

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:yio_recipe_app/main.dart';

void main() {
  testWidgets('YIO Recipe App initializes correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const YioRecipeApp());

    // Verify app title
    expect(find.text('YIO'), findsWidgets);
    
    // Verify bottom navigation bar exists
    expect(find.byType(NavigationBar), findsWidgets);
  });
}
