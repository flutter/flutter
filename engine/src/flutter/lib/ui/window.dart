// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
part of dart.ui;

/// A view into which a Flutter [Scene] is drawn.
///
/// Each [FlutterView] has its own layer tree that is rendered
/// whenever [render] is called on it with a [Scene].
///
/// ## Insets and Padding
///
/// {@animation 300 300 https://flutter.github.io/assets-for-api-docs/assets/widgets/window_padding.mp4}
///
/// In this illustration, the black areas represent system UI that the app
/// cannot draw over. The red area represents view padding that the view may not
/// be able to detect gestures in and may not want to draw in. The grey area
/// represents the system keyboard, which can cover over the bottom view padding
/// when visible.
///
/// The [viewInsets] are the physical pixels which the operating
/// system reserves for system UI, such as the keyboard, which would fully
/// obscure any content drawn in that area.
///
/// The [viewPadding] are the physical pixels on each side of the
/// display that may be partially obscured by system UI or by physical
/// intrusions into the display, such as an overscan region on a television or a
/// "notch" on a phone. Unlike the insets, these areas may have portions that
/// show the user view-painted pixels without being obscured, such as a
/// notch at the top of a phone that covers only a subset of the area. Insets,
/// on the other hand, either partially or fully obscure the window, such as an
/// opaque keyboard or a partially translucent status bar, which cover an area
/// without gaps.
///
/// The [padding] property is computed from both
/// [viewInsets] and [viewPadding]. It will allow a
/// view inset to consume view padding where appropriate, such as when a phone's
/// keyboard is covering the bottom view padding and so "absorbs" it.
///
/// Clients that want to position elements relative to the view padding
/// regardless of the view insets should use the [viewPadding]
/// property, e.g. if you wish to draw a widget at the center of the screen with
/// respect to the iPhone "safe area" regardless of whether the keyboard is
/// showing.
///
/// [padding] is useful for clients that want to know how much
/// padding should be accounted for without concern for the current inset(s)
/// state, e.g. determining whether a gesture should be considered for scrolling
/// purposes. This value varies based on the current state of the insets. For
/// example, a visible keyboard will consume all gestures in the bottom part of
/// the [viewPadding] anyway, so there is no need to account for
/// that in the [padding], which is always safe to use for such
/// calculations.
class FlutterView {
  FlutterView._(this.viewId, this.platformDispatcher);

  /// The opaque ID for this view.
  final Object viewId;

  /// The platform dispatcher that this view is registered with, and gets its
  /// information from.
  final PlatformDispatcher platformDispatcher;

  /// The configuration of this view.
  ViewConfiguration get viewConfiguration {
    assert(platformDispatcher._viewConfigurations.containsKey(viewId));
    return platformDispatcher._viewConfigurations[viewId]!;
  }

  /// The number of device pixels for each logical pixel for the screen this
  /// view is displayed on.
  ///
  /// This number might not be a power of two. Indeed, it might not even be an
  /// integer. For example, the Nexus 6 has a device pixel ratio of 3.5.
  ///
  /// Device pixels are also referred to as physical pixels. Logical pixels are
  /// also referred to as device-independent or resolution-independent pixels.
  ///
  /// By definition, there are roughly 38 logical pixels per centimeter, or
  /// about 96 logical pixels per inch, of the physical display. The value
  /// returned by [devicePixelRatio] is ultimately obtained either from the
  /// hardware itself, the device drivers, or a hard-coded value stored in the
  /// operating system or firmware, and may be inaccurate, sometimes by a
  /// significant margin.
  ///
  /// The Flutter framework operates in logical pixels, so it is rarely
  /// necessary to directly deal with this property.
  ///
  /// When this changes, [PlatformDispatcher.onMetricsChanged] is called.
  ///
  /// See also:
  ///
  ///  * [WidgetsBindingObserver], for a mechanism at the widgets layer to
  ///    observe when this value changes.
  double get devicePixelRatio => viewConfiguration.devicePixelRatio;

  /// The dimensions and location of the rectangle into which the scene rendered
  /// in this view will be drawn on the screen, in physical pixels.
  ///
  /// When this changes, [PlatformDispatcher.onMetricsChanged] is called.
  ///
  /// At startup, the size and location of the view may not be known before Dart
  /// code runs. If this value is observed early in the application lifecycle,
  /// it may report [Rect.zero].
  ///
  /// This value does not take into account any on-screen keyboards or other
  /// system UI. The [padding] and [viewInsets] properties provide a view into
  /// how much of each side of the view may be obscured by system UI.
  ///
  /// See also:
  ///
  ///  * [WidgetsBindingObserver], for a mechanism at the widgets layer to
  ///    observe when this value changes.
  Rect get physicalGeometry => viewConfiguration.geometry;

