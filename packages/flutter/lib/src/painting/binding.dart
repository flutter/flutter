// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data' show Uint8List;
import 'dart:ui' as ui show instantiateImageCodec, Codec;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show ServicesBinding;

import 'image_cache.dart';

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
  }

  /// The current [PaintingBinding], if one has been created.
  static PaintingBinding get instance => _instance;
  static PaintingBinding _instance;

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
