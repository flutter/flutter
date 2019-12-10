// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of engine;

/// When set to true, all platform messages will be printed to the console.
const bool _debugPrintPlatformMessages = false;

/// The Web implementation of [ui.Window].
class EngineWindow extends ui.Window {
  EngineWindow() {
    _addBrightnessMediaQueryListener();
  }

  @override
  double get devicePixelRatio {
    if (_debugDevicePixelRatio != null) {
      return _debugDevicePixelRatio;
    }

    if (experimentalUseSkia) {
      return html.window.devicePixelRatio;
    } else {
      return 1.0;
    }
  }

  /// Overrides the default device pixel ratio.
  ///
  /// This is useful in tests to emulate screens of different dimensions.
  void debugOverrideDevicePixelRatio(double value) {
    assert(() {
      _debugDevicePixelRatio = value;
      return true;
    }());
  }

  double _debugDevicePixelRatio;

  @override
  ui.Size get physicalSize {
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
      if (html.window.visualViewport != null) {
        windowInnerWidth = html.window.visualViewport.width * devicePixelRatio;
        windowInnerHeight =
            html.window.visualViewport.height * devicePixelRatio;
      } else {
        windowInnerWidth = html.window.innerWidth * devicePixelRatio;
        windowInnerHeight = html.window.innerHeight * devicePixelRatio;
      }
      if (windowInnerWidth != _lastKnownWindowInnerWidth ||
          windowInnerHeight != _lastKnownWindowInnerHeight) {
        _lastKnownWindowInnerWidth = windowInnerWidth;
        _lastKnownWindowInnerHeight = windowInnerHeight;
        _physicalSize = ui.Size(
          windowInnerWidth,
          windowInnerHeight,
        );
      }
    }

