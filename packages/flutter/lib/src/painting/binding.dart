// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data' show Uint8List;
import 'dart:ui' as ui show instantiateImageCodec, Codec;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show ServicesBinding;

import 'image_cache.dart';
import 'shader_warm_up.dart';

const double _kDefaultDecodedCacheRatioCap = 0.0;

/// Binding for the painting library.
///
/// Hooks into the cache eviction logic to clear the image cache.
///
/// Requires the [ServicesBinding] to be mixed in earlier.
mixin PaintingBinding on BindingBase, ServicesBinding {
  @override
  void initInstances() {
    super.initInstances();
    _instance = this;
    _imageCache = createImageCache();
    if (shaderWarmUp != null) {
      shaderWarmUp.execute();
    }
  }

  /// The current [PaintingBinding], if one has been created.
  static PaintingBinding get instance => _instance;
  static PaintingBinding _instance;

  /// [ShaderWarmUp] to be executed during [initInstances].
  ///
  /// If the application has scenes that require the compilation of complex
  /// shaders that are not covered by [DefaultShaderWarmUp], it may cause jank
  /// in the middle of an animation or interaction. In that case, set
  /// [shaderWarmUp] to a custom [ShaderWarmUp] before calling [initInstances]
  /// (usually before [runApp] for normal Flutter apps, and before
  /// [enableFlutterDriverExtension] for Flutter driver tests). Paint the scene
  /// in the custom [ShaderWarmUp] so Flutter can pre-compile and cache the
  /// shaders during startup. The warm up is only costly (100ms-200ms,
  /// depending on the shaders to compile) during the first run after the
  /// installation or a data wipe. The warm up does not block the main thread
  /// so there should be no "Application Not Responding" warning.
  ///
  /// Currently the warm-up happens synchronously on the GPU thread which means
  /// the rendering of the first frame on the GPU thread will be postponed until
  /// the warm-up is finished.
  ///
  /// See also:
  ///
  ///  * [ShaderWarmUp], the interface of how this warm up works.
  static ShaderWarmUp shaderWarmUp = const DefaultShaderWarmUp();

  /// The singleton that implements the Flutter framework's image cache.
  ///
  /// The cache is used internally by [ImageProvider] and should generally not
  /// be accessed directly.
  ///
  /// The image cache is created during startup by the [createImageCache]
  /// method.
  ImageCache get imageCache => _imageCache;
  ImageCache _imageCache;

  /// Creates the [ImageCache] singleton (accessible via [imageCache]).
  ///
  /// This method can be overridden to provide a custom image cache.
  @protected
  ImageCache createImageCache() => ImageCache();

  /// The maximum multiple of the compressed image size used when caching an
  /// animated image.
  ///
  /// Individual frames of animated images can be cached into memory to avoid
  /// using CPU to re-decode them for every loop in the animation. This behavior
  /// will result in out-of-memory crashes when decoding large (or large numbers
  /// of) animated images so is disabled by default. Set this value to control
  /// how much memory each animated image is allowed to use for caching decoded
  /// frames compared to its compressed size. For example, setting this to `2.0`
  /// means that a 400KB GIF would be allowed at most to use 800KB of memory
  /// caching unessential decoded frames. A setting of `1.0` or less disables
  /// all caching of unessential decoded frames. See
  /// [_kDefaultDecodedCacheRatioCap] for the default value.
  ///
  /// @deprecated The in-memory cache of decoded frames causes issues with
  /// memory consumption. Soon this API and the in-memory cache will be removed.
  /// See
  /// [flutter/flutter#26081](https://github.com/flutter/flutter/issues/26081)
  /// for more context.
  @deprecated
  double get decodedCacheRatioCap => _kDecodedCacheRatioCap;
  double _kDecodedCacheRatioCap = _kDefaultDecodedCacheRatioCap;
  /// Changes the maximum multiple of compressed image size used when caching an
  /// animated image.
  ///
  /// Changing this value only affects new images, not images that have already
  /// been decoded.
  ///
  /// @deprecated The in-memory cache of decoded frames causes issues with
  /// memory consumption. Soon this API and the in-memory cache will be removed.
  /// See
  /// [flutter/flutter#26081](https://github.com/flutter/flutter/issues/26081)
  /// for more context.
  @deprecated
  set decodedCacheRatioCap(double value) {
    assert (value != null);
    assert (value >= 0.0);
    _kDecodedCacheRatioCap = value;
  }

  // ignore: deprecated_member_use_from_same_package
  /// Calls through to [dart:ui] with [decodedCacheRatioCap] from [ImageCache].
  Future<ui.Codec> instantiateImageCodec(Uint8List list) {
    return ui.instantiateImageCodec(list, decodedCacheRatioCap: decodedCacheRatioCap); // ignore: deprecated_member_use_from_same_package
  }

  @override
  void evict(String asset) {
    super.evict(asset);
    imageCache.clear();
  }
}

/// The singleton that implements the Flutter framework's image cache.
///
/// The cache is used internally by [ImageProvider] and should generally not be
/// accessed directly.
///
/// The image cache is created during startup by the [PaintingBinding]'s
/// [PaintingBinding.createImageCache] method.
ImageCache get imageCache => PaintingBinding.instance.imageCache;
