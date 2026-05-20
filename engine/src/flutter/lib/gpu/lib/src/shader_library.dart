// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

part of flutter_gpu;

base class ShaderLibrary extends NativeFieldWrapperClass1 {
  static ShaderLibrary? fromAsset(String assetName) {
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

  @Native<Handle Function(Handle, Handle)>(
    symbol: 'InternalFlutterGpu_ShaderLibrary_InitializeWithAsset',
  )
  external String? _initializeWithAsset(String assetName);

  @Native<Handle Function(Pointer<Void>, Handle)>(
    symbol: 'InternalFlutterGpu_ShaderLibrary_ReinitializeWithAsset',
  )
  external String? _reinitializeWithAsset(String assetName);

  @Native<Handle Function(Pointer<Void>, Handle, Handle)>(
    symbol: 'InternalFlutterGpu_ShaderLibrary_GetShader',
  )
  external Shader? _getShader(String shaderName, Shader shaderWrapper);
}
