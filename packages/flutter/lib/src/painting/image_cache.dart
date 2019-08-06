// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'image_stream.dart';

const int _kDefaultSize = 1000;
const int _kDefaultSizeBytes = 100 << 20; // 100 MiB

/// Class for caching images.
///
/// Implements a least-recently-used cache of up to 1000 images, and up to 100
/// MB. The maximum size can be adjusted using [maximumSize] and
/// [maximumSizeBytes]. Images that are actively in use (i.e. to which the
/// application is holding references, either via [ImageStream] objects,
/// [ImageStreamCompleter] objects, [ImageInfo] objects, or raw [dart:ui.Image]
/// objects) may get evicted from the cache (and thus need to be refetched from
/// the network if they are referenced in the [putIfAbsent] method), but the raw
/// bits are kept in memory for as long as the application is using them.
///
/// The [putIfAbsent] method is the main entry-point to the cache API. It
/// returns the previously cached [ImageStreamCompleter] for the given key, if
/// available; if not, it calls the given callback to obtain it first. In either
/// case, the key is moved to the "most recently used" position.
///
/// Generally this class is not used directly. The [ImageProvider] class and its
/// subclasses automatically handle the caching of images.
///
/// A shared instance of this cache is retained by [PaintingBinding] and can be
/// obtained via the [imageCache] top-level property in the [painting] library.
class ImageCache {
  final Map<Object, _PendingImage> _pendingImages = <Object, _PendingImage>{};
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
      clear();
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
  int get maximumSizeBytes => _maximumSizeBytes;
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
      clear();
    } else {
      _checkCacheSize();
    }
  }

  /// The current size of cached entries in bytes.
  int get currentSizeBytes => _currentSizeBytes;
  int _currentSizeBytes = 0;

  /// Evicts all entries from the cache.
  ///
  /// This is useful if, for instance, the root asset bundle has been updated
  /// and therefore new images must be obtained.
  ///
  /// Images which have not finished loading yet will not be removed from the
  /// cache, and when they complete they will be inserted as normal.
  void clear() {
    _cache.clear();
    _pendingImages.clear();
    _currentSizeBytes = 0;
  }

  /// Evicts a single entry from the cache, returning true if successful.
  /// Pending images waiting for completion are removed as well, returning true if successful.
  ///
  /// When a pending image is removed the listener on it is removed as well to prevent
  /// it from adding itself to the cache if it eventually completes.
  ///
  /// The [key] must be equal to an object used to cache an image in
  /// [ImageCache.putIfAbsent].
  ///
  /// If the key is not immediately available, as is common, consider using
  /// [ImageProvider.evict] to call this method indirectly instead.
  ///
  /// See also:
  ///
  ///  * [ImageProvider], for providing images to the [Image] widget.
  bool evict(Object key) {
    final _PendingImage pendingImage = _pendingImages.remove(key);
    if (pendingImage != null) {
      pendingImage.removeListener();
      return true;
    }
    final _CachedImage image = _cache.remove(key);
    if (image != null) {
      _currentSizeBytes -= image.sizeBytes;
      return true;
    }
    return false;
  }

  /// Returns the previously cached [ImageStream] for the given key, if available;
  /// if not, calls the given callback to obtain it first. In either case, the
  /// key is moved to the "most recently used" position.
  ///
  /// The arguments must not be null. The `loader` cannot return null.
  ///
  /// In the event that the loader throws an exception, it will be caught only if
  /// `onError` is also provided. When an exception is caught resolving an image,
  /// no completers are cached and `null` is returned instead of a new
  /// completer.
  ImageStreamCompleter putIfAbsent(Object key, ImageStreamCompleter loader(), { ImageErrorListener onError }) {
    assert(key != null);
    assert(loader != null);
    ImageStreamCompleter result = _pendingImages[key]?.completer;
    // Nothing needs to be done because the image hasn't loaded yet.
    if (result != null)
      return result;
    // Remove the provider from the list so that we can move it to the
    // recently used position below.
    final _CachedImage image = _cache.remove(key);
    if (image != null) {
      _cache[key] = image;
      return image.completer;
    }
    try {
      result = loader();
    } catch (error, stackTrace) {
      if (onError != null) {
        onError(error, stackTrace);
        return null;
      } else {
        rethrow;
      }
    }
    void listener(ImageInfo info, bool syncCall) {
      // Images that fail to load don't contribute to cache size.
      final int imageSize = info?.image == null ? 0 : info.image.height * info.image.width * 4;
      final _CachedImage image = _CachedImage(result, imageSize);
      // If the image is bigger than the maximum cache size, and the cache size
      // is not zero, then increase the cache size to the size of the image plus
      // some change.
      if (maximumSizeBytes > 0 && imageSize > maximumSizeBytes) {
        _maximumSizeBytes = imageSize + 1000;
      }
      _currentSizeBytes += imageSize;
      final _PendingImage pendingImage = _pendingImages.remove(key);
      if (pendingImage != null) {
        pendingImage.removeListener();
      }

      _cache[key] = image;
      _checkCacheSize();
    }
    if (maximumSize > 0 && maximumSizeBytes > 0) {
      final ImageStreamListener streamListener = ImageStreamListener(listener);
      _pendingImages[key] = _PendingImage(result, streamListener);
      // Listener is removed in [_PendingImage.removeListener].
      result.addListener(streamListener);
    }
    return result;
  }

  // Remove images from the cache until both the length and bytes are below
  // maximum, or the cache is empty.
  void _checkCacheSize() {
    while (_currentSizeBytes > _maximumSizeBytes || _cache.length > _maximumSize) {
      final Object key = _cache.keys.first;
      final _CachedImage image = _cache[key];
      _currentSizeBytes -= image.sizeBytes;
      _cache.remove(key);
    }
    assert(_currentSizeBytes >= 0);
    assert(_cache.length <= maximumSize);
    assert(_currentSizeBytes <= maximumSizeBytes);
  }
}

class _CachedImage {
  _CachedImage(this.completer, this.sizeBytes);

  final ImageStreamCompleter completer;
  final int sizeBytes;
}

class _PendingImage {
  _PendingImage(this.completer, this.listener);

  final ImageStreamCompleter completer;
  final ImageStreamListener listener;

  void removeListener() {
    completer.removeListener(listener);
  }
}