  /// The dimensions of the rectangle into which the scene rendered in this view
  /// will be drawn on the screen, in physical pixels.
  ///
  /// When this changes, [PlatformDispatcher.onMetricsChanged] is called.
  ///
  /// At startup, the size of the view may not be known before Dart code runs.
  /// If this value is observed early in the application lifecycle, it may
  /// report [Size.zero].
  ///
  /// This value does not take into account any on-screen keyboards or other
  /// system UI. The [padding] and [viewInsets] properties provide information
  /// about how much of each side of the view may be obscured by system UI.
  ///
  /// This value is the same as the `size` member of [physicalGeometry].
  ///
  /// See also:
  ///
  ///  * [physicalGeometry], which reports the location of the view as well as
  ///    its size.
  ///  * [WidgetsBindingObserver], for a mechanism at the widgets layer to
  ///    observe when this value changes.
  Size get physicalSize => viewConfiguration.geometry.size;

  /// The number of physical pixels on each side of the display rectangle into
  /// which the view can render, but over which the operating system will likely
  /// place system UI, such as the keyboard, that fully obscures any content.
  ///
  /// When this property changes, [PlatformDispatcher.onMetricsChanged] is called.
  ///
  /// The relationship between this [viewInsets],
  /// [viewPadding], and [padding] are described in
  /// more detail in the documentation for [FlutterView].
  ///
  /// See also:
  ///
  ///  * [WidgetsBindingObserver], for a mechanism at the widgets layer to
  ///    observe when this value changes.
  ///  * [MediaQuery.of], a simpler mechanism for the same.
  ///  * [Scaffold], which automatically applies the view insets in material
  ///    design applications.
  ViewPadding get viewInsets => viewConfiguration.viewInsets;

  /// The number of physical pixels on each side of the display rectangle into
  /// which the view can render, but which may be partially obscured by system
  /// UI (such as the system notification area), or physical intrusions in
  /// the display (e.g. overscan regions on television screens or phone sensor
  /// housings).
  ///
  /// Unlike [padding], this value does not change relative to
  /// [viewInsets]. For example, on an iPhone X, it will not
  /// change in response to the soft keyboard being visible or hidden, whereas
  /// [padding] will.
  ///
  /// When this property changes, [PlatformDispatcher.onMetricsChanged] is called.
  ///
  /// The relationship between this [viewInsets],
  /// [viewPadding], and [padding] are described in
  /// more detail in the documentation for [FlutterView].
  ///
  /// See also:
  ///
  ///  * [WidgetsBindingObserver], for a mechanism at the widgets layer to
  ///    observe when this value changes.
  ///  * [MediaQuery.of], a simpler mechanism for the same.
  ///  * [Scaffold], which automatically applies the padding in material design
  ///    applications.
  ViewPadding get viewPadding => viewConfiguration.viewPadding;

  /// The number of physical pixels on each side of the display rectangle into
  /// which the view can render, but where the operating system will consume
  /// input gestures for the sake of system navigation.
  ///
  /// For example, an operating system might use the vertical edges of the
  /// screen, where swiping inwards from the edges takes users backward
  /// through the history of screens they previously visited.
  ///
  /// When this property changes, [PlatformDispatcher.onMetricsChanged] is called.
  ///
  /// See also:
  ///
  ///  * [WidgetsBindingObserver], for a mechanism at the widgets layer to
  ///    observe when this value changes.
  ///  * [MediaQuery.of], a simpler mechanism for the same.
  ViewPadding get systemGestureInsets => viewConfiguration.systemGestureInsets;

  /// The number of physical pixels on each side of the display rectangle into
  /// which the view can render, but which may be partially obscured by system
  /// UI (such as the system notification area), or physical intrusions in
  /// the display (e.g. overscan regions on television screens or phone sensor
  /// housings).
  ///
  /// This value is calculated by taking `max(0.0, FlutterView.viewPadding -
  /// FlutterView.viewInsets)`. This will treat a system IME that increases the
  /// bottom inset as consuming that much of the bottom padding. For example, on
  /// an iPhone X, [EdgeInsets.bottom] of [FlutterView.padding] is the same as
  /// [EdgeInsets.bottom] of [FlutterView.viewPadding] when the soft keyboard is
  /// not drawn (to account for the bottom soft button area), but will be `0.0`
  /// when the soft keyboard is visible.
  ///
  /// When this changes, [PlatformDispatcher.onMetricsChanged] is called.
  ///
  /// The relationship between this [viewInsets], [viewPadding], and [padding]
  /// are described in more detail in the documentation for [FlutterView].
  ///
  /// See also:
  ///
  /// * [WidgetsBindingObserver], for a mechanism at the widgets layer to
  ///   observe when this value changes.
  /// * [MediaQuery.of], a simpler mechanism for the same.
  /// * [Scaffold], which automatically applies the padding in material design
  ///   applications.
  ViewPadding get padding => viewConfiguration.padding;

