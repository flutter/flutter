// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of engine;

/// When set to true, all platform messages will be printed to the console.
const bool _debugPrintPlatformMessages = false;

/// The Web implementation of [ui.Window].
class EngineWindow extends ui.Window {
  @override
  double get devicePixelRatio => _devicePixelRatio;

  /// Overrides the default device pixel ratio.
  ///
  /// This is useful in tests to emulate screens of different dimensions.
  void debugOverrideDevicePixelRatio(double value) {
    assert(() {
      _devicePixelRatio = value;
      return true;
    }());
  }

  double _devicePixelRatio = 1.0;

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
      final int windowInnerWidth = html.window.innerWidth;
      final int windowInnerHeight = html.window.innerHeight;
      if (windowInnerWidth != _lastKnownWindowInnerWidth ||
          windowInnerHeight != _lastKnownWindowInnerHeight) {
        _lastKnownWindowInnerWidth = windowInnerWidth;
        _lastKnownWindowInnerHeight = windowInnerHeight;
        _physicalSize = ui.Size(
          windowInnerWidth.toDouble(),
          windowInnerHeight.toDouble(),
        );
      }
    }

    return _physicalSize;
  }

  ui.Size _physicalSize = ui.Size.zero;
  int _lastKnownWindowInnerWidth = -1;
  int _lastKnownWindowInnerHeight = -1;

  /// Overrides the value of [physicalSize] in tests.
  ui.Size webOnlyDebugPhysicalSizeOverride;

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
  set webOnlyLocationStrategy(LocationStrategy strategy) {
    _browserHistory.locationStrategy = strategy;
  }

  /// This setter is used by [WebNavigatorObserver] to update the url to
  /// reflect the [Navigator]'s current route name.
  set webOnlyRouteName(String routeName) {
    _browserHistory.setRouteName(routeName);
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
        }
        break;

      case 'flutter/textinput':
        textEditing.handleTextInput(data);
        return;

      case 'flutter/platform_views':
        handlePlatformViewCall(data, callback);
        return;

      case 'flutter/accessibility':
        // In widget tests we want to bypass processing of platform messages.
        accessibilityAnnouncements.handleMessage(data);
        break;
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
}

/// The window singleton.
///
/// `dart:ui` window delegates to this value. However, this value has a wider
/// API surface, providing Web-specific functionality that the standard
/// `dart:ui` version does not.
final EngineWindow window = EngineWindow();
