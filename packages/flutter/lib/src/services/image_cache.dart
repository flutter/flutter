// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' as ui;
import 'dart:typed_data' show Uint8List;

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
  final String url;

  _UrlFetcher(this.url);

  Future<ui.Image> loadImage() async {
    UrlResponse response = await fetchUrl(url);
    if (response.statusCode >= 400) {
      print("Failed (${response.statusCode}) to load image $url");
      return null;
    }
    return await decodeImageFromDataPipe(response.body);
  }

  bool operator ==(o) => o is _UrlFetcher && url == o.url;
  int get hashCode => url.hashCode;
}

class RawImageProvider implements ImageProvider {
  final Uint8List bytes;

  RawImageProvider(this.bytes);

  Future<ui.Image> loadImage() async {
    return await decodeImageFromList(bytes);
  }
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
