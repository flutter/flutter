// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:sky' as sky;

typedef void ImageListener(sky.Image image);

class ImageResource {
  ImageResource(this._futureImage) {
    _futureImage.then(_handleImageLoaded, onError: _handleImageError);
  }

  bool _resolved = false;
  Future<sky.Image> _futureImage;
  sky.Image _image;
  final List<ImageListener> _listeners = new List<ImageListener>();

  Future<sky.Image> get first => _futureImage;

  void addListener(ImageListener listener) {
    _listeners.add(listener);
    if (_resolved)
      listener(_image);
  }

  void removeListener(ImageListener listener) {
    _listeners.remove(listener);
  }

  void _handleImageLoaded(sky.Image image) {
    _image = image;
    _resolved = true;
    _notifyListeners();
  }

  void _handleImageError(e, stackTrace) {
    print('Failed to load image: $e\nStack trace: $stackTrace');
  }

  void _notifyListeners() {
    assert(_resolved);
    List<ImageListener> localListeners = new List<ImageListener>.from(_listeners);
    for (ImageListener listener in localListeners) {
      try {
        listener(_image);
      } catch(e) {
        print('Image listener had exception: $e');
      }
    }
  }
}
