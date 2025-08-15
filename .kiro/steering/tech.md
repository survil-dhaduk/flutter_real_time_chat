# Technology Stack

## Framework & Language

- **Flutter**: Latest stable version (SDK ^3.5.3)
- **Dart**: 3.0+ with null safety
- **Target Platforms**: iOS, Android, Web

## Core Dependencies

- **State Management**: flutter_bloc ^8.1.6 (BLoC pattern)
- **Dependency Injection**: get_it ^8.0.2 (Service Locator)
- **Functional Programming**: dartz ^0.10.1 (Either type for error handling)
- **Value Equality**: equatable ^2.0.5 (Entity comparison)

## Firebase Stack

- **firebase_core**: ^3.6.0 (Core Firebase functionality)
- **cloud_firestore**: ^5.4.4 (Real-time database)
- **firebase_auth**: ^5.3.1 (Authentication)

## Development Tools

- **Testing**: mockito ^5.4.4, build_runner ^2.4.13
- **Linting**: flutter_lints ^4.0.0
- **Analysis**: Standard Flutter analysis options

## Common Commands

### Development

```bash
# Get dependencies
flutter pub get

# Run the app
flutter run

# Run on specific device
flutter run -d chrome  # Web
flutter run -d ios     # iOS Simulator
flutter run -d android # Android Emulator
```

### Testing

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Generate mocks
dart run build_runner build
```

### Build & Deploy

```bash
# Build for release
flutter build apk --release      # Android APK
flutter build ios --release      # iOS
flutter build web --release      # Web

# Clean build artifacts
flutter clean
flutter pub get
```

### Code Quality

```bash
# Analyze code
flutter analyze

# Format code
dart format lib/ test/

# Check for outdated dependencies
flutter pub outdated
```

## Architecture Patterns

- **Clean Architecture**: Domain, Data, Presentation layers
- **BLoC Pattern**: Event-driven state management
- **Repository Pattern**: Data abstraction layer
- **Use Case Pattern**: Business logic encapsulation
- **Dependency Injection**: Service locator with get_it
