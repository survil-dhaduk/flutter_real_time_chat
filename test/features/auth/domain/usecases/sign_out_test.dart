import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:flutter_real_time_chat/core/errors/failures.dart';
import 'package:flutter_real_time_chat/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_real_time_chat/features/auth/domain/usecases/sign_out.dart';

import 'sign_out_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  late SignOutUseCase useCase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    useCase = SignOutUseCase(mockAuthRepository);
  });

  group('SignOutUseCase', () {
    test('should return void when sign out is successful', () async {
      // arrange
      when(mockAuthRepository.signOut())
          .thenAnswer((_) async => const Right(null));

      // act
      final result = await useCase();

      // assert
      expect(result, const Right(null));
      verify(mockAuthRepository.signOut());
      verifyNoMoreInteractions(mockAuthRepository);
    });

    test('should return AuthFailure when repository returns failure', () async {
      // arrange
      const tFailure = AuthFailure.notAuthenticated();
      when(mockAuthRepository.signOut())
          .thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await useCase();

      // assert
      expect(result, const Left(tFailure));
      verify(mockAuthRepository.signOut());
      verifyNoMoreInteractions(mockAuthRepository);
    });

    test('should return ServerFailure when server error occurs', () async {
      // arrange
      const tFailure = ServerFailure.general();
      when(mockAuthRepository.signOut())
          .thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await useCase();

      // assert
      expect(result, const Left(tFailure));
      verify(mockAuthRepository.signOut());
      verifyNoMoreInteractions(mockAuthRepository);
    });

    test('should return NetworkFailure when network error occurs', () async {
      // arrange
      const tFailure = NetworkFailure.general();
      when(mockAuthRepository.signOut())
          .thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await useCase();

      // assert
      expect(result, const Left(tFailure));
      verify(mockAuthRepository.signOut());
      verifyNoMoreInteractions(mockAuthRepository);
    });
  });
}
