// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:developer' as developer;
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:ui/src/engine/embedder.dart';
import 'package:ui/src/engine/keyboard.dart';
import 'package:ui/src/engine/mouse_cursor.dart';
import 'package:ui/src/engine/navigation.dart';
import 'package:ui/src/engine/platform_dispatcher.dart';
import 'package:ui/src/engine/platform_views/content_manager.dart';
import 'package:ui/src/engine/profiler.dart';
import 'package:ui/src/engine/safe_browser_api.dart';
import 'package:ui/src/engine/window.dart';
import 'package:ui/ui.dart' as ui;

/// The mode the app is running in.
/// Keep these in sync with the same constants on the framework-side under foundation/constants.dart.
const bool kReleaseMode =
    bool.fromEnvironment('dart.vm.product', defaultValue: false);
/// A constant that is true if the application was compiled in profile mode.
const bool kProfileMode =
    bool.fromEnvironment('dart.vm.profile', defaultValue: false);
/// A constant that is true if the application was compiled in debug mode.
const bool kDebugMode = !kReleaseMode && !kProfileMode;
/// Returns mode of the app is running in as a string.
String get buildMode => kReleaseMode
    ? 'release'
    : kProfileMode
        ? 'profile'
        : 'debug';

/// A benchmark metric that includes frame-related computations prior to
/// submitting layer and picture operations to the underlying renderer, such as
/// HTML and CanvasKit. During this phase we compute transforms, clips, and
/// other information needed for rendering.
const String kProfilePrerollFrame = 'preroll_frame';

/// A benchmark metric that includes submitting layer and picture information
/// to the renderer.
const String kProfileApplyFrame = 'apply_frame';

bool _engineInitialized = false;

final List<ui.VoidCallback> _hotRestartListeners = <ui.VoidCallback>[];

/// Requests that [listener] is called just before hot restarting the app.
void registerHotRestartListener(ui.VoidCallback listener) {
  _hotRestartListeners.add(listener);
}

/// Pretends that hot restart is about to happen.
///
/// Useful in tests to check that the engine performs appropriate clean-ups,
/// such as removing static DOM listeners, prior to allowing the Dart runtime
/// to re-initialize the program.
void debugEmulateHotRestart() {
  for (final ui.VoidCallback listener in _hotRestartListeners) {
    listener();
  }
}

/// This method performs one-time initialization of the Web environment that
/// supports the Flutter framework.
///
/// This is only available on the Web, as native Flutter configures the
/// environment in the native embedder.
void initializeEngine() {
  if (_engineInitialized) {
    return;
  }

  // Setup the hook that allows users to customize URL strategy before running
  // the app.
  _addUrlStrategyListener();

  // Called by the Web runtime just before hot restarting the app.
  //
  // This extension cleans up resources that are registered with browser's
  // global singletons that Dart compiler is unable to clean-up automatically.
  //
  // This extension does not need to clean-up Dart statics. Those are cleaned
  // up by the compiler.
  developer.registerExtension('ext.flutter.disassemble', (_, __) {
    for (final ui.VoidCallback listener in _hotRestartListeners) {
      listener();
    }
    return Future<developer.ServiceExtensionResponse>.value(
        developer.ServiceExtensionResponse.result('OK'));
  });

  _engineInitialized = true;

  // Initialize the FlutterViewEmbedder before initializing framework bindings.
  ensureFlutterViewEmbedderInitialized();

  if (Profiler.isBenchmarkMode) {
    Profiler.ensureInitialized();
  }

  bool waitingForAnimation = false;
  scheduleFrameCallback = () {
    // We're asked to schedule a frame and call `frameHandler` when the frame
    // fires.
    if (!waitingForAnimation) {
      waitingForAnimation = true;
      html.window.requestAnimationFrame((num highResTime) {
        frameTimingsOnVsync();

        // Reset immediately, because `frameHandler` can schedule more frames.
        waitingForAnimation = false;

        // We have to convert high-resolution time to `int` so we can construct
        // a `Duration` out of it. However, high-res time is supplied in
        // milliseconds as a double value, with sub-millisecond information
        // hidden in the fraction. So we first multiply it by 1000 to uncover
        // microsecond precision, and only then convert to `int`.
        final int highResTimeMicroseconds = (1000 * highResTime).toInt();

        // In Flutter terminology "building a frame" consists of "beginning
        // frame" and "drawing frame".
        //
        // We do not call `frameTimingsOnBuildFinish` from here because
        // part of the rasterization process, particularly in the HTML
        // renderer, takes place in the `SceneBuilder.build()`.
        frameTimingsOnBuildStart();
        if (EnginePlatformDispatcher.instance.onBeginFrame != null) {
          EnginePlatformDispatcher.instance.invokeOnBeginFrame(
              Duration(microseconds: highResTimeMicroseconds));
        }

        if (EnginePlatformDispatcher.instance.onDrawFrame != null) {
          // TODO(yjbanov): technically Flutter flushes microtasks between
          //                onBeginFrame and onDrawFrame. We don't, which hasn't
          //                been an issue yet, but eventually we'll have to
          //                implement it properly.
          EnginePlatformDispatcher.instance.invokeOnDrawFrame();
        }
      });
    }
  };

  Keyboard.initialize();
  MouseCursor.initialize();
}

void _addUrlStrategyListener() {
  jsSetUrlStrategy = allowInterop((JsUrlStrategy? jsStrategy) {
    customUrlStrategy =
        jsStrategy == null ? null : CustomUrlStrategy.fromJs(jsStrategy);
  });
  registerHotRestartListener(() {
    jsSetUrlStrategy = null;
  });
}

/// The shared instance of PlatformViewManager shared across the engine to handle
/// rendering of PlatformViews into the web app.
// TODO(dit): How to make this overridable from tests?
final PlatformViewManager platformViewManager = PlatformViewManager();

/// Converts a matrix represented using [Float64List] to one represented using
/// [Float32List].
///
/// 32-bit precision is sufficient because Flutter Engine itself (as well as
/// Skia) use 32-bit precision under the hood anyway.
///
/// 32-bit matrices require 2x less memory and in V8 they are allocated on the
/// JavaScript heap, thus avoiding a malloc.
///
/// See also:
/// * https://bugs.chromium.org/p/v8/issues/detail?id=9199
/// * https://bugs.chromium.org/p/v8/issues/detail?id=2022
Float32List toMatrix32(Float64List matrix64) {
  final Float32List matrix32 = Float32List(16);
  matrix32[15] = matrix64[15];
  matrix32[14] = matrix64[14];
  matrix32[13] = matrix64[13];
  matrix32[12] = matrix64[12];
  matrix32[11] = matrix64[11];
  matrix32[10] = matrix64[10];
  matrix32[9] = matrix64[9];
  matrix32[8] = matrix64[8];
  matrix32[7] = matrix64[7];
  matrix32[6] = matrix64[6];
  matrix32[5] = matrix64[5];
  matrix32[4] = matrix64[4];
  matrix32[3] = matrix64[3];
  matrix32[2] = matrix64[2];
  matrix32[1] = matrix64[1];
  matrix32[0] = matrix64[0];
  return matrix32;
}
