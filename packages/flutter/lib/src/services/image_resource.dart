// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' as ui;

import 'print.dart';

class ImageInfo {
  ImageInfo({ this.image, this.scale: 1.0 });
  final ui.Image image;
  final double scale;
}

/// A callback for when the image is available.
typedef void ImageListener(ImageInfo image);

/// A handle to an image resource
///
/// ImageResource represents a handle to a [ui.Image] object. The underlying
/// image object might change over time, either because the image is animating
/// or because the underlying image resource was mutated.
class ImageResource {
  ImageResource(this._futureImage) {
    _futureImage.then(_handleImageLoaded, onError: (exception, stack) => _handleImageError('Failed to load image:', exception, stack));
  }

  bool _resolved = false;
  Future<ImageInfo> _futureImage;
  ImageInfo _image;
  final List<ImageListener> _listeners = new List<ImageListener>();

  /// The first concrete [ui.Image] object represented by this handle.
  ///
  /// Instead of receivingly only the first image, most clients will want to
  /// [addListener] to be notified whenever a a concrete image is available.
  Future<ImageInfo> get first => _futureImage;

  /// Adds a listener callback that is called whenever a concrete [ui.Image]
  /// object is available. Note: If a concrete image is available currently,
  /// this object will call the listener synchronously.
  void addListener(ImageListener listener) {
    _listeners.add(listener);
    if (_resolved) {
      try {
        listener(_image);
      } catch (exception, stack) {
        _handleImageError('The following exception was thrown by a synchronously-invoked image listener:', exception, stack);
      }
    }
  }

  /// Stop listening for new concrete [ui.Image] objects.
  void removeListener(ImageListener listener) {
    _listeners.remove(listener);
  }

  void _handleImageLoaded(ImageInfo image) {
    _image = image;
    _resolved = true;
    _notifyListeners();
  }

  void _notifyListeners() {
    assert(_resolved);
    List<ImageListener> localListeners = new List<ImageListener>.from(_listeners);
    for (ImageListener listener in localListeners) {
      try {
        listener(_image);
      } catch (exception, stack) {
        _handleImageError('The following exception was thrown by an image listener:', exception, stack);
      }
    }
  }

  void _handleImageError(String message, dynamic exception, dynamic stack) {
    debugPrint('-- EXCEPTION CAUGHT BY SERVICES LIBRARY --------------------------------');
    debugPrint(message);
    debugPrint('$exception');
    debugPrint('Stack trace:');
    debugPrint('$stack');
    debugPrint('------------------------------------------------------------------------');
  }
}
