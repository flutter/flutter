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
import 'services.dart';
import 'util.dart';

typedef _HandleMessageCallBack = Future<bool> Function();

/// When set to true, all platform messages will be printed to the console.
const bool debugPrintPlatformMessages = false;

/// The view ID for the implicit flutter view provided by the platform.
const int kImplicitViewId = 0;

/// Represents all views in the Flutter Web Engine.
///
/// In addition to everything defined in [ui.FlutterView], this class adds
/// a few web-specific properties.
abstract interface class EngineFlutterView extends ui.FlutterView {
  ContextMenu get contextMenu;
  MouseCursor get mouseCursor;
  PlatformViewMessageHandler get platformViewMessageHandler;
  DomElement get rootElement;
}

/// The Web implementation of [ui.SingletonFlutterWindow].
class EngineFlutterWindow extends ui.SingletonFlutterWindow implements EngineFlutterView {
  EngineFlutterWindow(this.viewId, this.platformDispatcher) {
    platformDispatcher.viewData[viewId] = this;
    platformDispatcher.windowConfigurations[viewId] = const ViewConfiguration();
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
  EngineFlutterDisplay get display => EngineFlutterDisplay.instance;

  @override
  final int viewId;

  @override
  final EnginePlatformDispatcher platformDispatcher;

  @override
  late final MouseCursor mouseCursor = MouseCursor(rootElement);

  @override
  late final ContextMenu contextMenu = ContextMenu(rootElement);

  @override
  DomElement get rootElement => flutterViewEmbedder.flutterViewElement;

  @override
  late final PlatformViewMessageHandler platformViewMessageHandler =
      PlatformViewMessageHandler(platformViewsContainer: flutterViewEmbedder.glassPaneElement);

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

  ViewConfiguration get _viewConfiguration {
    assert(platformDispatcher.windowConfigurations.containsKey(viewId));
    return platformDispatcher.windowConfigurations[viewId] ??
        const ViewConfiguration();
  }

  @override
  ui.Rect get physicalGeometry => _viewConfiguration.geometry;

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

  late DimensionsProvider _dimensionsProvider;
  void configureDimensionsProvider(DimensionsProvider dimensionsProvider) {
    _dimensionsProvider = dimensionsProvider;
  }

  @override
  double get devicePixelRatio => display.devicePixelRatio;

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

  Stream<ui.Size?> get onResize => _dimensionsProvider.onResize;

  @override
  ui.Size get physicalSize {
    if (_physicalSize == null) {
      computePhysicalSize();
    }
    assert(_physicalSize != null);
    return _physicalSize!;
  }

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

  /// Forces the window to recompute its physical size. Useful for tests.
  void debugForceResize() {
    computePhysicalSize();
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

  @override
  ViewPadding get viewInsets => _viewInsets;
  ViewPadding _viewInsets = ui.ViewPadding.zero as ViewPadding;

  /// Lazily populated and cleared at the end of the frame.
  ui.Size? _physicalSize;

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

  ui.Size? debugPhysicalSizeOverride;
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
