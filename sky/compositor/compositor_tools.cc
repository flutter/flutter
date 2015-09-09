// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/compositor/compositor_tools.h"
#include "third_party/skia/include/core/SkShader.h"

namespace sky {
namespace compositor {

static SkShader* CreateCheckerboardShader(SkColor c1, SkColor c2, int size) {
  SkBitmap bm;
  bm.allocN32Pixels(2 * size, 2 * size);
  bm.eraseColor(c1);
  bm.eraseArea(SkIRect::MakeLTRB(0, 0, size, size), c2);
  bm.eraseArea(SkIRect::MakeLTRB(size, size, 2 * size, 2 * size), c2);
  return SkShader::CreateBitmapShader(bm, SkShader::kRepeat_TileMode,
                                      SkShader::kRepeat_TileMode);
}

static void DrawCheckerboard(SkCanvas* canvas,
                             SkColor c1,
                             SkColor c2,
                             int size) {
  SkPaint paint;
  paint.setShader(CreateCheckerboardShader(c1, c2, size))->unref();
  canvas->drawPaint(paint);
}

void DrawCheckerboard(SkCanvas* canvas, int width, int height) {
  SkRect rect = SkRect::MakeIWH(width, height);

  // Draw a checkerboard
  canvas->clipRect(rect);
  DrawCheckerboard(canvas, 0x9900FF00, 0x00000000, 12);

  // Stroke the drawn area
  SkPaint debugPaint;
  debugPaint.setStrokeWidth(3);
  debugPaint.setColor(SK_ColorRED);
  debugPaint.setStyle(SkPaint::kStroke_Style);
  canvas->drawRect(rect, debugPaint);
}

}  // namespace compositor
}  // namespace sky
