// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/dl_canvas.h"

#include "flutter/display_list/geometry/dl_geometry_conversions.h"
#include "flutter/third_party/skia/include/core/SkPoint3.h"
#include "flutter/third_party/skia/include/utils/SkShadowUtils.h"

namespace flutter {

DlRect DlCanvas::ComputeShadowBounds(const DlPath& path,
                                     float elevation,
                                     DlScalar dpr,
                                     const DlMatrix& ctm) {
  SkRect shadow_bounds(ToSkRect(path.GetBounds()));
  SkShadowUtils::GetLocalBounds(
      ToSkMatrix(ctm), path.GetSkPath(), SkPoint3::Make(0, 0, dpr * elevation),
      SkPoint3::Make(0, -1, 1), kShadowLightRadius / kShadowLightHeight,
      SkShadowFlags::kDirectionalLight_ShadowFlag, &shadow_bounds);
  return ToDlRect(shadow_bounds);
}

}  // namespace flutter
