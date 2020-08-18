// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.10
part of engine;

class CkPictureRecorder implements ui.PictureRecorder {
  ui.Rect? _cullRect;
  SkPictureRecorder? _skRecorder;
  CkCanvas? _recordingCanvas;

  CkCanvas beginRecording(ui.Rect bounds) {
    _cullRect = bounds;
    final SkPictureRecorder recorder = _skRecorder = SkPictureRecorder();
    final SkRect skRect = toSkRect(bounds);
    final SkCanvas skCanvas = recorder.beginRecording(skRect);
    return _recordingCanvas = CkCanvas(skCanvas);
  }

  CkCanvas? get recordingCanvas => _recordingCanvas;

  @override
  ui.Picture endRecording() {
    final SkPictureRecorder? recorder = _skRecorder;

    if (recorder == null) {
      throw StateError('PictureRecorder is not recording');
    }

    final SkPicture skPicture = recorder.finishRecordingAsPicture();
    recorder.delete();
    _skRecorder = null;
    return CkPicture(skPicture, _cullRect);
  }

  @override
  bool get isRecording => _skRecorder != null;
}
