import 'dart:async';
import 'dart:io';

/// Service to monitor network connectivity
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final StreamController<bool> _connectivityController =
      StreamController<bool>.broadcast();

  bool _isConnected = true;
  Timer? _connectivityTimer;

  /// Stream of connectivity status
  Stream<bool> get connectivityStream => _connectivityController.stream;

  /// Current connectivity status
  bool get isConnected => _isConnected;

  /// Initialize connectivity monitoring
  void initialize() {
    _startConnectivityCheck();
  }

  /// Start periodic connectivity checks
  void _startConnectivityCheck() {
    _connectivityTimer?.cancel();
    _connectivityTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkConnectivity(),
    );

    // Initial check
    _checkConnectivity();
  }

  /// Check internet connectivity
  Future<void> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));

      final newStatus = result.isNotEmpty && result[0].rawAddress.isNotEmpty;

      if (newStatus != _isConnected) {
        _isConnected = newStatus;
        _connectivityController.add(_isConnected);
      }
    } catch (e) {
      if (_isConnected) {
        _isConnected = false;
        _connectivityController.add(_isConnected);
      }
    }
  }

  /// Manually trigger connectivity check
  Future<bool> checkConnectivity() async {
    await _checkConnectivity();
    return _isConnected;
  }

  /// Dispose resources
  void dispose() {
    _connectivityTimer?.cancel();
    _connectivityController.close();
  }
}