    return _physicalSize;
  }

  ui.Size _physicalSize = ui.Size.zero;
  double _lastKnownWindowInnerWidth = -1;
  double _lastKnownWindowInnerHeight = -1;

  /// Overrides the value of [physicalSize] in tests.
  ui.Size webOnlyDebugPhysicalSizeOverride;

  @override
  double get physicalDepth => double.maxFinite;

  /// Handles the browser history integration to allow users to use the back
  /// button, etc.
  final BrowserHistory _browserHistory = BrowserHistory();

  /// Simulates clicking the browser's back button.
  Future<void> webOnlyBack() => _browserHistory.back();

  @override
  String get defaultRouteName => _browserHistory.currentPath;

  /// Change the strategy to use for handling browser history location.
  /// Setting this member will automatically update [_browserHistory].
  ///
  /// By setting this to null, the browser history will be disabled.
  set locationStrategy(LocationStrategy strategy) {
    _browserHistory.locationStrategy = strategy;
  }

  @override
  void sendPlatformMessage(
    String name,
    ByteData data,
    ui.PlatformMessageResponseCallback callback,
  ) {
    // In widget tests we want to bypass processing of platform messages.
    if (assertionsEnabled && ui.debugEmulateFlutterTesterEnvironment) {
      return;
    }
    if (_debugPrintPlatformMessages) {
      print('Sent platform message on channel: "$name"');
    }
    switch (name) {
      case 'flutter/assets':
        assert(ui.webOnlyAssetManager != null);
        final String url = utf8.decode(data.buffer.asUint8List());
        ui.webOnlyAssetManager.load(url).then((ByteData assetData) {
          _replyToPlatformMessage(callback, assetData);
        }, onError: (dynamic error) {
          html.window.console
              .warn('Error while trying to load an asset: $error');
          _replyToPlatformMessage(callback, null);
        });
        return;

      case 'flutter/platform':
        const MethodCodec codec = JSONMethodCodec();
        final MethodCall decoded = codec.decodeMethodCall(data);
        switch (decoded.method) {
          case 'SystemNavigator.pop':
            _browserHistory.exit().then((_) {
              _replyToPlatformMessage(
                  callback, codec.encodeSuccessEnvelope(true));
            });
            return;
          case 'HapticFeedback.vibrate':
            final String type = decoded.arguments;
            domRenderer.vibrate(_getHapticFeedbackDuration(type));
            return;
          case 'SystemChrome.setApplicationSwitcherDescription':
            final Map<String, dynamic> arguments = decoded.arguments;
            domRenderer.setTitle(arguments['label']);
            domRenderer.setThemeColor(ui.Color(arguments['primaryColor']));
            return;
          case 'SystemSound.play':
            // There are no default system sounds on web.
            return;
        }
        break;

      case 'flutter/textinput':
        textEditing.handleTextInput(data);
        return;

      case 'flutter/platform_views':
        if (experimentalUseSkia) {
          _rasterizer.viewEmbedder.handlePlatformViewCall(data, callback);
        } else {
          handlePlatformViewCall(data, callback);
        }
        return;

      case 'flutter/accessibility':
        // In widget tests we want to bypass processing of platform messages.
        accessibilityAnnouncements.handleMessage(data);
        return;

      case 'flutter/navigation':
        const MethodCodec codec = JSONMethodCodec();
        final MethodCall decoded = codec.decodeMethodCall(data);
        final Map<String, dynamic> message = decoded.arguments;
        switch (decoded.method) {
          case 'routePushed':
          case 'routeReplaced':
            _browserHistory.setRouteName(message['routeName']);
            break;
          case 'routePopped':
            _browserHistory.setRouteName(message['previousRouteName']);
            break;
        }
        return;
    }

    if (pluginMessageCallHandler != null) {
      pluginMessageCallHandler(name, data, callback);
      return;
    }

    // TODO(flutter_web): Some Flutter widgets send platform messages that we
    // don't handle on web. So for now, let's just ignore them. In the future,
    // we should consider uncommenting the following "callback(null)" line.

    // Passing [null] to [callback] indicates that the platform message isn't
    // implemented. Look at [MethodChannel.invokeMethod] to see how [null] is
    // handled.
    // callback(null);
  }

  int _getHapticFeedbackDuration(String type) {
    switch (type) {
      case 'HapticFeedbackType.lightImpact':
        return DomRenderer.vibrateLightImpact;
      case 'HapticFeedbackType.mediumImpact':
        return DomRenderer.vibrateMediumImpact;
      case 'HapticFeedbackType.heavyImpact':
        return DomRenderer.vibrateHeavyImpact;
      case 'HapticFeedbackType.selectionClick':
        return DomRenderer.vibrateSelectionClick;
      default:
        return DomRenderer.vibrateLongPress;
    }
  }

  /// In Flutter, platform messages are exchanged between threads so the
  /// messages and responses have to be exchanged asynchronously. We simulate
  /// that by adding a zero-length delay to the reply.
  void _replyToPlatformMessage(
    ui.PlatformMessageResponseCallback callback,
    ByteData data,
  ) {
    Future<void>.delayed(Duration.zero).then((_) {
      callback(data);
    });
  }

  @override
  ui.Brightness get platformBrightness => _platformBrightness;
  ui.Brightness _platformBrightness = ui.Brightness.light;

  /// Updates [_platformBrightness] and invokes [onPlatformBrightnessChanged]
  /// callback if [_platformBrightness] changed.
  void _updatePlatformBrightness(ui.Brightness newPlatformBrightness) {
    ui.Brightness previousPlatformBrightness = _platformBrightness;
    _platformBrightness = newPlatformBrightness;

    if (previousPlatformBrightness != _platformBrightness &&
        onPlatformBrightnessChanged != null) onPlatformBrightnessChanged();
  }

  /// Reference to css media query that indicates the user theme preference on the web.
  final html.MediaQueryList _brightnessMediaQuery =
      html.window.matchMedia('(prefers-color-scheme: dark)');

  /// A callback that is invoked whenever [_brightnessMediaQuery] changes value.
  ///
  /// Updates the [_platformBrightness] with the new user preference.
  html.EventListener _brightnessMediaQueryListener;

  /// Set the callback function for listening changes in [_brightnessMediaQuery] value.
  void _addBrightnessMediaQueryListener() {
    _updatePlatformBrightness(_brightnessMediaQuery.matches
        ? ui.Brightness.dark
        : ui.Brightness.light);

    _brightnessMediaQueryListener = (html.Event event) {
      final html.MediaQueryListEvent mqEvent = event;
      _updatePlatformBrightness(
          mqEvent.matches ? ui.Brightness.dark : ui.Brightness.light);
    };
    _brightnessMediaQuery.addListener(_brightnessMediaQueryListener);
    registerHotRestartListener(() {
      _removeBrightnessMediaQueryListener();
    });
  }

  /// Remove the callback function for listening changes in [_brightnessMediaQuery] value.
  void _removeBrightnessMediaQueryListener() {
    _brightnessMediaQuery.removeListener(_brightnessMediaQueryListener);
    _brightnessMediaQueryListener = null;
  }

  @override
  void render(ui.Scene scene) {
    if (experimentalUseSkia) {
      final LayerScene layerScene = scene;
      _rasterizer.draw(layerScene.layerTree);
    } else {
      final SurfaceScene surfaceScene = scene;
      domRenderer.renderScene(surfaceScene.webOnlyRootElement);
    }
  }

  final Rasterizer _rasterizer =
      experimentalUseSkia ? Rasterizer(Surface()) : null;
}

/// The window singleton.
///
/// `dart:ui` window delegates to this value. However, this value has a wider
/// API surface, providing Web-specific functionality that the standard
/// `dart:ui` version does not.
final EngineWindow window = EngineWindow();
