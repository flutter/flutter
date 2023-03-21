// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/effects/dl_path_effect.h"

namespace flutter {

static void DlPathEffectDeleter(void* p) {
  // Some of our target environments would prefer a sized delete,
  // but other target environments do not have that operator.
  // Use an unsized delete until we get better agreement in the
  // environments.
  // See https://github.com/flutter/flutter/issues/100327
  ::operator delete(p);
}

std::shared_ptr<DlPathEffect> DlDashPathEffect::Make(const SkScalar* intervals,
                                                     int count,
                                                     SkScalar phase) {
  size_t needed = sizeof(DlDashPathEffect) + sizeof(SkScalar) * count;
  void* storage = ::operator new(needed);

  std::shared_ptr<DlDashPathEffect> ret;
  ret.reset(new (storage) DlDashPathEffect(intervals, count, phase),
            DlPathEffectDeleter);
  return std::move(ret);
}

std::optional<SkRect> DlDashPathEffect::effect_bounds(SkRect& rect) const {
  // The dashed path will always be a subset of the original.
  return rect;
}

}  // namespace flutter
