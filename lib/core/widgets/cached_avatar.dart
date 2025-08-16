import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../constants/app_colors.dart';

/// A widget that displays a cached user avatar with fallback options
class CachedAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? displayName;
  final double radius;
  final Color? backgroundColor;
  final Color? textColor;
  final VoidCallback? onTap;

  const CachedAvatar({
    super.key,
    this.imageUrl,
    this.displayName,
    this.radius = 20,
    this.backgroundColor,
    this.textColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBackgroundColor =
        backgroundColor ?? theme.colorScheme.primary.withOpacity(0.1);
    final effectiveTextColor = textColor ?? theme.colorScheme.primary;

    Widget avatar;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      // Use cached network image
      avatar = CachedNetworkImage(
        imageUrl: imageUrl!,
        imageBuilder: (context, imageProvider) => CircleAvatar(
          radius: radius,
          backgroundImage: imageProvider,
        ),
        placeholder: (context, url) => CircleAvatar(
          radius: radius,
          backgroundColor: effectiveBackgroundColor,
          child: SizedBox(
            width: radius * 0.8,
            height: radius * 0.8,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(effectiveTextColor),
            ),
          ),
        ),
        errorWidget: (context, url, error) => _buildFallbackAvatar(
          effectiveBackgroundColor,
          effectiveTextColor,
        ),
        fadeInDuration: const Duration(milliseconds: 300),
        fadeOutDuration: const Duration(milliseconds: 100),
        memCacheWidth:
            (radius * 2 * MediaQuery.of(context).devicePixelRatio).round(),
        memCacheHeight:
            (radius * 2 * MediaQuery.of(context).devicePixelRatio).round(),
      );
    } else {
      // Use fallback avatar
      avatar =
          _buildFallbackAvatar(effectiveBackgroundColor, effectiveTextColor);
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: avatar,
      );
    }

    return avatar;
  }

  Widget _buildFallbackAvatar(Color backgroundColor, Color textColor) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      child: Text(
        _getInitials(),
        style: TextStyle(
          color: textColor,
          fontSize: radius * 0.6,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _getInitials() {
    if (displayName == null || displayName!.isEmpty) {
      return '?';
    }

    final words = displayName!.trim().split(' ');
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    } else if (words.length >= 2) {
      return '${words[0].substring(0, 1)}${words[1].substring(0, 1)}'
          .toUpperCase();
    }

    return displayName!.substring(0, 1).toUpperCase();
  }
}

/// A smaller variant of CachedAvatar for use in lists
class CachedAvatarSmall extends StatelessWidget {
  final String? imageUrl;
  final String? displayName;
  final VoidCallback? onTap;

  const CachedAvatarSmall({
    super.key,
    this.imageUrl,
    this.displayName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CachedAvatar(
      imageUrl: imageUrl,
      displayName: displayName,
      radius: 16,
      onTap: onTap,
    );
  }
}

/// A larger variant of CachedAvatar for profile pages
class CachedAvatarLarge extends StatelessWidget {
  final String? imageUrl;
  final String? displayName;
  final VoidCallback? onTap;

  const CachedAvatarLarge({
    super.key,
    this.imageUrl,
    this.displayName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CachedAvatar(
      imageUrl: imageUrl,
      displayName: displayName,
      radius: 40,
      onTap: onTap,
    );
  }
}

/// Avatar with online status indicator
class CachedAvatarWithStatus extends StatelessWidget {
  final String? imageUrl;
  final String? displayName;
  final bool isOnline;
  final double radius;
  final VoidCallback? onTap;

  const CachedAvatarWithStatus({
    super.key,
    this.imageUrl,
    this.displayName,
    this.isOnline = false,
    this.radius = 20,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CachedAvatar(
          imageUrl: imageUrl,
          displayName: displayName,
          radius: radius,
          onTap: onTap,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: radius * 0.4,
            height: radius * 0.4,
            decoration: BoxDecoration(
              color: isOnline ? AppColors.success : AppColors.textSecondary,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.surface,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
