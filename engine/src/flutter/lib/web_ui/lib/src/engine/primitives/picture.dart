// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

/// The implementation of [ui.Picture] shared by all renderers.
///
/// Owns the reference count, disposal checks, argument validation, and image
/// retention of a recorded picture, and delegates native operations to a
/// [BackendPicture].
class EnginePicture implements ui.Picture, StackTraceDebugger {
  /// Creates a picture that owns [backendPicture].
  ///
  /// [imageTracker], if provided, holds the image sources drawn into the
  /// picture. They stay open until every handle to this picture is disposed
  /// or garbage collected.
  EnginePicture(BackendPicture backendPicture, [this.imageTracker]) : _isClone = false {
    box = CountedRef<EnginePicture, BackendPicture>(
      backendPicture,
      this,
      'Picture',
      onDispose: _createDisposer(imageTracker),
    );
    _init();
  }

  EnginePicture._clone(this.box, this.imageTracker) : _isClone = true {
    box.ref(this);
    _init();
  }

  static void _disposeBackendPicture(BackendPicture backendPicture) {
    backendPicture.dispose();
  }

  /// Builds the [CountedRef] disposal callback without capturing `this`, so
  /// the finalization registry's strongly held [UniqueRef] does not retain
  /// [box] and prevent garbage collection.
  static void Function(BackendPicture) _createDisposer(PictureImageTracker? tracker) {
    if (tracker == null) {
      return _disposeBackendPicture;
    }
    return (BackendPicture backendPicture) {
      try {
        backendPicture.dispose();
      } finally {
        tracker.releaseAll();
      }
    };
  }

  void _init() {
    assert(() {
      _debugStackTrace = StackTrace.current;
      return true;
    }());
  }

  /// The reference-counted box shared by this picture and its clones.
  late final CountedRef<EnginePicture, BackendPicture> box;

  /// The image sources retained by this picture, or null if it retains none.
  final PictureImageTracker? imageTracker;

  final bool _isClone;
  bool _isDisposed = false;

  @override
  StackTrace get debugStackTrace => _debugStackTrace;
  late StackTrace _debugStackTrace;

  /// The native picture shared by this picture and its clones.
  BackendPicture get backendPicture {
    assert(!_isDisposed, 'The picture has been disposed.');
    return box.nativeObject;
  }

  /// Whether [dispose] has been called on this handle.
  bool get isDisposed => _isDisposed;

  @override
  bool get debugDisposed {
    bool? result;
    assert(() {
      result = _isDisposed;
      return true;
    }());
    if (result != null) {
      return result!;
    }
    throw StateError('Picture.debugDisposed is only available when asserts are enabled.');
  }

  /// A conservative bounding box of all the drawing operations in this
  /// picture.
  ui.Rect get cullRect {
    assert(!_isDisposed, 'Cannot get the cull rect of a disposed picture.');
    return box.nativeObject.cullRect;
  }

  @override
  int get approximateBytesUsed {
    assert(!_isDisposed, 'Cannot get the size of a disposed picture.');
    return box.nativeObject.approximateBytesUsed;
  }

  /// Creates another handle to the same native picture.
  ///
  /// The native picture and its retained image sources stay alive until every
  /// handle is disposed. [ui.Picture.onDispose] fires only for the original
  /// handle.
  EnginePicture clone() {
    assert(!_isDisposed, 'Cannot clone a disposed picture.');
    return EnginePicture._clone(box, imageTracker);
  }

  @override
  void dispose() {
    assert(!_isDisposed, 'Cannot dispose a picture that has already been disposed.');
    if (_isDisposed) {
      return;
    }
    if (!_isClone) {
      ui.Picture.onDispose?.call(this);
    }
    _isDisposed = true;
    box.unref(this);
  }

  @override
  Future<ui.Image> toImage(int width, int height) {
    return Future<ui.Image>.value(toImageSync(width, height));
  }

  @override
  ui.Image toImageSync(
    int width,
    int height, {
    ui.TargetPixelFormat targetFormat = ui.TargetPixelFormat.dontCare,
  }) {
    assert(!_isDisposed, 'Cannot convert a disposed picture to an image.');
    if (width <= 0 || height <= 0) {
      throw Exception('Invalid image dimensions.');
    }
    final BackendPicture picture = box.nativeObject;
    final BackendImage backendImage = picture.toImageSync(width, height, targetFormat);
    // A deferred image renders this picture later, so it must keep the image
    // sources recorded into the picture open for as long as it is alive.
    final PictureImageTracker? retainedTracker = picture.toImageSyncIsDeferred
        ? imageTracker?.clone()
        : null;
    return EngineImage(backendImage, width, height, retainedTracker: retainedTracker);
  }

