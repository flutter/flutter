// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@JS()
library window;

import 'dart:async';
import 'dart:typed_data';

import 'package:js/js.dart';
import 'package:meta/meta.dart';
import 'package:ui/ui.dart' as ui;

import '../engine.dart' show DimensionsProvider, registerHotRestartListener, renderer;
import 'dom.dart';
import 'navigation/history.dart';
import 'navigation/js_url_strategy.dart';
import 'navigation/url_strategy.dart';
import 'platform_dispatcher.dart';
import 'services.dart';
import 'test_embedding.dart';
import 'util.dart';

typedef _HandleMessageCallBack = Future<bool> Function();

/// When set to true, all platform messages will be printed to the console.
const bool debugPrintPlatformMessages = false;

/// The view ID for the implicit flutter view provided by the platform.
const int kImplicitViewId = 0;

/// Whether [_customUrlStrategy] has been set or not.
///
/// It is valid to set [_customUrlStrategy] to null, so we can't use a null
/// check to determine whether it was set or not. We need an extra boolean.
bool _isUrlStrategySet = false;

/// A custom URL strategy set by the app before running.
UrlStrategy? _customUrlStrategy;
set customUrlStrategy(UrlStrategy? strategy) {
  assert(!_isUrlStrategySet, 'Cannot set URL strategy more than once.');
  _isUrlStrategySet = true;
  _customUrlStrategy = strategy;
}

/// The Web implementation of [ui.SingletonFlutterWindow].
class EngineFlutterWindow extends ui.SingletonFlutterWindow {
  EngineFlutterWindow(this.viewId, this.platformDispatcher) {
    final EnginePlatformDispatcher engineDispatcher =
        platformDispatcher as EnginePlatformDispatcher;
    engineDispatcher.viewData[viewId] = this;
    engineDispatcher.windowConfigurations[viewId] = const ui.ViewConfiguration();
    if (_isUrlStrategySet) {
      _browserHistory = createHistoryForExistingState(_customUrlStrategy);
    }
    registerHotRestartListener(() {
      _browserHistory?.dispose();
      renderer.clearFragmentProgramCache();
      _dimensionsProvider.close();
    });
  }

  @override
  final Object viewId;

  @override
  final ui.PlatformDispatcher platformDispatcher;

  /// Handles the browser history integration to allow users to use the back
  /// button, etc.
  BrowserHistory get browserHistory {
    return _browserHistory ??=
        createHistoryForExistingState(_urlStrategyForInitialization);
  }

  UrlStrategy? get _urlStrategyForInitialization {
    final UrlStrategy? urlStrategy =
        _isUrlStrategySet ? _customUrlStrategy : _createDefaultUrlStrategy();
    // Prevent any further customization of URL strategy.
    _isUrlStrategySet = true;
    return urlStrategy;
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
    final UrlStrategy? strategy = _browserHistory?.urlStrategy;
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
    final UrlStrategy? strategy = _browserHistory?.urlStrategy;
    await _browserHistory?.tearDown();
    _browserHistory = MultiEntriesBrowserHistory(urlStrategy: strategy);
  }

  @visibleForTesting
  Future<void> debugInitializeHistory(
    UrlStrategy? strategy, {
    required bool useSingle,
  }) async {
    // Prevent any further customization of URL strategy.
    _isUrlStrategySet = true;
    await _browserHistory?.tearDown();
    if (useSingle) {
      _browserHistory = SingleEntryBrowserHistory(urlStrategy: strategy);
    } else {
      _browserHistory = MultiEntriesBrowserHistory(urlStrategy: strategy);
    }
  }

  Future<void> resetHistory() async {
    await _browserHistory?.tearDown();
    _browserHistory = null;
    // Reset the globals too.
    _isUrlStrategySet = false;
    _customUrlStrategy = null;
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
          browserHistory.setRouteName(
            arguments!.tryString('location'),
            state: arguments['state'],
            replace: arguments.tryBool('replace') ?? false,
          );
          return true;
      }
      return false;
    });
  }

  @override
  ui.ViewConfiguration get viewConfiguration {
    final EnginePlatformDispatcher engineDispatcher =
        platformDispatcher as EnginePlatformDispatcher;
    assert(engineDispatcher.windowConfigurations.containsKey(viewId));
    return engineDispatcher.windowConfigurations[viewId] ??
        const ui.ViewConfiguration();
  }

  late DimensionsProvider _dimensionsProvider;
  void configureDimensionsProvider(DimensionsProvider dimensionsProvider) {
    _dimensionsProvider = dimensionsProvider;
  }

  @override
  double get devicePixelRatio => _dimensionsProvider.getDevicePixelRatio();

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
      if (webOnlyDebugPhysicalSizeOverride != null) {
        _physicalSize = webOnlyDebugPhysicalSizeOverride;
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
  WindowPadding get viewInsets => _viewInsets;
  WindowPadding _viewInsets = ui.WindowPadding.zero as WindowPadding;

  /// Lazily populated and cleared at the end of the frame.
  ui.Size? _physicalSize;

  /// Overrides the value of [physicalSize] in tests.
  ui.Size? webOnlyDebugPhysicalSizeOverride;
}

typedef _JsSetUrlStrategy = void Function(JsUrlStrategy?);

/// A JavaScript hook to customize the URL strategy of a Flutter app.
//
// Keep this js name in sync with flutter_web_plugins. Find it at:
// https://github.com/flutter/flutter/blob/custom_location_strategy/packages/flutter_web_plugins/lib/src/navigation/js_url_strategy.dart
//
// TODO(mdebbar): Add integration test https://github.com/flutter/flutter/issues/66852
@JS('_flutter_web_set_location_strategy')
external set jsSetUrlStrategy(_JsSetUrlStrategy? newJsSetUrlStrategy);

UrlStrategy? _createDefaultUrlStrategy() {
  return ui.debugEmulateFlutterTesterEnvironment
      ? TestUrlStrategy.fromEntry(const TestHistoryEntry('default', null, '/'))
      : const HashUrlStrategy();
}

/// The Web implementation of [ui.SingletonFlutterWindow].
class EngineSingletonFlutterWindow extends EngineFlutterWindow {
  EngineSingletonFlutterWindow(
      super.windowId, super.platformDispatcher);

  @override
  double get devicePixelRatio =>
      _debugDevicePixelRatio ??
      EnginePlatformDispatcher.browserDevicePixelRatio;

  /// Overrides the default device pixel ratio.
  ///
  /// This is useful in tests to emulate screens of different dimensions.
  void debugOverrideDevicePixelRatio(double value) {
    _debugDevicePixelRatio = value;
  }

  double? _debugDevicePixelRatio;
}

/// The window singleton.
///
/// `dart:ui` window delegates to this value. However, this value has a wider
/// API surface, providing Web-specific functionality that the standard
/// `dart:ui` version does not.
final EngineSingletonFlutterWindow window =
    EngineSingletonFlutterWindow(kImplicitViewId, EnginePlatformDispatcher.instance);

/// The Web implementation of [ui.WindowPadding].
class WindowPadding implements ui.WindowPadding {
  const WindowPadding({
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
