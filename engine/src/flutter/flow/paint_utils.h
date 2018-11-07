// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_PAINT_UTILS_H_
#define FLUTTER_FLOW_PAINT_UTILS_H_

#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkColor.h"
#include "third_party/skia/include/core/SkRect.h"

namespace flow {

void DrawCheckerboard(SkCanvas* canvas, SkColor c1, SkColor c2, int size);

void DrawCheckerboard(SkCanvas* canvas, const SkRect& rect);

}  // namespace flow

#endif  // FLUTTER_FLOW_PAINT_UTILS_H_
