import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Use case for signing in a user with email and password
class SignInUseCase implements UseCase<User, SignInParams> {
  final AuthRepository repository;

  const SignInUseCase(this.repository);

  @override
  Future<Either<Failure, User>> call(SignInParams params) async {
    final trimmedEmail = params.email.trim().toLowerCase();

    // Validate email format
    if (!User.isValidEmail(trimmedEmail)) {
      return const Left(ValidationFailure.invalidEmail());
    }

    // Validate password is not empty
    if (params.password.isEmpty) {
      return const Left(ValidationFailure.emptyField('Password'));
    }

    // Validate password strength
    if (!User.isValidPassword(params.password)) {
      return const Left(ValidationFailure.invalidPassword());
    }

    // Call repository to sign in
    return await repository.signIn(
      email: trimmedEmail,
      password: params.password,
    );
  }
}

/// Parameters for the SignInUseCase
class SignInParams extends Equatable {
  final String email;
  final String password;

  const SignInParams({
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [email, password];
}
