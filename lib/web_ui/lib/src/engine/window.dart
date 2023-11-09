// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@JS()
library window;

import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:ui/ui.dart' as ui;
import 'package:ui/ui_web/src/ui_web.dart' as ui_web;

import '../engine.dart' show DimensionsProvider, registerHotRestartListener, renderer;
import 'display.dart';
import 'dom.dart';
import 'embedder.dart';
import 'mouse/context_menu.dart';
import 'mouse/cursor.dart';
import 'navigation/history.dart';
import 'platform_dispatcher.dart';
import 'platform_views/message_handler.dart';
import 'semantics/accessibility.dart';
import 'services.dart';
import 'util.dart';
import 'view_embedder/dom_manager.dart';

typedef _HandleMessageCallBack = Future<bool> Function();

/// When set to true, all platform messages will be printed to the console.
const bool debugPrintPlatformMessages = false;

/// The view ID for the implicit flutter view provided by the platform.
const int kImplicitViewId = 0;

/// Represents all views in the Flutter Web Engine.
///
/// In addition to everything defined in [ui.FlutterView], this class adds
/// a few web-specific properties.
base class EngineFlutterView implements ui.FlutterView {
  factory EngineFlutterView(
    int viewId,
    EnginePlatformDispatcher platformDispatcher,
  ) = _EngineFlutterViewImpl;

  EngineFlutterView._(
    this.viewId,
    this.platformDispatcher,
  );

  @override
  final int viewId;

  @override
  final EnginePlatformDispatcher platformDispatcher;

  final ViewConfiguration _viewConfiguration = const ViewConfiguration();

  @override
  void render(ui.Scene scene) => platformDispatcher.render(scene, this);

  @override
  void updateSemantics(ui.SemanticsUpdate update) => platformDispatcher.updateSemantics(update);

  // TODO(yjbanov): How should this look like for multi-view?
  //                https://github.com/flutter/flutter/issues/137445
  late final AccessibilityAnnouncements accessibilityAnnouncements =
      AccessibilityAnnouncements(hostElement: dom.announcementsHost);

  late final MouseCursor mouseCursor = MouseCursor(dom.rootElement);

  late final ContextMenu contextMenu = ContextMenu(dom.rootElement);

  late final DomManager dom =
      DomManager.fromFlutterViewEmbedderDEPRECATED(flutterViewEmbedder);

  late final PlatformViewMessageHandler platformViewMessageHandler =
      PlatformViewMessageHandler(platformViewsContainer: dom.platformViewsHost);

  @override
  ui.Size get physicalSize {
    if (_physicalSize == null) {
      computePhysicalSize();
    }
    assert(_physicalSize != null);
    return _physicalSize!;
  }

  /// Lazily populated and cleared at the end of the frame.
  ui.Size? _physicalSize;

  ui.Size? debugPhysicalSizeOverride;

  /// Computes the physical size of the screen from [domWindow].
  ///
  /// This function is expensive. It triggers browser layout if there are
  /// pending DOM writes.
  void computePhysicalSize() {
    bool override = false;

    assert(() {
      if (debugPhysicalSizeOverride != null) {
        _physicalSize = debugPhysicalSizeOverride;
        override = true;
      }
      return true;
    }());

    if (!override) {
      _physicalSize = _dimensionsProvider.computePhysicalSize();
    }
  }

  /// Forces the view to recompute its physical size. Useful for tests.
  void debugForceResize() {
    computePhysicalSize();
  }

  @override
  ViewPadding get viewInsets => _viewInsets;
  ViewPadding _viewInsets = ui.ViewPadding.zero as ViewPadding;

  @override
  ViewPadding get viewPadding => _viewConfiguration.viewPadding;

  @override
  ViewPadding get systemGestureInsets => _viewConfiguration.systemGestureInsets;

  @override
  ViewPadding get padding => _viewConfiguration.padding;

  @override
  ui.GestureSettings get gestureSettings => _viewConfiguration.gestureSettings;

  @override
  List<ui.DisplayFeature> get displayFeatures => _viewConfiguration.displayFeatures;

  @override
  EngineFlutterDisplay get display => EngineFlutterDisplay.instance;

  @override
  double get devicePixelRatio => display.devicePixelRatio;

  late DimensionsProvider _dimensionsProvider;
  void configureDimensionsProvider(DimensionsProvider dimensionsProvider) {
    _dimensionsProvider = dimensionsProvider;
  }

  Stream<ui.Size?> get onResize => _dimensionsProvider.onResize;
}

