// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' as ui;

import 'package:mojo/mojo/url_response.mojom.dart';

import 'fetch.dart';
import 'image_decoder.dart';
import 'image_resource.dart';

/// Implements a way to retrieve an image, for example by fetching it from the network.
/// Also used as a key in the image cache.
abstract class ImageProvider {
  Future<ui.Image> loadImage();
}

class _UrlFetcher implements ImageProvider {
  final String _url;

  _UrlFetcher(this._url);

  Future<ui.Image> loadImage() async {
    UrlResponse response = await fetchUrl(_url);
    if (response.statusCode >= 400) {
      print("Failed (${response.statusCode}) to load image $_url");
      return null;
    }
    return await decodeImageFromDataPipe(response.body);
  }

  bool operator ==(other) => other is _UrlFetcher && _url == other._url;
  int get hashCode => _url.hashCode;
}

class _ImageCache {
  _ImageCache._();

  final Map<ImageProvider, ImageResource> _cache =
      new Map<ImageProvider, ImageResource>();

  ImageResource loadProvider(ImageProvider provider) {
    return _cache.putIfAbsent(provider, () {
      return new ImageResource(provider.loadImage());
    });
  }

  ImageResource load(String url) {
    return loadProvider(new _UrlFetcher(url));
  }
}

final _ImageCache imageCache = new _ImageCache._();
