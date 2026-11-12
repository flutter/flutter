// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

/// Records a sequence of canvas drawing commands into a [CkPicture].
///
/// Manages a [PictureImageTracker] that retains any [ImageSource] instances
/// drawn to the recording canvas until the resulting picture is finished and
/// subsequently disposed.
///
/// If a recorder is abandoned and collected by garbage collection without
/// [endRecording] being called, [finalizer] releases all retained image
/// sources to prevent memory leaks.
class CkPictureRecorder implements LayerPictureRecorder {
  @visibleForTesting
  static Finalizer finalizer = NativeMemoryFinalizer((Object tracker) {
    (tracker as PictureImageTracker).releaseAll();
  });

  SkPictureRecorder? _skRecorder;
  CkCanvas? _recordingCanvas;

  /// Tracks [ImageSource] references for draw operations recorded on this recorder.
  final PictureImageTracker tracker = PictureImageTracker();

  /// Begins recording canvas commands within the specified [bounds].
  CkCanvas beginRecording(ui.Rect bounds) {
    final SkPictureRecorder recorder = _skRecorder = SkPictureRecorder();
    final Float32List skRect = toSkRect(bounds);
    final SkCanvas skCanvas = recorder.beginRecording(skRect);
    finalizer.attach(this, tracker, detach: this);
    return _recordingCanvas = CkCanvas.fromSkCanvas(skCanvas, recorder: this, tracker: tracker);
  }

  /// The active recording canvas, or null if not recording.
  CkCanvas? get recordingCanvas => _recordingCanvas;

  @override
  CkPicture endRecording() {
    final SkPictureRecorder? recorder = _skRecorder;

    if (recorder == null) {
      throw StateError('PictureRecorder is not recording');
    }

    // Detach the unended-recording finalizer now that ownership of the tracker
    // is being handed off to the resulting CkPicture.
    finalizer.detach(this);
    _recordingCanvas?.clearTracker();
    _recordingCanvas = null;
    final SkPicture skPicture = recorder.finishRecordingAsPicture();
    recorder.delete();
    _skRecorder = null;
    final PictureImageTracker? imageTracker = tracker.isEmpty ? null : tracker;
    final result = CkPicture(skPicture, imageTracker);
    // We invoke the handler here, not in the picture constructor, because we want
    // [result.approximateBytesUsed] to be available for the handler.
    ui.Picture.onCreate?.call(result);
    return result;
  }

  @override
  bool get isRecording => _skRecorder != null;

  @override
  bool get debugDisposed => _skRecorder == null;
}