final class _EngineFlutterViewImpl extends EngineFlutterView {
  _EngineFlutterViewImpl(
    int viewId,
    EnginePlatformDispatcher platformDispatcher,
  ) : super._(viewId, platformDispatcher) {
    platformDispatcher.registerView(this);
    registerHotRestartListener(() {
      // TODO(harryterkelsen): What should we do about this in multi-view?
      renderer.clearFragmentProgramCache();
      _dimensionsProvider.close();
    });
  }
}

/// The Web implementation of [ui.SingletonFlutterWindow].
final class EngineFlutterWindow extends EngineFlutterView implements ui.SingletonFlutterWindow {
  EngineFlutterWindow(
    int viewId,
    EnginePlatformDispatcher platformDispatcher,
  ) : super._(viewId, platformDispatcher) {
    platformDispatcher.registerView(this);
    if (ui_web.isCustomUrlStrategySet) {
      _browserHistory = createHistoryForExistingState(ui_web.urlStrategy);
    }
    registerHotRestartListener(() {
      _browserHistory?.dispose();
      renderer.clearFragmentProgramCache();
      _dimensionsProvider.close();
    });
  }

  @override
  ui.VoidCallback? get onMetricsChanged => platformDispatcher.onMetricsChanged;
  @override
  set onMetricsChanged(ui.VoidCallback? callback) {
    platformDispatcher.onMetricsChanged = callback;
  }

  @override
  ui.Locale get locale => platformDispatcher.locale;
  @override
  List<ui.Locale> get locales => platformDispatcher.locales;

  @override
  ui.Locale? computePlatformResolvedLocale(List<ui.Locale> supportedLocales) {
    return platformDispatcher.computePlatformResolvedLocale(supportedLocales);
  }

  @override
  ui.VoidCallback? get onLocaleChanged => platformDispatcher.onLocaleChanged;
  @override
  set onLocaleChanged(ui.VoidCallback? callback) {
    platformDispatcher.onLocaleChanged = callback;
  }

  @override
  String get initialLifecycleState => platformDispatcher.initialLifecycleState;

  @override
  double get textScaleFactor => platformDispatcher.textScaleFactor;

  @override
  bool get nativeSpellCheckServiceDefined => platformDispatcher.nativeSpellCheckServiceDefined;

  @override
  bool get brieflyShowPassword => platformDispatcher.brieflyShowPassword;

  @override
  bool get alwaysUse24HourFormat => platformDispatcher.alwaysUse24HourFormat;

  @override
  ui.VoidCallback? get onTextScaleFactorChanged => platformDispatcher.onTextScaleFactorChanged;
  @override
  set onTextScaleFactorChanged(ui.VoidCallback? callback) {
    platformDispatcher.onTextScaleFactorChanged = callback;
  }

  @override
  ui.Brightness get platformBrightness => platformDispatcher.platformBrightness;

  @override
  ui.VoidCallback? get onPlatformBrightnessChanged => platformDispatcher.onPlatformBrightnessChanged;
  @override
  set onPlatformBrightnessChanged(ui.VoidCallback? callback) {
    platformDispatcher.onPlatformBrightnessChanged = callback;
  }

  @override
  String? get systemFontFamily => platformDispatcher.systemFontFamily;

