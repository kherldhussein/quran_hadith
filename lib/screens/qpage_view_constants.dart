/// Constants used in QPageView for maintainability and consistency
library;

/// Animation and timing constants
class AnimationTimings {
  /// Standard animation duration for scroll operations (500ms)
  static const Duration scrollAnimationDuration = Duration(milliseconds: 500);

  /// Standard animation duration for fade/opacity transitions (300ms)
  static const Duration fadeTransitionDuration = Duration(milliseconds: 300);

  /// Delay before attempting auto-scroll after page load (500ms)
  static const Duration autoScrollDelay = Duration(milliseconds: 500);

  /// Regular update interval for progress tracking (10 seconds)
  static const Duration progressTrackingInterval = Duration(seconds: 10);

  /// Duration for translation retry snackbar display (4 seconds)
  static const Duration translationErrorSnackBarDuration = Duration(seconds: 4);
}

/// Opacity constants for UI elements
class UIOpacities {
  /// High opacity - for prominent UI elements (0.8 or 80%)
  static const double high = 0.8;

  /// Medium opacity - for secondary text and interactive elements (0.7 or 70%)
  static const double medium = 0.7;

  /// Medium-low opacity - for disabled or less prominent elements (0.5 or 50%)
  static const double mediumLow = 0.5;

  /// Low opacity - for subtle backgrounds and borders (0.1 or 10%)
  static const double low = 0.1;

  /// Very low opacity - for shadows and faint elements (0.05 or 5%)
  static const double veryLow = 0.05;

  /// Secondary element opacity (0.2 or 20%)
  static const double secondary = 0.2;

  /// Tertiary element opacity - for hover/disabled states (0.3 or 30%)
  static const double tertiary = 0.3;
}

/// Spacing constants
class Spacings {
  /// Small spacing value (8 pixels)
  static const double small = 8.0;

  /// Medium spacing value (12 pixels)
  static const double medium = 12.0;

  /// Standard spacing value (16 pixels)
  static const double standard = 16.0;

  /// Large spacing value (20 pixels)
  static const double large = 20.0;

  /// Extra large spacing value (40 pixels)
  static const double extraLarge = 40.0;
}

/// Text styling constants
class TextSizes {
  /// Small text size (10 pixels)
  static const double small = 10.0;

  /// Regular text size (14 pixels)
  static const double regular = 14.0;

  /// Medium text size (16 pixels)
  static const double medium = 16.0;

  /// Large text size (18 pixels)
  static const double large = 18.0;

  /// Extra large text size (24 pixels)
  static const double extraLarge = 24.0;
}

/// Border radius constants
class BorderRadii {
  /// Small border radius (12 pixels)
  static const double small = 12.0;

  /// Medium border radius (16 pixels)
  static const double medium = 16.0;

  /// Large border radius (20 pixels)
  static const double large = 20.0;

  /// Circular border radius (maximum)
  static const double circular = 20.0;
}

/// Scroll calculation constants
class ScrollConstants {
  /// Approximate pixels per ayah card (for scroll position tracking)
  static const double pixelsPerAyah = 100.0;
}

/// Elevation constants for cards and containers
class Elevations {
  /// No elevation (flat design)
  static const double none = 0.0;

  /// Subtle elevation (2 pixels)
  static const double subtle = 2.0;

  /// Medium elevation (5 pixels)
  static const double medium = 5.0;

  /// High elevation (10 pixels)
  static const double high = 10.0;

  /// Extra high elevation (20 pixels)
  static const double extraHigh = 20.0;
}
