// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'image_stream.dart';

const int _kDefaultSize = 1000;
const int _kDefaultSizeBytes = 10000000; // 10 MB

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
  final Map<Object, ImageStreamCompleter> _pendingImages = <Object, ImageStreamCompleter>{};
  final Map<Object, _CachedImage> _cache = <Object, _CachedImage>{};

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
      _sizeBytes = 0;
    } else {
      _checkCacheSize();
    }
  }

  /// The current number of cached entries.
  int get currentSize => _cache.length;

  /// Maximum size of entries to store in the cache in bytes.
  ///
  /// Once more than this amount of bytes have been cached, the
  /// least-recently-used entry is evicted until there are fewer than the
  /// maximum bytes.
  int get maximumSizeBytes => _maximumSize;
  int _maximumSizeBytes = _kDefaultSizeBytes;

  /// Changes the maximum cache bytes.
  ///
  /// If the new size is smaller than the current size in bytes, the
  /// extraneous elements are evicted immediately. Setting this to zero and then
  /// returning it to its original value will therefore immediately clear the
  /// cache.
  set maximumSizeBytes(int value) {
    assert(value != null);
    assert(value >= 0);
    if (value == _maximumSizeBytes)
      return;
    _maximumSizeBytes = value;
    if (_maximumSizeBytes == 0) {
      _cache.clear();
      _sizeBytes = 0;
    } else {
      _checkCacheSize();
    }
  }

  int _sizeBytes = 0;
  /// The current size of cached entries in bytes.
  int get sizeBytes => _sizeBytes;

  /// Evicts all entries from the cache.
  ///
  /// This is useful if, for instance, the root asset bundle has been updated
  /// and therefore new images must be obtained.
  void clear() {
    _cache.clear();
  }

  /// Evicts a single entry from the cache, returning true if successful.
  ///
  /// [key] is usually an image's corresponding [ImageProvider]. For example,
  /// to evict a network image like below:
  ///
  ///     new Image.network(url);
  ///
  /// You need to pass a [NetworkImage] object to this method to evict it:
  ///
  ///     ImageCache.evict(new NetworkImage(url));
  bool evict(Object key) {
    return _cache.remove(key) != null;
  }

  /// Returns the previously cached [ImageStream] for the given key, if available;
  /// if not, calls the given callback to obtain it first. In either case, the
  /// key is moved to the "most recently used" position.
  ///
  /// The arguments must not be null. The `loader` cannot return null.
  ImageStreamCompleter putIfAbsent(Object key, ImageStreamCompleter loader()) {
    assert(key != null);
    assert(loader != null);
    final ImageStreamCompleter result = _pendingImages[key];
    // Nothing needs to be done because the image hasn't loaded yet.
    if (result != null)
      return result;
    final _CachedImage image = _cache.remove(key);
    if (image != null) {
      // Remove the provider from the list so that we can put it back in below
      // and thus move it to the end of the list.
      _cache[key] = image;
      return image.completer;
    } else {
      final ImageStreamCompleter result = loader();
      void listener(ImageInfo info, bool syncCall) {
        final _CachedImage image = new _CachedImage(result, info.image == null ? 0 : info.image.height * info.image.width * 4);
        _pendingImages.remove(key);
        _cache[key] = image;
        _checkCacheSize();
        result.removeListener(listener);
      }
      if (maximumSize != 0 && maximumSizeBytes != 0)
        result.addListener(listener);
      return result;
    }
  }

  void _checkCacheSize() {
    while (_sizeBytes > _maximumSizeBytes || _cache.length >= _maximumSize) {
      final Object key = _cache.keys.first;
      final _CachedImage image = _cache[key];
      _sizeBytes -= image.sizeBytes;
      _cache.remove(key);
    }
    assert(_cache.length <= maximumSize);
    assert(_sizeBytes <= maximumSizeBytes);
  }
}

class _CachedImage {
  _CachedImage(this.completer, this.sizeBytes);

  final ImageStreamCompleter completer;
  final int sizeBytes;
}