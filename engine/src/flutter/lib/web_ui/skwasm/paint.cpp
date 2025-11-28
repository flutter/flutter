// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "export.h"
#include "helpers.h"
#include "live_objects.h"

#include "flutter/display_list/dl_paint.h"
#include "flutter/display_list/geometry/dl_geometry_types.h"

using namespace Skwasm;
using namespace flutter;

SKWASM_EXPORT DlPaint* paint_create(bool isAntiAlias,
                                    DlBlendMode blendMode,
                                    uint32_t color,
                                    DlDrawStyle style,
                                    DlScalar strokeWidth,
                                    DlStrokeCap strokeCap,
                                    DlStrokeJoin strokeJoin,
                                    DlScalar strokeMiterLimit,
                                    bool invertColors) {
  livePaintCount++;
  auto paint = new DlPaint();
  paint->setAntiAlias(isAntiAlias);
  paint->setBlendMode(blendMode);
  paint->setDrawStyle(style);
  paint->setStrokeWidth(strokeWidth);
  paint->setStrokeCap(strokeCap);
  paint->setStrokeJoin(strokeJoin);
  paint->setColor(DlColor(color));
  paint->setStrokeMiter(strokeMiterLimit);
  paint->setInvertColors(invertColors);
  return paint;
}

SKWASM_EXPORT void paint_dispose(DlPaint* paint) {
  livePaintCount--;
  delete paint;
}

SKWASM_EXPORT void paint_setShader(DlPaint* paint,
                                   sp_wrapper<DlColorSource>* shader) {
  paint->setColorSource(shader->shared());
}

SKWASM_EXPORT void paint_setImageFilter(DlPaint* paint,
                                        sp_wrapper<DlImageFilter>* filter) {
  paint->setImageFilter(filter->shared());
}

SKWASM_EXPORT void paint_setColorFilter(
    DlPaint* paint,
    sp_wrapper<const DlColorFilter>* filter) {
  paint->setColorFilter(filter->shared());
}

SKWASM_EXPORT void paint_setMaskFilter(DlPaint* paint,
                                       sp_wrapper<DlMaskFilter>* filter) {
  paint->setMaskFilter(filter->shared());
}