  /// {@macro dart.ui.ViewConfiguration.displayFeatures}
  ///
  /// When this changes, [PlatformDispatcher.onMetricsChanged] is called.
  ///
  /// See also:
  ///
  ///  * [WidgetsBindingObserver], for a mechanism at the widgets layer to
  ///    observe when this value changes.
  ///  * [MediaQuery.of], a simpler mechanism to access this data.
  List<DisplayFeature> get displayFeatures => viewConfiguration.displayFeatures;

  /// Updates the view's rendering on the GPU with the newly provided [Scene].
  ///
  /// This function must be called within the scope of the
  /// [PlatformDispatcher.onBeginFrame] or [PlatformDispatcher.onDrawFrame]
  /// callbacks being invoked.
  ///
  /// If this function is called a second time during a single
  /// [PlatformDispatcher.onBeginFrame]/[PlatformDispatcher.onDrawFrame]
  /// callback sequence or called outside the scope of those callbacks, the call
  /// will be ignored.
  ///
  /// To record graphical operations, first create a [PictureRecorder], then
  /// construct a [Canvas], passing that [PictureRecorder] to its constructor.
  /// After issuing all the graphical operations, call the
  /// [PictureRecorder.endRecording] function on the [PictureRecorder] to obtain
  /// the final [Picture] that represents the issued graphical operations.
  ///
  /// Next, create a [SceneBuilder], and add the [Picture] to it using
  /// [SceneBuilder.addPicture]. With the [SceneBuilder.build] method you can
  /// then obtain a [Scene] object, which you can display to the user via this
  /// [render] function.
  ///
  /// See also:
  ///
  /// * [SchedulerBinding], the Flutter framework class which manages the
  ///   scheduling of frames.
  /// * [RendererBinding], the Flutter framework class which manages layout and
  ///   painting.
  void render(Scene scene) => _render(scene);

  @Native<Void Function(Pointer<Void>)>(symbol: 'PlatformConfigurationNativeApi::Render')
  external static void _render(Scene scene);

  /// Change the retained semantics data about this [FlutterView].
  ///
  /// If [PlatformDispatcher.semanticsEnabled] is true, the user has requested that this function
  /// be called whenever the semantic content of this [FlutterView]
  /// changes.
  ///
  /// This function disposes the given update, which means the semantics update
  /// cannot be used further.
  void updateSemantics(SemanticsUpdate update) => _updateSemantics(update);

  @Native<Void Function(Pointer<Void>)>(symbol: 'PlatformConfigurationNativeApi::UpdateSemantics')
  external static void _updateSemantics(SemanticsUpdate update);
}

/// A [FlutterView] that includes access to setting callbacks and retrieving
/// properties that reside on the [PlatformDispatcher].
///
/// It is the type of the global [window] singleton used by applications that
/// only have a single main window.
///
/// In addition to the properties of [FlutterView], this class provides access
/// to platform-specific properties. To modify or retrieve these properties,
/// applications designed for more than one main window should prefer using
/// `WidgetsBinding.instance.platformDispatcher` instead.
///
/// Prefer access through `WidgetsBinding.instance.window` or
/// `WidgetsBinding.instance.platformDispatcher` over a static reference to
/// [window], or [PlatformDispatcher.instance]. See the documentation for
/// [PlatformDispatcher.instance] for more details about this recommendation.
class SingletonFlutterWindow extends FlutterView {
  SingletonFlutterWindow._(super.windowId, super.platformDispatcher)
      : super._();

  /// A callback that is invoked whenever the [devicePixelRatio],
  /// [physicalSize], [padding], [viewInsets], [PlatformDispatcher.views], or
  /// [systemGestureInsets] values change.
  ///
  /// {@macro dart.ui.window.accessorForwardWarning}
  ///
  /// See [PlatformDispatcher.onMetricsChanged] for more information.
  VoidCallback? get onMetricsChanged => platformDispatcher.onMetricsChanged;
  set onMetricsChanged(VoidCallback? callback) {
    platformDispatcher.onMetricsChanged = callback;
  }

  /// The system-reported default locale of the device.
  ///
  /// {@template dart.ui.window.accessorForwardWarning}
  /// Accessing this value returns the value contained in the
  /// [PlatformDispatcher] singleton, so instead of getting it from here, you
  /// should consider getting it from `WidgetsBinding.instance.platformDispatcher` instead
  /// (or, when `WidgetsBinding` isn't available, from
  /// [PlatformDispatcher.instance]). The reason this value forwards to the
  /// [PlatformDispatcher] is to provide convenience for applications that only
  /// use a single main window.
  /// {@endtemplate}
  ///
  /// This establishes the language and formatting conventions that window
  /// should, if possible, use to render their user interface.
  ///
  /// This is the first locale selected by the user and is the user's primary
  /// locale (the locale the device UI is displayed in)
  ///
  /// This is equivalent to `locales.first` and will provide an empty non-null
  /// locale if the [locales] list has not been set or is empty.
  Locale get locale => platformDispatcher.locale;

