// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
part of engine;

class SkPictureRecorder implements ui.PictureRecorder {
  ui.Rect _cullRect;
  js.JsObject _recorder;
  SkCanvas _recordingCanvas;

  SkCanvas beginRecording(ui.Rect bounds) {
    _cullRect = bounds;
    _recorder = js.JsObject(canvasKit['SkPictureRecorder']);
    final js.JsObject skRect = js.JsObject(canvasKit['LTRBRect'],
        <double>[bounds.left, bounds.top, bounds.right, bounds.bottom]);
    final js.JsObject skCanvas =
        _recorder.callMethod('beginRecording', <js.JsObject>[skRect]);
    _recordingCanvas = SkCanvas(skCanvas);
    return _recordingCanvas;
  }

  SkCanvas get recordingCanvas => _recordingCanvas;

  @override
  ui.Picture endRecording() {
    final js.JsObject skPicture =
        _recorder.callMethod('finishRecordingAsPicture');
    _recorder.callMethod('delete');
    _recorder = null;
    return SkPicture(skPicture, _cullRect);
  }

  @override
  bool get isRecording => _recorder != null;
}
