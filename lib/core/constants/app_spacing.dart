/// Spacing constants following Material Design 3 guidelines
class AppSpacing {
  // Prevent instantiation
  AppSpacing._();

  // Base spacing unit (4dp)
  static const double unit = 4.0;

  // Standard spacing values
  static const double xs = unit; // 4dp
  static const double sm = unit * 2; // 8dp
  static const double md = unit * 3; // 12dp
  static const double lg = unit * 4; // 16dp
  static const double xl = unit * 5; // 20dp
  static const double xxl = unit * 6; // 24dp
  static const double xxxl = unit * 8; // 32dp

  // Semantic spacing
  static const double padding = lg; // 16dp
  static const double margin = lg; // 16dp
  static const double gap = md; // 12dp
  static const double gutter = xxl; // 24dp

  // Component-specific spacing
  static const double buttonPadding = lg; // 16dp
  static const double cardPadding = lg; // 16dp
  static const double listItemPadding = lg; // 16dp
  static const double inputPadding = lg; // 16dp
  static const double appBarPadding = lg; // 16dp

  // Chat-specific spacing
  static const double messageBubblePadding = md; // 12dp
  static const double messageBubbleMargin = sm; // 8dp
  static const double messageSpacing = sm; // 8dp
  static const double chatInputPadding = lg; // 16dp
  static const double chatRoomItemPadding = lg; // 16dp

  // Border radius values
  static const double radiusXs = unit; // 4dp
  static const double radiusSm = unit * 2; // 8dp
  static const double radiusMd = unit * 3; // 12dp
  static const double radiusLg = unit * 4; // 16dp
  static const double radiusXl = unit * 5; // 20dp
  static const double radiusXxl = unit * 7; // 28dp

  // Component-specific border radius
  static const double buttonRadius = radiusSm; // 8dp
  static const double cardRadius = radiusMd; // 12dp
  static const double inputRadius = radiusSm; // 8dp
  static const double messageBubbleRadius = radiusLg; // 16dp
  static const double avatarRadius = radiusXxl; // 28dp

  // Elevation values
  static const double elevationNone = 0.0;
  static const double elevationLow = 1.0;
  static const double elevationMedium = 3.0;
  static const double elevationHigh = 6.0;
  static const double elevationVeryHigh = 12.0;

  // Icon sizes
  static const double iconXs = 16.0;
  static const double iconSm = 20.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 40.0;
  static const double iconXxl = 48.0;

  // Avatar sizes
  static const double avatarSm = 32.0;
  static const double avatarMd = 40.0;
  static const double avatarLg = 56.0;
  static const double avatarXl = 72.0;

  // Minimum touch target size
  static const double minTouchTarget = 48.0;

  // Screen breakpoints
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 1024.0;
  static const double desktopBreakpoint = 1440.0;

  // Layout constraints
  static const double maxContentWidth = 1200.0;
  static const double minButtonHeight = 40.0;
  static const double maxButtonWidth = 280.0;
}