  /// The full system-reported supported locales of the device.
  ///
  /// {@macro dart.ui.window.accessorForwardWarning}
  ///
  /// This establishes the language and formatting conventions that window
  /// should, if possible, use to render their user interface.
  ///
  /// The list is ordered in order of priority, with lower-indexed locales being
  /// preferred over higher-indexed ones. The first element is the primary [locale].
  ///
  /// The [onLocaleChanged] callback is called whenever this value changes.
  ///
  /// See also:
  ///
  ///  * [WidgetsBindingObserver], for a mechanism at the widgets layer to
  ///    observe when this value changes.
  List<Locale> get locales => platformDispatcher.locales;

  /// Performs the platform-native locale resolution.
  ///
  /// Each platform may return different results.
  ///
  /// If the platform fails to resolve a locale, then this will return null.
  ///
  /// This method returns synchronously and is a direct call to
  /// platform specific APIs without invoking method channels.
  Locale? computePlatformResolvedLocale(List<Locale> supportedLocales) {
    return platformDispatcher.computePlatformResolvedLocale(supportedLocales);
  }

  /// A callback that is invoked whenever [locale] changes value.
  ///
  /// {@macro dart.ui.window.accessorForwardWarning}
  ///
  /// The framework invokes this callback in the same zone in which the
  /// callback was set.
  ///
  /// See also:
  ///
  ///  * [WidgetsBindingObserver], for a mechanism at the widgets layer to
  ///    observe when this callback is invoked.
  VoidCallback? get onLocaleChanged => platformDispatcher.onLocaleChanged;
  set onLocaleChanged(VoidCallback? callback) {
    platformDispatcher.onLocaleChanged = callback;
  }

  /// The lifecycle state immediately after dart isolate initialization.
  ///
  /// {@macro dart.ui.window.accessorForwardWarning}
  ///
  /// This property will not be updated as the lifecycle changes.
  ///
  /// It is used to initialize [SchedulerBinding.lifecycleState] at startup
  /// with any buffered lifecycle state events.
  String get initialLifecycleState => platformDispatcher.initialLifecycleState;

  /// The system-reported text scale.
  ///
  /// {@macro dart.ui.window.accessorForwardWarning}
  ///
  /// This establishes the text scaling factor to use when rendering text,
  /// according to the user's platform preferences.
  ///
  /// The [onTextScaleFactorChanged] callback is called whenever this value
  /// changes.
  ///
  /// See also:
  ///
  ///  * [WidgetsBindingObserver], for a mechanism at the widgets layer to
  ///    observe when this value changes.
  double get textScaleFactor => platformDispatcher.textScaleFactor;

  /// Whether the spell check service is supported on the current platform.
  ///
  /// {@macro dart.ui.window.accessorForwardWarning}
  ///
  /// This option is used by [EditableTextState] to define its
  /// [SpellCheckConfiguration] when spell check is enabled, but no spell check
  /// service is specified.
  bool get nativeSpellCheckServiceDefined => platformDispatcher.nativeSpellCheckServiceDefined;

  /// Whether briefly displaying the characters as you type in obscured text
  /// fields is enabled in system settings.
  ///
  /// See also:
  ///
  ///  * [EditableText.obscureText], which when set to true hides the text in
  ///    the text field.
  bool get brieflyShowPassword => platformDispatcher.brieflyShowPassword;

  /// The setting indicating whether time should always be shown in the 24-hour
  /// format.
  ///
  /// {@macro dart.ui.window.accessorForwardWarning}
  ///
  /// This option is used by [showTimePicker].
  bool get alwaysUse24HourFormat => platformDispatcher.alwaysUse24HourFormat;

  /// A callback that is invoked whenever [textScaleFactor] changes value.
  ///
  /// {@macro dart.ui.window.accessorForwardWarning}
  ///
  /// The framework invokes this callback in the same zone in which the
  /// callback was set.
  ///
  /// See also:
  ///
  ///  * [WidgetsBindingObserver], for a mechanism at the widgets layer to
  ///    observe when this callback is invoked.
  VoidCallback? get onTextScaleFactorChanged => platformDispatcher.onTextScaleFactorChanged;
  set onTextScaleFactorChanged(VoidCallback? callback) {
    platformDispatcher.onTextScaleFactorChanged = callback;
  }

  /// The setting indicating the current brightness mode of the host platform.
  ///
  /// {@macro dart.ui.window.accessorForwardWarning}
  ///
  /// If the platform has no preference, [platformBrightness] defaults to
  /// [Brightness.light].
  Brightness get platformBrightness => platformDispatcher.platformBrightness;

