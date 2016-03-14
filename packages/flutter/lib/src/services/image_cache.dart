// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' show hashValues;

import 'package:mojo/mojo/url_response.mojom.dart';
import 'package:quiver/collection.dart';

import 'fetch.dart';
import 'image_decoder.dart';
import 'image_resource.dart';

/// Implements a way to retrieve an image, for example by fetching it from the
/// network. Also used as a key in the image cache.
abstract class ImageProvider { // ignore: one_member_abstracts
  Future<ImageInfo> loadImage();
}

class _UrlFetcher implements ImageProvider {
  _UrlFetcher(this._url, this._scale);

  final String _url;
  final double _scale;

  Future<ImageInfo> loadImage() async {
    UrlResponse response = await fetchUrl(_url);
    if (response.statusCode >= 400) {
      print("Failed (${response.statusCode}) to load image $_url");
      return null;
    }
    return new ImageInfo(
      image: await decodeImageFromDataPipe(response.body),
      scale: _scale
    );
  }

  bool operator ==(dynamic other) {
    if (other is! _UrlFetcher)
      return false;
    final _UrlFetcher typedOther = other;
    return _url == typedOther._url && _scale == typedOther._scale;
  }

  int get hashCode => hashValues(_url, _scale);
}

const int _kDefaultSize = 1000;

class ImageCache {
  ImageCache._();

  final LruMap<ImageProvider, ImageResource> _cache =
      new LruMap<ImageProvider, ImageResource>(maximumSize: _kDefaultSize);

  int get maximumSize => _cache.maximumSize;
  set maximumSize(int value) { _cache.maximumSize = value; }

  ImageResource loadProvider(ImageProvider provider) {
    return _cache.putIfAbsent(provider, () {
      return new ImageResource(provider.loadImage());
    });
  }

  ImageResource load(String url, { double scale: 1.0 }) {
    return loadProvider(new _UrlFetcher(url, scale));
  }
}

final ImageCache imageCache = new ImageCache._();
