// This is a basic Flutter widget test for HomePlates app

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_app/data/local/sample_model.dart';
import 'package:flutter_app/utils/constants.dart';

void main() {
  setUpAll(() async {
    // Initialize Hive for testing
    await Hive.initFlutter();
    Hive.registerAdapter(SampleModelAdapter());
    await Hive.openBox<SampleModel>(HiveBoxes.sampleBox);
  });

  tearDownAll(() async {
    // Close Hive boxes after tests
    await Hive.close();
  });

  testWidgets('HomePlates app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const HomePlatesApp());

    // Wait for splash screen
    await tester.pump(const Duration(seconds: 3));

    // Verify that we can find the HomePlates title
    expect(find.textContaining('Home'), findsWidgets);
  });
}