  @override
  ui.VoidCallback? get onSystemFontFamilyChanged => platformDispatcher.onSystemFontFamilyChanged;
  @override
  set onSystemFontFamilyChanged(ui.VoidCallback? callback) {
    platformDispatcher.onSystemFontFamilyChanged = callback;
  }

  @override
  ui.FrameCallback? get onBeginFrame => platformDispatcher.onBeginFrame;
  @override
  set onBeginFrame(ui.FrameCallback? callback) {
    platformDispatcher.onBeginFrame = callback;
  }

  @override
  ui.VoidCallback? get onDrawFrame => platformDispatcher.onDrawFrame;
  @override
  set onDrawFrame(ui.VoidCallback? callback) {
    platformDispatcher.onDrawFrame = callback;
  }

  @override
  ui.TimingsCallback? get onReportTimings => platformDispatcher.onReportTimings;
  @override
  set onReportTimings(ui.TimingsCallback? callback) {
    platformDispatcher.onReportTimings = callback;
  }

  @override
  ui.PointerDataPacketCallback? get onPointerDataPacket => platformDispatcher.onPointerDataPacket;
  @override
  set onPointerDataPacket(ui.PointerDataPacketCallback? callback) {
    platformDispatcher.onPointerDataPacket = callback;
  }

  @override
  ui.KeyDataCallback? get onKeyData => platformDispatcher.onKeyData;
  @override
  set onKeyData(ui.KeyDataCallback? callback) {
    platformDispatcher.onKeyData = callback;
  }

  @override
  String get defaultRouteName => platformDispatcher.defaultRouteName;

  @override
  void scheduleFrame() => platformDispatcher.scheduleFrame();

  @override
  bool get semanticsEnabled => platformDispatcher.semanticsEnabled;

  @override
  ui.VoidCallback? get onSemanticsEnabledChanged => platformDispatcher.onSemanticsEnabledChanged;
  @override
  set onSemanticsEnabledChanged(ui.VoidCallback? callback) {
    platformDispatcher.onSemanticsEnabledChanged = callback;
  }

  @override
  ui.FrameData get frameData => const ui.FrameData.webOnly();

  @override
  ui.VoidCallback? get onFrameDataChanged => null;
  @override
  set onFrameDataChanged(ui.VoidCallback? callback) {}

  @override
  ui.AccessibilityFeatures get accessibilityFeatures => platformDispatcher.accessibilityFeatures;

  @override
  ui.VoidCallback? get onAccessibilityFeaturesChanged =>
      platformDispatcher.onAccessibilityFeaturesChanged;
  @override
  set onAccessibilityFeaturesChanged(ui.VoidCallback? callback) {
    platformDispatcher.onAccessibilityFeaturesChanged = callback;
  }

  @override
  void sendPlatformMessage(
    String name,
    ByteData? data,
    ui.PlatformMessageResponseCallback? callback,
  ) {
    platformDispatcher.sendPlatformMessage(name, data, callback);
  }

  @override
  ui.PlatformMessageCallback? get onPlatformMessage => platformDispatcher.onPlatformMessage;
  @override
  set onPlatformMessage(ui.PlatformMessageCallback? callback) {
    platformDispatcher.onPlatformMessage = callback;
  }

  @override
  void setIsolateDebugName(String name) => ui.PlatformDispatcher.instance.setIsolateDebugName(name);

  /// Handles the browser history integration to allow users to use the back
  /// button, etc.
  BrowserHistory get browserHistory {
    return _browserHistory ??=
        createHistoryForExistingState(_urlStrategyForInitialization);
  }

  ui_web.UrlStrategy? get _urlStrategyForInitialization {
    // Prevent any further customization of URL strategy.
    ui_web.preventCustomUrlStrategy();
    return ui_web.urlStrategy;
  }

  BrowserHistory?
      _browserHistory; // Must be either SingleEntryBrowserHistory or MultiEntriesBrowserHistory.

