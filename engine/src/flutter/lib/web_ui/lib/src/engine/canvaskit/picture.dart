// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:ui/ui.dart' as ui;

import '../layer/layer_painting.dart';
import '../primitives/image.dart';
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
    _ref = CkCountedRef<CkPicture, SkPicture>(skPicture, this, 'Picture');
    _initStackTrace();
  }

  CkPicture._clone(CkCountedRef<CkPicture, SkPicture> ref) : _isClone = true {
    _ref = ref;
    ref.ref(this);
    _initStackTrace();
  }

  final bool _isClone;

  late final CkCountedRef<CkPicture, SkPicture> _ref;

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
  EngineImage toImageSync(
    int width,
    int height, {
    ui.TargetPixelFormat targetFormat = ui.TargetPixelFormat.dontCare,
  }) {
    // Ensure the picture is not disposed before rendering.
    assert(debugCheckNotDisposed('Cannot convert picture to image.'));

    // Retrieve the cached/reusable surface dedicated to picture-to-image conversions.
    final CkSurface surface = CanvasKitRenderer.instance.pictureToImageSurface;
    // Resize the temporary surface to match the requested image dimensions.
    surface.setSize(BitmapSize(width, height));
    final SkSurface skiaSurface = surface.skSurface!;

    // Wrap the Skia canvas in a CkCanvas to perform standard operations.
    final ckCanvas = CkCanvas.fromSkCanvas(skiaSurface.getCanvas());
    // Clear any previous frames from the scratch surface with full transparency.
    ckCanvas.clear(const ui.Color(0x00000000));
    // Draw this picture into the scratch surface.
    ckCanvas.drawPicture(this);
    // Take a snapshot of the current state of the scratch surface.
    final SkImage skImage = skiaSurface.makeImageSnapshot();

    // TODO(hterkelsen): This is a hack to get the pixels from the SkImage.
    // We should be able to do this without creating a new image. This is
    // a workaround for a bug in CanvasKit.
    // Configure the metadata describing the expected layout of pixel data.
    final imageInfo = SkImageInfo(
      alphaType: canvasKit.AlphaType.Premul,
      colorType: canvasKit.ColorType.RGBA_8888,
      colorSpace: SkColorSpaceSRGB,
      width: width.toDouble(),
      height: height.toDouble(),
    );
    // Read the snapshot's raw pixel bytes back into the CPU memory.
    final Uint8List? pixels = skImage.readPixels(0, 0, imageInfo);
    // Immediately delete the snapshot to free up GPU memory.
    skImage.delete();
    if (pixels == null) {
      throw StateError('Unable to convert read pixels from SkImage.');
    }
    // Re-create a CPU-backed raster SkImage from the loaded pixel bytes.
    final SkImage? rasterImage = canvasKit.MakeImage(imageInfo, pixels, 4 * width);
    if (rasterImage == null) {
      throw StateError('Unable to convert image pixels into SkImage.');
    }
    // Return the rasterized image wrapped as a Flutter EngineImage.
    return EngineImage(
      CkImageDelegate(rasterImage),
      rasterImage.width().toInt(),
      rasterImage.height().toInt(),
    );
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
