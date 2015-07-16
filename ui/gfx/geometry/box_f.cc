// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gfx/geometry/box_f.h"

#include <algorithm>

#include "base/logging.h"
#include "base/strings/stringprintf.h"

namespace gfx {

std::string BoxF::ToString() const {
  return base::StringPrintf("%s %fx%fx%f",
                            origin().ToString().c_str(),
                            width_,
                            height_,
                            depth_);
}

bool BoxF::IsEmpty() const {
  return (width_ == 0 && height_ == 0) ||
         (width_ == 0 && depth_ == 0) ||
         (height_ == 0 && depth_ == 0);
}

void BoxF::ExpandTo(const Point3F& min, const Point3F& max) {
  DCHECK_LE(min.x(), max.x());
  DCHECK_LE(min.y(), max.y());
  DCHECK_LE(min.z(), max.z());

  float min_x = std::min(x(), min.x());
  float min_y = std::min(y(), min.y());
  float min_z = std::min(z(), min.z());
  float max_x = std::max(right(), max.x());
  float max_y = std::max(bottom(), max.y());
  float max_z = std::max(front(), max.z());

  origin_.SetPoint(min_x, min_y, min_z);
  width_ = max_x - min_x;
  height_ = max_y - min_y;
  depth_ = max_z - min_z;
}

void BoxF::Union(const BoxF& box) {
  if (IsEmpty()) {
    *this = box;
    return;
  }
  if (box.IsEmpty())
    return;
  ExpandTo(box);
}

void BoxF::ExpandTo(const Point3F& point) {
  ExpandTo(point, point);
}

void BoxF::ExpandTo(const BoxF& box) {
  ExpandTo(box.origin(), gfx::Point3F(box.right(), box.bottom(), box.front()));
}

BoxF UnionBoxes(const BoxF& a, const BoxF& b) {
  BoxF result = a;
  result.Union(b);
  return result;
}

}  // namespace gfx
