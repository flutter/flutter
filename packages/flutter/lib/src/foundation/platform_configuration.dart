import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

/// Device configuration dispatcher.
///
/// This is the central entry point for device configuration changes.
/// Bindings should register callbacks to handle change events.
class DeviceConfigurationDispatch {
  /// Receives all events related to platform configuration change.
  PlatformConfigurationDelegate configurationDelegate;

  /// Sends platform raw messages.
  void sendPlatformMessage(
    String name,
    ByteData data,
    PlatformMessageResponseCallback callback,
  ) {}

  /// Receives all raw platform messages.
  PlatformMessageCallback get onPlatformMessage {}

  void setIsolateDebugName(String name) {}
  ByteData getPersistentIsolateData() {}
}

/// Registered with [DeviceConfigurationDispatch] by the binding to manage
/// and accumulate device configuration changes.
abstract class PlatformConfigurationManager {
  const PlatformConfigurationManager(DeviceConfigurationDispatch dispatch);

  void onPlatformConfigurationChanged(PlatformConfigurationChangedEvent event);

  /// The current platform configuration.
  PlatformConfiguration get configuration;

  /// The current set of screens on this device.
  Set<Screen> get screens;

  static PlatformConfigurationManager get instance {
    return FoundationBinding.instance.platformConfigurationManager;
  }
}

class PlatformConfigurationDelegate {
  VoidCallback onLocaleChanged;
  VoidCallback onTextScaleFactorChanged;
  VoidCallback onPlatformBrightnessChanged;
  VoidCallback onSemanticsEnabledChanged;
  VoidCallback onAccessibilityFeaturesChanged;
  SemanticsActionCallback onSemanticsAction;
  ScreenChangeCallback onScreenChanged;
  WindowChangeCallback onWindowChanged;
}

/// Configuration of the platform.
@immutable
class PlatformConfiguration {
  /// Const constructor for [PlatformConfiguration].
  const PlatformConfiguration({
    this.accessibilityFeatures,
    this.alwaysUse24HourFormat,
    this.semanticsEnabled,
    this.platformBrightness,
    this.textScaleFactor,
    this.locales,
    this.locale,
    this.defaultRouteName,
    this.initialLifecycleState,
  });

  final AccessibilityFeatures accessibilityFeatures;
  final bool alwaysUse24HourFormat;
  final bool semanticsEnabled;
  final Brightness platformBrightness;
  final double textScaleFactor;
  final List<Locale> locales;
  final Locale locale;
  final String defaultRouteName;
  final String initialLifecycleState;
}

abstract class ScreenManager {
  const ScreenManager(DeviceConfigurationDispatch dispatch);

  void onScreenChanged(ScreenChangedEvent event) {}

  Screen get screen;

  /// The current set of windows on this screen.
  Set<Window> get windows;

  static ScreenManager get instance {
    return FoundationBinding.instance.screenManager;
  }
}

@immutable
class Screen {
  // Opaque platform-provided screen id
  Object id;
  // Platform-provided name for screen.
  String name;
  // Screen rect in Flutter logical pixels
  Rect logicalGeometry;
  // Device pixel ratio in device pixels to logical pixels.
  Size devicePixelRatio;
  // Screen rect in device pixels
  Rect deviceGeometry;
  // Physical screen size in millimeters. Null if not available.
  Size physicalSizeMillimeters;
  // Screen pixel format information
  ScreenPixelFormat pixelFormat;

  /// The number of physical pixels on each side of this screen rectangle into
  /// which the application can place a window, but over which the operating
  /// system will likely place system UI, such as the keyboard or system menus,
  /// that fully obscures any content.
  ScreenPadding viewInsets;

  /// The number of physical pixels on each side of this screen rectangle into
  /// which the application can place a window, but which may be partially
  /// obscured by system UI (such as the system notification area), or physical
  /// intrusions in the display (e.g. overscan regions on television screens or
  /// phone sensor housings).
  ScreenPadding viewPadding;

  /// The number of physical pixels on each side of this screen rectangle into
  /// which the application can place a window, but where the operating system
  /// will consume input gestures for the sake of system navigation.
  ScreenPadding systemGestureInsets;

  /// The number of physical pixels on each side of this screen rectangle into
  /// which the application can place a window, but which may be partially
  /// obscured by system UI (such as the system notification area), or
  /// physical intrusions in the display (e.g. overscan regions on television
  /// screens or phone sensor housings).
  ScreenPadding padding;
}

/// A representation of distances for each of the four edges of a rectangle,
/// used to encode the view insets and padding that applications should place
/// around their user interface, as exposed by [Screen.viewInsets] and
/// [Screen.padding]. View insets and padding are preferably read via
/// [MediaQuery.of].
///
/// For a generic class that represents distances around a rectangle, see the
/// [EdgeInsets] class.
///
/// See also:
///
///  * [WidgetsBindingObserver], for a widgets layer mechanism to receive
///    notifications when the padding changes.
///  * [MediaQuery.of], for the preferred mechanism for accessing these values.
///  * [Scaffold], which automatically applies the padding in material design
///    applications.
class ScreenPadding {
  const ScreenPadding._({this.left, this.top, this.right, this.bottom});