  /// A callback that is invoked whenever [platformBrightness] changes value.
  ///
  /// {@macro dart.ui.window.accessorForwardWarning}
  ///
  /// The framework invokes this callback in the same zone in which the
  /// callback was set.
  ///
  /// See also:
  ///
  ///  * [WidgetsBindingObserver], for a mechanism at the widgets layer to
  ///    observe when this callback is invoked.
  VoidCallback? get onPlatformBrightnessChanged => platformDispatcher.onPlatformBrightnessChanged;
  set onPlatformBrightnessChanged(VoidCallback? callback) {
    platformDispatcher.onPlatformBrightnessChanged = callback;
  }

  /// The setting indicating the system font of the host platform.
  ///
  /// {@macro dart.ui.window.accessorForwardWarning}
  String? get systemFontFamily => platformDispatcher.systemFontFamily;

  /// A callback that is invoked whenever [systemFontFamily] changes value.
  ///
  /// {@macro dart.ui.window.accessorForwardWarning}
  ///
  /// The framework invokes this callback in the same zone in which the
  /// callback was set.
  ///
  /// See also:
  ///
  ///  * [WidgetsBindingObserver], for a mechanism at the widgets layer to
  ///    observe when this callback is invoked.
  VoidCallback? get onSystemFontFamilyChanged => platformDispatcher.onSystemFontFamilyChanged;
  set onSystemFontFamilyChanged(VoidCallback? callback) {
    platformDispatcher.onSystemFontFamilyChanged = callback;
  }

  /// A callback that is invoked to notify the window that it is an appropriate
  /// time to provide a scene using the [SceneBuilder] API and the [render]
  /// method.
  ///
  /// {@macro dart.ui.window.accessorForwardWarning}
  ///
  /// When possible, this is driven by the hardware VSync signal. This is only
  /// called if [scheduleFrame] has been called since the last time this
  /// callback was invoked.
  ///
  /// The [onDrawFrame] callback is invoked immediately after [onBeginFrame],
  /// after draining any microtasks (e.g. completions of any [Future]s) queued
  /// by the [onBeginFrame] handler.
  ///
  /// The framework invokes this callback in the same zone in which the
  /// callback was set.
  ///
  /// See also:
  ///
  ///  * [SchedulerBinding], the Flutter framework class which manages the
  ///    scheduling of frames.
  ///  * [RendererBinding], the Flutter framework class which manages layout and
  ///    painting.
  FrameCallback? get onBeginFrame => platformDispatcher.onBeginFrame;
  set onBeginFrame(FrameCallback? callback) {
    platformDispatcher.onBeginFrame = callback;
  }

  /// A callback that is invoked for each frame after [onBeginFrame] has
  /// completed and after the microtask queue has been drained.
  ///
  /// {@macro dart.ui.window.accessorForwardWarning}
  ///
  /// This can be used to implement a second phase of frame rendering that
  /// happens after any deferred work queued by the [onBeginFrame] phase.
  ///
  /// The framework invokes this callback in the same zone in which the
  /// callback was set.
  ///
  /// See also:
  ///
  ///  * [SchedulerBinding], the Flutter framework class which manages the
  ///    scheduling of frames.
  ///  * [RendererBinding], the Flutter framework class which manages layout and
  ///    painting.
  VoidCallback? get onDrawFrame => platformDispatcher.onDrawFrame;
  set onDrawFrame(VoidCallback? callback) {
    platformDispatcher.onDrawFrame = callback;
  }

  /// A callback that is invoked to report the [FrameTiming] of recently
  /// rasterized frames.
  ///
  /// {@macro dart.ui.window.accessorForwardWarning}
  ///
  /// It's preferred to use [SchedulerBinding.addTimingsCallback] than to use
  /// [SingletonFlutterWindow.onReportTimings] directly because
  /// [SchedulerBinding.addTimingsCallback] allows multiple callbacks.
  ///
  /// This can be used to see if the window has missed frames (through
  /// [FrameTiming.buildDuration] and [FrameTiming.rasterDuration]), or high
  /// latencies (through [FrameTiming.totalSpan]).
  ///
  /// Unlike [Timeline], the timing information here is available in the release
  /// mode (additional to the profile and the debug mode). Hence this can be
  /// used to monitor the application's performance in the wild.
  ///
  /// {@macro dart.ui.TimingsCallback.list}
  ///
  /// If this is null, no additional work will be done. If this is not null,
  /// Flutter spends less than 0.1ms every 1 second to report the timings
  /// (measured on iPhone6S). The 0.1ms is about 0.6% of 16ms (frame budget for
  /// 60fps), or 0.01% CPU usage per second.
  TimingsCallback? get onReportTimings => platformDispatcher.onReportTimings;
  set onReportTimings(TimingsCallback? callback) {
    platformDispatcher.onReportTimings = callback;
  }

