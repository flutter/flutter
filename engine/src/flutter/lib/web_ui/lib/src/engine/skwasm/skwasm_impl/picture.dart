// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/src/engine/skwasm/skwasm_impl.dart';
import 'package:ui/ui.dart' as ui;

class SkwasmPicture implements LayerPicture, StackTraceDebugger {
  SkwasmPicture.fromHandle(PictureHandle handle, [this.imageTracker]) : _isClone = false {
    box = CountedRef<SkwasmPicture, PictureHandle>(
      handle,
      this,
      'Picture',
      onDispose: (PictureHandle h) {
        pictureDispose(h);
        imageTracker?.releaseAll();
      },
    );
    _init();
    ui.Picture.onCreate?.call(this);
  }

  /// Clones a picture from an existing [handleBox], retaining references
  /// to any recorded image sources.
  SkwasmPicture.cloneOf(CountedRef<SkwasmPicture, PictureHandle> handleBox, [this.imageTracker])
    : box = handleBox,
      _isClone = true {
    box.ref(this);
    _init();
  }

  final bool _isClone;

  /// Retained image sources for images recorded onto this picture.
  final PictureImageTracker? imageTracker;

  void _init() {
    assert(() {
      _debugStackTrace = StackTrace.current;
      return true;
    }());
  }

  @override
  StackTrace get debugStackTrace => _debugStackTrace;
  late StackTrace _debugStackTrace;

  late final CountedRef<SkwasmPicture, PictureHandle> box;

  PictureHandle get handle => box.nativeObject;

  @override
  Future<ui.Image> toImage(int width, int height) async => toImageSync(width, height);

  @override
  int get approximateBytesUsed => pictureApproximateBytesUsed(handle);

  @override
  void dispose() {
    if (_disposed) {
      return;
    }
    if (!_isClone) {
      ui.Picture.onDispose?.call(this);
    }
    _disposed = true;
    box.unref(this);
  }

  @override
  ui.Image toImageSync(
    int width,
    int height, {
    ui.TargetPixelFormat targetFormat = ui.TargetPixelFormat.dontCare,
  }) {
    final ImageHandle handleImg = imageCreateFromPicture(handle, width, height);
    return EngineImage(SkwasmImage(handleImg), width, height);
  }

  @override
  ui.Rect get cullRect {
    return withStackScope((StackScope s) {
      final RawRect rect = s.allocFloatArray(4);
      pictureGetCullRect(handle, rect);
      return s.convertRectFromNative(rect);
    });
  }

  @override
  LayerPicture clone() => SkwasmPicture.cloneOf(box, imageTracker);

  @override
  String toString() {
    return 'SkwasmPicture(${handle.address})';
  }

  @override
  bool get isDisposed => _disposed;

  bool _disposed = false;

  @override
  bool get debugDisposed {
    bool? result;
    assert(() {
      result = _disposed;
      return true;
    }());

    if (result != null) {
      return result!;
    }

    throw StateError('Picture.debugDisposed is only available when asserts are enabled.');
  }
}

/// Records a sequence of canvas drawing commands into a [SkwasmPicture].
///
/// Manages a [PictureImageTracker] that retains any [ImageSource] instances
/// drawn to the recording canvas until the resulting picture is finished and
/// subsequently disposed.
///
/// If a recorder is abandoned and collected by garbage collection without
/// [endRecording] being called, [finalizer] releases all retained image
/// sources to prevent memory leaks.
class SkwasmPictureRecorder extends SkwasmObjectWrapper<RawPictureRecorder>
    implements LayerPictureRecorder {
  SkwasmPictureRecorder()
    : super(
        pictureRecorderCreate(),
        (PictureRecorderHandle h) => pictureRecorderDispose(h),
        'PictureRecorder',
      );

  @visibleForTesting
  static NativeMemoryFinalizer finalizer = NativeMemoryFinalizer((Object tracker) {
    (tracker as PictureImageTracker).releaseAll();
  });

  SkwasmCanvas? _recordingCanvas;

  /// Tracks [ImageSource] references for draw operations recorded on this recorder.
  final PictureImageTracker tracker = PictureImageTracker();

  /// The active recording canvas, or null if not recording.
  SkwasmCanvas? get recordingCanvas => _recordingCanvas;

  /// Begins recording canvas commands within the specified [bounds].
  SkwasmCanvas beginRecording(ui.Rect bounds) {
    if (isRecording) {
      throw StateError('PictureRecorder is already recording');
    }
    _isRecording = true;
    final canvas = SkwasmCanvas.fromHandle(
      withStackScope(
        (StackScope s) => pictureRecorderBeginRecording(handle, s.convertRectToNative(bounds)),
      ),
      recorder: this,
      tracker: tracker,
    );
    _recordingCanvas = canvas;
    finalizer.attach(this, tracker, detach: this);
    return canvas;
  }

  @override
  SkwasmPicture endRecording() {
    if (!isRecording) {
      throw StateError('PictureRecorder is not recording');
    }
    _isRecording = false;
    // Detach the unended-recording finalizer now that ownership of the tracker
    // is being handed off to the resulting SkwasmPicture.
    finalizer.detach(this);
    _recordingCanvas?.clearTracker();
    _recordingCanvas = null;

    final PictureImageTracker? imageTracker = tracker.isEmpty ? null : tracker;
    final picture = SkwasmPicture.fromHandle(pictureRecorderEndRecording(handle), imageTracker);
    dispose();
    return picture;
  }

  @override
  void dispose() {
    if (_isRecording) {
      _isRecording = false;
      finalizer.detach(this);
      _recordingCanvas?.clearTracker();
      _recordingCanvas = null;
      tracker.releaseAll();
    }
    super.dispose();
  }

  bool _isRecording = false;

  @override
  bool get isRecording => _isRecording;
}
