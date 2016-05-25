// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:ui' show hashValues;

import 'package:flutter/foundation.dart';
import 'package:flutter/http.dart' as http;

import 'image_decoder.dart';
import 'image_resource.dart';

/// Implements a way to retrieve an image, for example by fetching it from the
/// network. Also used as a key in the image cache.
///
/// This is the interface implemented by objects that can be used as the
/// argument to [ImageCache.loadProvider].
///
/// The [ImageCache.load] function uses an [ImageProvider] that fetches images
/// described by URLs. One could create an [ImageProvider] that used a custom
/// protocol, e.g. a direct TCP connection to a remote host, or using a
/// screenshot API from the host platform; such an image provider would then
/// share the same cache as all the other image loading codepaths that used the
/// [imageCache].
abstract class ImageProvider { // ignore: one_member_abstracts
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const ImageProvider();

  /// Subclasses must implement this method by having it asynchronously return
  /// an [ImageInfo] that represents the image provided by this [ImageProvider].
  Future<ImageInfo> loadImage();

  /// Subclasses must implement the `==` operator so that the image cache can
  /// distinguish identical requests.
  @override
  bool operator ==(dynamic other);

  /// Subclasses must implement the `hashCode` operator so that the image cache
  /// can efficiently store the providers in a map.
  @override
  int get hashCode;
}

class _UrlFetcher implements ImageProvider {
  _UrlFetcher(this._url, this._scale);

  final String _url;
  final double _scale;

  @override
  Future<ImageInfo> loadImage() async {
    try {
      return new ImageInfo(
        image: await decodeImageFromDataPipe(await http.readDataPipe(Uri.base.resolve(_url))),
        scale: _scale
      );
    } catch (exception, stack) {
      FlutterError.reportError(new FlutterErrorDetails(
        exception: exception,
        stack: stack,
        library: 'services library',
        context: 'while fetching an image for the image cache',
        silent: true
      ));
      return null;
    }
  }

  @override
  bool operator ==(dynamic other) {
    if (other is! _UrlFetcher)
      return false;
    final _UrlFetcher typedOther = other;
    return _url == typedOther._url && _scale == typedOther._scale;
  }

  @override
  int get hashCode => hashValues(_url, _scale);
}

const int _kDefaultSize = 1000;

/// Class for the [imageCache] object.
///
/// Implements a least-recently-used cache of up to 1000 images. The maximum
/// size can be adjusted using [maximumSize]. Images that are actively in use
/// (i.e. to which the application is holding references, either via
/// [ImageResource] objects, [ImageInfo] objects, or raw [ui.Image] objects) may
/// get evicted from the cache (and thus need to be refetched from the network
/// if they are referenced in the [load] method), but the raw bits are kept in
/// memory for as long as the application is using them.
///
/// The [load] method fetches the image with the given URL and scale.
///
/// For more complicated use cases, the [loadProvider] method can be used with a
/// custom [ImageProvider].
class ImageCache {
  ImageCache._();

  final LinkedHashMap<ImageProvider, ImageResource> _cache =
      new LinkedHashMap<ImageProvider, ImageResource>();

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

  /// Calls the [ImageProvider.loadImage] method on the given image provider, if
  /// necessary, and returns an [ImageResource] that encapsulates a [Future] for
  /// the given image.
  ///
  /// If the given [ImageProvider] has already been used and is still in the
  /// cache, then the [ImageResource] object is immediately usable and the
  /// provider is not called.
  ImageResource loadProvider(ImageProvider provider) {
    ImageResource result = _cache[provider];
    if (result != null) {
      _cache.remove(provider);
    } else {
      if (_cache.length == maximumSize && maximumSize > 0)
        _cache.remove(_cache.keys.first);
      result = new ImageResource(provider.loadImage());;
    }
    if (maximumSize > 0) {
      assert(_cache.length < maximumSize);
      _cache[provider] = result;
    }
    assert(_cache.length <= maximumSize);
    return result;
  }

  /// Fetches the given URL, associating it with the given scale.
  ///
  /// The return value is an [ImageResource], which encapsulates a [Future] for
  /// the given image.
  ///
  /// If the given URL has already been fetched for the given scale, and it is
  /// still in the cache, then the [ImageResource] object is immediately usable.
  ImageResource load(String url, { double scale: 1.0 }) {
    assert(url != null);
    assert(scale != null);
    return loadProvider(new _UrlFetcher(url, scale));
  }
}

/// The singleton that implements the Flutter framework's image cache.
///
/// The simplest use of this object is as follows:
///
/// ```dart
/// imageCache.load(myImageUrl).first.then(myImageHandler);
/// ```
///
/// ...where `myImageHandler` is a function with one argument, an [ImageInfo]
/// object.
final ImageCache imageCache = new ImageCache._();