  /// The distance from the left edge to the first unpadded pixel, in physical pixels.
  final double left;

  /// The distance from the top edge to the first unpadded pixel, in physical pixels.
  final double top;

  /// The distance from the right edge to the first unpadded pixel, in physical pixels.
  final double right;

  /// The distance from the bottom edge to the first unpadded pixel, in physical pixels.
  final double bottom;

  /// A window padding that has zeros for each edge.
  static const ScreenPadding zero = ScreenPadding._(left: 0.0, top: 0.0, right: 0.0, bottom: 0.0);

  @override
  String toString() {
    return 'ScreenPadding(left: $left, top: $top, right: $right, bottom: $bottom)';
  }
}

typedef PlatformConfigurationChangeCallback = void Function(
    PlatformConfigurationChangedEvent event);

class PlatformConfigurationChangedEvent {}

typedef WindowChangeCallback = void Function(WindowChangedEvent event);

abstract class WindowChangedEvent {}

class WindowCreatedEvent extends WindowChangedEvent {}

class WindowDestroyedEvent extends WindowChangedEvent {}

class WindowReconfiguredEvent extends WindowChangedEvent {}

typedef ScreenChangeCallback = void Function(ScreenChangedEvent event);

abstract class ScreenChangedEvent {}

class ScreenAddedEvent extends ScreenChangedEvent {}

class ScreenRemovedEvent extends ScreenChangedEvent {}

class ScreenReconfiguredEvent extends ScreenChangedEvent {}

@immutable
class WindowConfiguration {
  Size size;
  Offset location;
  Rect geometry;
  double layer;
}

// Registers for changes to windows, keeps track of the current set of windows.
abstract class WindowManager {
  const WindowManager(DeviceConfigurationDispatch dispatch);

  void onWindowChanged(WindowChangedEvent event) {}

  Future<Window> createWindow(WindowConfiguration configuration) async {}
  Future<void> destroyWindow(Object id) async {}
  Future<Window> configureWindow(
    Object windowId,
    WindowConfiguration configuration,
  ) async {}

  /// The current set of windows on all screens.
  Set<Window> get windows;

  static WindowManager get instance {
    return FoundationBinding.instance.windowManager;
  }
}

class WindowChangeDelegate {
  WindowChangeDelegate(
      this.onBeginFrame, this.onDrawFrame, this.onReportTimings, this.onPointerDataPacket);
  final FrameCallback onBeginFrame;
  final VoidCallback onDrawFrame;
  final TimingsCallback onReportTimings;
  final PointerDataPacketCallback onPointerDataPacket;
}

/// Class representing a window on a screen.
///
/// Windows can only be on one screen at a time (except where they aren't: need
/// to figure this out. WindowPadding might need to be a set of rectangles whose
/// union is the safe area).
class Window {
  Future<Rect> setGeometry(Rect rect) {
    // Convenience that calls configureWindow using configuration updated with
    // new rect, returns actual geometry obtained, as allowed by the platform.
    // Size is in logical pixels.
  }

  // Opaque platform-provided window id
  Object id;

  // The screen that the window is on.
  Screen screen;

  void scheduleFrame() {}
  void render(Scene scene) {}
  void updateSemantics(SemanticsUpdate update) {}

  /// The configurable aspects of a window.
  WindowConfiguration configuration;

  // The values below are all read-only, non-configurable aspects of the window.

  /// The window rectangle, as it intersects with Screen.viewInsets for the
  /// screen it is on.
  ///
  /// The number of physical pixels on each side of this window rectangle into
  /// which the application can draw, but over which the operating
  /// system will likely place system UI, such as the keyboard or system menus,
  /// that fully obscures any content.
  WindowPadding get viewInsets {}

  /// The number of physical pixels on each side of this screen rectangle into
  /// which the application can place a window, but which may be partially
  /// obscured by system UI (such as the system notification area), or physical
  /// intrusions in the display (e.g. overscan regions on television screens or
  /// phone sensor housings).
  WindowPadding get viewPadding {}

  /// The number of physical pixels on each side of this screen rectangle into
  /// which the application can place a window, but where the operating system
  /// will consume input gestures for the sake of system navigation.
  WindowPadding get systemGestureInsets {}

  /// The number of physical pixels on each side of this screen rectangle into
  /// which the application can place a window, but which may be partially
  /// obscured by system UI (such as the system notification area), or
  /// physical intrusions in the display (e.g. overscan regions on television
  /// screens or phone sensor housings).
  WindowPadding get padding {}
}

enum ScreenPixelByteOrder {
  rgba,
  bgra,
  argb,
  abgr,
}

class ScreenPixelFormat {
  ScreenPixelByteOrder byteOrder;
  int bitsPerPixel;
  int bitsPerChannel;
}
