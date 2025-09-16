import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ResponsiveLayout {
  // Layout detection methods with platform awareness
  static bool isMobileLayout(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width < (kIsWeb ? 768 : 600);
  }
  
  static bool isTabletLayout(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (kIsWeb) {
      return width >= 768 && width < 1024;
    } else {
      return width >= 600 && width < 1200;
    }
  }
  
  static bool isDesktopLayout(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= (kIsWeb ? 1024 : 1200);
  }
  
  // Platform-aware spacing and padding
  static double getSpacing(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (kIsWeb) {
      if (width < 768) return 12.0;
      if (width < 1024) return 18.0;
      return 24.0;
    } else {
      if (width < 600) return 12.0;
      if (width < 1200) return 16.0;
      return 20.0;
    }
  }
  
  static EdgeInsets getPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (kIsWeb) {
      if (width < 768) return const EdgeInsets.all(16.0);
      if (width < 1024) return const EdgeInsets.all(20.0);
      return const EdgeInsets.all(24.0);
    } else {
      if (width < 600) return const EdgeInsets.all(12.0);
      if (width < 1200) return const EdgeInsets.all(18.0);
      return const EdgeInsets.all(24.0);
    }
  }
  
  // Typography scaling with platform considerations
  static double getFontSize(BuildContext context, {required double base}) {
    final width = MediaQuery.of(context).size.width;
    if (kIsWeb) {
      // Web typically needs slightly larger fonts for readability
      if (width < 768) return base * 1.05;
      if (width < 1024) return base * 1.15;
      return base * 1.25;
    } else {
      if (width < 600) return base;
      if (width < 1200) return base * 1.1;
      return base * 1.2;
    }
  }
  
  // Interactive element sizing with platform optimization
  static double getButtonHeight(BuildContext context) {
    if (kIsWeb) {
      return MediaQuery.of(context).size.width < 768 ? 44.0 : 48.0;
    } else {
      return MediaQuery.of(context).size.width < 600 ? 48.0 : 56.0;
    }
  }
  
  static double getIconSize(BuildContext context, {required double base}) {
    final width = MediaQuery.of(context).size.width;
    if (kIsWeb) {
      if (width < 768) return base * 1.1;
      if (width < 1024) return base * 1.3;
      return base * 1.5;
    } else {
      if (width < 600) return base;
      if (width < 1200) return base * 1.2;
      return base * 1.4;
    }
  }

  // Container constraints with platform-specific adjustments
  static BoxConstraints getContainerConstraints(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final safeHeight = screenHeight - MediaQuery.of(context).padding.top 
                                   - MediaQuery.of(context).padding.bottom;
    
    if (kIsWeb) {
      return BoxConstraints(
        maxHeight: isMobileLayout(context) 
            ? safeHeight * 0.75 
            : safeHeight * 0.85,
        maxWidth: double.infinity,
      );
    } else {
      return BoxConstraints(
        maxHeight: isMobileLayout(context) 
            ? safeHeight * 0.7 
            : safeHeight * 0.8,
        maxWidth: double.infinity,
      );
    }
  }

  // Modal-specific constraints for login and other modals
  static BoxConstraints getModalConstraints(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;
    final safeHeight = screenHeight - MediaQuery.of(context).padding.top 
                                   - MediaQuery.of(context).padding.bottom;
    
    if (kIsWeb) {
      if (screenWidth < 768) {
        // Web mobile view
        return BoxConstraints(
          maxHeight: safeHeight * 0.9,
          maxWidth: screenWidth - 40,
          minWidth: screenWidth - 40,
        );
      } else if (screenWidth < 1024) {
        // Web tablet view
        return BoxConstraints(
          maxHeight: safeHeight * 0.85,
          maxWidth: 550,
          minWidth: 450,
        );
      } else {
        // Web desktop view
        return const BoxConstraints(
          maxHeight: 650,
          maxWidth: 500,
          minWidth: 450,
        );
      }
    } else {
      if (isMobileLayout(context)) {
        // Mobile device
        return BoxConstraints(
          maxHeight: safeHeight * 0.85,
          maxWidth: screenWidth - 32,
          minWidth: screenWidth - 32,
        );
      } else if (isTabletLayout(context)) {
        // Tablet device
        return BoxConstraints(
          maxHeight: safeHeight * 0.8,
          maxWidth: 500,
          minWidth: 400,
        );
      } else {
        // Large mobile device or small tablet
        return const BoxConstraints(
          maxHeight: 600,
          maxWidth: 450,
          minWidth: 400,
        );
      }
    }
  }

  // Platform-aware screen space allocation
  static double getHeaderHeight(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final safeHeight = screenHeight - MediaQuery.of(context).padding.top 
                                   - MediaQuery.of(context).padding.bottom;
    
    if (kIsWeb) {
      return safeHeight * (isMobileLayout(context) ? 0.12 : 0.15);
    } else {
      return safeHeight * 0.15;
    }
  }

  static double getContentHeight(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final safeHeight = screenHeight - MediaQuery.of(context).padding.top 
                                   - MediaQuery.of(context).padding.bottom;
    
    if (kIsWeb) {
      return safeHeight * (isMobileLayout(context) ? 0.75 : 0.70);
    } else {
      return safeHeight * 0.70;
    }
  }

  static double getControlHeight(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final safeHeight = screenHeight - MediaQuery.of(context).padding.top 
                                   - MediaQuery.of(context).padding.bottom;
    
    return safeHeight * 0.15;
  }

  // Grid layout helpers with platform optimization
  static int getGridColumnCount(BuildContext context) {
    if (kIsWeb) {
      if (isDesktopLayout(context)) return 4;
      if (isTabletLayout(context)) return 3;
      return 2;
    } else {
      if (isDesktopLayout(context)) return 3;
      if (isTabletLayout(context)) return 2;
      return 1;
    }
  }

  static double getGridAspectRatio(BuildContext context) {
    if (kIsWeb) {
      if (isMobileLayout(context)) return 0.9;
      if (isTabletLayout(context)) return 1.1;
      return 1.3;
    } else {
      if (isMobileLayout(context)) return 0.8;
      if (isTabletLayout(context)) return 1.0;
      return 1.2;
    }
  }

  // Touch target sizes (platform-specific compliance)
  static double getTouchTargetSize(BuildContext context) {
    return kIsWeb ? 44.0 : 48.0; // Web vs mobile standards
  }

  // Card and component sizing with platform awareness
  static double getCardElevation(BuildContext context) {
    if (kIsWeb) {
      return isMobileLayout(context) ? 1.0 : 3.0;
    } else {
      return isMobileLayout(context) ? 2.0 : 4.0;
    }
  }

  static BorderRadius getCardBorderRadius(BuildContext context) {
    final radius = kIsWeb && isDesktopLayout(context) ? 18.0 : 
                   isMobileLayout(context) ? 12.0 : 16.0;
    return BorderRadius.circular(radius);
  }

  // Navigation and layout helpers with platform detection
  static bool shouldShowDrawer(BuildContext context) {
    return isMobileLayout(context);
  }

  static bool shouldShowNavigationRail(BuildContext context) {
    return !isMobileLayout(context);
  }

  static bool shouldShowBottomNavigation(BuildContext context) {
    return isMobileLayout(context) && !kIsWeb;
  }

  // Content width constraints with platform optimization
  static double getMaxContentWidth(BuildContext context) {
    if (kIsWeb) {
      if (isDesktopLayout(context)) return 1400.0;
      if (isTabletLayout(context)) return 1024.0;
      return double.infinity;
    } else {
      if (isDesktopLayout(context)) return 1200.0;
      return double.infinity;
    }
  }

  // Animation durations based on platform and screen size
  static Duration getAnimationDuration(BuildContext context) {
    if (kIsWeb) {
      return isMobileLayout(context) 
          ? const Duration(milliseconds: 250)
          : const Duration(milliseconds: 350);
    } else {
      return isMobileLayout(context) 
          ? const Duration(milliseconds: 200)
          : const Duration(milliseconds: 300);
    }
  }

  // Enhanced viewport detection with platform awareness
  static bool isVerySmallScreen(BuildContext context) {
    final size = MediaQuery.of(context).size;
    if (kIsWeb) {
      return size.height < 600 || size.width < 480;
    } else {
      return size.height < 600 || size.width < 400;
    }
  }

  static bool isLargeScreen(BuildContext context) {
    final size = MediaQuery.of(context).size;
    if (kIsWeb) {
      return size.width >= 1920 && size.height >= 1080;
    } else {
      return size.width >= 1200 && size.height >= 800;
    }
  }

  // Platform-specific safe padding adjustments
  static EdgeInsets getSafeModalPadding(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    final padding = MediaQuery.of(context).padding;
    
    if (kIsWeb) {
      return EdgeInsets.only(
        top: padding.top,
        left: 20,
        right: 20,
        bottom: viewInsets.bottom + 20,
      );
    } else {
      return EdgeInsets.only(
        top: padding.top,
        left: 16,
        right: 16,
        bottom: viewInsets.bottom + 16,
      );
    }
  }

  // Platform-specific scroll behavior
  static ScrollPhysics getScrollPhysics() {
    return kIsWeb 
        ? const ClampingScrollPhysics()
        : const BouncingScrollPhysics();
  }

  // Enhanced input handling for different platforms
  static TextInputType getKeyboardType(String inputType) {
    switch (inputType) {
      case 'email':
        return kIsWeb ? TextInputType.emailAddress : TextInputType.emailAddress;
      case 'phone':
        return kIsWeb ? TextInputType.text : TextInputType.phone;
      case 'number':
        return TextInputType.number;
      case 'url':
        return TextInputType.url;
      default:
        return TextInputType.text;
    }
  }

  // Platform-specific interaction feedback
  static void provideFeedback(BuildContext context, String type) {
    if (!kIsWeb) {
      // Mobile haptic feedback would go here
      // HapticFeedback.lightImpact();
    }
    // Web could have visual feedback instead
  }

  // Device orientation handling
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  // Platform-specific text scaling
  static double getTextScaleFactor(BuildContext context) {
    if (kIsWeb) {
      // Web should have more consistent text scaling
      return 1.0;
    } else {
      // Mobile can follow system text scaling
      return MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.3);
    }
  }
}
