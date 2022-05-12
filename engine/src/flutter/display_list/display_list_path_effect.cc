// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/display_list_path_effect.h"

#include <memory>
#include <optional>
#include <utility>

#include "include/core/SkRefCnt.h"
#include "include/core/SkScalar.h"

namespace flutter {

static void DlPathEffectDeleter(void* p) {
  // Some of our target environments would prefer a sized delete,
  // but other target environments do not have that operator.
  // Use an unsized delete until we get better agreement in the
  // environments.
  // See https://github.com/flutter/flutter/issues/100327
  ::operator delete(p);
}

std::shared_ptr<DlPathEffect> DlPathEffect::From(SkPathEffect* sk_path_effect) {
  if (sk_path_effect == nullptr) {
    return nullptr;
  }

  SkPathEffect::DashInfo info;
  if (SkPathEffect::DashType::kDash_DashType ==
      sk_path_effect->asADash(&info)) {
    auto dash_path_effect =
        DlDashPathEffect::Make(nullptr, info.fCount, info.fPhase);
    info.fIntervals =
        reinterpret_cast<DlDashPathEffect*>(dash_path_effect.get())
            ->intervals_unsafe();
    sk_path_effect->asADash(&info);
    return dash_path_effect;
  }
  // If not dash path effect, we will use UnknownPathEffect to wrap it.
  return std::make_shared<DlUnknownPathEffect>(sk_ref_sp(sk_path_effect));
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
  // SkDashPathEffect returns the original bounds as the bounds of the effect
  // since the dashed path will always be a subset of the original.
  return rect;
}

std::optional<SkRect> DlUnknownPathEffect::effect_bounds(SkRect& rect) const {
  if (!rect.isSorted()) {
    return std::nullopt;
  }
  SkPaint p;
  p.setPathEffect(sk_path_effect_);
  if (!p.canComputeFastBounds()) {
    return std::nullopt;
  }
  return p.computeFastBounds(rect, &rect);
}

}  // namespace flutter
