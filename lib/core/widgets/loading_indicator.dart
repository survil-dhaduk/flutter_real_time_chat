import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

/// A reusable loading indicator widget
class LoadingIndicator extends StatelessWidget {
  final String? message;
  final double size;
  final Color? color;

  const LoadingIndicator({
    super.key,
    this.message,
    this.size = 24.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            color: color ?? AppColors.primary,
            strokeWidth: 2.0,
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/// A full-screen loading overlay
class LoadingOverlay extends StatelessWidget {
  final String? message;
  final bool isLoading;
  final Widget child;

  const LoadingOverlay({
    super.key,
    this.message,
    required this.isLoading,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.3),
            child: Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: LoadingIndicator(
                    message: message,
                    size: 32.0,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A shimmer loading effect for list items
class ShimmerLoading extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ??
                BorderRadius.circular(AppSpacing.radiusSm),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                AppColors.surfaceVariant,
                AppColors.surface,
                AppColors.surfaceVariant,
              ],
              stops: [
                (_animation.value - 1).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 1).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A skeleton loader for chat messages
class MessageSkeletonLoader extends StatelessWidget {
  final bool isOwnMessage;

  const MessageSkeletonLoader({
    super.key,
    this.isOwnMessage = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        mainAxisAlignment:
            isOwnMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isOwnMessage) ...[
            const ShimmerLoading(
              width: 32,
              height: 32,
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Column(
            crossAxisAlignment: isOwnMessage
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              ShimmerLoading(
                width: 200,
                height: 16,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              const SizedBox(height: AppSpacing.xs),
              ShimmerLoading(
                width: 120,
                height: 12,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
            ],
          ),
          if (isOwnMessage) ...[
            const SizedBox(width: AppSpacing.sm),
            const ShimmerLoading(
              width: 32,
              height: 32,
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ],
        ],
      ),
    );
  }
}

/// A skeleton loader for chat room cards
class ChatRoomSkeletonLoader extends StatelessWidget {
  const ChatRoomSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          const ShimmerLoading(
            width: 48,
            height: 48,
            borderRadius: BorderRadius.all(Radius.circular(24)),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerLoading(
                  width: double.infinity,
                  height: 16,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                const SizedBox(height: AppSpacing.xs),
                ShimmerLoading(
                  width: 150,
                  height: 12,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const ShimmerLoading(
            width: 40,
            height: 12,
            borderRadius: BorderRadius.all(Radius.circular(6)),
          ),
        ],
      ),
    );
  }
}
