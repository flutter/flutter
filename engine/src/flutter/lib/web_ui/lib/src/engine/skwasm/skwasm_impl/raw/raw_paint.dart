// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@DefaultAsset('skwasm')
library skwasm_impl;

import 'dart:ffi';

import 'package:ui/src/engine/skwasm/skwasm_impl.dart';

final class RawPaint extends Opaque {}

typedef PaintHandle = Pointer<RawPaint>;

@Native<PaintHandle Function()>(symbol: 'paint_create', isLeaf: true)
external PaintHandle paintCreate();

@Native<Void Function(PaintHandle)>(symbol: 'paint_dispose', isLeaf: true)
external void paintDispose(PaintHandle paint);

@Native<Void Function(PaintHandle, Int)>(symbol: 'paint_setBlendMode', isLeaf: true)
external void paintSetBlendMode(PaintHandle paint, int blendMode);

@Native<Void Function(PaintHandle, Int)>(symbol: 'paint_setStyle', isLeaf: true)
external void paintSetStyle(PaintHandle paint, int paintStyle);

@Native<Int Function(PaintHandle)>(symbol: 'paint_getStyle', isLeaf: true)
external int paintGetStyle(PaintHandle paint);

@Native<Void Function(PaintHandle, Float)>(symbol: 'paint_setStrokeWidth', isLeaf: true)
external void paintSetStrokeWidth(PaintHandle paint, double strokeWidth);

@Native<Float Function(PaintHandle)>(symbol: 'paint_getStrokeWidth', isLeaf: true)
external double paintGetStrokeWidth(PaintHandle paint);

@Native<Void Function(PaintHandle, Int)>(symbol: 'paint_setStrokeCap', isLeaf: true)
external void paintSetStrokeCap(PaintHandle paint, int cap);

@Native<Int Function(PaintHandle)>(symbol: 'paint_getStrokeCap', isLeaf: true)
external int paintGetStrokeCap(PaintHandle paint);

@Native<Void Function(PaintHandle, Int)>(symbol: 'paint_setStrokeJoin', isLeaf: true)
external void paintSetStrokeJoin(PaintHandle paint, int join);

@Native<Int Function(PaintHandle)>(symbol: 'paint_getStrokeJoin', isLeaf: true)
external int paintGetStrokeJoin(PaintHandle paint);

@Native<Void Function(PaintHandle, Bool)>(symbol: 'paint_setAntiAlias', isLeaf: true)
external void paintSetAntiAlias(PaintHandle paint, bool antiAlias);

@Native<Bool Function(PaintHandle)>(symbol: 'paint_getAntiAlias', isLeaf: true)
external bool paintGetAntiAlias(PaintHandle paint);

@Native<Void Function(PaintHandle, Uint32)>(symbol: 'paint_setColorInt', isLeaf: true)
external void paintSetColorInt(PaintHandle paint, int color);

@Native<Uint32 Function(PaintHandle)>(symbol: 'paint_getColorInt', isLeaf: true)
external int paintGetColorInt(PaintHandle paint);

@Native<Void Function(PaintHandle, Float)>(symbol: 'paint_setMiterLimit', isLeaf: true)
external void paintSetMiterLimit(PaintHandle paint, double miterLimit);

@Native<Float Function(PaintHandle)>(symbol: 'paint_getMiterLimit', isLeaf: true)
external double paintGetMiterLimit(PaintHandle paint);

@Native<Void Function(PaintHandle, ShaderHandle)>(symbol: 'paint_setShader', isLeaf: true)
external void paintSetShader(PaintHandle handle, ShaderHandle shader);

@Native<Void Function(PaintHandle, ImageFilterHandle)>(symbol: 'paint_setImageFilter', isLeaf: true)
external void paintSetImageFilter(PaintHandle handle, ImageFilterHandle filter);

@Native<Void Function(PaintHandle, ColorFilterHandle)>(symbol: 'paint_setColorFilter', isLeaf: true)
external void paintSetColorFilter(PaintHandle handle, ColorFilterHandle filter);

@Native<Void Function(PaintHandle, MaskFilterHandle)>(symbol: 'paint_setMaskFilter', isLeaf: true)
external void paintSetMaskFilter(PaintHandle handle, MaskFilterHandle filter);
