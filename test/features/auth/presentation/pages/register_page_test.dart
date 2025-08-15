import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_test/bloc_test.dart';

import 'package:flutter_real_time_chat/features/auth/presentation/pages/register_page.dart';
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
        child: const RegisterPage(),
      ),
    );
  }

  group('RegisterPage', () {
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
      expect(find.text(AppStrings.createAccount), findsOneWidget);
      expect(find.text(AppStrings.displayName), findsOneWidget);
      expect(find.text(AppStrings.email), findsOneWidget);
      expect(find.text(AppStrings.password), findsOneWidget);
      expect(find.text(AppStrings.confirmPassword), findsOneWidget);
      expect(find.text(AppStrings.signUp), findsOneWidget);
      expect(find.text(AppStrings.alreadyHaveAccount), findsOneWidget);
      expect(find.text(AppStrings.login), findsOneWidget);
    });

    testWidgets('should have proper form fields', (tester) async {
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
      expect(find.byType(TextFormField), findsNWidgets(4));
      expect(find.byType(ElevatedButton), findsOneWidget);
    });
  });
}
