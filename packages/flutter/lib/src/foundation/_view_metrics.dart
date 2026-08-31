// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/rendering.dart';
/// @docImport 'package:flutter/widgets.dart';
/// @docImport 'package:flutter_test/flutter_test.dart';
///
/// @docImport 'binding.dart';
library;

// Unlike the rest of the foundation library (see README.md), this library
// imports all of `dart:ui`. It implements the complete [ui.PlatformDispatcher]
// and [ui.FlutterView] interfaces, so it needs every type that appears in their
// signatures; an explicit `show` list would name most of `dart:ui` and would
// have to be updated on every engine roll for members this library only
// forwards. The dependency is debug-only: everything below is unreachable in
// release builds, because the only thing that constructs it,
// [debugApplyViewMetricsOverrides], does so inside an `assert`.
import 'dart:typed_data' show ByteData;
import 'dart:ui' as ui;

import 'package:meta/meta.dart';

import 'debug.dart';

/// Wraps `dispatcher` so that the entries of [debugViewMetricsOverrides] are
/// applied to the view metrics it and its [ui.FlutterView]s report.
///
/// Returns `dispatcher` itself in release mode, and returns the same wrapper
/// every time it is called with the same `dispatcher`, so that the views it
/// vends keep a stable identity. Wrapping an already-wrapped dispatcher returns
/// it unchanged.
///
/// [BindingBase.platformDispatcher] applies this to
/// [ui.PlatformDispatcher.instance], which is what makes overrides visible to
/// the whole framework. [TestWidgetsFlutterBinding] applies it to the
/// dispatcher its [TestPlatformDispatcher] wraps, so that overrides also apply
/// in widget tests.
///
/// Installing the wrapper is behavior neutral while
/// [debugViewMetricsOverrides] is empty: every member forwards to the wrapped
/// object. It is therefore installed unconditionally rather than only while an
/// override exists, so that a [ui.FlutterView] handed to a [RenderView] or a
/// [View] does not change identity when tooling installs or removes an
/// override.
ui.PlatformDispatcher debugApplyViewMetricsOverrides(ui.PlatformDispatcher dispatcher) {
  var result = dispatcher;
  assert(() {
    if (dispatcher is! _DebugViewMetricsPlatformDispatcher) {
      result = _wrappers[dispatcher] ??= _DebugViewMetricsPlatformDispatcher(dispatcher);
    }
    return true;
  }());
  return result;
}

// Keyed by the wrapped dispatcher so that the wrapper cannot outlive it.
final Expando<_DebugViewMetricsPlatformDispatcher> _wrappers =
    Expando<_DebugViewMetricsPlatformDispatcher>('debugViewMetricsOverrides');

/// A [ui.PlatformDispatcher] that reports the metrics of
/// [debugViewMetricsOverrides] in place of the ones the platform reports.
///
/// Members that do not carry an overridable metric forward to [_dispatcher]
/// unchanged.
///
/// There is one instance per wrapped dispatcher, plus one per view: the
/// per-view instances are what [ui.FlutterView.platformDispatcher] returns, and
/// they resolve the platform-wide metrics ([ui.PlatformDispatcher.textScaleFactor],
/// [ui.PlatformDispatcher.accessibilityFeatures] and friends) from the override
/// of the view they belong to. The instance that is not tied to a view resolves
/// them from the override of [ui.PlatformDispatcher.implicitView], because
/// consumers that read those metrics off the binding rather than off a view —
/// [SemanticsBinding.accessibilityFeatures], for one — have no view to resolve
/// against.
///
/// This class deliberately does not implement `noSuchMethod`: when `dart:ui`
/// grows a member, this library must fail to compile so that whoever adds the
/// member decides whether it is an overridable view metric or plain forwarding.
class _DebugViewMetricsPlatformDispatcher implements ui.PlatformDispatcher {
  _DebugViewMetricsPlatformDispatcher(this._dispatcher) : _viewId = null, _root = null;

  _DebugViewMetricsPlatformDispatcher._forView(_DebugViewMetricsPlatformDispatcher root, int viewId)
    : _root = root,
      _viewId = viewId,
      _dispatcher = root._dispatcher;

