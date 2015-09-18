// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of skysprites;

class ImageMap {
  ImageMap(AssetBundle bundle) : _bundle = bundle;

  final AssetBundle _bundle;
  final Map<String, sky.Image> _images = new Map<String, sky.Image>();

  Future<List<sky.Image>> load(List<String> urls) {
    return Future.wait(urls.map(_loadImage));
  }

  Future<sky.Image> _loadImage(String url) async {
    sky.Image image = await _bundle.loadImage(url).first;
    _images[url] = image;
    return image;
  }

  sky.Image getImage(String url) => _images[url];
  sky.Image operator [](String url) => _images[url];
}
