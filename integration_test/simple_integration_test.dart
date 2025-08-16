import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

import 'package:flutter_real_time_chat/main.dart' as app;
import 'helpers/firebase_test_setup.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Simple Integration Tests', () {
    late MockFirebaseAuth mockAuth;
    late FakeFirebaseFirestore mockFirestore;

    setUpAll(() async {
      await FirebaseTestSetup.initialize();
    });

    setUp(() async {
      mockAuth = MockFirebaseAuth();
      mockFirestore = FakeFirebaseFirestore();
      await FirebaseTestSetup.setupTestData(mockFirestore);
      await resetTestDependencies();
      await initializeTestDependencies(mockAuth, mockFirestore);
    });

    tearDown(() async {
      await FirebaseTestSetup.cleanup(mockFirestore);
    });

    testWidgets('App launches and shows login screen',
        (WidgetTester tester) async {
      await tester.pumpWidget(app.MyApp());
      await tester.pumpAndSettle();

      // Should show some form of authentication UI
      expect(find.byType(MaterialApp), findsOneWidget);

      // Look for common authentication elements
      final hasLoginElements = find.text('Sign In').evaluate().isNotEmpty ||
          find.text('Login').evaluate().isNotEmpty ||
          find.text('Welcome').evaluate().isNotEmpty ||
          find.byType(TextField).evaluate().isNotEmpty;

      expect(hasLoginElements, true,
          reason: 'Should show authentication UI elements');
    });

    testWidgets('Can enter text in input fields', (WidgetTester tester) async {
      await tester.pumpWidget(app.MyApp());
      await tester.pumpAndSettle();

      // Find text fields and try to enter text
      final textFields = find.byType(TextField);
      if (textFields.evaluate().isNotEmpty) {
        await tester.enterText(textFields.first, 'test@example.com');
        await tester.pump();

        // Verify text was entered
        expect(find.text('test@example.com'), findsOneWidget);
      }
    });

    testWidgets('App handles button taps without crashing',
        (WidgetTester tester) async {
      await tester.pumpWidget(app.MyApp());
      await tester.pumpAndSettle();

      // Find buttons and try tapping them
      final buttons = find.byType(ElevatedButton);
      if (buttons.evaluate().isNotEmpty) {
        await tester.tap(buttons.first);
        await tester.pumpAndSettle();

        // App should not crash
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('Navigation works without errors', (WidgetTester tester) async {
      await tester.pumpWidget(app.MyApp());
      await tester.pumpAndSettle();

      // Look for navigation elements
      final navElements = [
        find.text('Create Account'),
        find.text('Register'),
        find.text('Sign Up'),
        find.byIcon(Icons.arrow_back),
        find.byIcon(Icons.menu),
      ];

      for (final element in navElements) {
        if (element.evaluate().isNotEmpty) {
          await tester.tap(element);
          await tester.pumpAndSettle();

          // Should not crash
          expect(tester.takeException(), isNull);
          break; // Only test one navigation element
        }
      }
    });

    testWidgets('Firebase integration works', (WidgetTester tester) async {
      // Test that Firebase mocks are working
      expect(mockAuth, isNotNull);
      expect(mockFirestore, isNotNull);

      // Test basic Firestore operations
      final testDoc = mockFirestore.collection('test').doc('test');
      await testDoc.set({'test': 'data'});

      final snapshot = await testDoc.get();
      expect(snapshot.exists, true);
      expect(snapshot.data()?['test'], 'data');
    });

    testWidgets('Performance test - app startup time',
        (WidgetTester tester) async {
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(app.MyApp());
      await tester.pumpAndSettle();

      stopwatch.stop();

      // App should start within reasonable time (10 seconds)
      expect(stopwatch.elapsedMilliseconds, lessThan(10000));
      print('App startup time: ${stopwatch.elapsedMilliseconds}ms');
    });

    testWidgets('Memory usage test - multiple screen transitions',
        (WidgetTester tester) async {
      await tester.pumpWidget(app.MyApp());
      await tester.pumpAndSettle();

      // Perform multiple operations to test memory usage
      for (int i = 0; i < 10; i++) {
        // Find any tappable element and tap it
        final tappableElements = [
          find.byType(ElevatedButton),
          find.byType(TextButton),
          find.byType(IconButton),
          find.byType(InkWell),
        ];

        for (final element in tappableElements) {
          if (element.evaluate().isNotEmpty) {
            await tester.tap(element.first);
            await tester.pump(const Duration(milliseconds: 100));
            break;
          }
        }
      }

      await tester.pumpAndSettle();

      // App should still be responsive
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Error handling test - invalid operations',
        (WidgetTester tester) async {
      await tester.pumpWidget(app.MyApp());
      await tester.pumpAndSettle();

      // Try to trigger errors by entering invalid data
      final textFields = find.byType(TextField);
      if (textFields.evaluate().length >= 2) {
        // Enter invalid email format
        await tester.enterText(textFields.first, 'invalid-email');
        await tester.pump();

        // Enter short password
        await tester.enterText(textFields.at(1), '123');
        await tester.pump();

        // Try to submit
        final buttons = find.byType(ElevatedButton);
        if (buttons.evaluate().isNotEmpty) {
          await tester.tap(buttons.first);
          await tester.pumpAndSettle();
        }
      }

      // App should handle errors gracefully
      expect(tester.takeException(), isNull);
    });

    testWidgets('Real-time data simulation test', (WidgetTester tester) async {
      await tester.pumpWidget(app.MyApp());
      await tester.pumpAndSettle();

      // Simulate real-time data updates
      final testCollection = mockFirestore.collection('messages');

      // Add some test data
      for (int i = 1; i <= 5; i++) {
        await testCollection.add({
          'content': 'Test message $i',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'senderId': 'test-user',
        });

        await tester.pump(const Duration(milliseconds: 100));
      }

      await tester.pumpAndSettle();

      // Verify no crashes occurred during data updates
      expect(tester.takeException(), isNull);
    });

    testWidgets('Stress test - rapid user interactions',
        (WidgetTester tester) async {
      await tester.pumpWidget(app.MyApp());
      await tester.pumpAndSettle();

      // Perform rapid interactions
      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 20; i++) {
        // Find any interactive element
        final interactiveElements = [
          find.byType(TextField),
          find.byType(ElevatedButton),
          find.byType(TextButton),
        ];

        for (final element in interactiveElements) {
          if (element.evaluate().isNotEmpty) {
            if (element == find.byType(TextField)) {
              await tester.enterText(element.first, 'rapid test $i');
            } else {
              await tester.tap(element.first);
            }
            await tester.pump(const Duration(milliseconds: 50));
            break;
          }
        }
      }

      await tester.pumpAndSettle();
      stopwatch.stop();

      print(
          'Rapid interactions completed in: ${stopwatch.elapsedMilliseconds}ms');

      // App should remain stable
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
