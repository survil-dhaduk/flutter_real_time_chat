# Project Structure & Organization

## Clean Architecture Layers

The project follows Clean Architecture principles with clear separation of concerns across three main layers:

### 1. Presentation Layer (`presentation/`)

- **bloc/**: BLoC/Cubit classes for state management
- **pages/**: Screen widgets and route definitions
- **widgets/**: Reusable UI components specific to the feature

### 2. Domain Layer (`domain/`)

- **entities/**: Core business objects (User, Message, ChatRoom)
- **repositories/**: Abstract repository interfaces
- **usecases/**: Business logic implementation (one class per use case)

### 3. Data Layer (`data/`)

- **datasources/**: External data sources (Firebase, API clients)
- **models/**: Data transfer objects that extend domain entities
- **repositories/**: Concrete repository implementations

## Directory Structure

```
lib/
├── core/                          # Shared utilities and base classes
│   ├── constants/                 # App-wide constants (colors, strings)
│   ├── errors/                    # Failure classes and error handling
│   ├── theme/                     # App theming and styling
│   ├── usecases/                  # Base use case classes
│   ├── utils/                     # Utility functions and helpers
│   └── widgets/                   # Shared UI components
├── features/                      # Feature-based organization
│   ├── auth/                      # Authentication feature
│   │   ├── data/
│   │   │   ├── datasources/       # Firebase Auth integration
│   │   │   ├── models/            # UserModel extends User entity
│   │   │   └── repositories/      # AuthRepositoryImpl
│   │   ├── domain/
│   │   │   ├── entities/          # User entity
│   │   │   ├── repositories/      # AuthRepository interface
│   │   │   └── usecases/          # SignIn, SignUp, SignOut, GetCurrentUser
│   │   └── presentation/
│   │       ├── bloc/              # AuthBloc/AuthCubit
│   │       ├── pages/             # LoginPage, RegisterPage
│   │       └── widgets/           # Auth-specific widgets
│   └── chat/                      # Chat functionality
│       ├── data/
│       │   ├── datasources/       # Firestore integration
│       │   ├── models/            # MessageModel, ChatRoomModel
│       │   └── repositories/      # ChatRepositoryImpl
│       ├── domain/
│       │   ├── entities/          # Message, ChatRoom entities
│       │   ├── repositories/      # ChatRepository interface
│       │   └── usecases/          # SendMessage, GetMessages, etc.
│       └── presentation/
│           ├── bloc/              # ChatBloc, MessageCubit
│           ├── pages/             # ChatPage, RoomListPage
│           └── widgets/           # MessageBubble, ChatInput
├── injection/                     # Dependency injection setup
├── firebase_options.dart         # Firebase configuration
└── main.dart                     # App entry point
```

## Naming Conventions

### Files & Directories

- **snake_case** for all file and directory names
- **Feature-first** organization (group by feature, not by layer)
- **Descriptive names** that clearly indicate purpose

### Classes & Interfaces

- **PascalCase** for class names
- **Entities**: Plain names (User, Message, ChatRoom)
- **Models**: EntityName + "Model" (UserModel, MessageModel)
- **Repositories**: EntityName + "Repository" (AuthRepository)
- **Use Cases**: Verb phrases (SignIn, GetCurrentUser, SendMessage)
- **BLoCs**: EntityName + "Bloc" or "Cubit" (AuthBloc, MessageCubit)
- **Pages**: EntityName + "Page" (LoginPage, ChatPage)

### Constants & Enums

- **SCREAMING_SNAKE_CASE** for constants
- **PascalCase** for enum names
- **camelCase** for enum values

## Code Organization Rules

### Import Order

1. Dart core libraries
2. Flutter libraries
3. Third-party packages
4. Local imports (relative paths)

### File Structure Within Classes

1. Static constants
2. Instance variables
3. Constructors
4. Static methods
5. Instance methods
6. Overridden methods
7. Private methods

### Entity Guidelines

- Extend `Equatable` for value comparison
- Include validation methods as static functions
- Provide `copyWith` methods for immutable updates
- Use `const` constructors where possible

### Repository Pattern

- Abstract repositories in domain layer define contracts
- Concrete implementations in data layer handle external dependencies
- Return `Either<Failure, T>` for error handling
- Use streams for real-time data (Firestore streams)

### BLoC Pattern

- Use **Cubits** for simple state changes
- Use **Blocs** for complex event handling with multiple events
- Sealed classes for type-safe state definitions
- Separate events and states into different files for complex features

### Testing Structure

- Mirror the `lib/` structure in `test/`
- Unit tests for all business logic (domain layer)
- Widget tests for UI components
- Integration tests for complete user flows
- Mock external dependencies using mockito
