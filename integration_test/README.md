# Integration Tests

This directory contains comprehensive integration tests for the Real-Time Chat application. These tests verify end-to-end functionality, real-time data handling, error scenarios, and performance characteristics.

## Test Structure

### Test Files

- **`app_test.dart`** - Main application integration tests covering complete user flows
- **`auth_flow_test.dart`** - Authentication flow tests (login, registration, logout)
- **`chat_functionality_test.dart`** - Chat features (rooms, messaging, real-time updates)
- **`performance_test.dart`** - Performance and load testing scenarios
- **`error_handling_test.dart`** - Error scenarios and recovery mechanisms
- **`test_runner.dart`** - Runs all integration tests in sequence

### Helper Files

- **`helpers/test_helpers.dart`** - Utility functions for test operations
- **`helpers/firebase_test_setup.dart`** - Firebase mocking and test data setup

## Test Coverage

### Authentication Flow Tests

- User registration with validation
- Login with error handling
- Authentication state persistence
- Logout functionality
- Authentication guards for protected routes
- Password reset flow (if implemented)
- Session expiration handling

### Chat Functionality Tests

- Chat room creation and management
- Real-time message sending and receiving
- Message status tracking and read receipts
- Chat room joining and participant management
- Message pagination and loading
- Multiple chat rooms navigation
- Chat interface user experience

### Performance Tests

- Rapid message sending performance
- Real-time listener performance with high message volume
- Chat room list loading performance
- Message history loading performance
- Memory usage during extended chat sessions
- Network latency simulation
- Concurrent user simulation
- UI responsiveness during heavy load

### Error Handling Tests

- Authentication error handling and recovery
- Chat room creation error handling
- Message sending error handling and retry
- Real-time connection error handling
- Data loading error handling
- Invalid data handling
- Permission error handling
- Session expiration handling
- Concurrent error scenarios
- Graceful degradation during partial failures

## Running Tests

### Prerequisites

1. Ensure Flutter SDK is installed and configured
2. Install dependencies: `flutter pub get`
3. Ensure Firebase is configured for the project

### Running Individual Test Files

```bash
# Run main app integration tests
flutter test integration_test/app_test.dart

# Run authentication flow tests
flutter test integration_test/auth_flow_test.dart

# Run chat functionality tests
flutter test integration_test/chat_functionality_test.dart

# Run performance tests
flutter test integration_test/performance_test.dart

# Run error handling tests
flutter test integration_test/error_handling_test.dart
```

### Running All Tests

```bash
# Run all integration tests
flutter test integration_test/test_runner.dart

# Run with verbose output
flutter test integration_test/test_runner.dart --verbose

# Run on specific device
flutter test integration_test/test_runner.dart -d chrome
flutter test integration_test/test_runner.dart -d android
flutter test integration_test/test_runner.dart -d ios
```

### Running Tests on Different Platforms

```bash
# Web
flutter test integration_test/ -d chrome

# Android
flutter test integration_test/ -d android

# iOS
flutter test integration_test/ -d ios
```

## Test Configuration

### Mock Services

The tests use mocked Firebase services to ensure:

- Consistent test data
- Isolated test environment
- Fast test execution
- No dependency on external services

### Test Data

Each test creates its own test data using:

- `MockFirebaseAuth` for authentication
- `FakeFirebaseFirestore` for database operations
- Predefined test users, rooms, and messages

### Performance Benchmarks

Performance tests include benchmarks for:

- Message sending: < 600ms per message
- Real-time updates: < 333ms per message
- Room list loading: < 5 seconds for 50 rooms
- Message history: < 8 seconds for 100 messages
- UI responsiveness: < 3 seconds under load

## Test Scenarios

### Complete User Flows

1. **New User Registration Flow**
   - Register → Verify profile creation → Navigate to chat rooms
2. **Existing User Login Flow**
   - Login → Authenticate → Navigate to chat rooms
3. **Chat Room Creation Flow**
   - Create room → Join room → Send messages → Verify real-time updates
4. **Message Exchange Flow**
   - Send message → Verify delivery → Simulate read receipt → Verify status

### Error Recovery Scenarios

1. **Network Interruption**
   - Send message → Simulate network loss → Restore network → Verify retry
2. **Authentication Failure**
   - Invalid credentials → Show error → Retry with valid credentials
3. **Permission Errors**
   - Access restricted room → Handle permission error → Redirect appropriately

### Performance Scenarios

1. **High Message Volume**
   - Send 25+ messages rapidly → Verify performance benchmarks
2. **Concurrent Users**
   - Simulate 5+ users → Send messages concurrently → Verify real-time updates
3. **Extended Session**
   - 100+ operations → Verify memory usage → Test continued responsiveness

## Debugging Tests

### Common Issues

1. **Test Timeouts**
   - Increase timeout values in test configuration
   - Check for infinite loops in real-time listeners
2. **Mock Data Issues**
   - Verify test data setup in `firebase_test_setup.dart`
   - Check data cleanup between tests
3. **Widget Not Found**
   - Verify widget keys and text content
   - Check navigation state and route names

### Debug Output

Tests include debug output for:

- Performance timing measurements
- Test data creation confirmation
- Error scenario simulation status

### Logging

Enable verbose logging during test runs:

```bash
flutter test integration_test/ --verbose
```

## Continuous Integration

### CI Configuration

For CI/CD pipelines, configure tests to run on:

- Multiple Flutter versions
- Different platforms (web, Android, iOS)
- Various screen sizes and orientations

### Test Reports

Generate test reports using:

```bash
flutter test integration_test/ --coverage --reporter=json > test_results.json
```

## Maintenance

### Adding New Tests

1. Create test file in appropriate category
2. Follow existing naming conventions
3. Use helper functions for common operations
4. Include performance benchmarks where applicable
5. Add error scenarios and recovery testing

### Updating Test Data

1. Modify `firebase_test_setup.dart` for new data requirements
2. Update helper functions in `test_helpers.dart`
3. Ensure backward compatibility with existing tests

### Performance Baseline Updates

Update performance benchmarks when:

- App performance improves significantly
- New features affect performance characteristics
- Platform-specific optimizations are implemented

## Best Practices

1. **Test Isolation** - Each test should be independent and not rely on other tests
2. **Clean State** - Reset mocks and data between tests
3. **Realistic Scenarios** - Test real user workflows and edge cases
4. **Performance Awareness** - Include timing assertions for critical operations
5. **Error Coverage** - Test both happy path and error scenarios
6. **Documentation** - Keep test descriptions clear and maintainable
