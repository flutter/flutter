// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_GFX_SHADOW_VALUE_H_
#define UI_GFX_SHADOW_VALUE_H_

#include <string>
#include <vector>

#include "third_party/skia/include/core/SkColor.h"
#include "ui/gfx/geometry/vector2d.h"
#include "ui/gfx/gfx_export.h"

namespace gfx {

class Insets;

class ShadowValue;
typedef std::vector<ShadowValue> ShadowValues;

// ShadowValue encapsulates parameters needed to define a shadow, including the
// shadow's offset, blur amount and color.
class GFX_EXPORT ShadowValue {
 public:
  ShadowValue();
  ShadowValue(const gfx::Vector2d& offset, double blur, SkColor color);
  ~ShadowValue();

  int x() const { return offset_.x(); }
  int y() const { return offset_.y(); }
  const gfx::Vector2d& offset() const { return offset_; }
  double blur() const { return blur_; }
  SkColor color() const { return color_; }

  ShadowValue Scale(float scale) const;

  std::string ToString() const;

  // Gets margin space needed for shadows. Note that values in returned Insets
  // are negative because shadow margins are outside a boundary.
  static Insets GetMargin(const ShadowValues& shadows);

 private:
  gfx::Vector2d offset_;

  // Blur amount of the shadow in pixels. If underlying implementation supports
  // (e.g. Skia), it can have fraction part such as 0.5 pixel. The value
  // defines a range from full shadow color at the start point inside the
  // shadow to fully transparent at the end point outside it. The range is
  // perpendicular to and centered on the shadow edge. For example, a blur
  // amount of 4.0 means to have a blurry shadow edge of 4 pixels that
  // transitions from full shadow color to fully transparent and with 2 pixels
  // inside the shadow and 2 pixels goes beyond the edge.
  double blur_;

  SkColor color_;
};

}  // namespace gfx

#endif  // UI_GFX_SHADOW_VALUE_H_
