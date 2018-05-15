// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'image_stream.dart';


/// Class for the [imageCache] object.
///
/// Implements a least-recently-used-cache of up to 10MB worth of images. The
/// maximum size can be adjusted using [maximumSize]
/// The [putIfAbsent] method is the main entry-point to the cache API. It
/// returns the previously cached [ImageStreamCompleter] for the given key, if
/// available; if not, it calls the given callback to obtain it first. In either
/// case, the key is moved to the "most recently used" position.
///
/// Images that are actively in use (i.e. to which the application is holding
/// references, either via [ImageStream] objects, [ImageStreamCompleter]
/// objects, [ImageInfo] objects, or raw [dart:ui.Image] objects) may get
/// evicted from the cache (and thus need to be refetched from the network if
/// they are referenced in the [putIfAbsent] method), but the raw bits are kept
/// in memory for as long as the application is using them.
///
/// Generally this class is not used directly. The [ImageProvider] class and its
/// subclasses automatically handle the caching of images.
class ImageCache {
  ImageCache({double kilobytes = 1024 * 10.0}) 
    : _maximumSize = kilobytes,
      assert(_maximumSize != null);

  /// Network images don't immediately have a size and don't contribute to the
  /// current cache limits until they resolve.
  final Map<Object, ImageStreamCompleter> _pending = <Object, ImageStreamCompleter>{};
  final Map<Object, _SizedImage> _cache = <Object, _SizedImage>{};

  double _currentSize = 0.0;
  /// The current size of the cache in kilobytes.
  double get currentSize => _currentSize;

  double _maximumSize;
  double get maximumSize => _maximumSize;
  /// Changes the maximum cache size in kilobytes.
  ///
  /// If the new size is smaller than the current size, the extraneous elements
  /// are evicted immediately. Setting this to zero and then returning it to 
  /// its original value will therefore immediately clear the cache.
  set maximumSize(double value) {
    if (value == _maximumSize)
      return;
    _maximumSize = value;
    if (_currentSize > _maximumSize)
      _evictImages();
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
  /// The arguments must not be null. The `loader` cannot return null.
  ImageStreamCompleter putIfAbsent(Object key, ImageStreamCompleter loader()) {
    assert(key != null);
    assert(loader != null);
    final _SizedImage result = _cache[key];
    if (result != null) {
      // Remove the provider from the list so that we can put it back in below
      // and thus move it to the end of the list.
      _cache.remove(key);
      _cache[key] = result;
      return result.image;
    }
    ImageStreamCompleter completer = _pending[key];
    if (completer == null) {
      completer = loader();
      ImageListener listener;
      // The listener can be invoked synchronously if syncCall is true, so
      // add the completer to pending immediately.
      _pending[key] = completer;
      listener = (ImageInfo info, bool syncCall) {
        final double size = info.image != null 
          ? (info.image.width * info.image.height * 4) / 1024
          : 0.0;
        _pending.remove(key);
        _currentSize += size;
        _cache[key] = new _SizedImage(completer, size);
        completer.removeListener(listener);
        if (_currentSize > _maximumSize)
          _evictImages();
      };
      completer.addListener(listener);
    }
    return completer;
  }

  /// Removes images from that cache until it is empty or until [curentSize]
  /// is less than [maximumSize].
  void _evictImages() {
    // first determine how many images need to be removed.
    double removedSize = 0.0;
    int removeCount = 0;
    for (Object key in _cache.keys) {
      if (_currentSize - removedSize <= maximumSize) {
        break;
      }
      final _SizedImage image = _cache[key];
      removedSize += image.size;
      removeCount += 1;
    }
    for (int i = 0; i < removeCount; i++) {
      _cache.remove(_cache.keys.first);
    }
    _currentSize -= removedSize;
  }
}

// Because we don't have tuples.
class _SizedImage {
  _SizedImage(this.image, this.size);

  final ImageStreamCompleter image;

  /// Size of the image in kilobytes.
  final double size;
}