  /// The dispatcher whose metrics are being overridden.
  final ui.PlatformDispatcher _dispatcher;

  /// The dispatcher that owns the view wrappers, or null if this is that
  /// dispatcher.
  final _DebugViewMetricsPlatformDispatcher? _root;

  /// The view whose override supplies the platform-wide metrics, or null to use
  /// [ui.PlatformDispatcher.implicitView].
  final int? _viewId;

  // Keyed by the wrapped view so that a wrapper cannot outlive the view it
  // wraps, and so that repeated reads of `views` return the same wrappers:
  // views are compared by identity and used as map keys (as GlobalKeys, by
  // RenderView and by the widgets layer), so their identity has to be stable.
  // Only the root dispatcher ever populates this; the per-view ones resolve
  // through [_root], so `late` keeps them from allocating an Expando each.
  late final Expando<_DebugViewMetricsFlutterView> _views = Expando<_DebugViewMetricsFlutterView>();

  DebugViewMetricsOverride? get _override {
    final int? viewId = _viewId ?? _dispatcher.implicitView?.viewId;
    return viewId == null ? null : debugViewMetricsOverrides[viewId];
  }

  _DebugViewMetricsFlutterView _wrapView(ui.FlutterView view) {
    final _DebugViewMetricsPlatformDispatcher root = _root ?? this;
    return root._views[view] ??= _DebugViewMetricsFlutterView(view, root);
  }

  // Overridden metrics.

  @override
  ui.AccessibilityFeatures get accessibilityFeatures {
    final ui.AccessibilityFeatures features = _dispatcher.accessibilityFeatures;
    final DebugViewMetricsOverride? override = _override;
    return override == null ? features : _DebugAccessibilityFeatures(features, override);
  }

  @override
  bool get alwaysUse24HourFormat =>
      _override?.alwaysUse24HourFormat ?? _dispatcher.alwaysUse24HourFormat;

  @override
  ui.Brightness get platformBrightness =>
      _override?.platformBrightness ?? _dispatcher.platformBrightness;

  @override
  double get textScaleFactor => _override?.textScaleFactor ?? _dispatcher.textScaleFactor;

  @override
  double scaleFontSize(double unscaledFontSize) {
    final double? textScaleFactor = _override?.textScaleFactor;
    if (textScaleFactor == null) {
      return _dispatcher.scaleFontSize(unscaledFontSize);
    }
    // The platform curve that `scaleFontSize` normally applies is not
    // parameterized by a factor, so an overridden factor is applied linearly,
    // which is what `TextScaler.linear` and `TestPlatformDispatcher` do too.
    assert(unscaledFontSize >= 0);
    assert(unscaledFontSize.isFinite);
    return unscaledFontSize * textScaleFactor;
  }

  // Views, wrapped so that the metrics they report are overridden too.

  @override
  Iterable<ui.FlutterView> get views => _dispatcher.views.map(_wrapView);

  @override
  ui.FlutterView? view({required int id}) {
    final ui.FlutterView? view = _dispatcher.view(id: id);
    return view == null ? null : _wrapView(view);
  }

  @override
  ui.FlutterView? get implicitView {
    final ui.FlutterView? view = _dispatcher.implicitView;
    return view == null ? null : _wrapView(view);
  }

  // Everything below carries no overridable view metric and is forwarded.

  @override
  String get defaultRouteName => _dispatcher.defaultRouteName;

  @override
  Iterable<ui.Display> get displays => _dispatcher.displays;

  @override
  int? get engineId => _dispatcher.engineId;

  @override
  ui.FrameData get frameData => _dispatcher.frameData;

  @override
  String get initialLifecycleState => _dispatcher.initialLifecycleState;

  // The text spacing preferences below are in logical pixels, like
  // [ui.DisplayFeature.bounds], but unlike display features they are
  // typographic offsets applied to logical font sizes rather than positions on
  // the screen, so an overridden device pixel ratio leaves them alone: the
  // user asked for "two more logical pixels between letters", and that is still
  // what they get in the overridden logical space.
  @override
  double? get letterSpacingOverride => _dispatcher.letterSpacingOverride;

