// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ffi';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:ui/src/engine.dart';
import 'package:ui/src/engine/skwasm/skwasm_impl.dart';
import 'package:ui/ui.dart' as ui;

class SkwasmImage implements ui.Image, StackTraceDebugger {
  SkwasmImage(ImageHandle handle) {
    box = CountedRef<SkwasmImage, ImageHandle>(
      handle,
      this,
      'SkImage',
      onDispose: (ImageHandle h) => imageDispose(h),
      onDisposed: (SkwasmImage image) => ui.Image.onDispose?.call(image),
    );
    _init();
    ui.Image.onCreate?.call(this);
  }

  SkwasmImage.cloneOf(this.box) {
    box.ref(this);
    _init();
  }

  factory SkwasmImage.fromPixels(
    Uint8List pixels,
    int width,
    int height,
    ui.PixelFormat format, {
    int? rowBytes,
  }) {
    final SkDataHandle dataHandle = skDataCreate(pixels.length);
    final Pointer<Uint8> dataPointer = skDataGetPointer(dataHandle).cast<Uint8>();
    for (var i = 0; i < pixels.length; i++) {
      dataPointer[i] = pixels[i];
    }
    final ImageHandle imageHandle = imageCreateFromPixels(
      dataHandle,
      width,
      height,
      format.index,
      rowBytes ?? 4 * width,
    );
    skDataDispose(dataHandle);
    return SkwasmImage(imageHandle);
  }

  void _init() {
    assert(() {
      _debugStackTrace = StackTrace.current;
      return true;
    }());
  }

  @override
  StackTrace get debugStackTrace => _debugStackTrace;
  late StackTrace _debugStackTrace;

  late final CountedRef<SkwasmImage, ImageHandle> box;

  bool _disposed = false;

  @override
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    box.unref(this);
  }

  ImageHandle get handle => box.nativeObject;

  @override
  bool get debugDisposed {
    bool? result;
    assert(() {
      result = _disposed;
      return true;
    }());

    if (result != null) {
      return result!;
    }

    throw StateError('Image.debugDisposed is only available when asserts are enabled.');
  }

  @override
  int get width => imageGetWidth(handle);

  @override
  int get height => imageGetHeight(handle);

  @override
  Future<ByteData?> toByteData({ui.ImageByteFormat format = ui.ImageByteFormat.rawRgba}) async {
    if (format == ui.ImageByteFormat.png) {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawImage(this, ui.Offset.zero, ui.Paint());
      final picture = recorder.endRecording() as SkwasmPicture;
      final surface = renderer.pictureToImageSurface as SkwasmSurface;
      await surface.setSize(BitmapSize(width, height));
      final DomImageBitmap bitmap = (await surface.rasterizeToImageBitmaps(<SkwasmPicture>[
        picture,
      ])).single;
      final DomOffscreenCanvas offscreenCanvas = createDomOffscreenCanvas(
        bitmap.width,
        bitmap.height,
      );
      final context =
          offscreenCanvas.getContext('bitmaprenderer')! as DomImageBitmapRenderingContext;
      context.transferFromImageBitmap(bitmap);
      final DomBlob blob = await offscreenCanvas.convertToBlob();
      final arrayBuffer = (await blob.arrayBuffer().toDart)! as JSArrayBuffer;

      // Zero out the contents of the canvas so that resources can be reclaimed
      // by the browser.
      context.transferFromImageBitmap(null);
      return ByteData.view(arrayBuffer.toDart);
    } else {
      return renderer.pictureToImageSurface.rasterizeImage(this, format);
    }
  }

  @override
  ui.ColorSpace get colorSpace => ui.ColorSpace.sRGB;

  @override
  SkwasmImage clone() => SkwasmImage.cloneOf(box);

  @override
  bool isCloneOf(ui.Image other) => other is SkwasmImage && handle == other.handle;

  @override
  List<StackTrace>? debugGetOpenHandleStackTraces() => box.debugGetStackTraces();

  @override
  String toString() => '[$width\u00D7$height]';
}
