# Dependency Injection

This directory contains the dependency injection setup for the Real-Time Chat application using GetIt service locator.

## Overview

The dependency injection system is configured to follow clean architecture principles with proper separation of concerns and dependency hierarchy.

## Structure

### Dependencies Registration Order

1. **External Dependencies**: Firebase instances (FirebaseAuth, FirebaseFirestore)
2. **Core Utilities**: Logger and other shared utilities
3. **Data Sources**: Remote data sources for auth and chat features
4. **Repositories**: Repository implementations that depend on data sources
5. **Use Cases**: Business logic that depends on repositories
6. **BLoCs**: State management components (to be added in future tasks)

### Lifecycle Management

- **Singletons**: Used for shared instances like Firebase services, repositories, and use cases
- **Factories**: Will be used for BLoCs to ensure fresh instances and proper disposal

## Usage

### Initialization

The dependency injection is automatically initialized in `main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize dependency injection
  await initializeDependencies();

  runApp(const MyApp());
}
```

### Accessing Dependencies

Use the global service locator `sl` to access registered dependencies:

```dart
import 'package:flutter_real_time_chat/injection/injection.dart';

// Get a use case
final signInUseCase = sl<SignInUseCase>();

// Get a repository
final authRepository = sl<AuthRepository>();

// Get a utility
final logger = sl<Logger>();
```

### Example Usage in BLoCs (Future Implementation)

```dart
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignInUseCase _signIn;
  final SignUpUseCase _signUp;
  final SignOutUseCase _signOut;
  final GetCurrentUserUseCase _getCurrentUser;

  AuthBloc({
    required SignInUseCase signIn,
    required SignUpUseCase signUp,
    required SignOutUseCase signOut,
    required GetCurrentUserUseCase getCurrentUser,
  }) : _signIn = signIn,
       _signUp = signUp,
       _signOut = signOut,
       _getCurrentUser = getCurrentUser,
       super(AuthInitial());
}

// Registration in injection.dart
sl.registerFactory(() => AuthBloc(
  signIn: sl<SignInUseCase>(),
  signUp: sl<SignUpUseCase>(),
  signOut: sl<SignOutUseCase>(),
  getCurrentUser: sl<GetCurrentUserUseCase>(),
));
```

## Testing

For testing, use the `resetDependencies()` function to ensure clean state between tests:

```dart
setUp(() async {
  await resetDependencies();
  // Register test-specific dependencies or mocks
});
```

## Verification

The `areDependenciesInitialized()` function can be used to verify that all required dependencies are properly registered:

```dart
if (areDependenciesInitialized()) {
  print('All dependencies are ready!');
} else {
  print('Some dependencies are missing!');
}
```

## Future Enhancements

When implementing BLoCs in future tasks:

1. Register BLoCs as factories (not singletons)
2. Ensure proper disposal in widget lifecycle
3. Use BlocProvider to provide BLoCs to widgets
4. Consider using MultiBlocProvider for multiple BLoCs

## Dependencies Registered

### Auth Feature

- `AuthRemoteDataSource` / `AuthRemoteDataSourceImpl`
- `AuthRepository` / `AuthRepositoryImpl`
- `SignInUseCase`
- `SignUpUseCase`
- `SignOutUseCase`
- `GetCurrentUserUseCase`

### Chat Feature

- `ChatRemoteDataSource` / `ChatRemoteDataSourceImpl`
- `ChatRepository` / `ChatRepositoryImpl`
- `GetChatRoomsUseCase`
- `CreateChatRoomUseCase`
- `JoinChatRoomUseCase`
- `SendMessageUseCase`
- `GetMessagesUseCase`
- `MarkMessageAsReadUseCase`

### Core

- `Logger`
- `FirebaseAuth`
- `FirebaseFirestore`
