// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show hashValues;

import 'image_stream.dart';

const int _kDefaultSize = 1000;
const int _kDefaultSizeBytes = 100 << 20; // 100 MiB

/// Class for caching images.
///
/// Implements a least-recently-used cache of up to 1000 images, and up to 100
/// MB. The maximum size can be adjusted using [maximumSize] and
/// [maximumSizeBytes].
///
/// The cache also holds a list of "live" references. An image is considered
/// live if its [ImageStreamCompleter]'s listener count has never dropped to
/// zero after adding at least one listener. The cache uses
/// [ImageStreamCompleter.addOnLastListenerRemovedCallback] to determine when
/// this has happened.
///
/// The [putIfAbsent] method is the main entry-point to the cache API. It
/// returns the previously cached [ImageStreamCompleter] for the given key, if
/// available; if not, it calls the given callback to obtain it first. In either
/// case, the key is moved to the "most recently used" position.
///
/// A caller can determine whether an image is already in the cache by using
/// [containsKey], which will return true if the image is tracked by the cache
/// in a pending or compelted state. More fine grained information is available
/// by using the [locationForKey] method.
///
/// Generally this class is not used directly. The [ImageProvider] class and its
/// subclasses automatically handle the caching of images.
///
/// A shared instance of this cache is retained by [PaintingBinding] and can be
/// obtained via the [imageCache] top-level property in the [painting] library.
///
/// {@tool snippet}
///
/// This sample shows how to supply your own caching logic and replace the
/// global [imageCache] variable.
///
/// ```dart
/// /// This is the custom implementation of [ImageCache] where we can override
/// /// the logic.
/// class MyImageCache extends ImageCache {
///   @override
///   void clear() {
///     print("Clearing cache!");
///     super.clear();
///   }
/// }
///
/// class MyWidgetsBinding extends WidgetsFlutterBinding {
///   @override
///   ImageCache createImageCache() => MyImageCache();
/// }
///
/// void main() {
///   // The constructor sets global variables.
///   MyWidgetsBinding();
///   runApp(MyApp());
/// }
///
/// class MyApp extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return Container();
///   }
/// }
/// ```
/// {@end-tool}
class ImageCache {
  final Map<Object, _PendingImage> _pendingImages = <Object, _PendingImage>{};
  final Map<Object, _CachedImage> _cache = <Object, _CachedImage>{};
  /// ImageStreamCompleters with at least one listener. These images may or may
  /// not fit into the _pendingImages or _cache objects.
  ///
  /// Unlike _cache, the [_CachedImage] for this may have a null byte size.
  final Map<Object, _CachedImage> _liveImages = <Object, _CachedImage>{};

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
  /// Pending images waiting for completion are removed as well, returning true
  /// if successful.
  ///
  /// When a pending image is removed the listener on it is removed as well to
  /// prevent it from adding itself to the cache if it eventually completes.
  ///
  /// The `key` must be equal to an object used to cache an image in
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

  /// Updates the least recently used image cache with this image, if it is
  /// less than the [maximumSizeBytes] of this cache.
  ///
  /// Resizes the cache as appropriate to maintain the constraints of
  /// [maximumSize] and [maximumSizeBytes].
  void _touch(Object key, _CachedImage image) {
    if (image.sizeBytes != null && image.sizeBytes <= maximumSizeBytes) {
      _currentSizeBytes += image.sizeBytes;
      _cache[key] = image;
      _checkCacheSize();
    }
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
      assert(_liveImages.containsKey(key));
      _cache[key] = image;
      return image.completer;
    }

    final _CachedImage liveImage = _liveImages[key];
    if (liveImage != null) {
      _touch(key, liveImage);
      return liveImage.completer;
    }