  Future<void> _useSingleEntryBrowserHistory() async {
    // Recreate the browser history mode that's appropriate for the existing
    // history state.
    //
    // If it happens to be a single-entry one, then there's nothing further to do.
    //
    // But if it's a multi-entry one, it will be torn down below and replaced
    // with a single-entry history.
    //
    // See: https://github.com/flutter/flutter/issues/79241
    _browserHistory ??=
        createHistoryForExistingState(_urlStrategyForInitialization);

    if (_browserHistory is SingleEntryBrowserHistory) {
      return;
    }

    // At this point, we know that `_browserHistory` is a non-null
    // `MultiEntriesBrowserHistory` instance.
    final ui_web.UrlStrategy? strategy = _browserHistory?.urlStrategy;
    await _browserHistory?.tearDown();
    _browserHistory = SingleEntryBrowserHistory(urlStrategy: strategy);
  }

  Future<void> _useMultiEntryBrowserHistory() async {
    // Recreate the browser history mode that's appropriate for the existing
    // history state.
    //
    // If it happens to be a multi-entry one, then there's nothing further to do.
    //
    // But if it's a single-entry one, it will be torn down below and replaced
    // with a multi-entry history.
    //
    // See: https://github.com/flutter/flutter/issues/79241
    _browserHistory ??=
        createHistoryForExistingState(_urlStrategyForInitialization);

    if (_browserHistory is MultiEntriesBrowserHistory) {
      return;
    }

    // At this point, we know that `_browserHistory` is a non-null
    // `SingleEntryBrowserHistory` instance.
    final ui_web.UrlStrategy? strategy = _browserHistory?.urlStrategy;
    await _browserHistory?.tearDown();
    _browserHistory = MultiEntriesBrowserHistory(urlStrategy: strategy);
  }

  @visibleForTesting
  Future<void> debugInitializeHistory(
    ui_web.UrlStrategy? strategy, {
    required bool useSingle,
  }) async {
    await _browserHistory?.tearDown();

    ui_web.urlStrategy = strategy;
    if (useSingle) {
      _browserHistory = SingleEntryBrowserHistory(urlStrategy: strategy);
    } else {
      _browserHistory = MultiEntriesBrowserHistory(urlStrategy: strategy);
    }
  }

  Future<void> resetHistory() async {
    await _browserHistory?.tearDown();
    _browserHistory = null;
    ui_web.debugResetCustomUrlStrategy();
  }

  Future<void> _endOfTheLine = Future<void>.value();

  Future<bool> _waitInTheLine(_HandleMessageCallBack callback) async {
    final Future<void> currentPosition = _endOfTheLine;
    final Completer<void> completer = Completer<void>();
    _endOfTheLine = completer.future;
    await currentPosition;
    bool result = false;
    try {
      result = await callback();
    } finally {
      completer.complete();
    }
    return result;
  }

  Future<bool> handleNavigationMessage(ByteData? data) async {
    return _waitInTheLine(() async {
      final MethodCall decoded = const JSONMethodCodec().decodeMethodCall(data);
      final Map<String, dynamic>? arguments = decoded.arguments as Map<String, dynamic>?;
      switch (decoded.method) {
        case 'selectMultiEntryHistory':
          await _useMultiEntryBrowserHistory();
          return true;
        case 'selectSingleEntryHistory':
          await _useSingleEntryBrowserHistory();
          return true;
        // the following cases assert that arguments are not null
        case 'routeUpdated': // deprecated
          assert(arguments != null);
          await _useSingleEntryBrowserHistory();
          browserHistory.setRouteName(arguments!.tryString('routeName'));
          return true;
        case 'routeInformationUpdated':
          assert(arguments != null);
          final String? uriString = arguments!.tryString('uri');
          final String path;
          if (uriString != null) {
            final Uri uri = Uri.parse(uriString);
            // Need to remove scheme and authority.
            path = Uri.decodeComponent(
              Uri(
                path: uri.path.isEmpty ? '/' : uri.path,
                queryParameters: uri.queryParametersAll.isEmpty ? null : uri.queryParametersAll,
                fragment: uri.fragment.isEmpty ? null : uri.fragment,
              ).toString(),
            );
          } else {
            path = arguments.tryString('location')!;
          }
          browserHistory.setRouteName(
            path,
            state: arguments['state'],
            replace: arguments.tryBool('replace') ?? false,
          );
          return true;
      }
      return false;
    });
  }

