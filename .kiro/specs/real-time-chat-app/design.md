# Design Document

## Overview

This design document outlines the architecture and implementation approach for a real-time chat application built with Flutter, Firebase Firestore, and BLoC state management. The application follows clean architecture principles with clear separation of concerns across Presentation, Domain, and Data layers.

## Architecture

### Clean Architecture Layers

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                       │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   Pages     │  │   Widgets   │  │      BLoCs          │  │
│  │             │  │             │  │                     │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     Domain Layer                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │  Entities   │  │ Use Cases   │  │   Repositories      │  │
│  │             │  │             │  │   (Interfaces)      │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      Data Layer                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   Models    │  │ Data Sources│  │   Repositories      │  │
│  │             │  │             │  │ (Implementations)   │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### State Management Architecture

The application uses BLoC (Business Logic Component) pattern with the following flow:

```
UI Event → BLoC → Use Case → Repository → Data Source → Firebase
                    ↓
UI State ← BLoC ← Use Case ← Repository ← Data Source ← Firebase
```

## Components and Interfaces

### Core Entities

#### User Entity

```dart
class User {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime lastSeen;
  final bool isOnline;
}
```

#### ChatRoom Entity

```dart
class ChatRoom {
  final String id;
  final String name;
  final String description;
  final String createdBy;
  final DateTime createdAt;
  final List<String> participants;
  final String? lastMessageId;
  final DateTime? lastMessageTime;
}
```

#### Message Entity

```dart
class Message {
  final String id;
  final String roomId;
  final String senderId;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final MessageStatus status;
  final Map<String, DateTime> readBy;
}

enum MessageType { text, image, file }
enum MessageStatus { sent, delivered, read }
```

### Repository Interfaces

#### AuthRepository

```dart
abstract class AuthRepository {
  Future<Either<Failure, User>> signIn(String email, String password);
  Future<Either<Failure, User>> signUp(String email, String password, String displayName);
  Future<Either<Failure, void>> signOut();
  Stream<User?> get authStateChanges;
  Future<Either<Failure, User>> getCurrentUser();
}
```

#### ChatRepository

```dart
abstract class ChatRepository {
  Future<Either<Failure, List<ChatRoom>>> getChatRooms();
  Future<Either<Failure, ChatRoom>> createChatRoom(String name, String description);
  Future<Either<Failure, void>> joinChatRoom(String roomId);
  Stream<List<Message>> getMessages(String roomId);
  Future<Either<Failure, void>> sendMessage(String roomId, String content);
  Future<Either<Failure, void>> markMessageAsRead(String messageId);
}
```

### Use Cases

#### Authentication Use Cases

- `SignInUseCase`: Handles user sign-in with email/password
- `SignUpUseCase`: Handles user registration
- `SignOutUseCase`: Handles user sign-out
- `GetCurrentUserUseCase`: Retrieves current authenticated user

#### Chat Use Cases

- `GetChatRoomsUseCase`: Retrieves available chat rooms
- `CreateChatRoomUseCase`: Creates new chat room
- `JoinChatRoomUseCase`: Joins existing chat room
- `SendMessageUseCase`: Sends message to chat room
- `GetMessagesUseCase`: Retrieves messages for a room
- `MarkMessageAsReadUseCase`: Marks message as read

### BLoC Components

#### AuthBloc

```dart
// Events
abstract class AuthEvent {}
class SignInRequested extends AuthEvent { ... }
class SignUpRequested extends AuthEvent { ... }
class SignOutRequested extends AuthEvent { ... }
class AuthStatusChanged extends AuthEvent { ... }

// States
abstract class AuthState {}
class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthAuthenticated extends AuthState { ... }
class AuthUnauthenticated extends AuthState {}
class AuthError extends AuthState { ... }
```

#### ChatBloc

```dart
// Events
abstract class ChatEvent {}
class LoadChatRooms extends ChatEvent {}
class CreateChatRoom extends ChatEvent { ... }
class JoinChatRoom extends ChatEvent { ... }
class LoadMessages extends ChatEvent { ... }
class SendMessage extends ChatEvent { ... }
class MessageReceived extends ChatEvent { ... }

// States
abstract class ChatState {}
class ChatInitial extends ChatState {}
class ChatLoading extends ChatState {}
class ChatRoomsLoaded extends ChatState { ... }
class ChatRoomJoined extends ChatState { ... }
class MessagesLoaded extends ChatState { ... }
class ChatError extends ChatState { ... }
```

## Data Models

### Firebase Firestore Schema

#### Users Collection

```json
{
  "users": {
    "userId": {
      "email": "user@example.com",
      "displayName": "John Doe",
      "photoUrl": "https://...",
      "createdAt": "timestamp",
      "lastSeen": "timestamp",
      "isOnline": true
    }
  }
}
```