    try {
      result = loader();
      _liveImages[key] = _CachedImage(result, null);
      result.addOnLastListenerRemovedCallback(() {
        _liveImages.remove(key);
      });
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
      if (!_liveImages.containsKey(key)) {
        assert(syncCall);
        result.addOnLastListenerRemovedCallback(() {
          _liveImages.remove(key);
        });
      }
      _liveImages[key] = image;
      final _PendingImage pendingImage = _pendingImages.remove(key);
      if (pendingImage != null) {
        pendingImage.removeListener();
      }

      _touch(key, image);
    }
    if (maximumSize > 0 && maximumSizeBytes > 0) {
      final ImageStreamListener streamListener = ImageStreamListener(listener);
      _pendingImages[key] = _PendingImage(result, streamListener);
      // Listener is removed in [_PendingImage.removeListener].
      result.addListener(streamListener);
    }
    return result;
  }

  /// The [ImageCacheLocation] information for the given `key`.
  ImageCacheLocation locationForKey(Object key) {
    return ImageCacheLocation._(
      pending: _pendingImages.containsKey(key),
      completed: _cache.containsKey(key),
      live: _liveImages.containsKey(key),
    );
  }

  /// Returns whether this `key` has been previously added by [putIfAbsent].
  bool containsKey(Object key) {
    return _pendingImages[key] != null || _cache[key] != null;
  }

  /// The number of live images being held by the [ImageCache].
  ///
  /// Compare with [ImageCache.currentSize] for completed held images.
  int get liveImageCount => _liveImages.length;

  /// The number of images being tracked as pending in the [ImageCache].
  ///
  /// Compare with [ImageCache.currentSize] for completedly held images.
  int get pendingImageCount => _pendingImages.length;

  /// Clears any live references to images in this cache.
  ///
  /// An image is considered live if its [ImageStreamCompleter] has never hit
  /// zero listeners after adding at least one listener. The
  /// [ImageStreamCompleter.addOnLastListenerRemovedCallback] is used to
  /// determine when this has happened.
  ///
  /// This is called after a hot reload to evict any stale references to image
  /// data for assets that have changed. Calling this method does not relieve
  /// memory pressure, since the live image caching only tracks image instances
  /// that are also being held by at least one other object.
  void clearLiveImages() {
    _liveImages.clear();
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

/// Information about how the [ImageCache] is tracking an image.
///
/// A [pending] image is one that has not completed yet. It may also be tracked
/// as [live] because something is listening to it, but it has not yet
/// [completed].
///
/// A [completed] image is being held in the cache, which uses Least Recently
/// Used semantics to determine when to evict an image. These images are subject
/// to eviction based on [ImageCache.maximumSizeBytes] and
/// [ImageCache.maximumSize]. It may be [live], but not [pending].
///
/// A [live] image is being held until its [ImageStreamCompleter] has no more
/// listeners. It may also be [pending] or [completed].
///
/// An [untracked] image is not being cached.
///
/// To obtain an [ImageCacheLocation], use [ImageCache.locationForKey] or
/// [ImageProvider.findCacheLocation].
class ImageCacheLocation {
  const ImageCacheLocation._({
    this.pending = false,
    this.completed = false,
    this.live = false,
  }) : assert(!pending || !completed);

  /// An image that has been submitted to [ImageCache.putIfAbsent], but
  /// not yet completed.
  final bool pending;

  /// An image that has been submitted to [ImageCache.putIfAbsent], has
  /// completed, fits based on the sizing rules of the cache, and has not been
  /// evicted.
  final bool completed;

  /// An image that has been submitted to [ImageCache.putIfAbsent], has
  /// completed, and has at least one listener on its [ImageStreamCompleter].
  final bool live;

  /// An image that is tracked in some way by the [ImageCache], whether
  /// [pending], [completed], or [live].
  bool get tracked => pending || completed || live;

  /// An image that either has not been submitted to
  /// [ImageCache.putIfAbsent] or has otherwise been evicted from the
  /// [completed] and [live] caches.
  bool get untracked => !pending && !completed && !live;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is ImageCacheLocation
        && other.pending == pending
        && other.completed == completed
        && other.live == live;
  }

  @override
  int get hashCode => hashValues(pending, completed, live);
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