  @override
  String toString() => 'Picture';
}

enum _RecorderState { idle, recording, disposed }

/// The native state of an active recording, owned by a single [UniqueRef] so
/// that an abandoned recording releases both the native recorder and the
/// retained image sources when it is garbage collected.
class _RecordingSession {
  _RecordingSession(this.backendRecorder, this.tracker);

  final BackendPictureRecorder backendRecorder;
  final PictureImageTracker tracker;

  /// Whether [tracker] now belongs to the recorded picture.
  bool trackerHandedOff = false;

  static void dispose(_RecordingSession session) {
    try {
      session.backendRecorder.dispose();
    } finally {
      if (!session.trackerHandedOff) {
        session.tracker.releaseAll();
      }
    }
  }
}

/// The implementation of [ui.PictureRecorder] shared by all renderers.
///
/// A recorder is single-use: it starts idle, records once when passed to
/// [ui.Canvas], and is disposed by [endRecording]. No native objects are
/// allocated until recording begins.
class EnginePictureRecorder implements ui.PictureRecorder {
  /// Creates an idle picture recorder.
  EnginePictureRecorder();

  /// Retains the image sources drawn into the recording canvas.
  ///
  /// Ownership passes to the recorded picture when [endRecording] is called,
  /// if any image sources were recorded.
  final PictureImageTracker tracker = PictureImageTracker();

  _RecorderState _state = _RecorderState.idle;
  EngineCanvas? _recordingCanvas;
  UniqueRef<_RecordingSession>? _sessionRef;

  @override
  bool get isRecording => _state == _RecorderState.recording;

  /// Whether this recorder has finished its recording and can no longer be
  /// used.
  bool get isDisposed => _state == _RecorderState.disposed;

  /// Whether this recorder has finished its recording.
  ///
  /// This is only available when asserts are enabled.
  bool get debugDisposed {
    bool? result;
    assert(() {
      result = isDisposed;
      return true;
    }());
    if (result != null) {
      return result!;
    }
    throw StateError('PictureRecorder.debugDisposed is only available when asserts are enabled.');
  }

  /// Starts recording drawing operations bounded by [cullRect] and returns
  /// the canvas that records them.
  ///
  /// Callers must go through [EngineCanvas.fromRecorder], which checks that
  /// this recorder is idle.
  EngineCanvas beginRecording(ui.Rect cullRect) {
    assert(_state == _RecorderState.idle);
    final BackendPictureRecorder backendRecorder = renderer.createPictureRecorder();
    final BackendCanvas backendCanvas;
    try {
      backendCanvas = backendRecorder.beginRecording(cullRect);
    } catch (_) {
      backendRecorder.dispose();
      rethrow;
    }
    _sessionRef = UniqueRef<_RecordingSession>(
      this,
      _RecordingSession(backendRecorder, tracker),
      'PictureRecorder',
      onDispose: _RecordingSession.dispose,
    );
    _state = _RecorderState.recording;
    return _recordingCanvas = EngineCanvas(backendCanvas, recorder: this, tracker: tracker);
  }

  @override
  EnginePicture endRecording() {
    if (_state != _RecorderState.recording) {
      throw StateError('PictureRecorder did not start recording.');
    }
    _state = _RecorderState.disposed;
    // Native `dart:ui` invalidates the canvas, so later calls on it are no-ops
    // instead of touching the finished native recorder.
    _recordingCanvas!.invalidate();
    _recordingCanvas = null;

    final UniqueRef<_RecordingSession> sessionRef = _sessionRef!;
    _sessionRef = null;
    final _RecordingSession session = sessionRef.nativeObject;
    final BackendPicture backendPicture;
    try {
      backendPicture = session.backendRecorder.endRecording();
      session.trackerHandedOff = true;
    } finally {
      sessionRef.dispose();
    }

    final result = EnginePicture(backendPicture, tracker.isEmpty ? null : tracker);
    // Invoke the handler here rather than in the picture constructor so that
    // [EnginePicture.approximateBytesUsed] is available to it.
    ui.Picture.onCreate?.call(result);
    return result;
  }

  @override
  String toString() => 'PictureRecorder(recording: $isRecording)';
}
