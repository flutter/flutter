// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@DefaultAsset('skwasm')
library skwasm_impl;

import 'dart:ffi';
import 'package:ui/src/engine/skwasm/skwasm_impl.dart';

final class RawSurface extends Opaque {}
typedef SurfaceHandle = Pointer<RawSurface>;

@Native<SurfaceHandle Function(Pointer<Int8>)>(
  symbol: 'surface_createFromCanvas',
  isLeaf: true)
external SurfaceHandle surfaceCreateFromCanvas(Pointer<Int8> querySelector);

@Native<Void Function(SurfaceHandle)>(
  symbol: 'surface_destroy',
  isLeaf: true)
external void surfaceDestroy(SurfaceHandle surface);

@Native<Void Function(SurfaceHandle, Int, Int)>(
  symbol: 'surface_setCanvasSize',
  isLeaf: true)
external void surfaceSetCanvasSize(
  SurfaceHandle surface,
  int width,
  int height
);

@Native<Void Function(SurfaceHandle, PictureHandle)>(
  symbol: 'surface_renderPicture',
  isLeaf: true)
external void surfaceRenderPicture(SurfaceHandle surface, PictureHandle picture);
