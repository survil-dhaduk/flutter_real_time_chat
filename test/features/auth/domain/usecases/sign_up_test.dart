import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:flutter_real_time_chat/core/errors/failures.dart';
import 'package:flutter_real_time_chat/features/auth/domain/entities/user.dart';
import 'package:flutter_real_time_chat/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_real_time_chat/features/auth/domain/usecases/sign_up.dart';

import 'sign_up_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  late SignUpUseCase useCase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    useCase = SignUpUseCase(mockAuthRepository);
  });

  const tEmail = 'test@example.com';
  const tPassword = 'password123';
  const tDisplayName = 'Test User';
  final tUser = User(
    id: '1',
    email: tEmail,
    displayName: tDisplayName,
    createdAt: DateTime(2024, 1, 1),
    lastSeen: DateTime(2024, 1, 1),
  );

  group('SignUpUseCase', () {
    test('should return User when sign up is successful', () async {
      // arrange
      when(mockAuthRepository.signUp(
        email: anyNamed('email'),
        password: anyNamed('password'),
        displayName: anyNamed('displayName'),
      )).thenAnswer((_) async => Right(tUser));

      // act
      final result = await useCase(const SignUpParams(
        email: tEmail,
        password: tPassword,
        displayName: tDisplayName,
      ));

      // assert
      expect(result, Right(tUser));
      verify(mockAuthRepository.signUp(
        email: tEmail,
        password: tPassword,
        displayName: tDisplayName,
      ));
      verifyNoMoreInteractions(mockAuthRepository);
    });

    test('should return ValidationFailure when email is invalid', () async {
      // arrange
      const tInvalidEmail = 'invalid-email';

      // act
      final result = await useCase(const SignUpParams(
        email: tInvalidEmail,
        password: tPassword,
        displayName: tDisplayName,
      ));

      // assert
      expect(result, const Left(ValidationFailure.invalidEmail()));
      verifyZeroInteractions(mockAuthRepository);
    });

    test('should return ValidationFailure when password is empty', () async {
      // act
      final result = await useCase(const SignUpParams(
        email: tEmail,
        password: '',
        displayName: tDisplayName,
      ));

      // assert
      expect(result, const Left(ValidationFailure.emptyField('Password')));
      verifyZeroInteractions(mockAuthRepository);
    });

    test('should return ValidationFailure when password is invalid', () async {
      // arrange
      const tWeakPassword = '123'; // Too short and no letters

      // act
      final result = await useCase(const SignUpParams(
        email: tEmail,
        password: tWeakPassword,
        displayName: tDisplayName,
      ));

      // assert
      expect(result, const Left(ValidationFailure.invalidPassword()));
      verifyZeroInteractions(mockAuthRepository);
    });

    test('should return ValidationFailure when display name is empty',
        () async {
      // act
      final result = await useCase(const SignUpParams(
        email: tEmail,
        password: tPassword,
        displayName: '',
      ));

      // assert
      expect(result, const Left(ValidationFailure.emptyField('Display name')));
      verifyZeroInteractions(mockAuthRepository);
    });

    test('should return ValidationFailure when display name is invalid',
        () async {
      // arrange
      const tInvalidDisplayName = 'A'; // Too short

      // act
      final result = await useCase(const SignUpParams(
        email: tEmail,
        password: tPassword,
        displayName: tInvalidDisplayName,
      ));

      // assert
      expect(result, const Left(ValidationFailure.invalidDisplayName()));
      verifyZeroInteractions(mockAuthRepository);
    });

    test('should normalize email and trim display name', () async {
      // arrange
      const tEmailWithSpaces = '  TEST@EXAMPLE.COM  ';
      const tDisplayNameWithSpaces = '  Test User  ';
      when(mockAuthRepository.signUp(
        email: anyNamed('email'),
        password: anyNamed('password'),
        displayName: anyNamed('displayName'),
      )).thenAnswer((_) async => Right(tUser));

      // act
      final result = await useCase(const SignUpParams(
        email: tEmailWithSpaces,
        password: tPassword,
        displayName: tDisplayNameWithSpaces,
      ));

      // assert
      expect(result, Right(tUser));
      verify(mockAuthRepository.signUp(
        email: 'test@example.com',
        password: tPassword,
        displayName: 'Test User',
      ));
    });

    test('should return AuthFailure when repository returns failure', () async {
      // arrange
      const tFailure = AuthFailure.emailAlreadyInUse();
      when(mockAuthRepository.signUp(
        email: anyNamed('email'),
        password: anyNamed('password'),
        displayName: anyNamed('displayName'),
      )).thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await useCase(const SignUpParams(
        email: tEmail,
        password: tPassword,
        displayName: tDisplayName,
      ));

      // assert
      expect(result, const Left(tFailure));
      verify(mockAuthRepository.signUp(
        email: tEmail,
        password: tPassword,
        displayName: tDisplayName,
      ));
    });
  });
}
