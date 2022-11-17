// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/paint_utils.h"

#include <stdlib.h>

#include "third_party/skia/include/core/SkBitmap.h"
#include "third_party/skia/include/core/SkPaint.h"
#include "third_party/skia/include/core/SkShader.h"

namespace flutter {

namespace {

sk_sp<SkShader> CreateCheckerboardShader(SkColor c1, SkColor c2, int size) {
  SkBitmap bm;
  bm.allocN32Pixels(2 * size, 2 * size);
  bm.eraseColor(c1);
  bm.eraseArea(SkIRect::MakeLTRB(0, 0, size, size), c2);
  bm.eraseArea(SkIRect::MakeLTRB(size, size, 2 * size, 2 * size), c2);
  return bm.makeShader(SkTileMode::kRepeat, SkTileMode::kRepeat,
                       SkSamplingOptions());
}

}  // anonymous namespace

void DrawCheckerboard(SkCanvas* canvas,
                      DisplayListBuilder* builder,
                      const SkRect& rect) {
  if (canvas) {
    DrawCheckerboard(canvas, rect);
  }
  if (builder) {
    DrawCheckerboard(builder, rect);
  }
}

void DrawCheckerboard(SkCanvas* canvas, const SkRect& rect) {
  // Draw a checkerboard
  canvas->save();
  canvas->clipRect(rect);

  // Secure random number generation isn't needed here.
  // NOLINTBEGIN(clang-analyzer-security.insecureAPI.rand)
  auto checkerboard_color =
      SkColorSetARGB(64, rand() % 256, rand() % 256, rand() % 256);
  // NOLINTEND(clang-analyzer-security.insecureAPI.rand)

  SkPaint paint;
  paint.setShader(CreateCheckerboardShader(checkerboard_color, 0x00000000, 12));
  canvas->drawPaint(paint);
  canvas->restore();

  // Stroke the drawn area
  SkPaint debug_paint;
  debug_paint.setStrokeWidth(8);
  debug_paint.setColor(SkColorSetA(checkerboard_color, 255));
  debug_paint.setStyle(SkPaint::kStroke_Style);
  canvas->drawRect(rect, debug_paint);
}

void DrawCheckerboard(DisplayListBuilder* builder, const SkRect& rect) {
  // Draw a checkerboard
  builder->save();
  builder->clipRect(rect, SkClipOp::kIntersect, false);

  // Secure random number generation isn't needed here.
  // NOLINTBEGIN(clang-analyzer-security.insecureAPI.rand)
  auto checkerboard_color =
      SkColorSetARGB(64, rand() % 256, rand() % 256, rand() % 256);
  // NOLINTEND(clang-analyzer-security.insecureAPI.rand)

  DlPaint paint;
  paint.setColorSource(DlColorSource::From(
      CreateCheckerboardShader(checkerboard_color, 0x00000000, 12)));
  builder->drawPaint(paint);
  builder->restore();

  // Stroke the drawn area
  DlPaint debug_paint;
  debug_paint.setStrokeWidth(8);
  debug_paint.setColor(SkColorSetA(checkerboard_color, 255));
  debug_paint.setDrawStyle(DlDrawStyle::kStroke);
  builder->drawRect(rect, debug_paint);
}

}  // namespace flutter
