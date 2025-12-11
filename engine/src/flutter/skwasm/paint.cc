// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/dl_paint.h"
#include "flutter/display_list/geometry/dl_geometry_types.h"
#include "flutter/skwasm/export.h"
#include "flutter/skwasm/helpers.h"
#include "flutter/skwasm/live_objects.h"

SKWASM_EXPORT flutter::DlPaint* paint_create(bool isAntiAlias,
                                             flutter::DlBlendMode blendMode,
                                             uint32_t color,
                                             flutter::DlDrawStyle style,
                                             flutter::DlScalar strokeWidth,
                                             flutter::DlStrokeCap strokeCap,
                                             flutter::DlStrokeJoin strokeJoin,
                                             flutter::DlScalar strokeMiterLimit,
                                             bool invertColors) {
  Skwasm::live_paint_count++;
  auto paint = new flutter::DlPaint();
  paint->setAntiAlias(isAntiAlias);
  paint->setBlendMode(blendMode);
  paint->setDrawStyle(style);
  paint->setStrokeWidth(strokeWidth);
  paint->setStrokeCap(strokeCap);
  paint->setStrokeJoin(strokeJoin);
  paint->setColor(flutter::DlColor(color));
  paint->setStrokeMiter(strokeMiterLimit);
  paint->setInvertColors(invertColors);
  return paint;
}

SKWASM_EXPORT void paint_dispose(flutter::DlPaint* paint) {
  Skwasm::live_paint_count--;
  delete paint;
}

SKWASM_EXPORT void paint_setShader(
    flutter::DlPaint* paint,
    Skwasm::sp_wrapper<flutter::DlColorSource>* shader) {
  paint->setColorSource(shader->Shared());
}

SKWASM_EXPORT void paint_setImageFilter(
    flutter::DlPaint* paint,
    Skwasm::sp_wrapper<flutter::DlImageFilter>* filter) {
  paint->setImageFilter(filter->Shared());
}

SKWASM_EXPORT void paint_setColorFilter(
    flutter::DlPaint* paint,
    Skwasm::sp_wrapper<const flutter::DlColorFilter>* filter) {
  paint->setColorFilter(filter->Shared());
}

SKWASM_EXPORT void paint_setMaskFilter(
    flutter::DlPaint* paint,
    Skwasm::sp_wrapper<flutter::DlMaskFilter>* filter) {
  paint->setMaskFilter(filter->Shared());
}
