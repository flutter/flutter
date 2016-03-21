// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gfx/skia_util.h"

#include "third_party/skia/include/core/SkBitmap.h"
#include "third_party/skia/include/core/SkBlurTypes.h"
#include "third_party/skia/include/core/SkColorFilter.h"
#include "third_party/skia/include/core/SkColorPriv.h"
#include "third_party/skia/include/core/SkUnPreMultiply.h"
#include "third_party/skia/include/effects/SkBlurMaskFilter.h"
#include "third_party/skia/include/effects/SkGradientShader.h"
#include "third_party/skia/include/effects/SkLayerDrawLooper.h"
#include "ui/gfx/geometry/quad_f.h"
#include "ui/gfx/geometry/rect.h"
#include "ui/gfx/geometry/rect_f.h"
#include "ui/gfx/transform.h"

namespace gfx {

SkRect RectToSkRect(const Rect& rect) {
  SkRect r;
  r.iset(rect.x(), rect.y(), rect.right(), rect.bottom());
  return r;
}

SkIRect RectToSkIRect(const Rect& rect) {
  return SkIRect::MakeXYWH(rect.x(), rect.y(), rect.width(), rect.height());
}

Rect SkIRectToRect(const SkIRect& rect) {
  return Rect(rect.x(), rect.y(), rect.width(), rect.height());
}

SkRect RectFToSkRect(const RectF& rect) {
  return SkRect::MakeXYWH(SkFloatToScalar(rect.x()),
                          SkFloatToScalar(rect.y()),
                          SkFloatToScalar(rect.width()),
                          SkFloatToScalar(rect.height()));
}

RectF SkRectToRectF(const SkRect& rect) {
  return RectF(SkScalarToFloat(rect.x()),
               SkScalarToFloat(rect.y()),
               SkScalarToFloat(rect.width()),
               SkScalarToFloat(rect.height()));
}

SkSize SizeFToSkSize(const SizeF& size) {
  return SkSize::Make(SkFloatToScalar(size.width()),
                      SkFloatToScalar(size.height()));
}

SizeF SkSizeToSizeF(const SkSize& size) {
  return SizeF(SkScalarToFloat(size.width()), SkScalarToFloat(size.height()));
}

void TransformToFlattenedSkMatrix(const gfx::Transform& transform,
                                  SkMatrix* flattened) {
  // Convert from 4x4 to 3x3 by dropping the third row and column.
  flattened->set(0, SkMScalarToScalar(transform.matrix().get(0, 0)));
  flattened->set(1, SkMScalarToScalar(transform.matrix().get(0, 1)));
  flattened->set(2, SkMScalarToScalar(transform.matrix().get(0, 3)));
  flattened->set(3, SkMScalarToScalar(transform.matrix().get(1, 0)));
  flattened->set(4, SkMScalarToScalar(transform.matrix().get(1, 1)));
  flattened->set(5, SkMScalarToScalar(transform.matrix().get(1, 3)));
  flattened->set(6, SkMScalarToScalar(transform.matrix().get(3, 0)));
  flattened->set(7, SkMScalarToScalar(transform.matrix().get(3, 1)));
  flattened->set(8, SkMScalarToScalar(transform.matrix().get(3, 3)));
}

skia::RefPtr<SkShader> CreateGradientShader(int start_point,
                                            int end_point,
                                            SkColor start_color,
                                            SkColor end_color) {
  SkColor grad_colors[2] = { start_color, end_color};
  SkPoint grad_points[2];
  grad_points[0].iset(0, start_point);
  grad_points[1].iset(0, end_point);

  return skia::AdoptRef(SkGradientShader::MakeLinear(
      grad_points, grad_colors, NULL, 2, SkShader::kRepeat_TileMode));
}

bool BitmapsAreEqual(const SkBitmap& bitmap1, const SkBitmap& bitmap2) {
  void* addr1 = NULL;
  void* addr2 = NULL;
  size_t size1 = 0;
  size_t size2 = 0;

  bitmap1.lockPixels();
  addr1 = bitmap1.getAddr32(0, 0);
  size1 = bitmap1.getSize();
  bitmap1.unlockPixels();

  bitmap2.lockPixels();
  addr2 = bitmap2.getAddr32(0, 0);
  size2 = bitmap2.getSize();
  bitmap2.unlockPixels();

  return (size1 == size2) && (0 == memcmp(addr1, addr2, bitmap1.getSize()));
}

void ConvertSkiaToRGBA(const unsigned char* skia,
                       int pixel_width,
                       unsigned char* rgba) {
  int total_length = pixel_width * 4;
  for (int i = 0; i < total_length; i += 4) {
    const uint32_t pixel_in = *reinterpret_cast<const uint32_t*>(&skia[i]);

    // Pack the components here.
    SkAlpha alpha = SkGetPackedA32(pixel_in);
    if (alpha != 0 && alpha != 255) {
      SkColor unmultiplied = SkUnPreMultiply::PMColorToColor(pixel_in);
      rgba[i + 0] = SkColorGetR(unmultiplied);
      rgba[i + 1] = SkColorGetG(unmultiplied);
      rgba[i + 2] = SkColorGetB(unmultiplied);
      rgba[i + 3] = alpha;
    } else {
      rgba[i + 0] = SkGetPackedR32(pixel_in);
      rgba[i + 1] = SkGetPackedG32(pixel_in);
      rgba[i + 2] = SkGetPackedB32(pixel_in);
      rgba[i + 3] = alpha;
    }
  }
}

void QuadFToSkPoints(const gfx::QuadF& quad, SkPoint points[4]) {
  points[0] = SkPoint::Make(quad.p1().x(), quad.p1().y());
  points[1] = SkPoint::Make(quad.p2().x(), quad.p2().y());
  points[2] = SkPoint::Make(quad.p3().x(), quad.p3().y());
  points[3] = SkPoint::Make(quad.p4().x(), quad.p4().y());
}

}  // namespace gfx