  /// A callback that is invoked when pointer data is available.
  ///
  /// {@macro dart.ui.window.accessorForwardWarning}
  ///
  /// The framework invokes this callback in the same zone in which the
  /// callback was set.
  ///
  /// See also:
  ///
  ///  * [GestureBinding], the Flutter framework class which manages pointer
  ///    events.
  PointerDataPacketCallback? get onPointerDataPacket => platformDispatcher.onPointerDataPacket;
  set onPointerDataPacket(PointerDataPacketCallback? callback) {
    platformDispatcher.onPointerDataPacket = callback;
  }

  /// A callback that is invoked when key data is available.
  ///
  /// The framework invokes this callback in the same zone in which the
  /// callback was set.
  KeyDataCallback? get onKeyData => platformDispatcher.onKeyData;
  set onKeyData(KeyDataCallback? callback) {
    platformDispatcher.onKeyData = callback;
  }

  /// The route or path that the embedder requested when the application was
  /// launched.
  ///
  /// {@macro dart.ui.window.accessorForwardWarning}
  ///
  /// This will be the string "`/`" if no particular route was requested.
  ///
  /// ## Android
  ///
  /// On Android, the initial route can be set on the [initialRoute](/javadoc/io/flutter/embedding/android/FlutterActivity.NewEngineIntentBuilder.html#initialRoute-java.lang.String-)
  /// method of the [FlutterActivity](/javadoc/io/flutter/embedding/android/FlutterActivity.html)'s
  /// intent builder.
  ///
  /// On a standalone engine, see https://flutter.dev/docs/development/add-to-app/android/add-flutter-screen#initial-route-with-a-cached-engine.
  ///
  /// ## iOS
  ///
  /// On iOS, the initial route can be set on the `initialRoute`
  /// parameter of the [FlutterViewController](/objcdoc/Classes/FlutterViewController.html)'s
  /// initializer.
  ///
  /// On a standalone engine, see https://flutter.dev/docs/development/add-to-app/ios/add-flutter-screen#route.
  ///
  /// See also:
  ///
  ///  * [Navigator], a widget that handles routing.
  ///  * [SystemChannels.navigation], which handles subsequent navigation
  ///    requests from the embedder.
  String get defaultRouteName => platformDispatcher.defaultRouteName;

  /// Requests that, at the next appropriate opportunity, the [onBeginFrame] and
  /// [onDrawFrame] callbacks be invoked.
  ///
  /// {@template dart.ui.window.functionForwardWarning}
  /// Calling this function forwards the call to the same function on the
  /// [PlatformDispatcher] singleton, so instead of calling it here, you should
  /// consider calling it on `WidgetsBinding.instance.platformDispatcher` instead (or, when
  /// `WidgetsBinding` isn't available, on [PlatformDispatcher.instance]). The
  /// reason this function forwards to the [PlatformDispatcher] is to provide
  /// convenience for applications that only use a single main window.
  /// {@endtemplate}
  ///
  /// See also:
  ///
  /// * [SchedulerBinding], the Flutter framework class which manages the
  ///   scheduling of frames.
  void scheduleFrame() => platformDispatcher.scheduleFrame();

  /// Whether the user has requested that [updateSemantics] be called when
  /// the semantic contents of window changes.
  ///
  /// {@macro dart.ui.window.accessorForwardWarning}
  ///
  /// The [onSemanticsEnabledChanged] callback is called whenever this value
  /// changes.
  bool get semanticsEnabled => platformDispatcher.semanticsEnabled;

  /// A callback that is invoked when the value of [semanticsEnabled] changes.
  ///
  /// {@macro dart.ui.window.accessorForwardWarning}
  ///
  /// The framework invokes this callback in the same zone in which the
  /// callback was set.
  VoidCallback? get onSemanticsEnabledChanged => platformDispatcher.onSemanticsEnabledChanged;
  set onSemanticsEnabledChanged(VoidCallback? callback) {
    platformDispatcher.onSemanticsEnabledChanged = callback;
  }

  /// The [FrameData] object for the current frame.
  FrameData get frameData => platformDispatcher.frameData;

  /// A callback that is invoked when the window updates the [FrameData].
  VoidCallback? get onFrameDataChanged => platformDispatcher.onFrameDataChanged;
  set onFrameDataChanged(VoidCallback? callback) {
    platformDispatcher.onFrameDataChanged = callback;
  }

  /// A callback that is invoked whenever the user requests an action to be
  /// performed.
  ///
  /// {@macro dart.ui.window.accessorForwardWarning}
  ///
  /// This callback is used when the user expresses the action they wish to
  /// perform based on the semantics supplied by [updateSemantics].
  ///
  /// The framework invokes this callback in the same zone in which the
  /// callback was set.
  SemanticsActionCallback? get onSemanticsAction => platformDispatcher.onSemanticsAction;
  set onSemanticsAction(SemanticsActionCallback? callback) {
    platformDispatcher.onSemanticsAction = callback;
  }

  /// Additional accessibility features that may be enabled by the platform.
  AccessibilityFeatures get accessibilityFeatures => platformDispatcher.accessibilityFeatures;

