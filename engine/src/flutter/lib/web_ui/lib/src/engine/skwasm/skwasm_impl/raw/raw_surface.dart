// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@DefaultAsset('skwasm')
library skwasm_impl;

import 'dart:_wasm';
import 'dart:ffi';
import 'dart:js_interop';
import 'package:ui/src/engine/skwasm/skwasm_impl.dart';

final class RawSurface extends Opaque {}

typedef SurfaceHandle = Pointer<RawSurface>;

final class RawRenderCallback extends Opaque {}

typedef OnRenderCallbackHandle = Pointer<RawRenderCallback>;

typedef CallbackId = int;

SurfaceHandle surfaceCreate(JSAny canvas) =>
    SurfaceHandle.fromAddress(surfaceCreateImpl(externRefForJSAny(canvas)).toIntUnsigned());

@pragma('wasm:import', 'skwasm.surface_create')
external WasmI32 surfaceCreateImpl(WasmExternRef? canvas);

@Native<UnsignedLong Function(SurfaceHandle)>(symbol: 'surface_getThreadId', isLeaf: true)
external int surfaceGetThreadId(SurfaceHandle handle);

@Native<Void Function(SurfaceHandle, OnRenderCallbackHandle)>(
  symbol: 'surface_setCallbackHandler',
  isLeaf: true,
)
external void surfaceSetCallbackHandler(SurfaceHandle surface, OnRenderCallbackHandle callback);

@Native<Void Function(SurfaceHandle)>(symbol: 'surface_destroy', isLeaf: true)
external void surfaceDestroy(SurfaceHandle surface);

@Native<Void Function(SurfaceHandle, Pointer<PictureHandle>, Int, Int32)>(
  symbol: 'surface_renderPictures',
  isLeaf: true,
)
external void surfaceRenderPictures(
  SurfaceHandle surface,
  Pointer<PictureHandle> picture,
  int count,
  CallbackId callbackId,
);

@Native<Void Function(SurfaceHandle, PictureHandle, Int32)>(
  symbol: 'surface_renderPictureDirect',
  isLeaf: true,
)
external void surfaceRenderPictureDirect(
  SurfaceHandle surface,
  PictureHandle picture,
  CallbackId callbackId,
);

@Native<Void Function(SurfaceHandle, ImageHandle, Int, Int32)>(
  symbol: 'surface_rasterizeImage',
  isLeaf: true,
)
external void surfaceRasterizeImage(
  SurfaceHandle handle,
  ImageHandle image,
  int format,
  CallbackId callbackId,
);
