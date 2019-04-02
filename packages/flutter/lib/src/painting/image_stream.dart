// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' as ui show Image, Codec, FrameInfo;
import 'dart:ui' show hashValues;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// A [dart:ui.Image] object with its corresponding scale.
///
/// ImageInfo objects are used by [ImageStream] objects to represent the
/// actual data of the image once it has been obtained.
@immutable
class ImageInfo {
  /// Creates an [ImageInfo] object for the given image and scale.
  ///
  /// Both the image and the scale must not be null.
  const ImageInfo({ @required this.image, this.scale = 1.0 })
    : assert(image != null),
      assert(scale != null);

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
  /// by the [dart:ui.Image.width] and [dart:ui.Image.height] properties) are double the
  /// height and width that should be used when painting the image (e.g. in the
  /// arguments given to [Canvas.drawImage]).
  final double scale;

  @override
  String toString() => '$image @ ${scale}x';

  @override
  int get hashCode => hashValues(image, scale);

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType)
      return false;
    final ImageInfo typedOther = other;
    return typedOther.image == image
        && typedOther.scale == scale;
  }
}

/// Signature for callbacks reporting that an image is available.
///
/// Used by [ImageStream].
///
/// The `synchronousCall` argument is true if the listener is being invoked
/// during the call to `addListener`. This can be useful if, for example,
/// [ImageStream.addListener] is invoked during a frame, so that a new rendering
/// frame is requested if the call was asynchronous (after the current frame)
/// and no rendering frame is requested if the call was synchronous (within the
/// same stack frame as the call to [ImageStream.addListener]).
typedef ImageListener = void Function(ImageInfo image, bool synchronousCall);

/// Signature for reporting errors when resolving images.
///
/// Used by [ImageStream] and [precacheImage] to report errors.
typedef ImageErrorListener = void Function(dynamic exception, StackTrace stackTrace);

class _ImageListenerPair {
  _ImageListenerPair(this.listener, this.errorListener);
  final ImageListener listener;
  final ImageErrorListener errorListener;
}

/// A handle to an image resource.
///
/// ImageStream represents a handle to a [dart:ui.Image] object and its scale
/// (together represented by an [ImageInfo] object). The underlying image object
/// might change over time, either because the image is animating or because the
/// underlying image resource was mutated.
///
/// ImageStream objects can also represent an image that hasn't finished
/// loading.
///
/// ImageStream objects are backed by [ImageStreamCompleter] objects.
///
/// See also:
///
///  * [ImageProvider], which has an example that includes the use of an
///    [ImageStream] in a [Widget].
class ImageStream extends Diagnosticable {
  /// Create an initially unbound image stream.
  ///
  /// Once an [ImageStreamCompleter] is available, call [setCompleter].
  ImageStream();

  /// The completer that has been assigned to this image stream.
  ///
  /// Generally there is no need to deal with the completer directly.
  ImageStreamCompleter get completer => _completer;
  ImageStreamCompleter _completer;

  List<_ImageListenerPair> _listeners;

  /// Assigns a particular [ImageStreamCompleter] to this [ImageStream].
  ///
  /// This is usually done automatically by the [ImageProvider] that created the
  /// [ImageStream].
  ///
  /// This method can only be called once per stream. To have an [ImageStream]
  /// represent multiple images over time, assign it a completer that
  /// completes several images in succession.
  void setCompleter(ImageStreamCompleter value) {
    assert(_completer == null);
    _completer = value;
    if (_listeners != null) {
      final List<_ImageListenerPair> initialListeners = _listeners;
      _listeners = null;
      for (_ImageListenerPair listenerPair in initialListeners) {
        _completer.addListener(
          listenerPair.listener,
          onError: listenerPair.errorListener,
        );
      }
    }
  }

