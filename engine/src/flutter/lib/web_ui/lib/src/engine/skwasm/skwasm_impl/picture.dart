// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/src/engine.dart';
import 'package:ui/src/engine/skwasm/skwasm_impl.dart';
import 'package:ui/ui.dart' as ui;

class SkwasmPicture extends SkwasmObjectWrapper<RawPicture> implements LayerPicture {
  SkwasmPicture.fromHandle(PictureHandle handle, {this.isClone = false}) : super(handle, _registry);

  final bool isClone;

  static final SkwasmFinalizationRegistry<RawPicture> _registry =
      SkwasmFinalizationRegistry<RawPicture>((PictureHandle handle) => pictureDispose(handle));

  @override
  Future<ui.Image> toImage(int width, int height) async => toImageSync(width, height);

  @override
  int get approximateBytesUsed => pictureApproximateBytesUsed(handle);

  @override
  void dispose() {
    super.dispose();
    if (!isClone) {
      ui.Picture.onDispose?.call(this);
    }
  }

  @override
  ui.Image toImageSync(
    int width,
    int height, {
    ui.TargetPixelFormat targetFormat = ui.TargetPixelFormat.dontCare,
  }) => SkwasmImage(imageCreateFromPicture(handle, width, height));

  @override
  ui.Rect get cullRect {
    return withStackScope((StackScope s) {
      final RawRect rect = s.allocFloatArray(4);
      pictureGetCullRect(handle, rect);
      return s.convertRectFromNative(rect);
    });
  }

  @override
  LayerPicture clone() {
    pictureRef(handle);
    return SkwasmPicture.fromHandle(handle, isClone: true);
  }

  @override
  String toString() {
    return 'SkwasmPicture(${handle.address})';
  }

  @override
  bool get isDisposed => debugDisposed;
}

class SkwasmPictureRecorder extends SkwasmObjectWrapper<RawPictureRecorder>
    implements LayerPictureRecorder {
  SkwasmPictureRecorder() : super(pictureRecorderCreate(), _registry);

  static final SkwasmFinalizationRegistry<RawPictureRecorder> _registry =
      SkwasmFinalizationRegistry<RawPictureRecorder>(
        (PictureRecorderHandle handle) => pictureRecorderDispose(handle),
      );

  @override
  SkwasmPicture endRecording() {
    isRecording = false;

    final picture = SkwasmPicture.fromHandle(pictureRecorderEndRecording(handle));
    ui.Picture.onCreate?.call(picture);
    dispose();
    return picture;
  }

  @override
  bool isRecording = true;
}
