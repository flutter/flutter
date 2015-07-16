// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gfx/shadow_value.h"

#include <algorithm>

#include "base/strings/stringprintf.h"
#include "ui/gfx/geometry/insets.h"
#include "ui/gfx/geometry/vector2d_conversions.h"

namespace gfx {

ShadowValue::ShadowValue() : blur_(0), color_(0) {
}

ShadowValue::ShadowValue(const gfx::Vector2d& offset,
                         double blur,
                         SkColor color)
    : offset_(offset), blur_(blur), color_(color) {
}

ShadowValue::~ShadowValue() {
}

ShadowValue ShadowValue::Scale(float scale) const {
  gfx::Vector2d scaled_offset =
      gfx::ToFlooredVector2d(gfx::ScaleVector2d(offset_, scale));
  return ShadowValue(scaled_offset, blur_ * scale, color_);
}

std::string ShadowValue::ToString() const {
  return base::StringPrintf("(%d,%d),%.2f,rgba(%d,%d,%d,%d)", offset_.x(),
                            offset_.y(), blur_, SkColorGetR(color_),
                            SkColorGetG(color_), SkColorGetB(color_),
                            SkColorGetA(color_));
}

// static
Insets ShadowValue::GetMargin(const ShadowValues& shadows) {
  int left = 0;
  int top = 0;
  int right = 0;
  int bottom = 0;

  for (size_t i = 0; i < shadows.size(); ++i) {
    const ShadowValue& shadow = shadows[i];

    // Add 0.5 to round up to the next integer.
    int blur = static_cast<int>(shadow.blur() / 2 + 0.5);

    left = std::max(left, blur - shadow.x());
    top = std::max(top, blur - shadow.y());
    right = std::max(right, blur + shadow.x());
    bottom = std::max(bottom, blur + shadow.y());
  }

  return Insets(-top, -left, -bottom, -right);
}

}  // namespace gfx