  @override
  double? get lineHeightScaleFactorOverride => _dispatcher.lineHeightScaleFactorOverride;

  @override
  ui.Locale get locale => _dispatcher.locale;

  @override
  List<ui.Locale> get locales => _dispatcher.locales;

  @override
  bool get nativeSpellCheckServiceDefined => _dispatcher.nativeSpellCheckServiceDefined;

  @override
  bool get brieflyShowPassword => _dispatcher.brieflyShowPassword;

  @override
  double? get paragraphSpacingOverride => _dispatcher.paragraphSpacingOverride;

  @override
  bool get semanticsEnabled => _dispatcher.semanticsEnabled;

  @override
  bool get supportsShowingSystemContextMenu => _dispatcher.supportsShowingSystemContextMenu;

  @override
  String? get systemFontFamily => _dispatcher.systemFontFamily;

  @override
  double? get wordSpacingOverride => _dispatcher.wordSpacingOverride;

  @override
  ui.VoidCallback? get onAccessibilityFeaturesChanged => _dispatcher.onAccessibilityFeaturesChanged;
  @override
  set onAccessibilityFeaturesChanged(ui.VoidCallback? callback) {
    _dispatcher.onAccessibilityFeaturesChanged = callback;
  }

  @override
  ui.FrameCallback? get onBeginFrame => _dispatcher.onBeginFrame;
  @override
  set onBeginFrame(ui.FrameCallback? callback) {
    _dispatcher.onBeginFrame = callback;
  }

  @override
  ui.VoidCallback? get onDrawFrame => _dispatcher.onDrawFrame;
  @override
  set onDrawFrame(ui.VoidCallback? callback) {
    _dispatcher.onDrawFrame = callback;
  }

  @override
  ui.ErrorCallback? get onError => _dispatcher.onError;
  @override
  set onError(ui.ErrorCallback? callback) {
    _dispatcher.onError = callback;
  }

  @override
  ui.VoidCallback? get onFrameDataChanged => _dispatcher.onFrameDataChanged;
  @override
  set onFrameDataChanged(ui.VoidCallback? callback) {
    _dispatcher.onFrameDataChanged = callback;
  }

  @override
  ui.HitTestCallback? get onHitTest => _dispatcher.onHitTest;
  @override
  set onHitTest(ui.HitTestCallback? callback) {
    _dispatcher.onHitTest = callback;
  }

  @override
  ui.KeyDataCallback? get onKeyData => _dispatcher.onKeyData;
  @override
  set onKeyData(ui.KeyDataCallback? callback) {
    _dispatcher.onKeyData = callback;
  }

  @override
  ui.VoidCallback? get onLocaleChanged => _dispatcher.onLocaleChanged;
  @override
  set onLocaleChanged(ui.VoidCallback? callback) {
    _dispatcher.onLocaleChanged = callback;
  }

  @override
  ui.VoidCallback? get onMetricsChanged => _dispatcher.onMetricsChanged;
  @override
  set onMetricsChanged(ui.VoidCallback? callback) {
    _dispatcher.onMetricsChanged = callback;
  }

  @override
  ui.VoidCallback? get onPlatformBrightnessChanged => _dispatcher.onPlatformBrightnessChanged;
  @override
  set onPlatformBrightnessChanged(ui.VoidCallback? callback) {
    _dispatcher.onPlatformBrightnessChanged = callback;
  }

  @override
  ui.VoidCallback? get onPlatformConfigurationChanged => _dispatcher.onPlatformConfigurationChanged;
  @override
  set onPlatformConfigurationChanged(ui.VoidCallback? callback) {
    _dispatcher.onPlatformConfigurationChanged = callback;
  }

  @override
  ui.PlatformMessageCallback? get onPlatformMessage => _dispatcher.onPlatformMessage;
  @override
  set onPlatformMessage(ui.PlatformMessageCallback? callback) {
    _dispatcher.onPlatformMessage = callback;
  }

