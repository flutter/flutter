// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "export.h"
#include "helpers.h"
#include "third_party/skia/include/core/SkColorFilter.h"
#include "third_party/skia/include/core/SkImageFilter.h"
#include "third_party/skia/include/core/SkMaskFilter.h"
#include "third_party/skia/include/core/SkPaint.h"
#include "third_party/skia/include/core/SkShader.h"

using namespace Skwasm;

SKWASM_EXPORT SkPaint* paint_create() {
  auto paint = new SkPaint();

  // Antialias defaults to true in flutter.
  paint->setAntiAlias(true);
  return paint;
}

SKWASM_EXPORT void paint_dispose(SkPaint* paint) {
  delete paint;
}

SKWASM_EXPORT void paint_setBlendMode(SkPaint* paint, SkBlendMode mode) {
  paint->setBlendMode(mode);
}

// No getter for blend mode, as it's non trivial. Cache on the dart side.

SKWASM_EXPORT void paint_setStyle(SkPaint* paint, SkPaint::Style style) {
  paint->setStyle(style);
}

SKWASM_EXPORT SkPaint::Style paint_getStyle(SkPaint* paint) {
  return paint->getStyle();
}

SKWASM_EXPORT void paint_setStrokeWidth(SkPaint* paint, SkScalar width) {
  paint->setStrokeWidth(width);
}

SKWASM_EXPORT SkScalar paint_getStrokeWidth(SkPaint* paint) {
  return paint->getStrokeWidth();
}

SKWASM_EXPORT void paint_setStrokeCap(SkPaint* paint, SkPaint::Cap cap) {
  paint->setStrokeCap(cap);
}

SKWASM_EXPORT SkPaint::Cap paint_getStrokeCap(SkPaint* paint) {
  return paint->getStrokeCap();
}

SKWASM_EXPORT void paint_setStrokeJoin(SkPaint* paint, SkPaint::Join join) {
  paint->setStrokeJoin(join);
}

SKWASM_EXPORT SkPaint::Join paint_getStrokeJoin(SkPaint* paint) {
  return paint->getStrokeJoin();
}

SKWASM_EXPORT void paint_setAntiAlias(SkPaint* paint, bool antiAlias) {
  paint->setAntiAlias(antiAlias);
}

SKWASM_EXPORT bool paint_getAntiAlias(SkPaint* paint) {
  return paint->isAntiAlias();
}

SKWASM_EXPORT void paint_setColorInt(SkPaint* paint, SkColor colorInt) {
  paint->setColor(colorInt);
}

SKWASM_EXPORT SkColor paint_getColorInt(SkPaint* paint) {
  return paint->getColor();
}

SKWASM_EXPORT void paint_setMiterLimit(SkPaint* paint, SkScalar miterLimit) {
  paint->setStrokeMiter(miterLimit);
}

SKWASM_EXPORT SkScalar paint_getMiterLImit(SkPaint* paint) {
  return paint->getStrokeMiter();
}

SKWASM_EXPORT void paint_setShader(SkPaint* paint, SkShader* shader) {
  paint->setShader(sk_ref_sp<SkShader>(shader));
}

SKWASM_EXPORT void paint_setImageFilter(SkPaint* paint, SkImageFilter* filter) {
  paint->setImageFilter(sk_ref_sp<SkImageFilter>(filter));
}

SKWASM_EXPORT void paint_setColorFilter(SkPaint* paint, SkColorFilter* filter) {
  paint->setColorFilter(sk_ref_sp<SkColorFilter>(filter));
}

SKWASM_EXPORT void paint_setMaskFilter(SkPaint* paint, SkMaskFilter* filter) {
  paint->setMaskFilter(sk_ref_sp<SkMaskFilter>(filter));
}
