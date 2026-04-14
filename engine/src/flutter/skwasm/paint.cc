// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/dl_paint.h"
#include "flutter/display_list/geometry/dl_geometry_types.h"
#include "flutter/skwasm/export.h"
#include "flutter/skwasm/helpers.h"
#include "flutter/skwasm/live_objects.h"

SKWASM_EXPORT flutter::DlPaint* paint_create(
    bool is_anti_alias,
    flutter::DlBlendMode blend_mode,
    uint32_t color,
    flutter::DlDrawStyle style,
    flutter::DlScalar stroke_width,
    flutter::DlStrokeCap stroke_cap,
    flutter::DlStrokeJoin stroke_join,
    flutter::DlScalar stroke_miter_limit,
    bool invert_colors) {
  Skwasm::live_paint_count++;
  auto paint = new flutter::DlPaint();
  paint->setAntiAlias(is_anti_alias);
  paint->setBlendMode(blend_mode);
  paint->setDrawStyle(style);
  paint->setStrokeWidth(stroke_width);
  paint->setStrokeCap(stroke_cap);
  paint->setStrokeJoin(stroke_join);
  paint->setColor(flutter::DlColor(color));
  paint->setStrokeMiter(stroke_miter_limit);
  paint->setInvertColors(invert_colors);
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