  @override
  ui.PointerDataPacketCallback? get onPointerDataPacket => _dispatcher.onPointerDataPacket;
  @override
  set onPointerDataPacket(ui.PointerDataPacketCallback? callback) {
    _dispatcher.onPointerDataPacket = callback;
  }

  @override
  ui.TimingsCallback? get onReportTimings => _dispatcher.onReportTimings;
  @override
  set onReportTimings(ui.TimingsCallback? callback) {
    _dispatcher.onReportTimings = callback;
  }

  @override
  ui.SemanticsActionEventCallback? get onSemanticsActionEvent => _dispatcher.onSemanticsActionEvent;
  @override
  set onSemanticsActionEvent(ui.SemanticsActionEventCallback? callback) {
    _dispatcher.onSemanticsActionEvent = callback;
  }

  @override
  ui.VoidCallback? get onSemanticsEnabledChanged => _dispatcher.onSemanticsEnabledChanged;
  @override
  set onSemanticsEnabledChanged(ui.VoidCallback? callback) {
    _dispatcher.onSemanticsEnabledChanged = callback;
  }

  @override
  ui.VoidCallback? get onSystemFontFamilyChanged => _dispatcher.onSystemFontFamilyChanged;
  @override
  set onSystemFontFamilyChanged(ui.VoidCallback? callback) {
    _dispatcher.onSystemFontFamilyChanged = callback;
  }

  @override
  ui.VoidCallback? get onTextScaleFactorChanged => _dispatcher.onTextScaleFactorChanged;
  @override
  set onTextScaleFactorChanged(ui.VoidCallback? callback) {
    _dispatcher.onTextScaleFactorChanged = callback;
  }

  @override
  ui.ViewFocusChangeCallback? get onViewFocusChange => _dispatcher.onViewFocusChange;
  @override
  set onViewFocusChange(ui.ViewFocusChangeCallback? callback) {
    _dispatcher.onViewFocusChange = callback;
  }

  @override
  ui.Locale? computePlatformResolvedLocale(List<ui.Locale> supportedLocales) =>
      _dispatcher.computePlatformResolvedLocale(supportedLocales);

  @override
  ByteData? getPersistentIsolateData() => _dispatcher.getPersistentIsolateData();

  @override
  void registerBackgroundIsolate(ui.RootIsolateToken token) =>
      _dispatcher.registerBackgroundIsolate(token);

  @override
  void requestDartPerformanceMode(ui.DartPerformanceMode mode) =>
      _dispatcher.requestDartPerformanceMode(mode);

  @override
  void requestViewFocusChange({
    required int viewId,
    required ui.ViewFocusState state,
    required ui.ViewFocusDirection direction,
  }) => _dispatcher.requestViewFocusChange(viewId: viewId, state: state, direction: direction);

  @override
  void scheduleFrame() => _dispatcher.scheduleFrame();

  @override
  void scheduleWarmUpFrame({
    required ui.VoidCallback beginFrame,
    required ui.VoidCallback drawFrame,
  }) => _dispatcher.scheduleWarmUpFrame(beginFrame: beginFrame, drawFrame: drawFrame);

  @override
  void sendPlatformMessage(
    String name,
    ByteData? data,
    ui.PlatformMessageResponseCallback? callback,
  ) => _dispatcher.sendPlatformMessage(name, data, callback);

  @override
  void sendPortPlatformMessage(String name, ByteData? data, int identifier, Object port) {
    // `port` is declared as a `SendPort` by the VM's dart:ui and as an `Object`
    // by the web's, so this parameter is widened to `Object` to satisfy both.
    // Forwarding it therefore needs a downcast that only exists on the VM,
    // which is what going through `dynamic` expresses; `strict-casts` reports
    // that downcast, and there is nothing here to check it against on the web.
    final dynamic sendPort = port;
    // ignore: argument_type_not_assignable
    _dispatcher.sendPortPlatformMessage(name, data, identifier, sendPort);
  }

  @override
  void setApplicationLocale(ui.Locale locale) => _dispatcher.setApplicationLocale(locale);

  @override
  void setIsolateDebugName(String name) => _dispatcher.setIsolateDebugName(name);

