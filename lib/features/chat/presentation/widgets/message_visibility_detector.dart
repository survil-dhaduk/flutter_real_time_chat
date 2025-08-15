import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Widget that detects when a message becomes visible and triggers a callback
class MessageVisibilityDetector extends StatelessWidget {
  final String messageId;
  final Widget child;
  final VoidCallback? onVisible;
  final double visibilityThreshold;

  const MessageVisibilityDetector({
    super.key,
    required this.messageId,
    required this.child,
    this.onVisible,
    this.visibilityThreshold = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('message_$messageId'),
      onVisibilityChanged: (visibilityInfo) {
        final visiblePercentage = visibilityInfo.visibleFraction;
        if (visiblePercentage >= visibilityThreshold) {
          onVisible?.call();
        }
      },
      child: child,
    );
  }
}
