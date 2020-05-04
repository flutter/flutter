import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

import 'binding.dart';

// -------------- Base API (doesn't require bindings/managers) ---------------

/// Device configuration dispatcher.
///
/// This is the central entry point for platform messages and configuration events.
class PlatformDispatcher {
  /// Receives all events related to platform configuration changes.
  PlatformConfigurationEventCallback onPlatformConfigurationChanged;

  /// Receives all events related to screens.
  ScreenEventCallback onScreenEvent;

  /// Receives all events related to windows.
  PlatformWindowEventCallback onWindowEvent;

  /// A callback invoked when any window begins a frame.
  ///
  /// {@template flutter.foundation.PlatformDispatcher.onBeginFrame}
  /// A callback that is invoked to notify the application that it is an
  /// appropriate time to provide a scene using the [SceneBuilder] API and the
  /// [PlatformWindow.render] method of the window for the provided platform ID.
  /// When possible, this is driven by the hardware VSync signal. This is only
  /// called if [PlatformWindow.scheduleFrame] for the window with the provided
  /// ID has been called since the last time this callback was invoked.
  /// {@endtemplate}
  FrameCallback onBeginFrame;

  /// {@template flutter.foundation.PlatformDispatcher.onDrawFrame}
  /// A callback that is invoked for each frame after [onBeginFrame] has
  /// completed and after the microtask queue has been drained.
  ///
  /// This can be used to implement a second phase of frame rendering that
  /// happens after any deferred work queued by the [onBeginFrame] phase.
  /// {@endtemplate}
  VoidCallback onDrawFrame;

  /// {@template flutter.foundation.PlatformDispatcher.onPointerDataPacket}
  /// A callback that is invoked when pointer data is available for a window.
  /// {@endtemplate}
  ///
  /// This callback is called when any window receives a pointer event.
  PointerDataPacketCallback onPointerDataPacket;

  /// {@template flutter.foundation.PlatformDispatcher.onReportTimings}
  /// A callback that is invoked to report the [FrameTiming] of recently
  /// rasterized frames for a window.
  /// {@endtemplate}
  ///
  /// This callback is called whenever any window receives timing information.
  TimingsCallback onReportTimings;

  /// Opens a new window and returns the window created.
  ///
  /// The configuration obtained and the one requested may not match, depending
  /// on what the platform was able to accommodate.
  Future<PlatformWindow> openWindow(PlatformWindowConfigurationRequest configuration) async {
    // ...
  }

  /// Encodes and sends raw messages to the platform.
  void sendPlatformMessage(
    String name,
    ByteData data,
    PlatformMessageResponseCallback callback,
  ) {
    // ...
  }

  /// Called by the platform code to receive raw platform messages and parse
  /// them.
  PlatformMessageCallback get onPlatformMessage {
    // ...
  }

  /// Allows setting of the root isolate debug name.
  void setIsolateDebugName(String name) {
    // ...
  }

  /// Retrieves the persistent data from the root isolate.
  ByteData getPersistentIsolateData() {
    // ...
  }
}

/// Callback types used by the [PlatformDispatcher].
typedef PlatformWindowBeginFrameCallback = void Function(Object windowId, Duration duration);
typedef PlatformWindowDrawFrameCallback = void Function(Object windowId);
typedef PlatformWindowReportTimingsCallback = void Function(
    Object windowId, List<FrameTiming> timings);
typedef PlatformWindowPointerDataPacketCallback = void Function(
    Object windowId, PointerDataPacket packet);

/// Callback type for events relating to platform configuration changes.
typedef PlatformConfigurationEventCallback = void Function(PlatformConfigurationEvent event);

/// Base class for platform configuration events.
@immutable
class PlatformConfigurationEvent {
  /// A const constructor so subclasses can be const.
  const PlatformConfigurationEvent();
}

/// The platform configuration has changed.
class PlatformConfigurationChangedEvent extends PlatformConfigurationEvent {
  /// A const constructor for a [PlatformConfigurationChangedEvent].
  ///
  /// The [configuration] parameter must not be null.
  const PlatformConfigurationChangedEvent({this.configuration});

  /// The new platform configuration.
  final PlatformConfiguration configuration;
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

  /// Additional accessibility features that may be enabled by the platform.
  final AccessibilityFeatures accessibilityFeatures;

