// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' as ui show Image;

import 'package:flutter/foundation.dart';

/// A [ui.Image] object with its corresponding scale.
///
/// ImageInfo objects are used by [ImageStream] objects to represent the
/// actual data of the image once it has been obtained.
@immutable
class ImageInfo {
  /// Creates an [ImageInfo] object for the given image and scale.
  ///
  /// Both the image and the scale must not be null.
  ImageInfo({ @required this.image, this.scale: 1.0 }) {
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
  /// by the [Image.width] and [Image.height] properties) are double the
  /// height and width that should be used when painting the image (e.g. in the
  /// arguments given to [Canvas.drawImage]).
  final double scale;

  @override
  String toString() => '$image @ ${scale}x';
}

/// Signature for callbacks reporting that an image is available.
///
/// synchronousCall is true if the listener is being invoked during the call
/// to addListener.
///
/// Used by [ImageStream].
typedef void ImageListener(ImageInfo image, bool synchronousCall);

/// A handle to an image resource.
///
/// ImageStream represents a handle to a [ui.Image] object and its scale
/// (together represented by an [ImageInfo] object). The underlying image object
/// might change over time, either because the image is animating or because the
/// underlying image resource was mutated.
///
/// ImageStream objects can also represent an image that hasn't finished
/// loading.
///
/// ImageStream objects are backed by [ImageStreamCompleter] objects.
class ImageStream {
  /// Create an initially unbound image stream.
  ///
  /// Once an [ImageStreamCompleter] is available, call [setCompleter].
  ImageStream();

  /// The completer that has been assigned to this image stream.
  ///
  /// Generally there is no need to deal with the completer directly.
  ImageStreamCompleter get completer => _completer;
  ImageStreamCompleter _completer;

  List<ImageListener> _listeners;

  /// Assigns a particular [ImageStreamCompleter] to this [ImageStream].
  ///
  /// This is usually done automatically by the [ImageProvider] that created the
  /// [ImageStream].
  void setCompleter(ImageStreamCompleter value) {
    assert(_completer == null);
    _completer = value;
    if (_listeners != null) {
      final List<ImageListener> initialListeners = _listeners;
      _listeners = null;
      initialListeners.forEach(_completer.addListener);
    }
  }

  /// Adds a listener callback that is called whenever a concrete [ImageInfo]
  /// object is available. If a concrete image is already available, this object
  /// will call the listener synchronously.
  void addListener(ImageListener listener) {
    if (_completer != null)
      return _completer.addListener(listener);
    _listeners ??= <ImageListener>[];
    _listeners.add(listener);
  }

  /// Stop listening for new concrete [ImageInfo] objects.
  void removeListener(ImageListener listener) {
    if (_completer != null)
      return _completer.removeListener(listener);
    assert(_listeners != null);
    _listeners.remove(listener);
  }

  /// Returns an object which can be used with `==` to determine if this
  /// [ImageStream] shares the same listeners list as another [ImageStream].
  ///
  /// This can be used to avoid unregistering and reregistering listeners after
  /// calling [ImageProvider.resolve] on a new, but possibly equivalent,
  /// [ImageProvider].
  ///
  /// The key may change once in the lifetime of the object. When it changes, it
  /// will go from being different than other [ImageStream]'s keys to
  /// potentially being the same as others'. No notification is sent when this
  /// happens.
  Object get key => _completer != null ? _completer : this;

  @override
  String toString() {
    final StringBuffer result = new StringBuffer();
    result.write('$runtimeType(');
    if (_completer == null) {
      result.write('unresolved; ');
      if (_listeners != null) {
        result.write('${_listeners.length} listener${_listeners.length == 1 ? "" : "s" }');
      } else {
        result.write('no listeners');
      }
    } else {
      result.write('${_completer.runtimeType}; ');
      final List<String> description = <String>[];
      _completer.debugFillDescription(description);
      result.write(description.join('; '));
    }
    result.write(')');
    return result.toString();
  }
}

/// Base class for those that manage the loading of [ui.Image] objects for
/// [ImageStream]s.
///
/// This class is rarely used directly. Generally, an [ImageProvider] subclass
/// will return an [ImageStream] and automatically configure it with the right
/// [ImageStreamCompleter] when possible.
class ImageStreamCompleter {
  final List<ImageListener> _listeners = <ImageListener>[];
  ImageInfo _current;

  /// Adds a listener callback that is called whenever a concrete [ImageInfo]
  /// object is available. If a concrete image is already available, this object
  /// will call the listener synchronously.
  ///
  /// The listener will be passed a flag indicating whether a synchronous call
  /// occurred. If the listener is added within a render object paint function,
  /// then use this flag to avoid calling markNeedsPaint during a paint.
  void addListener(ImageListener listener) {
    _listeners.add(listener);
    if (_current != null) {
      try {
        listener(_current, true);
      } catch (exception, stack) {
        _handleImageError('by a synchronously-called image listener', exception, stack);
      }
    }
  }

  /// Stop listening for new concrete [ImageInfo] objects.
  void removeListener(ImageListener listener) {
    _listeners.remove(listener);
  }

  /// Calls all the registered listeners to notify them of a new image.
  @protected
  void setImage(ImageInfo image) {
    _current = image;
    if (_listeners.isEmpty)
      return;
    final List<ImageListener> localListeners = new List<ImageListener>.from(_listeners);
    for (ImageListener listener in localListeners) {
      try {
        listener(image, false);
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
    final List<String> description = <String>[];
    debugFillDescription(description);
    return '$runtimeType(${description.join("; ")})';
  }

  /// Accumulates a list of strings describing the object's state. Subclasses
  /// should override this to have their information included in [toString].
  @protected
  @mustCallSuper
  void debugFillDescription(List<String> description) {
    if (_current == null)
      description.add('unresolved');
    else
      description.add('$_current');
    description.add('${_listeners.length} listener${_listeners.length == 1 ? "" : "s" }');
  }
}

/// Manages the loading of [ui.Image] objects for static [ImageStream]s (those
/// with only one frame).
class OneFrameImageStreamCompleter extends ImageStreamCompleter {
  /// Creates a manager for one-frame [ImageStream]s.
  ///
  /// The image resource awaits the given [Future]. When the future resolves,
  /// it notifies the [ImageListener]s that have been registered with
  /// [addListener].
  ///
  /// The [InformationCollector], if provided, is invoked if the given [Future]
  /// resolves with an error, and can be used to supplement the reported error
  /// message (for example, giving the image's URL).
  ///
  /// Errors are reported using [FlutterError.reportError] with the `silent`
  /// argument on [FlutterErrorDetails] set to true, meaning that by default the
  /// message is only dumped to the console in debug mode (see [new
  /// FlutterErrorDetails]).
  OneFrameImageStreamCompleter(Future<ImageInfo> image, { InformationCollector informationCollector }) {
    assert(image != null);
    image.then<Null>(setImage, onError: (dynamic error, StackTrace stack) {
      FlutterError.reportError(new FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'services',
        context: 'resolving a single-frame image stream',
        informationCollector: informationCollector
      ));
    });
  }
}
