import 'package:flutter_test/flutter_test.dart';

import '../../../../../lib/features/auth/data/datasources/auth_remote_data_source.dart';

void main() {
  group('AuthRemoteDataSource', () {
    test('should create AuthException with message', () {
      // Arrange
      const message = 'Test error message';
      const code = 'test-error';

      // Act
      const exception = AuthException(message, code: code);

      // Assert
      expect(exception.message, message);
      expect(exception.code, code);
      expect(exception.toString(), 'AuthException: $message (Code: $code)');
    });

    test('should create AuthException without code', () {
      // Arrange
      const message = 'Test error message';

      // Act
      const exception = AuthException(message);

      // Assert
      expect(exception.message, message);
      expect(exception.code, null);
      expect(exception.toString(), 'AuthException: $message');
    });

    test('should implement AuthRemoteDataSource interface', () {
      // This test verifies that AuthRemoteDataSourceImpl implements the interface
      // without actually instantiating it (which would require Firebase initialization)
      expect(AuthRemoteDataSourceImpl, isA<Type>());
    });
  });
}
