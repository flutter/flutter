// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/paint_utils.h"

#include <stdlib.h>

#include "third_party/skia/include/core/SkBitmap.h"
#include "third_party/skia/include/core/SkPaint.h"
#include "third_party/skia/include/core/SkShader.h"

namespace flow {

namespace {

sk_sp<SkShader> CreateCheckerboardShader(SkColor c1, SkColor c2, int size) {
  SkBitmap bm;
  bm.allocN32Pixels(2 * size, 2 * size);
  bm.eraseColor(c1);
  bm.eraseArea(SkIRect::MakeLTRB(0, 0, size, size), c2);
  bm.eraseArea(SkIRect::MakeLTRB(size, size, 2 * size, 2 * size), c2);
  return SkShader::MakeBitmapShader(bm, SkShader::kRepeat_TileMode,
                                    SkShader::kRepeat_TileMode);
}

}  // anonymous namespace

void DrawCheckerboard(SkCanvas* canvas, SkColor c1, SkColor c2, int size) {
  SkPaint paint;
  paint.setShader(CreateCheckerboardShader(c1, c2, size));
  canvas->drawPaint(paint);
}

void DrawCheckerboard(SkCanvas* canvas, const SkRect& rect) {
  // Draw a checkerboard
  canvas->save();
  canvas->clipRect(rect);

  auto checkerboard_color =
      SkColorSetARGB(64, rand() % 256, rand() % 256, rand() % 256);

  DrawCheckerboard(canvas, checkerboard_color, 0x00000000, 12);
  canvas->restore();

  // Stroke the drawn area
  SkPaint debugPaint;
  debugPaint.setStrokeWidth(8);
  debugPaint.setColor(SkColorSetA(checkerboard_color, 255));
  debugPaint.setStyle(SkPaint::kStroke_Style);
  canvas->drawRect(rect, debugPaint);
}

}  // namespace flow
