import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

import 'package:flutter_real_time_chat/main.dart' as app;
import 'package:flutter_real_time_chat/core/routing/route_names.dart';

import 'helpers/test_helpers.dart';
import 'helpers/firebase_test_setup.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Flow Integration Tests', () {
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

    testWidgets('User registration flow with validation',
        (WidgetTester tester) async {
      await tester.pumpWidget(app.MyApp());
      await tester.pumpAndSettle();

      // Navigate to registration page
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      // Test form validation - empty fields
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create Account'));
      await tester.pumpAndSettle();

      // Should show validation errors
      expect(find.textContaining('required'), findsWidgets);

      // Test invalid email format
      await TestHelpers.enterText(tester, 'Email', 'invalid-email');
      await TestHelpers.enterText(tester, 'Display Name', 'Test User');
      await TestHelpers.enterText(tester, 'Password', '123');
      await TestHelpers.enterText(tester, 'Confirm Password', '456');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Create Account'));
      await tester.pumpAndSettle();

      // Should show email and password validation errors
      expect(find.textContaining('valid email'), findsOneWidget);
      expect(find.textContaining('password'), findsWidgets);

      // Test password mismatch
      await TestHelpers.enterText(tester, 'Email', 'test@example.com');
      await TestHelpers.enterText(tester, 'Password', 'password123');
      await TestHelpers.enterText(tester, 'Confirm Password', 'different123');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Create Account'));
      await tester.pumpAndSettle();

      expect(find.textContaining('match'), findsOneWidget);

      // Test successful registration
      await TestHelpers.enterText(tester, 'Confirm Password', 'password123');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Create Account'));
      await tester.pumpAndSettle();

      // Should navigate to chat rooms list
      expect(find.text('Chat Rooms'), findsOneWidget);
    });

    testWidgets('User login flow with error handling',
        (WidgetTester tester) async {
      await tester.pumpWidget(app.MyApp());
      await tester.pumpAndSettle();

      // Should be on login page
      expect(find.text('Welcome Back'), findsOneWidget);

      // Test empty form submission
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pumpAndSettle();

      expect(find.textContaining('required'), findsWidgets);

      // Test invalid credentials
      await TestHelpers.enterText(tester, 'Email', 'wrong@example.com');
      await TestHelpers.enterText(tester, 'Password', 'wrongpassword');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pumpAndSettle();

      // Should show authentication error
      expect(find.textContaining('Invalid'), findsOneWidget);

      // Test successful login
      await TestHelpers.authenticateUser(
          mockAuth, 'test@example.com', 'Test User');

      await TestHelpers.enterText(tester, 'Email', 'test@example.com');
      await TestHelpers.enterText(tester, 'Password', 'password123');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pumpAndSettle();

      // Should navigate to chat rooms list
      expect(find.text('Chat Rooms'), findsOneWidget);
    });

    testWidgets('Authentication state persistence',
        (WidgetTester tester) async {
      // Setup authenticated user
      await TestHelpers.authenticateUser(
          mockAuth, 'test@example.com', 'Test User');

      await tester.pumpWidget(app.MyApp());
      await tester.pumpAndSettle();

      // Should skip login and go directly to chat rooms
      expect(find.text('Chat Rooms'), findsOneWidget);
      expect(find.text('Welcome Back'), findsNothing);
    });

    testWidgets('Logout functionality', (WidgetTester tester) async {
      // Setup authenticated user
      await TestHelpers.authenticateUser(
          mockAuth, 'test@example.com', 'Test User');

      await tester.pumpWidget(app.MyApp());
      await tester.pumpAndSettle();

      // Should be on chat rooms page
      expect(find.text('Chat Rooms'), findsOneWidget);

      // Test logout
      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();

      // Should return to login page
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Chat Rooms'), findsNothing);
    });

    testWidgets('Authentication guard for protected routes',
        (WidgetTester tester) async {
      await tester.pumpWidget(app.MyApp());
      await tester.pumpAndSettle();

      // Try to navigate to protected route without authentication
      TestHelpers.navigateViaDeepLink(tester, RouteNames.chatRoomsList);
      await tester.pumpAndSettle();

      // Should redirect to login page
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Chat Rooms'), findsNothing);
    });

    testWidgets('Password reset flow', (WidgetTester tester) async {
      await tester.pumpWidget(app.MyApp());
      await tester.pumpAndSettle();

      // Navigate to password reset (if implemented)
      if (find.text('Forgot Password?').evaluate().isNotEmpty) {
        await tester.tap(find.text('Forgot Password?'));
        await tester.pumpAndSettle();

        // Test password reset form
        await TestHelpers.enterText(tester, 'Email', 'test@example.com');
        await tester.tap(find.widgetWithText(ElevatedButton, 'Reset Password'));
        await tester.pumpAndSettle();

        // Should show success message
        expect(find.textContaining('reset'), findsOneWidget);
      }
    });

    testWidgets('User profile data creation', (WidgetTester tester) async {
      await tester.pumpWidget(app.MyApp());
      await tester.pumpAndSettle();

      // Register new user
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      await TestHelpers.enterText(tester, 'Email', 'newuser@example.com');
      await TestHelpers.enterText(tester, 'Display Name', 'New User');
      await TestHelpers.enterText(tester, 'Password', 'password123');
      await TestHelpers.enterText(tester, 'Confirm Password', 'password123');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Create Account'));
      await tester.pumpAndSettle();

      // Verify user profile was created in Firestore
      final userDoc = await mockFirestore
          .collection('users')
          .where('email', isEqualTo: 'newuser@example.com')
          .get();

      expect(userDoc.docs.isNotEmpty, true);
      expect(userDoc.docs.first.data()['displayName'], 'New User');
    });

    testWidgets('Authentication error recovery', (WidgetTester tester) async {
      await tester.pumpWidget(app.MyApp());
      await tester.pumpAndSettle();

      // Simulate network error during login
      await TestHelpers.simulateNetworkError(mockFirestore);

      await TestHelpers.enterText(tester, 'Email', 'test@example.com');
      await TestHelpers.enterText(tester, 'Password', 'password123');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pumpAndSettle();

      // Should show network error
      expect(find.textContaining('network'), findsOneWidget);

      // Test retry mechanism
      await TestHelpers.restoreNetwork(mockFirestore);
      await TestHelpers.authenticateUser(
          mockAuth, 'test@example.com', 'Test User');

      if (find.textContaining('Retry').evaluate().isNotEmpty) {
        await tester.tap(find.textContaining('Retry'));
        await tester.pumpAndSettle();

        // Should succeed after network restoration
        expect(find.text('Chat Rooms'), findsOneWidget);
      }
    });

    testWidgets('Multiple authentication attempts',
        (WidgetTester tester) async {
      await tester.pumpWidget(app.MyApp());
      await tester.pumpAndSettle();

      // Test multiple failed login attempts
      for (int i = 1; i <= 3; i++) {
        await TestHelpers.enterText(tester, 'Email', 'wrong$i@example.com');
        await TestHelpers.enterText(tester, 'Password', 'wrongpassword$i');

        await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
        await tester.pumpAndSettle();

        // Should show error for each attempt
        expect(find.textContaining('Invalid'), findsOneWidget);
      }

      // Test successful login after failures
      await TestHelpers.authenticateUser(
          mockAuth, 'test@example.com', 'Test User');

      await TestHelpers.enterText(tester, 'Email', 'test@example.com');
      await TestHelpers.enterText(tester, 'Password', 'password123');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Chat Rooms'), findsOneWidget);
    });
  });
}