#### ChatRooms Collection

```json
{
  "chatRooms": {
    "roomId": {
      "name": "General Discussion",
      "description": "General chat room",
      "createdBy": "userId",
      "createdAt": "timestamp",
      "participants": ["userId1", "userId2"],
      "lastMessageId": "messageId",
      "lastMessageTime": "timestamp"
    }
  }
}
```

#### Messages Collection

```json
{
  "messages": {
    "messageId": {
      "roomId": "roomId",
      "senderId": "userId",
      "content": "Hello world!",
      "type": "text",
      "timestamp": "timestamp",
      "status": "delivered",
      "readBy": {
        "userId1": "timestamp",
        "userId2": "timestamp"
      }
    }
  }
}
```

### Real-time Data Flow

1. **Message Sending Flow:**

   - User types message → UI triggers SendMessage event
   - ChatBloc processes event → calls SendMessageUseCase
   - UseCase calls ChatRepository → ChatRemoteDataSource
   - Message stored in Firestore → Real-time listeners notify all clients

2. **Message Receiving Flow:**

   - Firestore listener detects new message
   - ChatRemoteDataSource streams update → ChatRepository
   - Repository notifies BLoC → UI updates with new message

3. **Message Status Updates:**
   - Message sent → status: "sent"
   - Message stored in Firestore → status: "delivered"
   - Recipient opens chat → status: "read" with timestamp

## Error Handling

### Failure Types

```dart
abstract class Failure {
  final String message;
  const Failure(this.message);
}

class ServerFailure extends Failure { ... }
class NetworkFailure extends Failure { ... }
class AuthFailure extends Failure { ... }
class ValidationFailure extends Failure { ... }
```

### Error Handling Strategy

- Use `Either<Failure, Success>` pattern for error handling
- Implement global error handling in BLoCs
- Display user-friendly error messages in UI
- Implement retry mechanisms for network failures
- Log errors for debugging purposes

## Testing Strategy

### Unit Testing

- Test all use cases with mock repositories
- Test BLoC logic with mock use cases
- Test entity validation and business rules
- Test utility functions and helpers

### Widget Testing

- Test individual widgets in isolation
- Test widget interactions and state changes
- Test navigation flows
- Test form validation and user input

### Integration Testing

- Test complete user flows (sign-in, send message, etc.)
- Test real-time data synchronization
- Test offline/online scenarios
- Test error scenarios and recovery

### Testing Structure

```
test/
├── unit/
│   ├── domain/
│   │   ├── entities/
│   │   └── usecases/
│   ├── data/
│   │   ├── models/
│   │   └── repositories/
│   └── presentation/
│       └── bloc/
├── widget/
│   ├── pages/
│   └── widgets/
└── integration/
    └── app_test.dart
```

## Security Considerations

### Firebase Security Rules

- Implement proper Firestore security rules
- Ensure users can only access their authorized chat rooms
- Validate message ownership before allowing modifications
- Implement rate limiting for message sending

### Data Validation

- Validate all user inputs on client and server side
- Sanitize message content to prevent XSS
- Implement proper authentication token handling
- Use secure password requirements

## Performance Optimizations

### Real-time Data Management

- Implement pagination for message loading
- Use Firestore query limits to prevent large data loads
- Implement message caching for offline support
- Optimize listener subscriptions to prevent memory leaks

### UI Performance

- Use ListView.builder for efficient message rendering
- Implement image caching for user avatars
- Use const constructors where possible
- Implement proper widget disposal in BLoCs

## Dependency Injection

### Service Locator Pattern

```dart
// Using get_it for dependency injection
final GetIt sl = GetIt.instance;

void init() {
  // BLoCs
  sl.registerFactory(() => AuthBloc(signIn: sl(), signUp: sl(), signOut: sl()));
  sl.registerFactory(() => ChatBloc(getChatRooms: sl(), sendMessage: sl()));

  // Use Cases
  sl.registerLazySingleton(() => SignInUseCase(sl()));
  sl.registerLazySingleton(() => SendMessageUseCase(sl()));

  // Repositories
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));
  sl.registerLazySingleton<ChatRepository>(() => ChatRepositoryImpl(sl()));

  // Data Sources
  sl.registerLazySingleton<AuthRemoteDataSource>(() => AuthRemoteDataSourceImpl());
  sl.registerLazySingleton<ChatRemoteDataSource>(() => ChatRemoteDataSourceImpl());
}
```

This design provides a solid foundation for building a scalable, maintainable real-time chat application that meets all the specified requirements while following Flutter and Firebase best practices.
