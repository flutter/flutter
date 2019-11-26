// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of engine;

/// An implementation of [ui.PictureRecorder] backed by a [RecordingCanvas].
class EnginePictureRecorder implements ui.PictureRecorder {
  EnginePictureRecorder();

  RecordingCanvas _canvas;
  ui.Rect cullRect;
  bool _isRecording = false;

  RecordingCanvas beginRecording(ui.Rect bounds) {
    assert(!_isRecording);
    cullRect = bounds;
    _isRecording = true;
    _canvas = RecordingCanvas(cullRect);
    return _canvas;
  }

  @override
  bool get isRecording => _isRecording;

  @override
  ui.Picture endRecording() {
    // Returning null is what the flutter engine does:
    // lib/ui/painting/picture_recorder.cc
    if (!_isRecording) {
      return null;
    }
    _isRecording = false;
    return EnginePicture(_canvas, cullRect);
  }
}

/// An implementation of [ui.Picture] which is backed by a [RecordingCanvas].
class EnginePicture implements ui.Picture {
  /// This class is created by the engine, and should not be instantiated
  /// or extended directly.
  ///
  /// To create a [Picture], use a [PictureRecorder].
  EnginePicture(this.recordingCanvas, this.cullRect);

  @override
  Future<ui.Image> toImage(int width, int height) async {
    final BitmapCanvas canvas = BitmapCanvas(ui.Rect.fromLTRB(0, 0, width.toDouble(), height.toDouble()));
    recordingCanvas.apply(canvas);
    final String imageDataUrl = canvas.canvas.toDataUrl();
    final html.ImageElement imageElement = html.ImageElement()
      ..src = imageDataUrl
      ..width = width
      ..height = height;
    return HtmlImage(
      imageElement,
      width,
      height,
    );
  }

  @override
  void dispose() {}

  @override
  int get approximateBytesUsed => 0;

  final RecordingCanvas recordingCanvas;
  final ui.Rect cullRect;
}
