// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' as ui show Image;

import 'package:flutter/foundation.dart';

/// A [ui.Image] object with its corresponding scale.
///
/// ImageInfo objects are used by [ImageResource] objects to represent the
/// actual data of the image once it has been obtained.
class ImageInfo {
  /// Creates an [ImageInfo] object for the given image and scale.
  ///
  /// Both the image and the scale must not be null.
  ImageInfo({ this.image, this.scale: 1.0 }) {
    assert(image != null);
    assert(scale != null);
  }

  /// The raw image pixels.
  ///
  /// This is the object to pass to the [Canvas.drawImage],
  /// [Canvas.drawImageRect], or [Canvas.drawImageNine] methods when painting
  /// the image.
  final ui.Image image;

  /// The linear scale factor for drawing this image at its intended size.
  ///
  /// The scale factor applies to the width and the height.
  ///
  /// For example, if this is 2.0 it means that there are four image pixels for
  /// every one logical pixel, and the image's actual width and height (as given
  /// by the [ui.Image.width] and [ui.Image.height] properties) are double the
  /// height and width that should be used when painting the image (e.g. in the
  /// arguments given to [Canvas.drawImage]).
  final double scale;

  @override
  String toString() => '$image @ ${scale}x';
}

/// Signature for callbacks reporting that an image is available.
///
/// Used by [ImageResource].
typedef void ImageListener(ImageInfo image);

/// A handle to an image resource.
///
/// ImageResource represents a handle to a [ui.Image] object and its scale
/// (together represented by an [ImageInfo] object). The underlying image object
/// might change over time, either because the image is animating or because the
/// underlying image resource was mutated.
///
/// ImageResource objects can also represent an image that hasn't finished
/// loading.
class ImageResource {
  /// Creates an image resource.
  ///
  /// The image resource awaits the given [Future]. When the future resolves,
  /// it notifies the [ImageListener]s that have been registered with
  /// [addListener].
  ImageResource(this._futureImage) {
    _futureImage.then(
      _handleImageLoaded,
      onError: (dynamic exception, dynamic stack) {
        _handleImageError('while loading an image', exception, stack);
      }
    );
  }

  bool _resolved = false;
  Future<ImageInfo> _futureImage;
  ImageInfo _image;
  final List<ImageListener> _listeners = new List<ImageListener>();

  /// The first concrete [ImageInfo] object represented by this handle.
  ///
  /// Instead of receiving only the first image, most clients will want to
  /// [addListener] to be notified whenever a a concrete image is available.
  Future<ImageInfo> get first => _futureImage;

  /// Adds a listener callback that is called whenever a concrete [ImageInfo]
  /// object is available. If a concrete image is already available, this object
  /// will call the listener synchronously.
  void addListener(ImageListener listener) {
    _listeners.add(listener);
    if (_resolved) {
      try {
        listener(_image);
      } catch (exception, stack) {
        _handleImageError('by a synchronously-called image listener', exception, stack);
      }
    }
  }

  /// Stop listening for new concrete [ImageInfo] objects.
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
        _handleImageError('by an image listener', exception, stack);
      }
    }
  }

  void _handleImageError(String context, dynamic exception, dynamic stack) {
    FlutterError.reportError(new FlutterErrorDetails(
      exception: exception,
      stack: stack,
      library: 'image resource service',
      context: context
    ));
  }

  @override
  String toString() {
    StringBuffer result = new StringBuffer();
    result.write('$runtimeType(');
    if (!_resolved)
      result.write('unresolved');
    else
      result.write('$_image');
    result.write('; ${_listeners.length} listener${_listeners.length == 1 ? "" : "s" }');
    result.write(')');
    return result.toString();
  }
}
