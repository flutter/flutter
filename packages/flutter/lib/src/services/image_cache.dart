// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'image_stream.dart';

const int _kDefaultSize = 1000;

/// Class for the [imageCache] object.
///
/// Implements a least-recently-used cache of up to 1000 images. The maximum
/// size can be adjusted using [maximumSize]. Images that are actively in use
/// (i.e. to which the application is holding references, either via
/// [ImageStream] objects, [ImageStreamCompleter] objects, [ImageInfo] objects,
/// or raw [Image] objects) may get evicted from the cache (and thus need to
/// be refetched from the network if they are referenced in the [putIfAbsent]
/// method), but the raw bits are kept in memory for as long as the application
/// is using them.
///
/// The [putIfAbsent] method is the main entry-point to the cache API. It
/// returns the previously cached [ImageStreamCompleter] for the given key, if
/// available; if not, it calls the given callback to obtain it first. In either
/// case, the key is moved to the "most recently used" position.
///
/// Generally this class is not used directly. The [ImageProvider] class and its
/// subclasses automatically handle the caching of images.
class ImageCache {
  final Map<Object, ImageStreamCompleter> _cache = <Object, ImageStreamCompleter>{};

  /// Maximum number of entries to store in the cache.
  ///
  /// Once this many entries have been cached, the least-recently-used entry is
  /// evicted when adding a new entry.
  int get maximumSize => _maximumSize;
  int _maximumSize = _kDefaultSize;
  /// Changes the maximum cache size.
  ///
  /// If the new size is smaller than the current number of elements, the
  /// extraneous elements are evicted immediately. Setting this to zero and then
  /// returning it to its original value will therefore immediately clear the
  /// cache.
  set maximumSize(int value) {
    assert(value != null);
    assert(value >= 0);
    if (value == maximumSize)
      return;
    _maximumSize = value;
    if (maximumSize == 0) {
      _cache.clear();
    } else {
      while (_cache.length > maximumSize)
        _cache.remove(_cache.keys.first);
    }
  }

  /// Evicts all entries from the cache.
  ///
  /// This is useful if, for instance, the root asset bundle has been updated
  /// and therefore new images must be obtained.
  // TODO(ianh): Provide a way to target individual images. This is currently non-trivial
  // because by the time we get to the imageCache, the keys we're using are opaque.
  void clear() {
    _cache.clear();
  }

  /// Returns the previously cached [ImageStream] for the given key, if available;
  /// if not, calls the given callback to obtain it first. In either case, the
  /// key is moved to the "most recently used" position.
  ///
  /// The arguments cannot be null. The `loader` cannot return null.
  ImageStreamCompleter putIfAbsent(Object key, ImageStreamCompleter loader()) {
    assert(key != null);
    assert(loader != null);
    ImageStreamCompleter result = _cache[key];
    if (result != null) {
      // Remove the provider from the list so that we can put it back in below
      // and thus move it to the end of the list.
      _cache.remove(key);
    } else {
      if (_cache.length == maximumSize && maximumSize > 0)
        _cache.remove(_cache.keys.first);
      result = loader();
    }
    if (maximumSize > 0) {
      assert(_cache.length < maximumSize);
      _cache[key] = result;
    }
    assert(_cache.length <= maximumSize);
    return result;
  }
}

/// The singleton that implements the Flutter framework's image cache.
///
/// The cache is used internally by [ImageProvider] and should generally not be
/// accessed directly.
final ImageCache imageCache = new ImageCache();
