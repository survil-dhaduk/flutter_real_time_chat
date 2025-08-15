import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:flutter_real_time_chat/core/errors/failures.dart';
import 'package:flutter_real_time_chat/features/auth/domain/entities/user.dart';
import 'package:flutter_real_time_chat/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_real_time_chat/features/auth/domain/usecases/get_current_user.dart';

import 'get_current_user_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  late GetCurrentUserUseCase useCase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    useCase = GetCurrentUserUseCase(mockAuthRepository);
  });

  final tUser = User(
    id: '1',
    email: 'test@example.com',
    displayName: 'Test User',
    createdAt: DateTime(2024, 1, 1),
    lastSeen: DateTime(2024, 1, 1),
  );

  group('GetCurrentUserUseCase', () {
    test('should return User when user is authenticated', () async {
      // arrange
      when(mockAuthRepository.getCurrentUser())
          .thenAnswer((_) async => Right(tUser));

      // act
      final result = await useCase();

      // assert
      expect(result, Right(tUser));
      verify(mockAuthRepository.getCurrentUser());
      verifyNoMoreInteractions(mockAuthRepository);
    });

    test('should return AuthFailure when user is not authenticated', () async {
      // arrange
      const tFailure = AuthFailure.notAuthenticated();
      when(mockAuthRepository.getCurrentUser())
          .thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await useCase();

      // assert
      expect(result, const Left(tFailure));
      verify(mockAuthRepository.getCurrentUser());
      verifyNoMoreInteractions(mockAuthRepository);
    });

    test('should return ServerFailure when server error occurs', () async {
      // arrange
      const tFailure = ServerFailure.general();
      when(mockAuthRepository.getCurrentUser())
          .thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await useCase();

      // assert
      expect(result, const Left(tFailure));
      verify(mockAuthRepository.getCurrentUser());
      verifyNoMoreInteractions(mockAuthRepository);
    });

    test('should return NetworkFailure when network error occurs', () async {
      // arrange
      const tFailure = NetworkFailure.general();
      when(mockAuthRepository.getCurrentUser())
          .thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await useCase();

      // assert
      expect(result, const Left(tFailure));
      verify(mockAuthRepository.getCurrentUser());
      verifyNoMoreInteractions(mockAuthRepository);
    });
  });
}