  @override
  void setSemanticsTreeEnabled(bool enabled) => _dispatcher.setSemanticsTreeEnabled(enabled);

  @override
  void updateSemantics(ui.SemanticsUpdate update) => _dispatcher.updateSemantics(update);

  @override
  String toString() =>
      'DebugViewMetricsPlatformDispatcher(${_viewId == null ? 'implicit view' : 'view $_viewId'})';
}

/// A [ui.FlutterView] that reports the metrics its entry in
/// [debugViewMetricsOverrides] specifies in place of the ones the platform
/// reports.
///
/// Members that do not carry an overridable view metric forward to [_view]
/// unchanged. In particular [display] reports the real [ui.Display], because it
/// describes hardware rather than the view.
///
/// Like [_DebugViewMetricsPlatformDispatcher], this class deliberately does not
/// implement `noSuchMethod`, so that a new `dart:ui` member has to be
/// classified rather than silently reporting null.
class _DebugViewMetricsFlutterView implements ui.FlutterView {
  _DebugViewMetricsFlutterView(this._view, _DebugViewMetricsPlatformDispatcher root)
    : platformDispatcher = _DebugViewMetricsPlatformDispatcher._forView(root, _view.viewId);

  /// The view whose metrics are being overridden.
  final ui.FlutterView _view;

  /// The dispatcher that resolves this view's platform-wide metric overrides.
  ///
  /// This is not the dispatcher [debugApplyViewMetricsOverrides] returned; see
  /// [_DebugViewMetricsPlatformDispatcher] for why they differ.
  @override
  final ui.PlatformDispatcher platformDispatcher;

  DebugViewMetricsOverride? get _override => debugViewMetricsOverrides[_view.viewId];

  // Overridden metrics.

  @override
  double get devicePixelRatio => _override?.devicePixelRatio ?? _view.devicePixelRatio;

  @override
  ui.Size get physicalSize => _override?.physicalSize ?? _view.physicalSize;

  @override
  ui.ViewConstraints get physicalConstraints {
    // Overriding the size of a view makes it a fixed-size view: a loose
    // constraint would let layout pick the real size back up and the override
    // would have no effect.
    final ui.Size? physicalSize = _override?.physicalSize;
    return physicalSize == null
        ? _view.physicalConstraints
        : ui.ViewConstraints.tight(physicalSize);
  }

  @override
  ui.ViewPadding get padding => _override?.padding ?? _view.padding;

  @override
  ui.ViewPadding get viewInsets => _override?.viewInsets ?? _view.viewInsets;

  @override
  ui.ViewPadding get viewPadding => _override?.viewPadding ?? _view.viewPadding;

  @override
  List<ui.DisplayFeature> get displayFeatures {
    final double? devicePixelRatio = _override?.devicePixelRatio;
    final List<ui.DisplayFeature> displayFeatures = _view.displayFeatures;
    if (devicePixelRatio == null || displayFeatures.isEmpty) {
      return displayFeatures;
    }
    // [ui.DisplayFeature.bounds] is the one metric [ui.FlutterView] reports in
    // logical rather than physical pixels: the engine divides it by the real
    // device pixel ratio when it decodes it. Overriding that ratio changes the
    // logical space every other metric is reported in, so these have to move
    // with it, or a hinge would be reported outside the window it is inside.
    final double scale = _view.devicePixelRatio / devicePixelRatio;
    return <ui.DisplayFeature>[
      for (final ui.DisplayFeature displayFeature in displayFeatures)
        ui.DisplayFeature(
          bounds: ui.Rect.fromLTRB(
            displayFeature.bounds.left * scale,
            displayFeature.bounds.top * scale,
            displayFeature.bounds.right * scale,
            displayFeature.bounds.bottom * scale,
          ),
          type: displayFeature.type,
          state: displayFeature.state,
        ),
    ];
  }

  // Everything below carries no overridable view metric and is forwarded.

  @override
  ui.Display get display => _view.display;

