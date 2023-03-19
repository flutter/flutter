// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/dl_canvas.h"

#include "third_party/skia/include/utils/SkShadowUtils.h"

namespace flutter {

SkRect DlCanvas::ComputeShadowBounds(const SkPath& path,
                                     float elevation,
                                     SkScalar dpr,
                                     const SkMatrix& ctm) {
  SkRect shadow_bounds(path.getBounds());
  SkShadowUtils::GetLocalBounds(
      ctm, path, SkPoint3::Make(0, 0, dpr * elevation),
      SkPoint3::Make(0, -1, 1), kShadowLightRadius / kShadowLightHeight,
      SkShadowFlags::kDirectionalLight_ShadowFlag, &shadow_bounds);
  return shadow_bounds;
}

}  // namespace flutter
