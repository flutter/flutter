// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

part of flutter_gpu;

base class ShaderLibrary extends NativeFieldWrapperClass1 {
  /// Loads the shader bundle at [assetName] and returns its [ShaderLibrary],
  /// or `null` if the bundle could not be parsed.
  ///
  /// This is async so it can work on every platform. Some platforms can only
  /// read assets asynchronously, so loading is async everywhere for a
  /// consistent API. On platforms that can read synchronously the returned
  /// [Future] still completes in the same turn. A load failure is reported
  /// through the [Future] rather than thrown synchronously.
  ///
  /// The library is cached by [assetName], so repeated loads of the same
  /// asset return the same instance. The cache also backs hot reload (see
  /// [reinitialize]), which looks the library up by asset path.
  static Future<ShaderLibrary?> fromAsset(String assetName) async {
    final cached = _registry[assetName];
    if (cached != null) {
      return cached;
    }
    final lib = ShaderLibrary._();
    final error = lib._initializeWithAsset(assetName);
    if (error != null) {
      throw Exception("Failed to initialize ShaderLibrary: ${error}");
    }
    _registry[assetName] = lib;
    assert(() {
      _ensureHooksRegistered();
      return true;
    }());
    return lib;
  }

  /// Loads a [ShaderLibrary] directly from a shader bundle's [bytes] (the
  /// contents of a `.shaderbundle` compiled by `impellerc`), rather than from a
  /// bundled asset. This suits shader bundles produced or fetched at runtime,
  /// which have no entry in the asset manifest that [fromAsset] resolves.
  ///
  /// Async to match [fromAsset] and keep one entry point across platforms; on
  /// native the [Future] still completes in the same turn. Throws through the
  /// [Future] if [bytes] is not a parseable shader bundle.
  ///
  /// Unlike [fromAsset], the result is not cached (the bytes carry no stable
  /// key), so the asset-path hot reload does not apply. The caller owns the
  /// returned library and can refresh it in place with [reinitializeFromBytes]
  /// (for example after recompiling the source).
  static Future<ShaderLibrary?> fromBytes(ByteData bytes) async {
    final lib = ShaderLibrary._();
    final error = lib._initializeWithBytes(bytes);
    if (error != null) {
      throw Exception("Failed to initialize ShaderLibrary: ${error}");
    }
    assert(() {
      _ensureHooksRegistered();
      return true;
    }());
    return lib;
  }

  // Cache of libraries keyed by asset path. Holds strong references so the
  // native engine retains the registered shader functions (and any pipelines
  // built from them) for the lifetime of the isolate. Also the lookup table
  // the hot reload service extension uses to find the library to re-fetch.
  static final Map<String, ShaderLibrary> _registry = <String, ShaderLibrary>{};

  ShaderLibrary._();

  // Hold a Dart-side reference to shaders in the library as they're wrapped
  // for the first time. This prevents the wrapper from getting prematurely
  // destroyed.
  final Map<String, Shader?> shaders_ = {};

  Shader? operator [](String shaderName) {
    // This `flutter_gpu` library isn't always registered as part of the
    // builtin DartClassLibrary, and so we can't instantiate the Dart classes
    // on the engine side. Providing a new wrapper to [_getShader] for
    // wrapping the native counterpart (if it hasn't been wrapped already)
    // is a hack to work around this.
    return shaders_.putIfAbsent(
      shaderName,
      () => _getShader(shaderName, Shader._()),
    );
  }

  /// Re-fetches `assetKey` through the asset manager and reparses it into
  /// the cached `ShaderLibrary` for that key, marking each shader dirty so
  /// the next pipeline build evicts and re-registers it. The primary caller
  /// is the `ext.ui.gpu.reinitializeShaderLibrary` service extension driving
  /// hot reload from `flutter_tools`; tests may also call this directly.
  /// No-ops if no library has been loaded for `assetKey`.
  ///
  /// `assetKey` must be the asset's bundle path: the same string passed to
  /// [fromAsset] and listed in the asset manifest. That path is both the
  /// registry key here and the value `flutter_tools` dispatches, so the two
  /// must match for a reload to land.
  static void reinitialize(String assetKey) {
    final ShaderLibrary? lib = _registry[assetKey];
    if (lib == null) {
      // No library for this asset is loaded yet; the next `fromAsset` call
      // will pick up the fresh bytes on its own.
      return;
    }
    final String? error = lib._reinitializeWithAsset(assetKey);
    if (error != null) {
      throw Exception("Failed to reinitialize ShaderLibrary: ${error}");
    }
  }

  /// Test-only. Reloads this library from `assetName`'s bytes while keeping
  /// this library's identity and registry key. Production hot reload always
  /// re-fetches the original asset path via [reinitialize]; this hook lets
  /// tests simulate an edited bundle by swapping in a different fixture.
  String? debugReinitializeFromAsset(String assetName) =>
      _reinitializeWithAsset(assetName);

  /// Reparses [bytes] into this library in place, preserving its identity so
  /// any [Shader]s already handed out keep working (they are mutated and
  /// marked dirty so the next pipeline build re-registers them). The
  /// counterpart to [reinitialize] for a [fromBytes] library, which has no
  /// asset path to re-fetch. Use it to swap in a recompiled shader bundle.
  ///
  /// Returns null on success, or an error message if [bytes] could not be
  /// parsed (the live shaders are left unchanged in that case).
  String? reinitializeFromBytes(ByteData bytes) =>
      _reinitializeWithBytes(bytes);

  @Native<Handle Function(Handle, Handle)>(
    symbol: 'InternalFlutterGpu_ShaderLibrary_InitializeWithAsset',
  )
  external String? _initializeWithAsset(String assetName);

  @Native<Handle Function(Pointer<Void>, Handle)>(
    symbol: 'InternalFlutterGpu_ShaderLibrary_ReinitializeWithAsset',
  )
  external String? _reinitializeWithAsset(String assetName);

  @Native<Handle Function(Handle, Handle)>(
    symbol: 'InternalFlutterGpu_ShaderLibrary_InitializeWithBytes',
  )
  external String? _initializeWithBytes(ByteData bytes);

  @Native<Handle Function(Pointer<Void>, Handle)>(
    symbol: 'InternalFlutterGpu_ShaderLibrary_ReinitializeWithBytes',
  )
  external String? _reinitializeWithBytes(ByteData bytes);

  @Native<Handle Function(Pointer<Void>, Handle, Handle)>(
    symbol: 'InternalFlutterGpu_ShaderLibrary_GetShader',
  )
  external Shader? _getShader(String shaderName, Shader shaderWrapper);
}
