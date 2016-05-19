// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of flutter_sprites;

/// The ImageMap is a helper class for loading and keeping references to
/// multiple images.
class ImageMap {

  /// Creates a new ImageMap where images will be loaded from the specified
  /// [bundle].
  ImageMap(AssetBundle bundle) : _bundle = bundle;

  final AssetBundle _bundle;
  final Map<String, ui.Image> _images = new Map<String, ui.Image>();

  /// Loads a list of images given their urls.
  Future<List<ui.Image>> load(List<String> urls) {
    return Future.wait(urls.map(_loadImage));
  }

  Future<ui.Image> _loadImage(String url) async {
    ui.Image image = (await _bundle.loadImage(url).first).image;
    _images[url] = image;
    return image;
  }

  /// Returns a preloaded image, given its [url].
  ui.Image getImage(String url) => _images[url];

  /// Returns a preloaded image, given its [url].
  ui.Image operator [](String url) => _images[url];
}
