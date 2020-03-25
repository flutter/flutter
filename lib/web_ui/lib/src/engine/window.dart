// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
part of engine;

/// When set to true, all platform messages will be printed to the console.
const bool _debugPrintPlatformMessages = false;

/// The Web implementation of [ui.Window].
class EngineWindow extends ui.Window {
  EngineWindow() {
    _addBrightnessMediaQueryListener();
  }

  @override
  double get devicePixelRatio => _debugDevicePixelRatio != null
      ? _debugDevicePixelRatio
      : browserDevicePixelRatio;

  /// Returns device pixel ratio returned by browser.
  static double get browserDevicePixelRatio {
    double ratio = html.window.devicePixelRatio;
    // Guard against WebOS returning 0.
    return (ratio == null || ratio == 0.0) ? 1.0 : ratio;
  }

  /// Overrides the default device pixel ratio.
  ///
  /// This is useful in tests to emulate screens of different dimensions.
  void debugOverrideDevicePixelRatio(double value) {
    _debugDevicePixelRatio = value;
  }

  double _debugDevicePixelRatio;

  @override
  ui.Size get physicalSize {
    if (_physicalSize == null) {
      _computePhysicalSize();
    }
    assert(_physicalSize != null);
    return _physicalSize;
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
      if (html.window.visualViewport != null) {
        windowInnerWidth = html.window.visualViewport.width * devicePixelRatio;
        windowInnerHeight =
            html.window.visualViewport.height * devicePixelRatio;
      } else {
        windowInnerWidth = html.window.innerWidth * devicePixelRatio;
        windowInnerHeight = html.window.innerHeight * devicePixelRatio;
      }
      _physicalSize = ui.Size(
        windowInnerWidth,
        windowInnerHeight,
      );
    }
  }

  /// Lazily populated and cleared at the end of the frame.
  ui.Size _physicalSize;

  /// Overrides the value of [physicalSize] in tests.
  ui.Size webOnlyDebugPhysicalSizeOverride;

  @override
  double get physicalDepth => double.maxFinite;

  /// Handles the browser history integration to allow users to use the back
  /// button, etc.
  final BrowserHistory _browserHistory = BrowserHistory();

  /// Simulates clicking the browser's back button.
  Future<void> webOnlyBack() => _browserHistory.back();

  /// Lazily initialized when the `defaultRouteName` getter is invoked.
  ///
  /// The reason for the lazy initialization is to give enough time for the app to set [locationStrategy]
  /// in `lib/src/ui/initialization.dart`.
  String _defaultRouteName;

  @override
  String get defaultRouteName => _defaultRouteName ??= _browserHistory.currentPath;

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
            _replyToPlatformMessage(callback, codec.encodeSuccessEnvelope(true));
            return;
          case 'SystemChrome.setApplicationSwitcherDescription':
            final Map<String, dynamic> arguments = decoded.arguments;
            domRenderer.setTitle(arguments['label']);
            domRenderer.setThemeColor(ui.Color(arguments['primaryColor']));
            _replyToPlatformMessage(callback, codec.encodeSuccessEnvelope(true));
            return;
          case 'SystemSound.play':
            // There are no default system sounds on web.
            _replyToPlatformMessage(callback, codec.encodeSuccessEnvelope(true));
            return;
          case 'Clipboard.setData':
            ClipboardMessageHandler().setDataMethodCall(decoded, callback);
            _replyToPlatformMessage(callback, codec.encodeSuccessEnvelope(true));
            return;
          case 'Clipboard.getData':
            ClipboardMessageHandler().getDataMethodCall(callback);
            _replyToPlatformMessage(callback, codec.encodeSuccessEnvelope(true));
            return;
        }
        break;

      case 'flutter/textinput':
        textEditing.channel.handleTextInput(data, callback);
        return;

      case 'flutter/web_test_e2e':
        const MethodCodec codec = JSONMethodCodec();
        _replyToPlatformMessage(callback, codec.encodeSuccessEnvelope(
          _handleWebTestEnd2EndMessage(codec, data)
        ));
        return;

      case 'flutter/platform_views':
        if (experimentalUseSkia) {
          rasterizer.viewEmbedder.handlePlatformViewCall(data, callback);
        } else {
          handlePlatformViewCall(data, callback);
        }
        return;

      case 'flutter/accessibility':
        // In widget tests we want to bypass processing of platform messages.
        final StandardMessageCodec codec = StandardMessageCodec();
        accessibilityAnnouncements.handleMessage(codec, data);
        _replyToPlatformMessage(callback, codec.encodeMessage(true));
        return;

      case 'flutter/navigation':
        const MethodCodec codec = JSONMethodCodec();
        final MethodCall decoded = codec.decodeMethodCall(data);
        final Map<String, dynamic> message = decoded.arguments;
        switch (decoded.method) {
          case 'routeUpdated':
          case 'routePushed':
          case 'routeReplaced':
            _browserHistory.setRouteName(message['routeName']);
            _replyToPlatformMessage(callback, codec.encodeSuccessEnvelope(true));
            break;
          case 'routePopped':
            _browserHistory.setRouteName(message['previousRouteName']);
            _replyToPlatformMessage(callback, codec.encodeSuccessEnvelope(true));
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
      if (callback != null) {
        callback(data);
      }
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
      rasterizer.draw(layerScene.layerTree);
    } else {
      final SurfaceScene surfaceScene = scene;
      domRenderer.renderScene(surfaceScene.webOnlyRootElement);
    }
  }

  @visibleForTesting
  Rasterizer rasterizer = experimentalUseSkia ? Rasterizer(Surface()) : null;
}

bool _handleWebTestEnd2EndMessage(MethodCodec codec, ByteData data) {
  final MethodCall decoded = codec.decodeMethodCall(data);
  final Map<String, dynamic> message = decoded.arguments;
  double ratio = double.parse(decoded.arguments);
  bool result = false;
  switch(decoded.method) {
    case 'setDevicePixelRatio':
      window.debugOverrideDevicePixelRatio(ratio);
      window.onMetricsChanged();
      return true;
  }
  return false;
}

/// The window singleton.
///
/// `dart:ui` window delegates to this value. However, this value has a wider
/// API surface, providing Web-specific functionality that the standard
/// `dart:ui` version does not.
final EngineWindow window = EngineWindow();
