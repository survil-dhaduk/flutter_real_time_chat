import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_test/bloc_test.dart';

import 'package:flutter_real_time_chat/features/auth/presentation/pages/login_page.dart';
import 'package:flutter_real_time_chat/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_real_time_chat/core/constants/app_strings.dart';
import 'package:flutter_real_time_chat/core/theme/app_theme.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockAuthBloc mockAuthBloc;

  setUp(() {
    mockAuthBloc = MockAuthBloc();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: BlocProvider<AuthBloc>(
        create: (context) => mockAuthBloc,
        child: const LoginPage(),
      ),
    );
  }

  group('LoginPage', () {
    testWidgets('should display all required UI elements', (tester) async {
      // Arrange
      whenListen(
        mockAuthBloc,
        Stream.fromIterable([const AuthUnauthenticated()]),
        initialState: const AuthUnauthenticated(),
      );

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Assert
      expect(find.text(AppStrings.appName), findsOneWidget);
      expect(find.text(AppStrings.login), findsOneWidget);
      expect(find.text(AppStrings.email), findsOneWidget);
      expect(find.text(AppStrings.password), findsOneWidget);
      expect(find.text(AppStrings.signIn), findsOneWidget);
      expect(find.text(AppStrings.forgotPassword), findsOneWidget);
      expect(find.text(AppStrings.dontHaveAccount), findsOneWidget);
      expect(find.text(AppStrings.register), findsOneWidget);
    });

    testWidgets('should show validation errors for empty fields',
        (tester) async {
      // Arrange
      whenListen(
        mockAuthBloc,
        Stream.fromIterable([const AuthUnauthenticated()]),
        initialState: const AuthUnauthenticated(),
      );

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.tap(find.text(AppStrings.signIn));
      await tester.pump();

      // Assert
      expect(find.text(AppStrings.emailRequired), findsOneWidget);
      expect(find.text(AppStrings.passwordRequired), findsOneWidget);
    });

    testWidgets('should show loading indicator when AuthLoading state',
        (tester) async {
      // Arrange
      whenListen(
        mockAuthBloc,
        Stream.fromIterable([const AuthLoading()]),
        initialState: const AuthLoading(),
      );

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