  /// A callback that is invoked when the value of [accessibilityFeatures] changes.
  ///
  /// {@macro dart.ui.window.accessorForwardWarning}
  ///
  /// The framework invokes this callback in the same zone in which the
  /// callback was set.
  VoidCallback? get onAccessibilityFeaturesChanged => platformDispatcher.onAccessibilityFeaturesChanged;
  set onAccessibilityFeaturesChanged(VoidCallback? callback) {
    platformDispatcher.onAccessibilityFeaturesChanged = callback;
  }

  /// Sends a message to a platform-specific plugin.
  ///
  /// {@macro dart.ui.window.functionForwardWarning}
  ///
  /// The `name` parameter determines which plugin receives the message. The
  /// `data` parameter contains the message payload and is typically UTF-8
  /// encoded JSON but can be arbitrary data. If the plugin replies to the
  /// message, `callback` will be called with the response.
  ///
  /// The framework invokes [callback] in the same zone in which this method
  /// was called.
  void sendPlatformMessage(String name,
      ByteData? data,
      PlatformMessageResponseCallback? callback) {
    platformDispatcher.sendPlatformMessage(name, data, callback);
  }

  /// Called whenever this window receives a message from a platform-specific
  /// plugin.
  ///
  /// {@macro dart.ui.window.accessorForwardWarning}
  ///
  /// The `name` parameter determines which plugin sent the message. The `data`
  /// parameter is the payload and is typically UTF-8 encoded JSON but can be
  /// arbitrary data.
  ///
  /// Message handlers must call the function given in the `callback` parameter.
  /// If the handler does not need to respond, the handler should pass null to
  /// the callback.
  ///
  /// The framework invokes this callback in the same zone in which the
  /// callback was set.
  // TODO(ianh): deprecate once framework uses [ChannelBuffers.setListener].
  PlatformMessageCallback? get onPlatformMessage => platformDispatcher.onPlatformMessage;
  set onPlatformMessage(PlatformMessageCallback? callback) {
    platformDispatcher.onPlatformMessage = callback;
  }

  /// Set the debug name associated with this platform dispatcher's root
  /// isolate.
  ///
  /// {@macro dart.ui.window.accessorForwardWarning}
  ///
  /// Normally debug names are automatically generated from the Dart port, entry
  /// point, and source file. For example: `main.dart$main-1234`.
  ///
  /// This can be combined with flutter tools `--isolate-filter` flag to debug
  /// specific root isolates. For example: `flutter attach --isolate-filter=[name]`.
  /// Note that this does not rename any child isolates of the root.
  void setIsolateDebugName(String name) => PlatformDispatcher.instance.setIsolateDebugName(name);
}

/// Additional accessibility features that may be enabled by the platform.
///
/// It is not possible to enable these settings from Flutter, instead they are
/// used by the platform to indicate that additional accessibility features are
/// enabled.
//
// When changes are made to this class, the equivalent APIs in each of the
// embedders *must* be updated.
class AccessibilityFeatures {
  const AccessibilityFeatures._(this._index);

  static const int _kAccessibleNavigationIndex = 1 << 0;
  static const int _kInvertColorsIndex = 1 << 1;
  static const int _kDisableAnimationsIndex = 1 << 2;
  static const int _kBoldTextIndex = 1 << 3;
  static const int _kReduceMotionIndex = 1 << 4;
  static const int _kHighContrastIndex = 1 << 5;
  static const int _kOnOffSwitchLabelsIndex = 1 << 6;

  // A bitfield which represents each enabled feature.
  final int _index;

  /// Whether there is a running accessibility service which is changing the
  /// interaction model of the device.
  ///
  /// For example, TalkBack on Android and VoiceOver on iOS enable this flag.
  bool get accessibleNavigation => _kAccessibleNavigationIndex & _index != 0;

  /// The platform is inverting the colors of the application.
  bool get invertColors => _kInvertColorsIndex & _index != 0;

  /// The platform is requesting that animations be disabled or simplified.
  bool get disableAnimations => _kDisableAnimationsIndex & _index != 0;

  /// The platform is requesting that text be rendered at a bold font weight.
  ///
  /// Only supported on iOS.
  bool get boldText => _kBoldTextIndex & _index != 0;

  /// The platform is requesting that certain animations be simplified and
  /// parallax effects removed.
  ///
  /// Only supported on iOS.
  bool get reduceMotion => _kReduceMotionIndex & _index != 0;

  /// The platform is requesting that UI be rendered with darker colors.
  ///
  /// Only supported on iOS.
  bool get highContrast => _kHighContrastIndex & _index != 0;

  /// The platform is requesting to show on/off labels inside switches.
  ///
  /// Only supported on iOS.
  bool get onOffSwitchLabels => _kOnOffSwitchLabelsIndex & _index != 0;

