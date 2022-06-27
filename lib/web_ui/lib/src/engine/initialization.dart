// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:developer' as developer;

import 'package:ui/src/engine/assets.dart';
import 'package:ui/src/engine/browser_detection.dart';
import 'package:ui/src/engine/canvaskit/initialization.dart';
import 'package:ui/src/engine/embedder.dart';
import 'package:ui/src/engine/keyboard.dart';
import 'package:ui/src/engine/mouse_cursor.dart';
import 'package:ui/src/engine/navigation.dart';
import 'package:ui/src/engine/platform_dispatcher.dart';
import 'package:ui/src/engine/platform_views/content_manager.dart';
import 'package:ui/src/engine/profiler.dart';
import 'package:ui/src/engine/safe_browser_api.dart';
import 'package:ui/src/engine/text/font_collection.dart';
import 'package:ui/src/engine/text/line_break_properties.dart';
import 'package:ui/src/engine/window.dart';
import 'package:ui/ui.dart' as ui;

import 'dom.dart';

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

/// Fully initializes the engine, including services and UI.
Future<void> initializeEngine({
  AssetManager? assetManager,
}) async {
  await initializeEngineServices(assetManager: assetManager);
  await initializeEngineUi();
}

/// How far along the initialization process the engine is currently is.
///
/// The initialization process starts with [none] and proceeds in increasing
/// `index` number until [initialized].
enum DebugEngineInitializationState {
  /// Initialization hasn't started yet.
  uninitialized,

  /// The engine is initializing its non-UI services.
  initializingServices,

  /// The engine has initialized its non-UI services, but hasn't started
  /// initializing the UI.
  initializedServices,

  /// The engine started attaching UI surfaces to the web page.
  initializingUi,

  /// The engine has fully completed initialization.
  ///
  /// At this point the framework can start using the engine for I/O, rendering,
  /// etc.
  ///
  /// This is the final state of the engine.
  initialized,
}

/// The current initialization state of the engine.
///
/// See [DebugEngineInitializationState] for possible states.
DebugEngineInitializationState get initializationState => _initializationState;
DebugEngineInitializationState _initializationState = DebugEngineInitializationState.uninitialized;

/// Resets the state back to [DebugEngineInitializationState.uninitialized].
///
/// This is for testing only.
void debugResetEngineInitializationState() {
  _initializationState = DebugEngineInitializationState.uninitialized;
}

/// Initializes non-UI engine services.
///
/// Does not put any UI onto the page. It is therefore safe to call this
/// function while the page is showing non-Flutter UI, such as a loading
/// indicator, a splash screen, or in an add-to-app scenario where the host page
/// is written using a different web framework.
///
/// See also:
///
///  * [initializeEngineUi], which is typically called after this function, and
///    puts UI elements on the page.
Future<void> initializeEngineServices({
  AssetManager? assetManager,
}) async {
  if (_initializationState != DebugEngineInitializationState.uninitialized) {
    assert(() {
      throw StateError(
        'Invalid engine initialization state. `initializeEngineServices` was '
        'called, but the engine has already started initialization and is '
        'currently in state "$_initializationState".'
      );
    }());
    return;
  }
  _initializationState = DebugEngineInitializationState.initializingServices;

  if (!useCanvasKit) {
    scheduleMicrotask(() {
      // Access [lineLookup] to force the lazy unpacking of line break data
      // now. Removing this line won't break anything. It's just an optimization
      // to make the unpacking happen while we are waiting for network requests.
      lineLookup;
    });
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

  if (Profiler.isBenchmarkMode) {
    Profiler.ensureInitialized();
  }

  bool waitingForAnimation = false;
  scheduleFrameCallback = () {
    // We're asked to schedule a frame and call `frameHandler` when the frame
    // fires.
    if (!waitingForAnimation) {
      waitingForAnimation = true;
      domWindow.requestAnimationFrame(allowInterop((num highResTime) {
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
      }));
    }
  };

  // This needs to be after `initializeEngine` because that is where the
  // canvaskit script is added to the page.
  if (useCanvasKit) {
    await initializeCanvasKit();
  }

  assetManager ??= const AssetManager();
  await _setAssetManager(assetManager);
  if (useCanvasKit) {
    await skiaFontCollection.ensureFontsLoaded();
  } else {
    await _fontCollection!.ensureFontsLoaded();
  }
  _initializationState = DebugEngineInitializationState.initializedServices;
}

/// Initializes the UI surfaces for the Flutter framework to render to.
///
/// Must be called after [initializeEngineServices].
///
/// This function will start altering the HTML structure of the page. If used
/// in an add-to-app scenario, the host page is expected to prepare for Flutter
/// UI appearing on screen prior to calling this function.
Future<void> initializeEngineUi() async {
  if (_initializationState != DebugEngineInitializationState.initializedServices) {
    assert(() {
      throw StateError(
        'Invalid engine initialization state. `initializeEngineUi` was '
        'called while the engine initialization state was '
        '"$_initializationState". `initializeEngineUi` can only be called '
        'when the engine is in state '
        '"${DebugEngineInitializationState.initializedServices}".'
      );
    }());
    return;
  }
  _initializationState = DebugEngineInitializationState.initializingUi;

  Keyboard.initialize(onMacOs: operatingSystem == OperatingSystem.macOs);
  MouseCursor.initialize();
  ensureFlutterViewEmbedderInitialized();
  _initializationState = DebugEngineInitializationState.initialized;
}

AssetManager get assetManager => _assetManager!;
AssetManager? _assetManager;

FontCollection get fontCollection => _fontCollection!;
FontCollection? _fontCollection;

Future<void> _setAssetManager(AssetManager assetManager) async {
  // ignore: unnecessary_null_comparison
  assert(assetManager != null, 'Cannot set assetManager to null');
  if (assetManager == _assetManager) {
    return;
  }

  _assetManager = assetManager;

  if (useCanvasKit) {
    ensureSkiaFontCollectionInitialized();
  } else {
    _fontCollection ??= FontCollection();
    _fontCollection!.clear();
  }

  if (_assetManager != null) {
    if (useCanvasKit) {
      await skiaFontCollection.registerFonts(_assetManager!);
    } else {
      await _fontCollection!.registerFonts(_assetManager!);
    }
  }

  if (ui.debugEmulateFlutterTesterEnvironment) {
    if (useCanvasKit) {
      skiaFontCollection.debugRegisterTestFonts();
    } else {
      _fontCollection!.debugRegisterTestFonts();
    }
  }
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