  /// Adds a listener callback that is called whenever a new concrete [ImageInfo]
  /// object is available. If a concrete image is already available, this object
  /// will call the listener synchronously.
  ///
  /// If the assigned [completer] completes multiple images over its lifetime,
  /// this listener will fire multiple times.
  ///
  /// The listener will be passed a flag indicating whether a synchronous call
  /// occurred. If the listener is added within a render object paint function,
  /// then use this flag to avoid calling [RenderObject.markNeedsPaint] during
  /// a paint.
  ///
  /// An [ImageErrorListener] can also optionally be added along with the
  /// `listener`. If an error occurred, `onError` will be called instead of
  /// `listener`.
  ///
  /// If a `listener` or `onError` handler is registered multiple times, then it
  /// will be called multiple times when the image stream completes (whether
  /// because a new image is available or because an error occurs,
  /// respectively). In general, registering a listener multiple times is
  /// discouraged because [removeListener] will remove the first instance that
  /// was added, even if it was added with a different `onError` than the
  /// intended paired `addListener` call.
  void addListener(ImageListener listener, { ImageErrorListener onError }) {
    if (_completer != null)
      return _completer.addListener(listener, onError: onError);
    _listeners ??= <_ImageListenerPair>[];
    _listeners.add(_ImageListenerPair(listener, onError));
  }

  /// Stop listening for new concrete [ImageInfo] objects and errors from
  /// the `listener`'s associated [ImageErrorListener].
  ///
  /// If `listener` has been added multiple times, this removes the first
  /// instance of the listener, along with the `onError` listener that was
  /// registered with that first instance. This might not be the instance that
  /// the `addListener` corresponding to this `removeListener` had added.
  ///
  /// For example, if one widget calls [addListener] with a global static
  /// function and a private error handler, and another widget calls
  /// [addListener] with the same global static function but a different private
  /// error handler, then the second widget is disposed and removes the image
  /// listener (the aforementioned global static function), it will remove the
  /// error handler from the first widget, not the second. If an error later
  /// occurs, the first widget, which is still supposedly listening, will not
  /// receive any messages, while the second, which is supposedly disposed, will
  /// have its callback invoked.
  void removeListener(ImageListener listener) {
    if (_completer != null)
      return _completer.removeListener(listener);
    assert(_listeners != null);
    for (int i = 0; i < _listeners.length; i += 1) {
      if (_listeners[i].listener == listener) {
        _listeners.removeAt(i);
        break;
      }
    }
  }

  /// Returns an object which can be used with `==` to determine if this
  /// [ImageStream] shares the same listeners list as another [ImageStream].
  ///
  /// This can be used to avoid un-registering and re-registering listeners
  /// after calling [ImageProvider.resolve] on a new, but possibly equivalent,
  /// [ImageProvider].
  ///
  /// The key may change once in the lifetime of the object. When it changes, it
  /// will go from being different than other [ImageStream]'s keys to
  /// potentially being the same as others'. No notification is sent when this
  /// happens.
  Object get key => _completer != null ? _completer : this;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ObjectFlagProperty<ImageStreamCompleter>(
      'completer',
      _completer,
      ifPresent: _completer?.toStringShort(),
      ifNull: 'unresolved',
    ));
    properties.add(ObjectFlagProperty<List<_ImageListenerPair>>(
      'listeners',
      _listeners,
      ifPresent: '${_listeners?.length} listener${_listeners?.length == 1 ? "" : "s" }',
      ifNull: 'no listeners',
      level: _completer != null ? DiagnosticLevel.hidden : DiagnosticLevel.info,
    ));
    _completer?.debugFillProperties(properties);
  }
}

/// Base class for those that manage the loading of [dart:ui.Image] objects for
/// [ImageStream]s.
///
/// [ImageStreamListener] objects are rarely constructed directly. Generally, an
/// [ImageProvider] subclass will return an [ImageStream] and automatically
/// configure it with the right [ImageStreamCompleter] when possible.
abstract class ImageStreamCompleter extends Diagnosticable {
  final List<_ImageListenerPair> _listeners = <_ImageListenerPair>[];
  ImageInfo _currentImage;
  FlutterErrorDetails _currentError;

