import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Use case for signing up a new user with email, password, and display name
class SignUpUseCase implements UseCase<User, SignUpParams> {
  final AuthRepository repository;

  const SignUpUseCase(this.repository);

  @override
  Future<Either<Failure, User>> call(SignUpParams params) async {
    final trimmedEmail = params.email.trim().toLowerCase();
    final trimmedDisplayName = params.displayName.trim();

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

    // Validate display name is not empty
    if (trimmedDisplayName.isEmpty) {
      return const Left(ValidationFailure.emptyField('Display name'));
    }

    // Validate display name format
    if (!User.isValidDisplayName(trimmedDisplayName)) {
      return const Left(ValidationFailure.invalidDisplayName());
    }

    // Call repository to sign up
    return await repository.signUp(
      email: trimmedEmail,
      password: params.password,
      displayName: trimmedDisplayName,
    );
  }
}

/// Parameters for the SignUpUseCase
class SignUpParams extends Equatable {
  final String email;
  final String password;
  final String displayName;

  const SignUpParams({
    required this.email,
    required this.password,
    required this.displayName,
  });

  @override
  List<Object> get props => [email, password, displayName];
}
