import 'package:integration_test/integration_test.dart';

// Import all integration test files
import 'app_test.dart' as app_test;
import 'auth_flow_test.dart' as auth_flow_test;
import 'chat_functionality_test.dart' as chat_functionality_test;
import 'performance_test.dart' as performance_test;
import 'error_handling_test.dart' as error_handling_test;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Run all integration tests
  app_test.main();
  auth_flow_test.main();
  chat_functionality_test.main();
  performance_test.main();
  error_handling_test.main();
}
