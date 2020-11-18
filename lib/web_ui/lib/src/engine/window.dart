// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.12
part of engine;

/// When set to true, all platform messages will be printed to the console.
const bool/*!*/ _debugPrintPlatformMessages = false;

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
  EngineFlutterWindow(this._windowId, this.platformDispatcher) {
    final EnginePlatformDispatcher engineDispatcher = platformDispatcher as EnginePlatformDispatcher;
    engineDispatcher._windows[_windowId] = this;
    engineDispatcher._windowConfigurations[_windowId] = ui.ViewConfiguration();
    if (_isUrlStrategySet) {
      _browserHistory =
          MultiEntriesBrowserHistory(urlStrategy: _customUrlStrategy);
    }
  }

  final Object _windowId;
  final ui.PlatformDispatcher platformDispatcher;

  /// Handles the browser history integration to allow users to use the back
  /// button, etc.
  @visibleForTesting
  BrowserHistory get browserHistory {
    final UrlStrategy? urlStrategy = _isUrlStrategySet
        ? _customUrlStrategy
        : _createDefaultUrlStrategy();
    // Prevent any further customization of URL strategy.
    _isUrlStrategySet = true;
    return _browserHistory ??=
        MultiEntriesBrowserHistory(urlStrategy: urlStrategy);
  }

  BrowserHistory? _browserHistory;

  Future<void> _useSingleEntryBrowserHistory() async {
    if (_browserHistory is SingleEntryBrowserHistory) {
      return;
    }
    final UrlStrategy? strategy = _browserHistory?.urlStrategy;
    await _browserHistory?.tearDown();
    _browserHistory = SingleEntryBrowserHistory(urlStrategy: strategy);
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

  @visibleForTesting
  Future<void> debugResetHistory() async {
    await _browserHistory?.tearDown();
    _browserHistory = null;

    // Reset the globals too.
    _isUrlStrategySet = false;
    _customUrlStrategy = null;
  }

  Future<bool> handleNavigationMessage(
      ByteData? data,
      ) async {
    final MethodCall decoded = JSONMethodCodec().decodeMethodCall(data);
    final Map<String, dynamic> arguments = decoded.arguments;

    switch (decoded.method) {
      case 'routeUpdated':
        await _useSingleEntryBrowserHistory();
        browserHistory.setRouteName(arguments['routeName']);
        return true;
      case 'routeInformationUpdated':
        assert(browserHistory is MultiEntriesBrowserHistory);
        browserHistory.setRouteName(
          arguments['location'],
          state: arguments['state'],
        );
        return true;
    }
    return false;
  }

  @override
  ui.ViewConfiguration get viewConfiguration {
    final EnginePlatformDispatcher engineDispatcher = platformDispatcher as EnginePlatformDispatcher;
    assert(engineDispatcher._windowConfigurations.containsKey(_windowId));
    return engineDispatcher._windowConfigurations[_windowId] ?? ui.ViewConfiguration();
  }

  @override
  ui.Size get physicalSize {
    if (_physicalSize == null) {
      _computePhysicalSize();
    }
    assert(_physicalSize != null);
    return _physicalSize!;
  }

  /// Computes the physical size of the screen from [html.window].
  ///
  /// This function is expensive. It triggers browser layout if there are
  /// pending DOM writes.
  void _computePhysicalSize() {
    bool override = false;

    assert(() {
      if (webOnlyDebugPhysicalSizeOverride != null) {
        _physicalSize = webOnlyDebugPhysicalSizeOverride;
        override = true;
      }
      return true;
    }());

    if (!override) {
      double windowInnerWidth;
      double windowInnerHeight;
      final html.VisualViewport? viewport = html.window.visualViewport;
      if (viewport != null) {
        windowInnerWidth = viewport.width!.toDouble() * devicePixelRatio;
        windowInnerHeight = viewport.height!.toDouble() * devicePixelRatio;
      } else {
        windowInnerWidth = html.window.innerWidth! * devicePixelRatio;
        windowInnerHeight = html.window.innerHeight! * devicePixelRatio;
      }
      _physicalSize = ui.Size(
        windowInnerWidth,
        windowInnerHeight,
      );
    }
  }

  void computeOnScreenKeyboardInsets() {
    double windowInnerHeight;
    final html.VisualViewport? viewport = html.window.visualViewport;
    if (viewport != null) {
      windowInnerHeight = viewport.height!.toDouble() * devicePixelRatio;
    } else {
      windowInnerHeight = html.window.innerHeight! * devicePixelRatio;
    }
    final double bottomPadding = _physicalSize!.height - windowInnerHeight;
    _viewInsets =
        WindowPadding(bottom: bottomPadding, left: 0, right: 0, top: 0);
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
    double height = 0;
    double width = 0;
    if (html.window.visualViewport != null) {
      height =
          html.window.visualViewport!.height!.toDouble() * devicePixelRatio;
      width = html.window.visualViewport!.width!.toDouble() * devicePixelRatio;
    } else {
      height = html.window.innerHeight! * devicePixelRatio;
      width = html.window.innerWidth! * devicePixelRatio;
    }

    // This method compares the new dimensions with the previous ones.
    // Return false if the previous dimensions are not set.
    if (_physicalSize != null) {
      // First confirm both height and width are effected.
      if (_physicalSize!.height != height && _physicalSize!.width != width) {
        // If prior to rotation height is bigger than width it should be the
        // opposite after the rotation and vice versa.
        if ((_physicalSize!.height > _physicalSize!.width && height < width) ||
            (_physicalSize!.width > _physicalSize!.height && width < height)) {
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
// TODO: Add integration test https://github.com/flutter/flutter/issues/66852
@JS('_flutter_web_set_location_strategy')
// ignore: unused_element
external set _jsSetUrlStrategy(_JsSetUrlStrategy? newJsSetUrlStrategy);

UrlStrategy? _createDefaultUrlStrategy() {
  return ui.debugEmulateFlutterTesterEnvironment
      ? null
      : const HashUrlStrategy();
}

/// The Web implementation of [ui.SingletonFlutterWindow].
class EngineSingletonFlutterWindow extends EngineFlutterWindow {
  EngineSingletonFlutterWindow(Object windowId, ui.PlatformDispatcher platformDispatcher) : super(windowId, platformDispatcher);

  @override
  double get devicePixelRatio => _debugDevicePixelRatio ?? EnginePlatformDispatcher.browserDevicePixelRatio;

  /// Overrides the default device pixel ratio.
  ///
  /// This is useful in tests to emulate screens of different dimensions.
  void debugOverrideDevicePixelRatio(double value) {
    _debugDevicePixelRatio = value;
  }

  double? _debugDevicePixelRatio;
}

/// A type of [FlutterView] that can be hosted inside of a [FlutterWindow].
class EngineFlutterWindowView extends ui.FlutterWindow {
  EngineFlutterWindowView._(this._viewId, this.platformDispatcher);

  final Object _viewId;

  final ui.PlatformDispatcher platformDispatcher;

  @override
  ui.ViewConfiguration get viewConfiguration {
    final EnginePlatformDispatcher engineDispatcher = platformDispatcher as EnginePlatformDispatcher;
    assert(engineDispatcher._windowConfigurations.containsKey(_viewId));
    return engineDispatcher._windowConfigurations[_viewId] ?? ui.ViewConfiguration();
  }
}

/// The window singleton.
///
/// `dart:ui` window delegates to this value. However, this value has a wider
/// API surface, providing Web-specific functionality that the standard
/// `dart:ui` version does not.
final EngineSingletonFlutterWindow window = EngineSingletonFlutterWindow(0, EnginePlatformDispatcher.instance);

/// The Web implementation of [ui.WindowPadding].
class WindowPadding implements ui.WindowPadding {
  const WindowPadding({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  final double left;
  final double top;
  final double right;
  final double bottom;
}
