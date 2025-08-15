import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:flutter_real_time_chat/core/errors/failures.dart';
import 'package:flutter_real_time_chat/features/auth/domain/entities/user.dart';
import 'package:flutter_real_time_chat/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_real_time_chat/features/auth/domain/usecases/sign_in.dart';

import 'sign_in_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  late SignInUseCase useCase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    useCase = SignInUseCase(mockAuthRepository);
  });

  const tEmail = 'test@example.com';
  const tPassword = 'password123';
  final tUser = User(
    id: '1',
    email: tEmail,
    displayName: 'Test User',
    createdAt: DateTime(2024, 1, 1),
    lastSeen: DateTime(2024, 1, 1),
  );

  group('SignInUseCase', () {
    test('should return User when sign in is successful', () async {
      // arrange
      when(mockAuthRepository.signIn(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => Right(tUser));

      // act
      final result = await useCase(const SignInParams(
        email: tEmail,
        password: tPassword,
      ));

      // assert
      expect(result, Right(tUser));
      verify(mockAuthRepository.signIn(
        email: tEmail,
        password: tPassword,
      ));
      verifyNoMoreInteractions(mockAuthRepository);
    });

    test('should return ValidationFailure when email is invalid', () async {
      // arrange
      const tInvalidEmail = 'invalid-email';

      // act
      final result = await useCase(const SignInParams(
        email: tInvalidEmail,
        password: tPassword,
      ));

      // assert
      expect(result, const Left(ValidationFailure.invalidEmail()));
      verifyZeroInteractions(mockAuthRepository);
    });

    test('should return ValidationFailure when password is empty', () async {
      // act
      final result = await useCase(const SignInParams(
        email: tEmail,
        password: '',
      ));

      // assert
      expect(result, const Left(ValidationFailure.emptyField('Password')));
      verifyZeroInteractions(mockAuthRepository);
    });

    test('should return ValidationFailure when password is invalid', () async {
      // arrange
      const tWeakPassword = '123'; // Too short and no letters

      // act
      final result = await useCase(const SignInParams(
        email: tEmail,
        password: tWeakPassword,
      ));

      // assert
      expect(result, const Left(ValidationFailure.invalidPassword()));
      verifyZeroInteractions(mockAuthRepository);
    });

    test('should normalize email to lowercase and trim whitespace', () async {
      // arrange
      const tEmailWithSpaces = '  TEST@EXAMPLE.COM  ';
      when(mockAuthRepository.signIn(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => Right(tUser));

      // act
      final result = await useCase(const SignInParams(
        email: tEmailWithSpaces,
        password: tPassword,
      ));

      // assert
      expect(result, Right(tUser));
      verify(mockAuthRepository.signIn(
        email: 'test@example.com',
        password: tPassword,
      ));
    });

    test('should return AuthFailure when repository returns failure', () async {
      // arrange
      const tFailure = AuthFailure.invalidCredentials();
      when(mockAuthRepository.signIn(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await useCase(const SignInParams(
        email: tEmail,
        password: tPassword,
      ));

      // assert
      expect(result, const Left(tFailure));
      verify(mockAuthRepository.signIn(
        email: tEmail,
        password: tPassword,
      ));
    });
  });
}