  /// The setting indicating whether time should always be shown in the 24-hour
  /// format.
  final bool alwaysUse24HourFormat;

  /// Whether the user has requested that [updateSemantics] be called when the
  /// semantic contents of a window changes.
  final bool semanticsEnabled;

  /// The setting indicating the current brightness mode of the host platform.
  /// If the platform has no preference, [platformBrightness] defaults to
  /// [Brightness.light].
  final Brightness platformBrightness;

  /// The system-reported text scale.
  final double textScaleFactor;

  /// The full system-reported supported locales of the device.
  final List<Locale> locales;

  /// The system-reported default locale of the device.
  final Locale locale;

  /// The route or path that the embedder requested when the application was
  /// launched.
  final String defaultRouteName;

  /// The lifecycle state immediately after dart isolate initialization.
  final String initialLifecycleState;
}

/// Callback type for events relating to a screen.
typedef ScreenEventCallback = void Function(ScreenEvent event);

/// Base class for events relating to a screen.
@immutable
abstract class ScreenEvent {
  /// Const constructor so subclasses can be const.
  const ScreenEvent();
}

/// A screen was added to the device.
class ScreenAddedEvent extends ScreenEvent {
  /// A const constructor for a [ScreenAddedEvent].
  ///
  /// The [configuration] parameter must not be null.
  const ScreenAddedEvent({this.configuration});

  /// The configuration of the newly added screen.
  final ScreenConfiguration configuration;
}

/// A screen was removed from the device.
class ScreenRemovedEvent extends ScreenEvent {
  /// A const constructor for a [ScreenRemovedEvent].
  ///
  /// The [id] parameter must not be null.
  const ScreenRemovedEvent({this.id});

  /// The opaque platform ID of the screen that was removed.
  final Object id;
}

/// A screen changed configuration on the device.
class ScreenReconfiguredEvent extends ScreenEvent {
  /// A const constructor for a [ScreenRemovedEvent].
  ///
  /// The [configuration] parameter must not be null.
  const ScreenReconfiguredEvent({this.configuration});

  /// The newly configured screen.
  final ScreenConfiguration configuration;
}

/// Configuration information for screen.
@immutable
class ScreenConfiguration {
  /// Const constructor for [ScreenConfiguration] information.
  const ScreenConfiguration({
    this.id,
    this.name,
    this.logicalGeometry,
    this.devicePixelRatio,
    this.deviceGeometry,
    this.physicalSizeMillimeters,
    this.viewInsets,
    this.viewPadding,
    this.systemGestureInsets,
    this.padding,
  });

  /// Opaque platform-provided screen id
  final Object id;

  /// Platform-provided name for screen.
  final String name;

  /// Screen rect in Flutter logical pixels
  final Rect logicalGeometry;

  /// Device pixel ratio in device pixels to logical pixels.
  final Size devicePixelRatio;

  /// Screen rect in device pixels
  final Rect deviceGeometry;

  /// Physical screen size in millimeters. Null if not available.
  final Size physicalSizeMillimeters;

  /// The number of physical pixels on each side of this screen rectangle into
  /// which the application can place a window, but over which the operating
  /// system will likely place system UI, such as the keyboard or system menus,
  /// that fully obscures any content.
  final WindowPadding viewInsets;

  /// The number of physical pixels on each side of this screen rectangle into
  /// which the application can place a window, but which may be partially
  /// obscured by system UI (such as the system notification area), or physical
  /// intrusions in the display (e.g. overscan regions on television screens or
  /// phone sensor housings).
  final WindowPadding viewPadding;

  /// The number of physical pixels on each side of this screen rectangle into
  /// which the application can place a window, but where the operating system
  /// will consume input gestures for the sake of system navigation.
  final WindowPadding systemGestureInsets;

  /// The number of physical pixels on each side of this screen rectangle into
  /// which the application can place a window, but which may be partially
  /// obscured by system UI (such as the system notification area), or
  /// physical intrusions in the display (e.g. overscan regions on television
  /// screens or phone sensor housings).
  final WindowPadding padding;
}

/// Callback type for events relating to [PlatformWindow] events.
typedef PlatformWindowEventCallback = void Function(PlatformWindowEvent event);

