import '../../../features/auth/domain/entities/user.dart';
import '../../../features/auth/domain/repositories/auth_repository.dart';

/// Service that provides current user context throughout the application
class UserContextService {
  final AuthRepository _authRepository;
  User? _currentUser;

  UserContextService({
    required AuthRepository authRepository,
  }) : _authRepository = authRepository {
    // Listen to auth state changes and update current user
    _authRepository.authStateChanges.listen((user) {
      _currentUser = user;
    });
  }

  /// Gets the current authenticated user
  User? get currentUser => _currentUser;

  /// Gets the current user ID
  String? get currentUserId => _currentUser?.id;

  /// Checks if a user is currently authenticated
  bool get isAuthenticated => _currentUser != null;

  /// Initializes the service by getting the current user
  Future<void> initialize() async {
    final result = await _authRepository.getCurrentUser();
    result.fold(
      (failure) => _currentUser = null,
      (user) => _currentUser = user,
    );
  }

  /// Updates the current user context
  void updateCurrentUser(User? user) {
    _currentUser = user;
  }
}
