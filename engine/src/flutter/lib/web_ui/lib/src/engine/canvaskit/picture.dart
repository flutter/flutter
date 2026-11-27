// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:ui/ui.dart' as ui;

import '../backend/canvas.dart';
import '../backend/image.dart';
import '../backend/picture.dart';
import '../util.dart';
import 'canvas.dart';
import 'canvaskit_api.dart';
import 'image.dart';
import 'renderer.dart';
import 'surface.dart';

/// The CanvasKit [BackendPicture], wrapping an [SkPicture].
class CkPicture implements BackendPicture {
  /// Wraps [skiaObject], which this picture owns.
  CkPicture(this.skiaObject);

  /// The underlying CanvasKit picture.
  final SkPicture skiaObject;

  @override
  ui.Rect get cullRect => fromSkRect(skiaObject.cullRect());

  @override
  int get approximateBytesUsed => skiaObject.approximateBytesUsed();

  @override
  bool get toImageSyncIsDeferred => false;

  @override
  BackendImage toImageSync(int width, int height, ui.TargetPixelFormat targetFormat) {
    final CkSurface surface = CanvasKitRenderer.instance.pictureToImageSurface;
    surface.setSize(BitmapSize(width, height));
    final SkSurface skiaSurface = surface.skSurface!;

    final canvas = CkCanvas(skiaSurface.getCanvas());
    canvas.clear(const ui.Color(0x00000000));
    canvas.drawPicture(this);
    final SkImage skImage = skiaSurface.makeImageSnapshot();

    // TODO(hterkelsen): This is a hack to get the pixels from the SkImage.
    // We should be able to do this without creating a new image. This is
    // a workaround for a bug in CanvasKit.
    final imageInfo = SkImageInfo(
      alphaType: canvasKit.AlphaType.Premul,
      colorType: canvasKit.ColorType.RGBA_8888,
      colorSpace: SkColorSpaceSRGB,
      width: width.toDouble(),
      height: height.toDouble(),
    );
    final Uint8List? pixels = skImage.readPixels(0, 0, imageInfo);
    skImage.delete();
    if (pixels == null) {
      throw StateError('Unable to convert read pixels from SkImage.');
    }
    final SkImage? rasterImage = canvasKit.MakeImage(imageInfo, pixels, 4 * width);
    if (rasterImage == null) {
      throw StateError('Unable to convert image pixels into SkImage.');
    }
    return CkImageDelegate(rasterImage);
  }

  @override
  void dispose() {
    if (!(skiaObject as SkDeletable).isDeleted()) {
      skiaObject.delete();
    }
  }
}

/// The CanvasKit [BackendPictureRecorder], wrapping an [SkPictureRecorder].
class CkPictureRecorder implements BackendPictureRecorder {
  SkPictureRecorder? _skRecorder;

  @override
  BackendCanvas beginRecording(ui.Rect cullRect) {
    final SkPictureRecorder recorder = _skRecorder = SkPictureRecorder();
    return CkCanvas(recorder.beginRecording(toSkRect(cullRect)));
  }

  @override
  BackendPicture endRecording() => CkPicture(_skRecorder!.finishRecordingAsPicture());

  @override
  void dispose() {
    final SkPictureRecorder? recorder = _skRecorder;
    if (recorder != null && !(recorder as SkDeletable).isDeleted()) {
      recorder.delete();
    }
    _skRecorder = null;
  }
}