/// Base class for all [PlatformWindow] related events.
@immutable
abstract class PlatformWindowEvent {
  /// A const constructor so subclasses can be const.
  const PlatformWindowEvent();
}

/// A new [PlatformWindow] has been opened.
class PlatformWindowOpenedEvent extends PlatformWindowEvent {
  /// A const constructor for a [PlatformWindowOpenedEvent].
  ///
  /// The [window] parameter must not be null.
  const PlatformWindowOpenedEvent({this.window});

  /// The window that was opened.
  final PlatformWindow window;
}

/// A [PlatformWindow] has been closed.
class PlatformWindowClosedEvent extends PlatformWindowEvent {
  /// A const constructor for a [PlatformWindowOpenedEvent].
  ///
  /// The [id] parameter must not be null.
  const PlatformWindowClosedEvent({this.id});

  /// The opaque platform ID of the window that was closed.
  final Object id;
}

/// A [PlatformWindow] has been reconfigured.
class PlatformWindowReconfiguredEvent extends PlatformWindowEvent {
  /// A const constructor for a [PlatformWindowReconfiguredEvent].
  ///
  /// The [window] parameter must not be null.
  const PlatformWindowReconfiguredEvent({this.window});

  /// The reconfigured window.
  final PlatformWindow window;
}

/// Class that holds the information needed for a window configuration request.
///
/// Used to request a different configuration of a [PlatformWindow], so that
/// multiple window parameters can be configured simultaneously.
///
/// Parameters that shouldn't be changed may be null. At least one parameter
/// must be set.
@immutable
class PlatformWindowConfigurationRequest {
  /// Const constructor for a [PlatformWindowConfigurationRequest].
  const PlatformWindowConfigurationRequest({
    this.screen,
    this.geometry,
    this.order,
    this.orderWindowId,
  })  : assert(orderWindowId != null ||
            (order != PlatformWindowOrder.aboveWindow && order != PlatformWindowOrder.belowWindow)),
        assert(screen != null || geometry != null || order != null,
            'At least one parameter must be non-null');

  /// Makes a new copy of this [PlatformWindowConfigurationRequest] with some attributes
  /// replaced.
  PlatformWindowConfigurationRequest copyWith({
    Object screen,
    Rect geometry,
    PlatformWindowOrder layerRequest,
    Object layerWindowId,
  }) {
    return PlatformWindowConfigurationRequest(
      screen: screen ?? this.screen,
      geometry: geometry ?? this.geometry,
      order: layerRequest ?? this.order,
      orderWindowId: layerWindowId ?? this.orderWindowId,
    );
  }

  /// Opaque platform ID of the screen that this window should appear on.
  ///
  /// If the platform supports spanning multiple screens, this is the screen
  /// that the upper left corner of the window appears on.
  final Object screen;

  /// The geometry requested for the window on the [screen], in logical pixels.
  ///
  /// This uses the device pixel ratio of the screen with the upper left corner
  /// of this window on it.
  final Rect geometry;

  /// The depth ordering of this window relative to other windows.
  final PlatformWindowOrder order;

  /// The opaque ID of the window to place this window on a layer relative to,
  /// according to [order].
  ///
  /// Only used (and required) if [order] is
  /// [PlatformWindowOrder.aboveWindow] or [PlatformWindowOrder.belowWindow].
  ///
  /// This ID corresponds to the window that this one should be above or below.
  final Object orderWindowId;
}

/// An enum describing how to layer this window in a [PlatformWindowConfigurationRequest].
enum PlatformWindowOrder {
  /// Place this window immediately above the window with ID
  /// [PlatformWindowConfigurationRequest.orderWindowId].
  aboveWindow,

  /// Place this window immediately above the window with ID
  /// [PlatformWindowConfigurationRequest.orderWindowId].
  belowWindow,

  /// Place this window on top of all other windows.
  top,

  /// Place this window below all other windows.
  bottom,
}

/// Represents a platform window on a screen.
///
/// Windows are considered to be "on" the screen which contains their upper-left
/// corner.
///
/// Window coordinates are relative to the screen origin at the upper left
/// corner of the screen, and are in logical coordinates.
class PlatformWindow {
  /// Creates a new [PlatformWindow].
  ///
  /// All parameters must not be null.
  PlatformWindow({
    @required this.id,
    @required this.screen,
  })  : assert(id != null),
        assert(screen != null);

