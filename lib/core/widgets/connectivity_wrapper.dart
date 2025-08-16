import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';
import '../widgets/error_widgets.dart';

/// A wrapper widget that monitors connectivity and shows offline status
class ConnectivityWrapper extends StatefulWidget {
  final Widget child;
  final bool showOfflineIndicator;

  const ConnectivityWrapper({
    super.key,
    required this.child,
    this.showOfflineIndicator = true,
  });

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  final ConnectivityService _connectivityService = ConnectivityService();
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    _connectivityService.initialize();
    _connectivityService.connectivityStream.listen((isConnected) {
      if (mounted) {
        setState(() {
          _isConnected = isConnected;
        });
      }
    });
  }

  @override
  void dispose() {
    _connectivityService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!_isConnected && widget.showOfflineIndicator)
          OfflineDisplay(
            onRetry: () async {
              await _connectivityService.checkConnectivity();
            },
          ),
        Expanded(child: widget.child),
      ],
    );
  }
}
