// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of flutter_sprites;

class ImageMap {
  ImageMap(AssetBundle bundle) : _bundle = bundle;

  final AssetBundle _bundle;
  final Map<String, ui.Image> _images = new Map<String, ui.Image>();

  Future<List<ui.Image>> load(List<String> urls) {
    return Future.wait(urls.map(_loadImage));
  }

  Future<ui.Image> _loadImage(String url) async {
    ui.Image image = await _bundle.loadImage(url).first;
    _images[url] = image;
    return image;
  }

  ui.Image getImage(String url) => _images[url];
  ui.Image operator [](String url) => _images[url];
}
