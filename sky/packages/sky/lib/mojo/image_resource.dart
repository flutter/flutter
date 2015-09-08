// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:sky' as sky;

/// A callback for when the image is available.
typedef void ImageListener(sky.Image image);

/// A handle to an image resource
///
/// ImageResource represents a handle to a [sky.Image] object. The underlying
/// image object might change over time, either because the image is animating
/// or because the underlying image resource was mutated.
class ImageResource {
  ImageResource(this._futureImage) {
    _futureImage.then(_handleImageLoaded, onError: _handleImageError);
  }

  bool _resolved = false;
  Future<sky.Image> _futureImage;
  sky.Image _image;
  final List<ImageListener> _listeners = new List<ImageListener>();

  /// The first concrete [sky.Image] object represented by this handle.
  ///
  /// Instead of receivingly only the first image, most clients will want to
  /// [addListener] to be notified whenever a a concrete image is available.
  Future<sky.Image> get first => _futureImage;

  /// Adds a listener callback that is called whenever a concrete [sky.Image]
  /// object is available. Note: If a concrete image is available currently,
  /// this object will call the listener synchronously.
  void addListener(ImageListener listener) {
    _listeners.add(listener);
    if (_resolved)
      listener(_image);
  }

  /// Stop listening for new concrete [sky.Image] objects.
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
