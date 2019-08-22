// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of engine;

class SkPictureRecorder implements ui.PictureRecorder {
  @override
  ui.Rect cullRect;

  js.JsObject _recorder;

  @override
  RecordingCanvas beginRecording(ui.Rect bounds) {
    cullRect = bounds;
    _recorder = js.JsObject(canvasKit['SkPictureRecorder']);
    final js.JsObject skRect = js.JsObject(canvasKit['LTRBRect'],
        <double>[bounds.left, bounds.top, bounds.right, bounds.bottom]);
    final js.JsObject skCanvas =
        _recorder.callMethod('beginRecording', <js.JsObject>[skRect]);
    return SkRecordingCanvas(skCanvas);
  }

  @override
  ui.Picture endRecording() {
    final js.JsObject skPicture =
        _recorder.callMethod('finishRecordingAsPicture');
    _recorder.callMethod('delete');
    return SkPicture(skPicture, cullRect);
  }

  @override
  bool get isRecording => false;
}
