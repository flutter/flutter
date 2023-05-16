// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/src/engine/skwasm/skwasm_impl.dart';
import 'package:ui/ui.dart' as ui;

class SkwasmPicture implements ui.Picture {
  SkwasmPicture.fromHandle(this._handle);
  final PictureHandle _handle;

  PictureHandle get handle => _handle;

  @override
  Future<ui.Image> toImage(int width, int height) async => toImageSync(width, height);

  @override
  void dispose() {
    ui.Picture.onDispose?.call(this);
    pictureDispose(_handle);
    debugDisposed = true;
  }

  @override
  int get approximateBytesUsed => pictureApproximateBytesUsed(_handle);

  @override
  bool debugDisposed = false;

  @override
  ui.Image toImageSync(int width, int height) =>
    SkwasmImage(imageCreateFromPicture(handle, width, height));

  ui.Rect get cullRect {
    return withStackScope((StackScope s) {
      final RawRect rect = s.allocFloatArray(4);
      pictureGetCullRect(handle, rect);
      return s.convertRectFromNative(rect);
    });
  }
}

class SkwasmPictureRecorder implements ui.PictureRecorder {
  factory SkwasmPictureRecorder() =>
    SkwasmPictureRecorder._fromHandle(pictureRecorderCreate());

  SkwasmPictureRecorder._fromHandle(this._handle);
  final PictureRecorderHandle _handle;

  PictureRecorderHandle get handle => _handle;

  void delete() => pictureRecorderDestroy(_handle);

  @override
  SkwasmPicture endRecording() {
    isRecording = false;

    final SkwasmPicture picture = SkwasmPicture.fromHandle(pictureRecorderEndRecording(_handle));
    ui.Picture.onCreate?.call(picture);
    return picture;
  }

  @override
  bool isRecording = true;
}