  /// The corner radii the platform reports, in physical pixels.
  ///
  /// Unlike [displayFeatures] these are physical, so an overridden device pixel
  /// ratio converts them at the point they are read, and nothing is needed
  /// here.
  @override
  ui.DisplayCornerRadii? get displayCornerRadii => _view.displayCornerRadii;

  @override
  ui.GestureSettings get gestureSettings => _view.gestureSettings;

  @override
  ui.ViewPadding get systemGestureInsets => _view.systemGestureInsets;

  @override
  int get viewId => _view.viewId;

  @override
  void render(ui.Scene scene, {ui.Size? size}) => _view.render(scene, size: size);

  @override
  void updateSemantics(ui.SemanticsUpdate update) => _view.updateSemantics(update);

  @override
  String toString() => 'DebugViewMetricsFlutterView(id: $viewId)';
}

/// The [ui.AccessibilityFeatures] of [_features], with the flags that
/// [_override] specifies replaced.
@immutable
class _DebugAccessibilityFeatures implements ui.AccessibilityFeatures {
  const _DebugAccessibilityFeatures(this._features, this._override);

  final ui.AccessibilityFeatures _features;
  final DebugViewMetricsOverride _override;

  @override
  bool get accessibleNavigation => _override.accessibleNavigation ?? _features.accessibleNavigation;

  @override
  bool get autoPlayAnimatedImages =>
      _override.autoPlayAnimatedImages ?? _features.autoPlayAnimatedImages;

  @override
  bool get autoPlayVideos => _override.autoPlayVideos ?? _features.autoPlayVideos;

  @override
  bool get boldText => _override.boldText ?? _features.boldText;

  @override
  bool get deterministicCursor => _override.deterministicCursor ?? _features.deterministicCursor;

  @override
  bool get disableAnimations => _override.disableAnimations ?? _features.disableAnimations;

  @override
  bool get highContrast => _override.highContrast ?? _features.highContrast;

  @override
  bool get invertColors => _override.invertColors ?? _features.invertColors;

  @override
  bool get onOffSwitchLabels => _override.onOffSwitchLabels ?? _features.onOffSwitchLabels;

  @override
  bool get reduceMotion => _override.reduceMotion ?? _features.reduceMotion;

  @override
  bool get supportsAnnounce => _override.supportsAnnounce ?? _features.supportsAnnounce;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    // ui.AccessibilityFeatures compares runtimeType before reaching for its
    // private bitfield, so it never sees this class as equal to itself; this
    // only has to handle other instances of this class.
    return other is _DebugAccessibilityFeatures &&
        other.accessibleNavigation == accessibleNavigation &&
        other.autoPlayAnimatedImages == autoPlayAnimatedImages &&
        other.autoPlayVideos == autoPlayVideos &&
        other.boldText == boldText &&
        other.deterministicCursor == deterministicCursor &&
        other.disableAnimations == disableAnimations &&
        other.highContrast == highContrast &&
        other.invertColors == invertColors &&
        other.onOffSwitchLabels == onOffSwitchLabels &&
        other.reduceMotion == reduceMotion &&
        other.supportsAnnounce == supportsAnnounce;
  }

  @override
  int get hashCode => Object.hash(
    accessibleNavigation,
    autoPlayAnimatedImages,
    autoPlayVideos,
    boldText,
    deterministicCursor,
    disableAnimations,
    highContrast,
    invertColors,
    onOffSwitchLabels,
    reduceMotion,
    supportsAnnounce,
  );

  @override
  String toString() {
    final features = <String>[
      if (accessibleNavigation) 'accessibleNavigation',
      if (invertColors) 'invertColors',
      if (disableAnimations) 'disableAnimations',
      if (boldText) 'boldText',
      if (reduceMotion) 'reduceMotion',
      if (highContrast) 'highContrast',
      if (onOffSwitchLabels) 'onOffSwitchLabels',
      if (supportsAnnounce) 'supportsAnnounce',
      if (autoPlayAnimatedImages) 'autoPlayAnimatedImages',
      if (autoPlayVideos) 'autoPlayVideos',
      if (deterministicCursor) 'deterministicCursor',
    ];
    return 'AccessibilityFeatures$features';
  }
}
