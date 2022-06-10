// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:ui/ui.dart' as ui;

import 'dom.dart';
import 'html/bitmap_canvas.dart';
import 'html/recording_canvas.dart';
import 'html_image_codec.dart';
import 'safe_browser_api.dart';
import 'util.dart';

/// An implementation of [ui.PictureRecorder] backed by a [RecordingCanvas].
class EnginePictureRecorder implements ui.PictureRecorder {
  EnginePictureRecorder();

  RecordingCanvas? _canvas;
  late ui.Rect cullRect;
  bool _isRecording = false;

  RecordingCanvas beginRecording(ui.Rect bounds) {
    assert(!_isRecording);
    cullRect = bounds;
    _isRecording = true;
    return _canvas = RecordingCanvas(cullRect);
  }

  @override
  bool get isRecording => _isRecording;

  @override
  EnginePicture endRecording() {
    if (!_isRecording) {
      // The mobile version returns an empty picture in this case. To match the
      // behavior we produce a blank picture too.
      beginRecording(ui.Rect.largest);
    }
    _isRecording = false;
    _canvas!.endRecording();
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
    final ui.Rect imageRect = ui.Rect.fromLTRB(0, 0, width.toDouble(), height.toDouble());
    final BitmapCanvas canvas = BitmapCanvas.imageData(imageRect);
    recordingCanvas!.apply(canvas, imageRect);
    final String imageDataUrl = canvas.toDataUrl();
    final DomHTMLImageElement imageElement = createDomHTMLImageElement()
      ..src = imageDataUrl
      ..width = width
      ..height = height;

    // The image loads asynchronously. We need to wait before returning,
    // otherwise the returned HtmlImage will be temporarily unusable.
    final Completer<ui.Image> onImageLoaded = Completer<ui.Image>.sync();

    // Ignoring the returned futures from onError and onLoad because we're
    // communicating through the `onImageLoaded` completer.
    late final DomEventListener errorListener;
    errorListener = allowInterop((DomEvent event) {
      onImageLoaded.completeError(event);
      imageElement.removeEventListener('error', errorListener);
    });
    imageElement.addEventListener('error', errorListener);
    late final DomEventListener loadListener;
    loadListener = allowInterop((DomEvent event) {
      onImageLoaded.complete(HtmlImage(
        imageElement,
        width,
        height,
      ));
      imageElement.removeEventListener('load', loadListener);
    });
    imageElement.addEventListener('load', loadListener);
    return onImageLoaded.future;
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
  }

  @override
  bool get debugDisposed {
    if (assertionsEnabled) {
      return _disposed;
    }
    throw StateError('Picture.debugDisposed is only available when asserts are enabled.');
  }


  @override
  int get approximateBytesUsed => 0;

  final RecordingCanvas? recordingCanvas;
  final ui.Rect? cullRect;
}
