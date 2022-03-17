// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of ui;

Future<void> webOnlyInitializePlatform({
  engine.AssetManager? assetManager,
}) {
  final Future<void> initializationFuture =
      _initializePlatform(assetManager: assetManager);
  scheduleMicrotask(() {
    // Access [engine.lineLookup] to force the lazy unpacking of line break data
    // now. Removing this line won't break anything. It's just an optimization
    // to make the unpacking happen while we are waiting for network requests.
    engine.lineLookup;
  });
  return initializationFuture;
}

Future<void> _initializePlatform({
  engine.AssetManager? assetManager,
}) async {
  engine.initializeEngine();

  // This needs to be after `webOnlyInitializeEngine` because that is where the
  // canvaskit script is added to the page.
  if (engine.useCanvasKit) {
    await engine.initializeCanvasKit();
  }

  assetManager ??= const engine.AssetManager();
  await webOnlySetAssetManager(assetManager);
  if (engine.useCanvasKit) {
    await engine.skiaFontCollection.ensureFontsLoaded();
  } else {
    await _fontCollection!.ensureFontsLoaded();
  }

  _webOnlyIsInitialized = true;
}

// TODO(yjbanov): can we make this late non-null? See https://github.com/dart-lang/sdk/issues/42214
engine.AssetManager? _assetManager;
engine.FontCollection? _fontCollection;

bool _webOnlyIsInitialized = false;
bool get webOnlyIsInitialized => _webOnlyIsInitialized;
Future<void> webOnlySetAssetManager(engine.AssetManager assetManager) async {
  // ignore: unnecessary_null_comparison
  assert(assetManager != null,
      'Cannot set assetManager to null');
  if (assetManager == _assetManager) {
    return;
  }

  _assetManager = assetManager;

  if (engine.useCanvasKit) {
    engine.ensureSkiaFontCollectionInitialized();
  } else {
    _fontCollection ??= engine.FontCollection();
    _fontCollection!.clear();
  }

  if (_assetManager != null) {
    if (engine.useCanvasKit) {
      await engine.skiaFontCollection.registerFonts(_assetManager!);
    } else {
      await _fontCollection!.registerFonts(_assetManager!);
    }
  }

  if (debugEmulateFlutterTesterEnvironment) {
    if (engine.useCanvasKit) {
      engine.skiaFontCollection.debugRegisterTestFonts();
    } else {
      _fontCollection!.debugRegisterTestFonts();
    }
  }
}

bool get debugEmulateFlutterTesterEnvironment =>
    _debugEmulateFlutterTesterEnvironment;

set debugEmulateFlutterTesterEnvironment(bool value) {
  _debugEmulateFlutterTesterEnvironment = value;
  if (_debugEmulateFlutterTesterEnvironment) {
    const Size logicalSize = Size(800.0, 600.0);
    engine.window.webOnlyDebugPhysicalSizeOverride =
        logicalSize * window.devicePixelRatio;
  }
}

bool _debugEmulateFlutterTesterEnvironment = false;
engine.AssetManager get webOnlyAssetManager => _assetManager!;
engine.FontCollection get webOnlyFontCollection => _fontCollection!;

/// Provides a compile time constant to customize flutter framework and other
/// users of ui engine for web runtime.
const bool isWeb = true;

/// Web specific SMI. Used by bitfield. The 0x3FFFFFFFFFFFFFFF used on VM
/// is not supported on Web platform.
const int kMaxUnsignedSMI = -1;

void webOnlyInitializeEngine() {
  engine.initializeEngine();
}

void webOnlySetPluginHandler(Future<void> Function(String, ByteData?, PlatformMessageResponseCallback?) handler) {
  engine.pluginMessageCallHandler = handler;
}

// TODO(yjbanov): The code below was temporarily moved from lib/web_ui/lib/src/engine/platform_views.dart
//                during the NNBD migration so that `dart:ui` does not have to export `dart:_engine`. NNBD
//                does not allow exported non-migrated libraries from migrated libraries. When `dart:_engine`
//                is migrated, we can move it back.

/// A function which takes a unique `id` and creates an HTML element.
typedef PlatformViewFactory = html.Element Function(int viewId);

/// A registry for factories that create platform views.
class PlatformViewRegistry {
  /// Register [viewTypeId] as being creating by the given [factory].
  bool registerViewFactory(String viewTypeId, PlatformViewFactory viewFactory,
      {bool isVisible = true}) {
    // TODO(web): Deprecate this once there's another way of calling `registerFactory` (js interop?)
    return engine.platformViewManager
        .registerFactory(viewTypeId, viewFactory, isVisible: isVisible);
  }
}

/// The platform view registry for this app.
final PlatformViewRegistry platformViewRegistry = PlatformViewRegistry();

// TODO(yjbanov): remove _Callback, _Callbacker, and _futurize. They are here only
//                because the analyzer wasn't able to infer the correct types during
//                NNBD migration.
typedef _Callback<T> = void Function(T result);
typedef _Callbacker<T> = String? Function(_Callback<T> callback);

// Note: this function is not directly tested so that it remains private, instead an exact
// copy of it has been inlined into the test at lib/ui/fixtures/ui_test.dart. if you change
// this function, then you  must update the test.
Future<T> _futurize<T>(_Callbacker<T> callbacker) {
  final Completer<T> completer = Completer<T>.sync();
  // If the callback synchronously throws an error, then synchronously
  // rethrow that error instead of adding it to the completer. This
  // prevents the Zone from receiving an uncaught exception.
  bool sync = true;
  final String? error = callbacker((T? t) {
    if (t == null) {
      if (sync) {
        throw Exception('operation failed');
      } else {
        completer.completeError(Exception('operation failed'));
      }
    } else {
      completer.complete(t);
    }
  });
  sync = false;
  if (error != null) {
    throw Exception(error);
  }
  return completer.future;
}