  /// Opaque platform-provided window id
  final Object id;

  /// The screen that the upper left corner of this window is on.
  final ScreenConfiguration screen;

  /// Requests the window be reconfigured with the given `rect` in logical
  /// coordinates.
  ///
  /// Returns the actual rect obtained from the platform.
  Future<Rect> setGeometry(Rect rect) {}

  /// Asks the engine to schedule a frame for this window.
  void scheduleFrame() {}

  /// Asks the engine to render the given `scene` in this window.
  void render(Scene scene) {}

  /// Updates the semantics for this window.
  void updateSemantics(SemanticsUpdate update) {}

  /// Called by the [PlatformDispatcher] when it receives an `onBeginFrame` for
  /// this window.
  ///
  /// {@macro flutter.foundation.PlatformDispatcher.onBeginFrame}
  void onBeginFrame(Duration duration) {}

  /// Called by the [PlatformDispatcher] when it receives an `onDrawFrame` for
  /// this window.
  ///
  /// {@macro flutter.foundation.PlatformDispatcher.onDrawFrame}
  void onDrawFrame() {}

  /// Called by the [PlatformDispatcher] when it receives an `onPointerDataPacket` for
  /// this window.
  ///
  /// {@macro flutter.foundation.PlatformDispatcher.onPointerDataPacket}
  void onPointerDataPacket(PointerDataPacket packet) {}

  /// Called by the [PlatformDispatcher] when it receives an `onReportTimings` for
  /// this window.
  ///
  /// {@macro flutter.foundation.PlatformDispatcher.onReportTimings}
  void onReportTimings(List<FrameTiming> timings) {}

  /// The geometry of the window on the [screen], in logical pixels.
  ///
  /// This is multiplied by the device pixel ratio of the screen with the upper
  /// left corner of this window on it to convert to the device's coordinates.
  Rect get geometry {}

  /// Requests that the platform configure the `window` with the `configuration`.
  ///
  /// Returns the window after configuration. The configuration obtained and the
  /// one requested may not match, depending on what the platform was able to
  /// accommodate.
  Future<PlatformWindow> configureWindow(PlatformWindowConfigurationRequest configuration) async {
    // ...
  }

  /// Closes the given window.
  ///
  /// Completes when the window has been closed.
  Future<void> closeWindow() async {}

  // The values below are all read-only, non-configurable aspects of the window.

  /// The window insets, as it intersects with Screen.viewInsets for the
  /// screen it is on.
  ///
  /// For instance, if the window doesn't overlap the
  /// [ScreenConfiguration.viewInsets] area, [viewInsets] will be
  /// [WindowPadding.zero].
  ///
  /// The number of physical pixels on each side of this window rectangle into
  /// which the application can draw, but over which the operating
  /// system will likely place system UI, such as the keyboard or system menus,
  /// that fully obscures any content.
  WindowPadding get viewInsets {}

  /// The window insets, as it intersects with [ScreenConfiguration.viewPadding]
  /// for the screen it is on.
  ///
  /// For instance, if the window doesn't overlap the
  /// [ScreenConfiguration.viewPadding] area, [viewPadding] will be
  /// [WindowPadding.zero].
  ///
  /// The number of physical pixels on each side of this screen rectangle into
  /// which the application can place a window, but which may be partially
  /// obscured by system UI (such as the system notification area), or physical
  /// intrusions in the display (e.g. overscan regions on television screens or
  /// phone sensor housings).
  WindowPadding get viewPadding {}

  /// The window insets, as it intersects with
  /// [ScreenConfiguration.systemGestureInsets] for the screen it is on.
  ///
  /// For instance, if the window doesn't overlap the
  /// [ScreenConfiguration.systemGestureInsets] area, [systemGestureInsets] will be
  /// [WindowPadding.zero].
  ///
  /// The number of physical pixels on each side of this screen rectangle into
  /// which the application can place a window, but where the operating system
  /// will consume input gestures for the sake of system navigation.
  WindowPadding get systemGestureInsets {}

