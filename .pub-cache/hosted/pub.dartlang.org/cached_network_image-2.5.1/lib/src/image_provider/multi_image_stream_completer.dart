import 'dart:async';
import 'dart:ui' as ui show Codec, FrameInfo;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/scheduler.dart';

/// Slows down animations by this factor to help in development.
double get timeDilation => _timeDilation;
double _timeDilation = 1.0;

/// An ImageStreamCompleter with support for loading multiple images.
class MultiImageStreamCompleter extends ImageStreamCompleter {
  /// The constructor to create an MultiImageStreamCompleter. The [codec]
  /// should be a stream with the images that should be shown. The
  /// [chunkEvents] should indicate the [ImageChunkEvent]s of the first image
  /// to show.
  MultiImageStreamCompleter({
    @required Stream<ui.Codec> codec,
    @required double scale,
    Stream<ImageChunkEvent> chunkEvents,
    InformationCollector informationCollector,
  })  : assert(codec != null),
        _informationCollector = informationCollector,
        _scale = scale {
    codec.listen((event) {
      if (_timer != null) {
        _nextImageCodec = event;
      } else {
        _handleCodecReady(event);
      }
    }, onError: (dynamic error, StackTrace stack) {
      reportError(
        context: ErrorDescription('resolving an image codec'),
        exception: error,
        stack: stack,
        informationCollector: informationCollector,
        silent: true,
      );
    });
    if (chunkEvents != null) {
      chunkEvents.listen(
        reportImageChunkEvent,
        onError: (dynamic error, StackTrace stack) {
          reportError(
            context: ErrorDescription('loading an image'),
            exception: error,
            stack: stack,
            informationCollector: informationCollector,
            silent: true,
          );
        },
      );
    }
  }

  ui.Codec _codec;
  ui.Codec _nextImageCodec;
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

  void _switchToNewCodec() {
    _framesEmitted = 0;
    _timer = null;
    _handleCodecReady(_nextImageCodec);
    _nextImageCodec = null;
  }

  void _handleCodecReady(ui.Codec codec) {
    _codec = codec;
    assert(_codec != null);

    if (hasListeners) {
      _decodeNextFrameAndSchedule();
    }
  }

  void _handleAppFrame(Duration timestamp) {
    _frameCallbackScheduled = false;
    if (!hasListeners) return;
    if (_isFirstFrame() || _hasFrameDurationPassed(timestamp)) {
      _emitFrame(ImageInfo(image: _nextFrame.image, scale: _scale));
      _shownTimestamp = timestamp;
      _frameDuration = _nextFrame.duration;
      _nextFrame = null;
      if (_framesEmitted % _codec.frameCount == 0 && _nextImageCodec != null) {
        _switchToNewCodec();
      } else {
        final completedCycles = _framesEmitted ~/ _codec.frameCount;
        if (_codec.repetitionCount == -1 ||
            completedCycles <= _codec.repetitionCount) {
          _decodeNextFrameAndSchedule();
        }
      }
      return;
    }
    final delay = _frameDuration - (timestamp - _shownTimestamp);
    _timer = Timer(delay * timeDilation, _scheduleAppFrame);
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
        context: ErrorDescription('resolving an image frame'),
        exception: exception,
        stack: stack,
        informationCollector: _informationCollector,
        silent: true,
      );
      return;
    }
    if (_codec.frameCount == 1) {
      // ImageStreamCompleter listeners removed while waiting for next frame to
      // be decoded.
      // There's no reason to emit the frame without active listeners.
      if (!hasListeners) {
        return;
      }

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
  void addListener(ImageStreamListener listener) {
    if (!hasListeners && _codec != null) _decodeNextFrameAndSchedule();
    super.addListener(listener);
  }

  @override
  void removeListener(ImageStreamListener listener) {
    super.removeListener(listener);
    if (!hasListeners) {
      _timer?.cancel();
      _timer = null;
    }
  }
}