  /// Whether any listeners are currently registered.
  ///
  /// Clients should not depend on this value for their behavior, because having
  /// one listener's logic change when another listener happens to start or stop
  /// listening will lead to extremely hard-to-track bugs. Subclasses might use
  /// this information to determine whether to do any work when there are no
  /// listeners, however; for example, [MultiFrameImageStreamCompleter] uses it
  /// to determine when to iterate through frames of an animated image.
  ///
  /// Typically this is used by overriding [addListener], checking if
  /// [hasListeners] is false before calling `super.addListener()`, and if so,
  /// starting whatever work is needed to determine when to call
  /// [notifyListeners]; and similarly, by overriding [removeListener], checking
  /// if [hasListeners] is false after calling `super.removeListener()`, and if
  /// so, stopping that same work.
  @protected
  bool get hasListeners => _listeners.isNotEmpty;

  /// Adds a listener callback that is called whenever a new concrete [ImageInfo]
  /// object is available or an error is reported. If a concrete image is
  /// already available, or if an error has been already reported, this object
  /// will call the listener or error listener synchronously.
  ///
  /// If the [ImageStreamCompleter] completes multiple images over its lifetime,
  /// this listener will fire multiple times.
  ///
  /// The listener will be passed a flag indicating whether a synchronous call
  /// occurred. If the listener is added within a render object paint function,
  /// then use this flag to avoid calling [RenderObject.markNeedsPaint] during
  /// a paint.
  ///
  /// An [ImageErrorListener] can also optionally be added along with the
  /// `listener`. If an error occurred, `onError` will be called instead of
  /// `listener`.
  ///
  /// If a `listener` or `onError` handler is registered multiple times, then it
  /// will be called multiple times when the image stream completes (whether
  /// because a new image is available or because an error occurs,
  /// respectively). In general, registering a listener multiple times is
  /// discouraged because [removeListener] will remove the first instance that
  /// was added, even if it was added with a different `onError` than the
  /// intended paired `addListener` call.
  void addListener(ImageListener listener, { ImageErrorListener onError }) {
    _listeners.add(_ImageListenerPair(listener, onError));
    if (_currentImage != null) {
      try {
        listener(_currentImage, true);
      } catch (exception, stack) {
        reportError(
          context: 'by a synchronously-called image listener',
          exception: exception,
          stack: stack,
        );
      }
    }
    if (_currentError != null && onError != null) {
      try {
        onError(_currentError.exception, _currentError.stack);
      } catch (exception, stack) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: exception,
            library: 'image resource service',
            context: 'by a synchronously-called image error listener',
            stack: stack,
          ),
        );
      }
    }
  }

  /// Stop listening for new concrete [ImageInfo] objects and errors from
  /// its associated [ImageErrorListener].
  ///
  /// If `listener` has been added multiple times, this removes the first
  /// instance of the listener, along with the `onError` listener that was
  /// registered with that first instance. This might not be the instance that
  /// the `addListener` corresponding to this `removeListener` had added.
  void removeListener(ImageListener listener) {
    for (int i = 0; i < _listeners.length; i += 1) {
      if (_listeners[i].listener == listener) {
        _listeners.removeAt(i);
        break;
      }
    }
  }

  /// Calls all the registered listeners to notify them of a new image.
  @protected
  void setImage(ImageInfo image) {
    _currentImage = image;
    if (_listeners.isEmpty)
      return;
    final List<ImageListener> localListeners = _listeners.map<ImageListener>(
      (_ImageListenerPair listenerPair) => listenerPair.listener
    ).toList();
    for (ImageListener listener in localListeners) {
      try {
        listener(image, false);
      } catch (exception, stack) {
        reportError(
          context: 'by an image listener',
          exception: exception,
          stack: stack,
        );
      }
    }
  }

  /// Calls all the registered error listeners to notify them of an error that
  /// occurred while resolving the image.
  ///
  /// If no error listeners are attached, a [FlutterError] will be reported
  /// instead.
  ///
  /// The `context` should be a string describing where the error was caught, in
  /// a form that will make sense in English when following the word "thrown",
  /// as in "thrown while obtaining the image from the network" (for the context
  /// "while obtaining the image from the network").
  ///
  /// The `exception` is the error being reported; the `stack` is the
  /// [StackTrace] associated with the exception.
  ///
  /// The `informationCollector` is a callback (of type [InformationCollector])
  /// that is called when the exception is used by [FlutterError.reportError].
  /// It is used to obtain further details to include in the logs, which may be
  /// expensive to collect, and thus should only be collected if the error is to
  /// be logged in the first place.
  ///
  /// The `silent` argument causes the exception to not be reported to the logs
  /// in release builds, if passed to [FlutterError.reportError]. (It is still
  /// sent to error handlers.) It should be set to true if the error is one that
  /// is expected to be encountered in release builds, for example network
  /// errors. That way, logs on end-user devices will not have spurious
  /// messages, but errors during development will still be reported.
  ///
  /// See [FlutterErrorDetails] for further details on these values.
  @protected
  void reportError({
    String context,
    dynamic exception,
    StackTrace stack,
    InformationCollector informationCollector,
    bool silent = false,
  }) {
    _currentError = FlutterErrorDetails(
      exception: exception,
      stack: stack,
      library: 'image resource service',
      context: context,
      informationCollector: informationCollector,
      silent: silent,
    );

    final List<ImageErrorListener> localErrorListeners =
      _listeners.map<ImageErrorListener>(
        (_ImageListenerPair listenerPair) => listenerPair.errorListener
      ).where(
        (ImageErrorListener errorListener) => errorListener != null
      ).toList();

    if (localErrorListeners.isEmpty) {
      FlutterError.reportError(_currentError);
    } else {
      for (ImageErrorListener errorListener in localErrorListeners) {
        try {
          errorListener(exception, stack);
        } catch (exception, stack) {
          FlutterError.reportError(
            FlutterErrorDetails(
              context: 'when reporting an error to an image listener',
              library: 'image resource service',
              exception: exception,
              stack: stack,
            ),
          );
        }
      }
    }
  }

  /// Accumulates a list of strings describing the object's state. Subclasses
  /// should override this to have their information included in [toString].
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(DiagnosticsProperty<ImageInfo>('current', _currentImage, ifNull: 'unresolved', showName: false));
    description.add(ObjectFlagProperty<List<_ImageListenerPair>>(
      'listeners',
      _listeners,
      ifPresent: '${_listeners?.length} listener${_listeners?.length == 1 ? "" : "s" }',
    ));
  }
}

