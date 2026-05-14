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

@Native<SurfaceHandle Function()>(symbol: 'surface_create', isLeaf: true)
external SurfaceHandle surfaceCreate();

// We use a wasm import directly here instead of @Native since this uses an externref
// in the function signature.
CallbackId surfaceSetCanvas(SurfaceHandle handle, JSAny canvas) =>
    surfaceSetCanvasImpl(handle.address.toWasmI32(), externRefForJSAny(canvas)).toIntUnsigned();
@pragma('wasm:import', 'skwasm.surface_setCanvas')
external WasmI32 surfaceSetCanvasImpl(WasmI32 surfaceHandle, WasmExternRef? frame);

@Native<Int32 Function(SurfaceHandle, Int, Int)>(symbol: 'surface_setSize', isLeaf: true)
external CallbackId surfaceSetSize(SurfaceHandle surface, int width, int height);

@Native<UnsignedLong Function(SurfaceHandle)>(symbol: 'surface_getThreadId', isLeaf: true)
external int surfaceGetThreadId(SurfaceHandle handle);

@Native<Int Function(SurfaceHandle)>(symbol: 'surface_getGlContext', isLeaf: true)
external int surfaceGetGlContext(SurfaceHandle handle);

@Native<Int32 Function(SurfaceHandle)>(symbol: 'surface_triggerContextLoss', isLeaf: true)
external CallbackId surfaceTriggerContextLoss(SurfaceHandle handle);

@Native<Void Function(SurfaceHandle, OnRenderCallbackHandle)>(
  symbol: 'surface_setCallbackHandler',
  isLeaf: true,
)
external void surfaceSetCallbackHandler(SurfaceHandle surface, OnRenderCallbackHandle callback);

@Native<Void Function(SurfaceHandle)>(symbol: 'surface_destroy', isLeaf: true)
external void surfaceDestroy(SurfaceHandle surface);

@Native<Void Function(SurfaceHandle, Int)>(
  symbol: 'surface_setResourceCacheLimitBytes',
  isLeaf: true,
)
external void surfaceSetResourceCacheLimitBytes(SurfaceHandle surface, int bytes);

@Native<Int32 Function(SurfaceHandle, Pointer<PictureHandle>, Int)>(
  symbol: 'surface_renderPictures',
  isLeaf: true,
)
external CallbackId surfaceRenderPictures(
  SurfaceHandle surface,
  Pointer<PictureHandle> picture,
  int count,
);

@Native<Int32 Function(SurfaceHandle, ImageHandle, Int)>(
  symbol: 'surface_rasterizeImage',
  isLeaf: true,
)
external CallbackId surfaceRasterizeImage(SurfaceHandle handle, ImageHandle image, int format);
