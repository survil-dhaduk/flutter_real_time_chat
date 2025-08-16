# Real-Time Chat App 💬

A modern, production-ready real-time chat application built with Flutter and Firebase Firestore. This project demonstrates clean architecture principles, BLoC state management, and real-time messaging capabilities.

## ✨ Features

- 🔐 **User Authentication** - Email/password registration and login
- 💬 **Real-Time Messaging** - Instant message delivery via Firestore streams
- 🏠 **Chat Rooms** - Create, join, and manage chat rooms
- ✅ **Message Status** - Sent, delivered, and read receipt tracking
- 📱 **Responsive Design** - Works on mobile, tablet, and web
- 🎨 **Modern UI** - Material Design 3 with dark/light theme support
- 🏗️ **Clean Architecture** - Scalable codebase with proper separation of concerns

## 🚀 Quick Start

### Prerequisites

- Flutter SDK (^3.5.3)
- Dart (3.0+)
- Firebase project setup
- Android Studio / VS Code
- iOS development tools (for iOS builds)

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/your-username/flutter_real_time_chat.git
   cd flutter_real_time_chat
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Configure Firebase**

   - Create a Firebase project
   - Add Android/iOS apps to your Firebase project
   - Download and place configuration files:
     - `android/app/google-services.json`
     - `ios/Runner/GoogleService-Info.plist`

4. **Generate build files**

   ```bash
   dart run build_runner build
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

## 🏗️ Architecture

This project follows **Clean Architecture** principles with three main layers:

```
📁 lib/
├── 🎨 presentation/     # UI layer (Pages, Widgets, BLoCs)
├── 💼 domain/          # Business logic (Entities, Use Cases, Repositories)
├── 📊 data/            # Data layer (Models, Data Sources, Repository Implementations)
└── 🔧 core/            # Shared utilities and configurations
```

### Key Patterns Used

- **BLoC Pattern** - State management with flutter_bloc
- **Repository Pattern** - Data abstraction layer
- **Use Case Pattern** - Business logic encapsulation
- **Dependency Injection** - Service locator with get_it

## 🧪 Testing

Run the comprehensive test suite:

```bash
# Unit tests
flutter test

# Widget tests
flutter test test/features/

# Integration tests
flutter test integration_test/

# Device testing (multiple screen sizes)
./scripts/test_devices.sh
```

## 📦 Building for Production

### Android

```bash
./scripts/build_android.sh
```

### iOS

```bash
./scripts/build_ios.sh
```

### Web

```bash
./scripts/build_web.sh
```

## 🔧 Configuration

### Environment Setup

The app supports multiple environments (development, staging, production):

```bash
# Development
flutter run --dart-define=ENVIRONMENT=development

# Production
flutter run --dart-define=ENVIRONMENT=production --release
```

### Firebase Security Rules

Firestore security rules are configured in `firestore.rules`. Deploy them using:

```bash
firebase deploy --only firestore:rules
```

## 📱 Supported Platforms

- ✅ **Android** (API 21+)
- ✅ **iOS** (iOS 12+)
- ✅ **Web** (Chrome, Safari, Firefox)

## 🎯 Performance

- 🚀 App launch time: < 3 seconds
- 💾 Memory optimized with proper disposal
- 📡 Real-time updates: < 1 second latency
- 🔄 Offline support with local caching

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase team for the backend services
- BLoC library maintainers
- Open source community

## 📞 Support

If you have any questions or need help, please:

1. Check the [documentation](docs/)
2. Search existing [issues](https://github.com/your-username/flutter_real_time_chat/issues)
3. Create a new issue if needed

---

**Made with ❤️ using Flutter and Firebase**