/// Manages the loading of [dart:ui.Image] objects for static [ImageStream]s (those
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
  OneFrameImageStreamCompleter(Future<ImageInfo> image, { InformationCollector informationCollector })
      : assert(image != null) {
    image.then<void>(setImage, onError: (dynamic error, StackTrace stack) {
      reportError(
        context: 'resolving a single-frame image stream',
        exception: error,
        stack: stack,
        informationCollector: informationCollector,
        silent: true,
      );
    });
  }
}

/// Manages the decoding and scheduling of image frames.
///
/// New frames will only be emitted while there are registered listeners to the
/// stream (registered with [addListener]).
///
/// This class deals with 2 types of frames:
///
///  * image frames - image frames of an animated image.
///  * app frames - frames that the flutter engine is drawing to the screen to
///    show the app GUI.
///
/// For single frame images the stream will only complete once.
///
/// For animated images, this class eagerly decodes the next image frame,
/// and notifies the listeners that a new frame is ready on the first app frame
/// that is scheduled after the image frame duration has passed.
///
/// Scheduling new timers only from scheduled app frames, makes sure we pause
/// the animation when the app is not visible (as new app frames will not be
/// scheduled).
///
/// See the following timeline example:
///
///     | Time | Event                                      | Comment                   |
///     |------|--------------------------------------------|---------------------------|
///     | t1   | App frame scheduled (image frame A posted) |                           |
///     | t2   | App frame scheduled                        |                           |
///     | t3   | App frame scheduled                        |                           |
///     | t4   | Image frame B decoded                      |                           |
///     | t5   | App frame scheduled                        | t5 - t1 < frameB_duration |
///     | t6   | App frame scheduled (image frame B posted) | t6 - t1 > frameB_duration |
///
class MultiFrameImageStreamCompleter extends ImageStreamCompleter {
  /// Creates a image stream completer.
  ///
  /// Immediately starts decoding the first image frame when the codec is ready.
  ///
  /// [codec] is a future for an initialized [ui.Codec] that will be used to
  /// decode the image.
  /// [scale] is the linear scale factor for drawing this frames of this image
  /// at their intended size.
  MultiFrameImageStreamCompleter({
    @required Future<ui.Codec> codec,
    @required double scale,
    InformationCollector informationCollector,
  }) : assert(codec != null),
       _informationCollector = informationCollector,
       _scale = scale {
    codec.then<void>(_handleCodecReady, onError: (dynamic error, StackTrace stack) {
      reportError(
        context: 'resolving an image codec',
        exception: error,
        stack: stack,
        informationCollector: informationCollector,
        silent: true,
      );
    });
  }

