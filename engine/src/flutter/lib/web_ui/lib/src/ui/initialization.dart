// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.12
part of ui;

Future<void> webOnlyInitializePlatform({
  engine.AssetManager? assetManager,
}) {
  final Future<void> initializationFuture = _initializePlatform(assetManager: assetManager);
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
  assert(assetManager != null, 'Cannot set assetManager to null'); // ignore: unnecessary_null_comparison
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

  if (debugEmulateFlutterTesterEnvironment && !engine.useCanvasKit) {
    _fontCollection!.debugRegisterTestFonts();
  }
}

bool get debugEmulateFlutterTesterEnvironment => _debugEmulateFlutterTesterEnvironment;

set debugEmulateFlutterTesterEnvironment(bool value) {
  _debugEmulateFlutterTesterEnvironment = value;
  if (_debugEmulateFlutterTesterEnvironment) {
    const Size logicalSize = Size(800.0, 600.0);
    engine.window.webOnlyDebugPhysicalSizeOverride = logicalSize * window.devicePixelRatio;
  }
}

bool _debugEmulateFlutterTesterEnvironment = false;
engine.AssetManager get webOnlyAssetManager => _assetManager!;
engine.FontCollection get webOnlyFontCollection => _fontCollection!;
