import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';

// Core
import '../core/utils/logger.dart';

// Auth Feature
import '../features/auth/data/datasources/auth_remote_data_source.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/domain/usecases/get_current_user.dart';
import '../features/auth/domain/usecases/sign_in.dart';
import '../features/auth/domain/usecases/sign_out.dart';
import '../features/auth/domain/usecases/sign_up.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';

// Chat Feature
import '../features/chat/data/datasources/chat_remote_data_source.dart';
import '../features/chat/data/datasources/chat_remote_data_source_impl.dart';
import '../features/chat/data/repositories/chat_repository_impl.dart';
import '../features/chat/domain/repositories/chat_repository.dart';
import '../features/chat/domain/usecases/create_chat_room.dart';
import '../features/chat/domain/usecases/get_chat_rooms.dart';
import '../features/chat/domain/usecases/get_messages.dart';
import '../features/chat/domain/usecases/join_chat_room.dart';
import '../features/chat/domain/usecases/mark_message_as_read.dart';
import '../features/chat/domain/usecases/send_message.dart';

/// Global service locator instance
final GetIt sl = GetIt.instance;

/// Initializes all dependencies for the application
///
/// This function sets up the dependency injection container with proper
/// hierarchy and lifecycle management. It should be called once during
/// app initialization before running the app.
///
/// Dependencies are registered in the following order:
/// 1. External dependencies (Firebase, etc.)
/// 2. Core utilities
/// 3. Data sources
/// 4. Repositories
/// 5. Use cases
/// 6. BLoCs (when implemented)
Future<void> initializeDependencies() async {
  // ============================================================================
  // External Dependencies
  // ============================================================================

  // Firebase instances - registered as singletons since they should be shared
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);

  // ============================================================================
  // Core Utilities
  // ============================================================================

  // Logger - registered as singleton for consistent logging across the app
  sl.registerLazySingleton<Logger>(() => const Logger());

  // ============================================================================
  // Data Sources
  // ============================================================================

  // Auth Remote Data Source
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(
      firebaseAuth: sl<FirebaseAuth>(),
      firestore: sl<FirebaseFirestore>(),
      logger: sl<Logger>(),
    ),
  );

  // Chat Remote Data Source
  sl.registerLazySingleton<ChatRemoteDataSource>(
    () => ChatRemoteDataSourceImpl(
      firestore: sl<FirebaseFirestore>(),
    ),
  );

  // ============================================================================
  // Repositories
  // ============================================================================

  // Auth Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl<AuthRemoteDataSource>(),
    ),
  );

  // Chat Repository
  sl.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(
      remoteDataSource: sl<ChatRemoteDataSource>(),
    ),
  );

  // ============================================================================
  // Use Cases
  // ============================================================================

  // Auth Use Cases
  sl.registerLazySingleton(() => SignInUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => SignUpUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => SignOutUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl<AuthRepository>()));

  // Chat Use Cases
  sl.registerLazySingleton(() => GetChatRoomsUseCase(sl<ChatRepository>()));
  sl.registerLazySingleton(() => CreateChatRoomUseCase(sl<ChatRepository>()));
  sl.registerLazySingleton(() => JoinChatRoomUseCase(sl<ChatRepository>()));
  sl.registerLazySingleton(() => SendMessageUseCase(sl<ChatRepository>()));
  sl.registerLazySingleton(() => GetMessagesUseCase(sl<ChatRepository>()));
  sl.registerLazySingleton(
      () => MarkMessageAsReadUseCase(sl<ChatRepository>()));

  // ============================================================================
  // BLoCs / Cubits
  // ============================================================================

  // Auth BLoC - registered as factory to ensure fresh instances
  sl.registerFactory(() => AuthBloc(
        signInUseCase: sl<SignInUseCase>(),
        signUpUseCase: sl<SignUpUseCase>(),
        signOutUseCase: sl<SignOutUseCase>(),
        getCurrentUserUseCase: sl<GetCurrentUserUseCase>(),
        authRepository: sl<AuthRepository>(),
      ));

  // Note: ChatBloc will be registered here when implemented in future tasks
  // sl.registerFactory(() => ChatBloc(
  //   getChatRooms: sl<GetChatRoomsUseCase>(),
  //   createChatRoom: sl<CreateChatRoomUseCase>(),
  //   joinChatRoom: sl<JoinChatRoomUseCase>(),
  //   sendMessage: sl<SendMessageUseCase>(),
  //   getMessages: sl<GetMessagesUseCase>(),
  //   markMessageAsRead: sl<MarkMessageAsReadUseCase>(),
  // ));
}

/// Resets all registered dependencies
///
/// This function is primarily used for testing to ensure clean state
/// between test runs. It should not be called in production code.
Future<void> resetDependencies() async {
  await sl.reset();
}

/// Checks if all required dependencies are registered
///
/// This function can be used for debugging dependency injection issues
/// Returns true if all core dependencies are properly registered
bool areDependenciesInitialized() {
  try {
    // Check external dependencies
    sl<FirebaseAuth>();
    sl<FirebaseFirestore>();

    // Check core utilities
    sl<Logger>();

    // Check data sources
    sl<AuthRemoteDataSource>();
    sl<ChatRemoteDataSource>();

    // Check repositories
    sl<AuthRepository>();
    sl<ChatRepository>();

    // Check use cases
    sl<SignInUseCase>();
    sl<SignUpUseCase>();
    sl<SignOutUseCase>();
    sl<GetCurrentUserUseCase>();
    sl<GetChatRoomsUseCase>();
    sl<CreateChatRoomUseCase>();
    sl<JoinChatRoomUseCase>();
    sl<SendMessageUseCase>();
    sl<GetMessagesUseCase>();
    sl<MarkMessageAsReadUseCase>();

    return true;
  } catch (e) {
    return false;
  }
}
