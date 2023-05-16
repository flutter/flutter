// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ffi';
import 'dart:typed_data';

import 'package:ui/src/engine.dart';
import 'package:ui/src/engine/skwasm/skwasm_impl.dart';
import 'package:ui/ui.dart' as ui;

class SkwasmImage implements ui.Image {
  SkwasmImage(this.handle);

  factory SkwasmImage.fromPixels(
    Uint8List pixels,
    int width,
    int height,
    ui.PixelFormat format, {
    int? rowBytes,
  }) {
    final SkDataHandle dataHandle = skDataCreate(pixels.length);
    final Pointer<Uint8> dataPointer = skDataGetPointer(dataHandle).cast<Uint8>();
    for (int i = 0; i < pixels.length; i++) {
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

  final ImageHandle handle;
  bool _isDisposed = false;

  @override
  int get width => imageGetWidth(handle);

  @override
  int get height => imageGetHeight(handle);

  @override
  Future<ByteData?> toByteData(
      {ui.ImageByteFormat format = ui.ImageByteFormat.rawRgba}) {
    return (renderer as SkwasmRenderer).surface.rasterizeImage(this, format);
  }

  @override
  ui.ColorSpace get colorSpace => ui.ColorSpace.sRGB;

  @override
  void dispose() {
    if (!_isDisposed) {
      imageDispose(handle);
      _isDisposed = true;
    }
  }

  @override
  bool get debugDisposed => _isDisposed;

  @override
  SkwasmImage clone() => this;

  @override
  bool isCloneOf(ui.Image other) => identical(this, other);

  @override
  List<StackTrace>? debugGetOpenHandleStackTraces() => null;

  @override
  String toString() => '[$width\u00D7$height]';
}
