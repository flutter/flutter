// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'image_stream.dart';

/// Class for the [imageCache] object.
///
/// Implements a least-recently-used cache of up to 1000 images. The maximum
/// size can be adjusted using [maximumSize]. Images that are actively in use
/// (i.e. to which the application is holding references, either via
/// [ImageStream] objects, [ImageStreamCompleter] objects, [ImageInfo] objects,
/// or raw [dart:ui.Image] objects) may get evicted from the cache (and thus
/// need to be refetched from the network if they are referenced in the
/// [putIfAbsent] method), but the raw bits are kept in memory for as long as
/// the application is using them.
///
/// The [putIfAbsent] method is the main entry-point to the cache API. It
/// returns the previously cached [ImageStreamCompleter] for the given key, if
/// available; if not, it calls the given callback to obtain it first. In either
/// case, the key is moved to the "most recently used" position.
///
/// Generally this class is not used directly. The [ImageProvider] class and its
/// subclasses automatically handle the caching of images.
class ImageCache {
  final Map<Object, ImageStreamCompleter> _completers = <Object, ImageStreamCompleter>{};
  final Map<Object, int> _sizes = <Object, int>{};

  int _cacheSize = 0;
  int _maximumSizeBytes = 1000000;

  /// Evicts all entries from the cache.
  ///
  /// This is useful if, for instance, the root asset bundle has been updated
  /// and therefore new images must be obtained.
  // TODO(ianh): Provide a way to target individual images. This is currently non-trivial
  // because by the time we get to the imageCache, the keys we're using are opaque.
  void clear() {
    _completers.clear();
    _sizes.clear();
  }

  ///
  void remove(Object key) {
    _completers.remove(key);
    _sizes.remove(key);
  }

  /// Returns the previously cached [ImageStream] for the given key, if available;
  /// if not, calls the given callback to obtain it first. In either case, the
  /// key is moved to the "most recently used" position.
  ///
  /// The arguments must not be null. The `loader` cannot return null.
  ImageStreamCompleter putIfAbsent(Object key, ImageStreamCompleter loader()) {
    assert(key != null);
    assert(loader != null);
    ImageStreamCompleter result = _completers[key];
    if (result != null) {
      result = _completers.remove(key);
    } else {
      result = loader();
      void listener(ImageInfo info, bool syncCall) {
        final int bytes = info.image.width * info.image.height * 4;
        _cacheSize += bytes;
        _sizes[key] = bytes;
        result.removeListener(listener);
      }
      result.addListener(listener);
    }
    if (_cacheSize > _maximumSizeBytes)
      _evictImages();
    _completers[key] = result;
    assert(result != null);
    return result;
  }

  void _evictImages() {
    while (_cacheSize > _maximumSizeBytes && _completers.isNotEmpty) {
      final Object key = _completers.keys.first;
      if (_sizes.containsKey(key)) {
        _completers.remove(key);
        final int size = _sizes.remove(key);
        _cacheSize -= size;
      }
    }
  }
}
