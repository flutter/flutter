// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of sprites;

class ImageMap {
  ImageMap(AssetBundle bundle) : _bundle = bundle;

  final AssetBundle _bundle;
  final Map<String, Image> _images = new Map<String, Image>();

  Future<List<Image>> load(List<String> urls) {
    return Future.wait(urls.map(_loadImage));
  }

  Future<Image> _loadImage(String url) async {
    Image image = await _bundle.loadImage(url);
    _images[url] = image;
    return image;
  }

  Image getImage(String url) => _images[url];
  Image operator [](String url) => _images[url];
}
