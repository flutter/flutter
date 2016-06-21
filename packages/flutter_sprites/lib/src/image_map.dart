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
    ImageStream stream = new AssetImage(url, bundle: _bundle).resolve(ImageConfiguration.empty);
    Completer<ui.Image> completer = new Completer<ui.Image>();
    void listener(ImageInfo frame) {
      final ui.Image image = frame.image;
      _images[url] = image;
      completer.complete(image);
      stream.removeListener(listener);
    }
    stream.addListener(listener);
    return completer.future;
  }

  /// Returns a preloaded image, given its [url].
  ui.Image getImage(String url) => _images[url];

  /// Returns a preloaded image, given its [url].
  ui.Image operator [](String url) => _images[url];
}
