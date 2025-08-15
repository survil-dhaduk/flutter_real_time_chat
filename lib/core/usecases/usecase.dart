import 'package:dartz/dartz.dart';
import '../errors/failures.dart';

/// Base class for all use cases in the application
abstract class UseCase<Type, Params> {
  /// Executes the use case with the given parameters
  Future<Either<Failure, Type>> call(Params params);
}

/// Base class for use cases that don't require parameters
abstract class NoParamsUseCase<Type> {
  /// Executes the use case without parameters
  Future<Either<Failure, Type>> call();
}

/// Base class for use cases that return streams
abstract class StreamUseCase<Type, Params> {
  /// Executes the use case and returns a stream
  Stream<Type> call(Params params);
}

/// Base class for stream use cases that don't require parameters
abstract class NoParamsStreamUseCase<Type> {
  /// Executes the use case and returns a stream without parameters
  Stream<Type> call();
}