  /// The window insets, as it intersects with [ScreenConfiguration.padding] for
  /// the screen it is on.
  ///
  /// For instance, if the window doesn't overlap the
  /// [ScreenConfiguration.padding] area, [padding] will be
  /// [WindowPadding.zero].
  ///
  /// The number of physical pixels on each side of this screen rectangle into
  /// which the application can place a window, but which may be partially
  /// obscured by system UI (such as the system notification area), or
  /// physical intrusions in the display (e.g. overscan regions on television
  /// screens or phone sensor housings).
  WindowPadding get padding {}
}

// ----------------- Binding-owned Managers ----------------------

/// Registered with [PlatformDispatcher] by the binding to manage
/// and accumulate device configuration changes.
class PlatformConfigurationManager with ChangeNotifier {
  /// Const constructor so subclasses can be const.
  PlatformConfigurationManager(PlatformDispatcher dispatch) {
    dispatch.onPlatformConfigurationChanged = onPlatformConfigurationChanged;
  }

  /// Called by the [PlatformDispatcher] whenever the configuration
  /// changes.
  @protected
  void onPlatformConfigurationChanged(PlatformConfigurationEvent event) {
    // handle events...
    notifyListeners();
  }

  /// The current platform configuration.
  PlatformConfiguration configuration;

  /// Gets the binding's instance of the current configuration manager.
  static PlatformConfigurationManager get instance {
    return BindingBase.instance.platformConfigurationManager;
  }
}

/// A screen manager that listens to events from the platform.
class ScreenManager with ChangeNotifier {
  /// Creates a screen manager that listens to the given dispatch.
  ScreenManager(PlatformDispatcher dispatch) {
    dispatch.onScreenEvent = onScreenEvent;
  }

  /// Called by the [PlatformDispatcher] whenever a screen event
  /// occurs.
  @protected
  void onScreenEvent(ScreenEvent event) {
    // Manage map of screens here.
    // ...
    notifyListeners();
  }

  /// The current set of screens on this device, mapped by platform id.
  Map<Object, ScreenConfiguration> screens;

  /// Gets the binding's instance of the current screen manager.
  static ScreenManager get instance {
    return BindingBase.instance.screenManager;
  }
}

/// A window manager that handles window events from the platform.
class WindowManager with ChangeNotifier {
  /// Creates a window manager that listens to events on the given dispatch.
  WindowManager(PlatformDispatcher dispatch) : _dispatch = dispatch {
    dispatch.onWindowEvent = onWindowEvent;
    dispatch.onPointerDataPacket = onPointerDataPacket;
    dispatch.onBeginFrame = onBeginFrame;
    dispatch.onDrawFrame = onDrawFrame;
    dispatch.onReportTimings = onReportTimings;
  }

  /// {@macro flutter.foundation.PlatformDispatcher.onBeginFrame}
  void onBeginFrame(Duration duration) {
    for (final PlatformWindow window in windows.values) {
      window.onBeginFrame(duration);
    }
  }

  /// {@macro flutter.foundation.PlatformDispatcher.onDrawFrame}
  void onDrawFrame() {
    for (final PlatformWindow window in windows.values) {
      window.onDrawFrame();
    }
  }

  /// {@macro flutter.foundation.PlatformDispatcher.onPointerDataPacket}
  void onPointerDataPacket(PointerDataPacket event) {
    // determine which window from the event, dispatch a pointer data packet to it.
    // ...
  }

  /// {@macro flutter.foundation.PlatformDispatcher.onReportTimings}
  void onReportTimings(List<FrameTiming> timings) {
    // only report the timings for the relevant window to each window, not all
    // timings.
    // ...
  }

  final PlatformDispatcher _dispatch;

  /// Called by the [PlatformDispatcher] whenever a window event
  /// occurs.
  @protected
  void onWindowEvent(PlatformWindowEvent event) {
    // Manage adding/removing/updating windows from the [windows] map.
    // ...
    notifyListeners();
  }

  /// Opens a new window and returns the window created.
  ///
  /// The configuration obtained and the one requested may not match, depending
  /// on what the platform was able to accommodate.
  Future<PlatformWindow> openWindow(PlatformWindowConfigurationRequest configuration) async {
    // Also adds the window to the list of windows.
    return await _dispatch.openWindow(configuration);
  }

  /// The current set of windows on all screens, mapped by platform id.
  Map<Object, PlatformWindow> windows;

  /// Gets the binding's instance of the current window manager.
  static WindowManager get instance {
    return BindingBase.instance.windowManager;
  }
}
