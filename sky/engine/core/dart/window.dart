// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of dart_ui;

/// Signature of callbacks that have no arguments and return no data.
typedef void VoidCallback();

/// Signature for [Window.onBeginFrame].
typedef void FrameCallback(Duration duration);

/// Signature for [Window.onPointerPacket].
typedef void PointerPacketCallback(ByteData serializedPacket);

/// Signature for [Window.onAppLifecycleStateChanged].
typedef void AppLifecycleStateCallback(AppLifecycleState state);

/// States that an application can be in.
enum AppLifecycleState {
  // These values must match the order of the values of
  // AppLifecycleState in sky_engine.mojom

  /// The application is not currently visible to the user. When the
  /// application is in this state, the engine will not call the
  /// [onBeginFrame] callback.
  paused,

  /// The application is visible to the user.
  resumed,
}

/// A representation of distances for each of the four edges of a rectangle,
/// used to encode the padding that applications should place around their user
/// interface, as exposed by [Window.padding].
///
/// For a generic class that represents distances around a rectangle, see the
/// [EdgeDims] class.
class WindowPadding {
  const WindowPadding._({ this.top, this.right, this.bottom, this.left });

  final double top;
  final double right;
  final double bottom;
  final double left;
}

/// An identifier used to select a user's language and formatting preferences,
/// consisting of a language and a country. This is a subset of locale
/// identifiers as defined by BCP 47.
class Locale {
  const Locale(this.languageCode, this.countryCode);

  /// The primary language subtag for the locale.
  final String languageCode;

  /// The region subtag for the locale.
  final String countryCode;

  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other is! Locale)
      return false;
    final Locale typedOther = other;
    return languageCode == typedOther.languageCode
        && countryCode == typedOther.countryCode;
  }

  int get hashCode {
    int result = 373;
    result = 37 * result + languageCode.hashCode;
    result = 37 * result + countryCode.hashCode;
    return result;
  }

  String toString() => '${languageCode}_$countryCode';
}

/// The most basic interface to the host operating system's user interface.
class Window {
  Window._();

  /// The number of device pixels for each logical pixel. This number might not
  /// be a power of two. Indeed, it might not even be an integer. For example,
  /// the Nexus 6 has a device pixel ratio of 3.5.
  double get devicePixelRatio => _devicePixelRatio;
  double _devicePixelRatio;

  /// The dimensions of the rectangle into which the application will be drawn,
  /// in logical pixels.
  Size get size => _size;
  Size _size;

  /// The number of pixels on each side of the display rectangle into which the
  /// application can render, but over which the operating system will likely
  /// place system UI (such as the Android system notification area), or which
  /// might be rendered outside of the physical display (e.g. overscan regions
  /// on television screens).
  WindowPadding get padding => _padding;
  WindowPadding _padding;

  /// A callback that is invoked whenever the [devicePixelRatio], [size], or
  /// [padding] values change.
  VoidCallback onMetricsChanged;

  /// The system-reported locale. This establishes the language and formatting
  /// conventions that application should, if possible, use to render their user
  /// interface.
  Locale get locale => _locale;
  Locale _locale;

  /// A callback that is invoked whenever [locale] changes value.
  VoidCallback onLocaleChanged;

  /// A callback that is invoked when there is a transition in the application's
  /// lifecycle (such as pausing or resuming).
  AppLifecycleStateCallback onAppLifecycleStateChanged;

  /// A callback that is invoked to notify the application that it is an
  /// appropriate time to provide a scene using the [SceneBuilder] API and the
  /// [render()] method. When possible, this is driven by the hardware VSync
  /// signal. This is only called if [scheduleFrame()] has been called since the
  /// last time this callback was invoked.
  FrameCallback onBeginFrame;

  /// A callback that is invoked when pointer data is available. The data is
  /// provided in the form of a raw byte stream containing an encoded mojo
  /// PointerPacket.
  PointerPacketCallback onPointerPacket;

  /// The route or path that the operating system requested when the application
  /// was launched.
  String get defaultRouteName => _defaultRouteName;
  String _defaultRouteName;

  /// A callback that is invoked when the operating system requests that the
  /// application goes "back" one step in its history. For example, on Android
  /// this is invoked in response to the "back" button.
  VoidCallback onPopRoute;

  /// Requests that, at the next appropriate opportunity, the [onBeginFrame]
  /// callback be invoked.
  void scheduleFrame() native "Window_scheduleFrame";

  /// Updates the application's rendering on the GPU with the newly provided
  /// [Scene]. For optimal performance, this should only be called in response
  /// to the [onBeginFrame] callback being invoked.
  void render(Scene scene) native "Window_render";

  /// Flushes pending real-time events, executing their callbacks.
  void flushRealTimeEvents() native "Scheduler_FlushRealTimeEvents";
}

/// The [Window] singleton. This object exposes the size of the display, the
/// core scheduler API, the input event callback, the graphics drawing API, and
/// other such core services.
final Window window = new Window._();
