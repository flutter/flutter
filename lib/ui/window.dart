// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of dart_ui;

/// Signature of callbacks that have no arguments and return no data.
typedef void VoidCallback();

/// Signature for [Window.onBeginFrame].
typedef void FrameCallback(Duration duration);

/// Signature for [Window.onPointerDataPacket].
typedef void PointerDataPacketCallback(PointerDataPacket packet);

/// Signature for [Window.onSemanticsAction].
typedef void SemanticsActionCallback(int id, SemanticsAction action);

/// Signature for [Window.onAppLifecycleStateChanged].
typedef void AppLifecycleStateCallback(AppLifecycleState state);

typedef void PlatformMessageResponseCallback(ByteData data);

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
  const WindowPadding._({ this.left, this.top, this.right, this.bottom });

  /// The distance from the left edge to the first unobscured pixel, in physical pixels.
  final double left;

  /// The distance from the top edge to the first unobscured pixel, in physical pixels.
  final double top;

  /// The distance from the right edge to the first unobscured pixel, in physical pixels.
  final double right;

  /// The distance from the bottom edge to the first unobscured pixel, in physical pixels.
  final double bottom;

  /// A window padding that has zeros for each edge.
  static const WindowPadding zero = const WindowPadding._(left: 0.0, top: 0.0, right: 0.0, bottom: 0.0);
}

/// An identifier used to select a user's language and formatting preferences,
/// consisting of a language and a country. This is a subset of locale
/// identifiers as defined by BCP 47.
class Locale {
  /// Creates a new Locale object. The first argument is the
  /// primary language subtag, the second is the region subtag.
  ///
  /// For example:
  ///
  ///     const Locale swissFrench = const Locale('fr', 'CH');
  ///     const Locale canadianFrench = const Locale('fr', 'CA');
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
///
/// There is a single Window instance in the system, which you can
/// obtain from the [window] property.
class Window {
  Window._();

  /// The number of device pixels for each logical pixel. This number might not
  /// be a power of two. Indeed, it might not even be an integer. For example,
  /// the Nexus 6 has a device pixel ratio of 3.5.
  double get devicePixelRatio => _devicePixelRatio;
  double _devicePixelRatio = 1.0;

  /// The dimensions of the rectangle into which the application will be drawn,
  /// in physical pixels.
  Size get physicalSize => _physicalSize;
  Size _physicalSize = Size.zero;

  /// The number of physical pixels on each side of the display rectangle into
  /// which the application can render, but over which the operating system will
  /// likely place system UI (such as the Android system notification area), or
  /// which might be rendered outside of the physical display (e.g. overscan
  /// regions on television screens).
  WindowPadding get padding => _padding;
  WindowPadding _padding = WindowPadding.zero;

  /// A callback that is invoked whenever the [devicePixelRatio],
  /// [physicalSize], or [padding] values change.
  VoidCallback onMetricsChanged;

  /// The system-reported locale.
  ///
  /// This establishes the language and formatting conventions that application
  /// should, if possible, use to render their user interface.
  ///
  /// The [onLocaleChanged] callback is called whenever this value changes.
  Locale get locale => _locale;
  Locale _locale;

  /// A callback that is invoked whenever [locale] changes value.
  VoidCallback onLocaleChanged;

  /// A callback that is invoked when there is a transition in the application's
  /// lifecycle (such as pausing or resuming).
  AppLifecycleStateCallback onAppLifecycleStateChanged;

  /// A callback that is invoked to notify the application that it is an
  /// appropriate time to provide a scene using the [SceneBuilder] API and the
  /// [render] method. When possible, this is driven by the hardware VSync
  /// signal. This is only called if [scheduleFrame] has been called since the
  /// last time this callback was invoked.
  FrameCallback onBeginFrame;

  /// A callback that is invoked when pointer data is available.
  PointerDataPacketCallback onPointerDataPacket;

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
  /// [Scene]. This function must be called within the scope of the
  /// [onBeginFrame] callback being invoked. If this function is called multiple
  /// times during a single [onBeginFrame] callback or called outside the scope
  /// of an [onBeginFrame], the call will be ignored.
  ///
  /// To record graphical operations, first create a
  /// [PictureRecorder], then construct a [Canvas], passing that
  /// [PictureRecorder] to its constructor. After issuing all the
  /// graphical operations, call the [endRecording] function on the
  /// [PictureRecorder] to obtain the final [Picture] that represents
  /// the issued graphical operations.
  ///
  /// Next, create a [SceneBuilder], and add the [Picture] to it using
  /// [SceneBuilder.addPicture]. With the [SceneBuilder.build] method
  /// you can then obtain a [Scene] object, which you can display to
  /// the user via this [render] function.
  void render(Scene scene) native "Window_render";

  /// Whether the user has requested that [updateSemantics] be called when
  /// the semantic contents of window changes.
  ///
  /// The [onSemanticsEnabledChanged] callback is called whenever this value
  /// changes.
  bool get semanticsEnabled => _semanticsEnabled;
  bool _semanticsEnabled = false;

  /// A callback that is invoked when the value of [semanticsEnabled] changes.
  VoidCallback onSemanticsEnabledChanged;

  /// A callback that is invoked whenever the user requests an action to be
  /// performed.
  ///
  /// This callback is used when the user expresses the action they wish to
  /// perform based on the semantics supplied by [updateSemantics].
  SemanticsActionCallback onSemanticsAction;

  /// Change the retained semantics data about this window.
  ///
  /// If [semanticsEnabled] is true, the user has requested that this funciton
  /// be called whenever the semantic content of this window changes.
  ///
  /// In either case, this function disposes the given update, which means the
  /// semantics update cannot be used further.
  void updateSemantics(SemanticsUpdate update) native "Window_updateSemantics";

  void sendPlatformMessage(String name,
                           ByteData data,
                           PlatformMessageResponseCallback callback) {
    _sendPlatformMessage(name, callback, data);
  }
  void _sendPlatformMessage(String name,
                            PlatformMessageResponseCallback callback,
                            ByteData data) native "Window_sendPlatformMessage";

}

/// The [Window] singleton. This object exposes the size of the display, the
/// core scheduler API, the input event callback, the graphics drawing API, and
/// other such core services.
final Window window = new Window._();