  @override
  String toString() {
    final List<String> features = <String>[];
    if (accessibleNavigation) {
      features.add('accessibleNavigation');
    }
    if (invertColors) {
      features.add('invertColors');
    }
    if (disableAnimations) {
      features.add('disableAnimations');
    }
    if (boldText) {
      features.add('boldText');
    }
    if (reduceMotion) {
      features.add('reduceMotion');
    }
    if (highContrast) {
      features.add('highContrast');
    }
    if (onOffSwitchLabels) {
      features.add('onOffSwitchLabels');
    }
    return 'AccessibilityFeatures$features';
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is AccessibilityFeatures
        && other._index == _index;
  }

  @override
  int get hashCode => _index.hashCode;
}

/// Describes the contrast of a theme or color palette.
enum Brightness {
  /// The color is dark and will require a light text color to achieve readable
  /// contrast.
  ///
  /// For example, the color might be dark grey, requiring white text.
  dark,

  /// The color is light and will require a dark text color to achieve readable
  /// contrast.
  ///
  /// For example, the color might be bright white, requiring black text.
  light,
}

/// The [SingletonFlutterWindow] representing the main window for applications
/// where there is only one window, such as applications designed for
/// single-display mobile devices.
///
/// Applications that are designed to use more than one window should interact
/// with the `WidgetsBinding.instance.platformDispatcher` instead.
///
/// Consider avoiding static references to this singleton through
/// [PlatformDispatcher.instance] and instead prefer using a binding for
/// dependency resolution such as `WidgetsBinding.instance.window`.
///
/// Static access of this `window` object means that Flutter has few, if any
/// options to fake or mock the given object in tests. Even in cases where Dart
/// offers special language constructs to forcefully shadow such properties,
/// those mechanisms would only be reasonable for tests and they would not be
/// reasonable for a future of Flutter where we legitimately want to select an
/// appropriate implementation at runtime.
///
/// The only place that `WidgetsBinding.instance.window` is inappropriate is if
/// access to these APIs is required before the binding is initialized by
/// invoking `runApp()` or `WidgetsFlutterBinding.instance.ensureInitialized()`.
/// In that case, it is necessary (though unfortunate) to use the
/// [PlatformDispatcher.instance] object statically.
///
/// See also:
///
/// * [PlatformDispatcher.views], contains the current list of Flutter windows
///   belonging to the application, including top level application windows like
///   this one.
/// * [PlatformDispatcher.implicitView], this window's view.
final SingletonFlutterWindow window = SingletonFlutterWindow._(0, PlatformDispatcher.instance);

/// Additional data available on each flutter frame.
class FrameData {
  const FrameData._({this.frameNumber = -1});

  /// The number of the current frame.
  ///
  /// This number monotonically increases, but doesn't necessarily
  /// start at a particular value.
  ///
  /// If not provided, defaults to -1.
  final int frameNumber;
}

/// Platform specific configuration for gesture behavior, such as touch slop.
///
/// These settings are provided via [ViewConfiguration] to each window, and should
/// be favored for configuring gesture behavior over the framework constants.
///
/// A `null` field indicates that the platform or view does not have a preference
/// and the fallback constants should be used instead.
class GestureSettings {
  /// Create a new [GestureSettings] value.
  ///
  /// Consider using [GestureSettings.copyWith] on an existing settings object
  /// to ensure that newly added fields are correctly set.
  const GestureSettings({
    this.physicalTouchSlop,
    this.physicalDoubleTapSlop,
  });

  /// The number of physical pixels a pointer is allowed to drift before it is
  /// considered an intentional movement.
  ///
  /// If `null`, the framework's default touch slop configuration should be used
  /// instead.
  final double? physicalTouchSlop;

  /// The number of physical pixels that the first and second tap of a double tap
  /// can drift apart to still be recognized as a double tap.
  ///
  /// If `null`, the framework's default double tap slop configuration should be used
  /// instead.
  final double? physicalDoubleTapSlop;

  /// Create a new [GestureSettings] object from an existing value, overwriting
  /// all of the provided fields.
  GestureSettings copyWith({
    double? physicalTouchSlop,
    double? physicalDoubleTapSlop,
  }) {
    return GestureSettings(
      physicalTouchSlop: physicalTouchSlop ?? this.physicalTouchSlop,
      physicalDoubleTapSlop: physicalDoubleTapSlop ?? this.physicalDoubleTapSlop,
    );
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is GestureSettings &&
      other.physicalTouchSlop == physicalTouchSlop &&
      other.physicalDoubleTapSlop == physicalDoubleTapSlop;
  }

  @override
  int get hashCode => Object.hash(physicalTouchSlop, physicalDoubleTapSlop);

  @override
  String toString() => 'GestureSettings(physicalTouchSlop: $physicalTouchSlop, physicalDoubleTapSlop: $physicalDoubleTapSlop)';
}
