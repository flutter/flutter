// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:ui/ui.dart' as ui;

import '../layer/layer_painting.dart';
import '../util.dart';
import 'canvas.dart';
import 'canvaskit_api.dart';
import 'image.dart';
import 'native_memory.dart';
import 'renderer.dart';
import 'surface.dart';

/// Implements [ui.Picture] on top of [SkPicture].
class CkPicture implements LayerPicture, StackTraceDebugger {
  CkPicture(SkPicture skPicture) : _isClone = false {
    _ref = CountedRef<CkPicture, SkPicture>(skPicture, this, 'Picture');
    _initStackTrace();
  }

  CkPicture._clone(CountedRef<CkPicture, SkPicture> ref) : _isClone = true {
    _ref = ref;
    ref.ref(this);
    _initStackTrace();
  }

  late final CountedRef<CkPicture, SkPicture> _ref;
  final bool _isClone;

  SkPicture get skiaObject => _ref.nativeObject;

  @override
  ui.Rect get cullRect => fromSkRect(skiaObject.cullRect());

  @override
  int get approximateBytesUsed => skiaObject.approximateBytesUsed();

  @override
  bool get debugDisposed {
    bool? result;
    assert(() {
      result = _isDisposed;
      return true;
    }());

    if (result != null) {
      return result!;
    }

    throw StateError('Picture.debugDisposed is only available when asserts are enabled.');
  }

  /// This is set to true when [dispose] is called and is never reset back to
  /// false.
  ///
  /// This extra flag is necessary on top of [rawSkiaObject] because
  /// [rawSkiaObject] being null does not indicate permanent deletion.
  bool _isDisposed = false;

  /// The stack trace taken when [dispose] was called.
  ///
  /// Returns null if [dispose] has not been called. Returns null in non-debug
  /// modes.
  StackTrace? _debugDisposalStackTrace;

  /// Throws an [AssertionError] if this picture was disposed.
  ///
  /// The [mainErrorMessage] is used as the first line in the error message. It
  /// is expected to end with a period, e.g. "Failed to draw picture." The full
  /// message will also explain that the error is due to the fact that the
  /// picture was disposed and include the stack trace taken when the picture
  /// was disposed.
  bool debugCheckNotDisposed(String mainErrorMessage) {
    if (_isDisposed) {
      throw StateError(
        '$mainErrorMessage\n'
        'The picture has been disposed. When the picture was disposed the '
        'stack trace was:\n'
        '$_debugDisposalStackTrace',
      );
    }
    return true;
  }

  @override
  void dispose() {
    assert(debugCheckNotDisposed('Cannot dispose picture.'));
    assert(() {
      _debugDisposalStackTrace = StackTrace.current;
      return true;
    }());
    if (!_isClone) {
      ui.Picture.onDispose?.call(this);
    }
    _isDisposed = true;
    _ref.unref(this);
  }

  @override
  Future<ui.Image> toImage(int width, int height) async {
    return toImageSync(width, height);
  }

  @override
  CkImage toImageSync(
    int width,
    int height, {
    ui.TargetPixelFormat targetFormat = ui.TargetPixelFormat.dontCare,
  }) {
    assert(debugCheckNotDisposed('Cannot convert picture to image.'));

    final CkSurface surface = CanvasKitRenderer.instance.pictureToImageSurface;
    surface.setSize(BitmapSize(width, height));
    final SkSurface skiaSurface = surface.skSurface!;

    final ckCanvas = CkCanvas.fromSkCanvas(skiaSurface.getCanvas());
    ckCanvas.clear(const ui.Color(0x00000000));
    ckCanvas.drawPicture(this);
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
    final SkImage? rasterImage = canvasKit.MakeImage(imageInfo, pixels, (4 * width).toDouble());
    if (rasterImage == null) {
      throw StateError('Unable to convert image pixels into SkImage.');
    }
    return CkImage(rasterImage);
  }

  @override
  LayerPicture clone() {
    return CkPicture._clone(_ref);
  }

  void _initStackTrace() {
    assert(() {
      _debugStackTrace = StackTrace.current;
      return true;
    }());
  }

  late StackTrace _debugStackTrace;

  @override
  StackTrace get debugStackTrace => _debugStackTrace;

  @override
  bool get isDisposed => _isDisposed;
}