  // TODO(mdebbar): Deprecate this and remove it.
  // https://github.com/flutter/flutter/issues/127395
  void debugOverrideDevicePixelRatio(double? value) {
    assert(() {
      printWarning(
        'The window.debugOverrideDevicePixelRatio API is deprecated and will '
        'be removed in a future release. Please use '
        '`debugOverrideDevicePixelRatio` from `dart:ui_web` instead.',
      );
      return true;
    }());
    display.debugOverrideDevicePixelRatio(value);
  }

  void computeOnScreenKeyboardInsets(bool isEditingOnMobile) {
    _viewInsets = _dimensionsProvider.computeKeyboardInsets(
      _physicalSize!.height,
      isEditingOnMobile,
    );
  }

  /// Uses the previous physical size and current innerHeight/innerWidth
  /// values to decide if a device is rotating.
  ///
  /// During a rotation the height and width values will (almost) swap place.
  /// Values can slightly differ due to space occupied by the browser header.
  /// For example the following values are collected for Pixel 3 rotation:
  ///
  /// height: 658 width: 393
  /// new height: 313 new width: 738
  ///
  /// The following values are from a changed caused by virtual keyboard.
  ///
  /// height: 658 width: 393
  /// height: 368 width: 393
  bool isRotation() {
    // This method compares the new dimensions with the previous ones.
    // Return false if the previous dimensions are not set.
    if (_physicalSize != null) {
      final ui.Size current = _dimensionsProvider.computePhysicalSize();
      // First confirm both height and width are effected.
      if (_physicalSize!.height != current.height && _physicalSize!.width != current.width) {
        // If prior to rotation height is bigger than width it should be the
        // opposite after the rotation and vice versa.
        if ((_physicalSize!.height > _physicalSize!.width && current.height < current.width) ||
            (_physicalSize!.width > _physicalSize!.height && current.width < current.height)) {
          // Rotation detected
          return true;
        }
      }
    }
    return false;
  }

  // TODO(mdebbar): Deprecate this and remove it.
  // https://github.com/flutter/flutter/issues/127395
  ui.Size? get webOnlyDebugPhysicalSizeOverride {
    assert(() {
      printWarning(
        'The webOnlyDebugPhysicalSizeOverride API is deprecated and will be '
        'removed in a future release. Please use '
        '`SingletonFlutterWindow.debugPhysicalSizeOverride` from `dart:ui_web` '
        'instead.',
      );
      return true;
    }());
    return debugPhysicalSizeOverride;
  }

  // TODO(mdebbar): Deprecate this and remove it.
  // https://github.com/flutter/flutter/issues/127395
  set webOnlyDebugPhysicalSizeOverride(ui.Size? value) {
    assert(() {
      printWarning(
        'The webOnlyDebugPhysicalSizeOverride API is deprecated and will be '
        'removed in a future release. Please use '
        '`SingletonFlutterWindow.debugPhysicalSizeOverride` from `dart:ui_web` '
        'instead.',
      );
      return true;
    }());
    debugPhysicalSizeOverride = value;
  }
}

/// The window singleton.
///
/// `dart:ui` window delegates to this value. However, this value has a wider
/// API surface, providing Web-specific functionality that the standard
/// `dart:ui` version does not.
final EngineFlutterWindow window =
    EngineFlutterWindow(kImplicitViewId, EnginePlatformDispatcher.instance);

/// The Web implementation of [ui.ViewPadding].
class ViewPadding implements ui.ViewPadding {
  const ViewPadding({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  @override
  final double left;
  @override
  final double top;
  @override
  final double right;
  @override
  final double bottom;
}