  ui.Codec _codec;
  final double _scale;
  final InformationCollector _informationCollector;
  ui.FrameInfo _nextFrame;
  // When the current was first shown.
  Duration _shownTimestamp;
  // The requested duration for the current frame;
  Duration _frameDuration;
  // How many frames have been emitted so far.
  int _framesEmitted = 0;
  Timer _timer;

  // Used to guard against registering multiple _handleAppFrame callbacks for the same frame.
  bool _frameCallbackScheduled = false;

  void _handleCodecReady(ui.Codec codec) {
    _codec = codec;
    assert(_codec != null);

    if (hasListeners) {
      _decodeNextFrameAndSchedule();
    }
  }

  void _handleAppFrame(Duration timestamp) {
    _frameCallbackScheduled = false;
    if (!hasListeners)
      return;
    if (_isFirstFrame() || _hasFrameDurationPassed(timestamp)) {
      _emitFrame(ImageInfo(image: _nextFrame.image, scale: _scale));
      _shownTimestamp = timestamp;
      _frameDuration = _nextFrame.duration;
      _nextFrame = null;
      final int completedCycles = _framesEmitted ~/ _codec.frameCount;
      if (_codec.repetitionCount == -1 || completedCycles <= _codec.repetitionCount) {
        _decodeNextFrameAndSchedule();
      }
      return;
    }
    final Duration delay = _frameDuration - (timestamp - _shownTimestamp);
    _timer = Timer(delay * timeDilation, () {
      _scheduleAppFrame();
    });
  }

  bool _isFirstFrame() {
    return _frameDuration == null;
  }

  bool _hasFrameDurationPassed(Duration timestamp) {
    assert(_shownTimestamp != null);
    return timestamp - _shownTimestamp >= _frameDuration;
  }

  Future<void> _decodeNextFrameAndSchedule() async {
    try {
      _nextFrame = await _codec.getNextFrame();
    } catch (exception, stack) {
      reportError(
        context: 'resolving an image frame',
        exception: exception,
        stack: stack,
        informationCollector: _informationCollector,
        silent: true,
      );
      return;
    }
    if (_codec.frameCount == 1) {
      // This is not an animated image, just return it and don't schedule more
      // frames.
      _emitFrame(ImageInfo(image: _nextFrame.image, scale: _scale));
      return;
    }
    _scheduleAppFrame();
  }

  void _scheduleAppFrame() {
    if (_frameCallbackScheduled) {
      return;
    }
    _frameCallbackScheduled = true;
    SchedulerBinding.instance.scheduleFrameCallback(_handleAppFrame);
  }

  void _emitFrame(ImageInfo imageInfo) {
    setImage(imageInfo);
    _framesEmitted += 1;
  }

  @override
  void addListener(ImageListener listener, { ImageErrorListener onError }) {
    if (!hasListeners && _codec != null)
      _decodeNextFrameAndSchedule();
    super.addListener(listener, onError: onError);
  }

  @override
  void removeListener(ImageListener listener) {
    super.removeListener(listener);
    if (!hasListeners) {
      _timer?.cancel();
      _timer = null;
    }
  }
}
