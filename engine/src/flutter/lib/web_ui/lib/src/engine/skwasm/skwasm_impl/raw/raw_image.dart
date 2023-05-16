// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@DefaultAsset('skwasm')
library skwasm_impl;

import 'dart:ffi';

import 'package:ui/src/engine/skwasm/skwasm_impl.dart';

final class RawImage extends Opaque {}
typedef ImageHandle = Pointer<RawImage>;

@Native<ImageHandle Function(
  PictureHandle,
  Int32,
  Int32,
)>(symbol: 'image_createFromPicture', isLeaf: true)
external ImageHandle imageCreateFromPicture(
  PictureHandle handle,
  int width,
  int height,
);

@Native<ImageHandle Function(
  SkDataHandle,
  Int,
  Int,
  Int,
  Size
)>(symbol: 'image_createFromPixels', isLeaf: true)
external ImageHandle imageCreateFromPixels(
  SkDataHandle pixelData,
  int width,
  int height,
  int pixelFormat,
  int rowByteCount,
);

@Native<Void Function(ImageHandle)>(symbol: 'image_dispose', isLeaf: true)
external void imageDispose(ImageHandle handle);

@Native<Int Function(ImageHandle)>(symbol: 'image_getWidth', isLeaf: true)
external int imageGetWidth(ImageHandle handle);

@Native<Int Function(ImageHandle)>(symbol: 'image_getHeight', isLeaf: true)
external int imageGetHeight(ImageHandle handle);
