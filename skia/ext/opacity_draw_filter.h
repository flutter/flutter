// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKIA_EXT_OPACITY_DRAW_FILTER_H
#define SKIA_EXT_OPACITY_DRAW_FILTER_H

#include "base/values.h"
#include "third_party/skia/include/core/SkDrawFilter.h"

class SkPaint;

namespace skia {

// This filter allows setting an opacity on every draw call to a canvas, and to
// disable image filtering. Note that the opacity setting is only correct in
// very limited conditions: when there is only zero or one opaque, nonlayer
// draw for every pixel in the surface.
class SK_API OpacityDrawFilter : public SkDrawFilter {
 public:
  OpacityDrawFilter(float opacity, bool disable_image_filtering);
  ~OpacityDrawFilter() override;
  bool filter(SkPaint* paint, SkDrawFilter::Type type) override;

 private:
  int alpha_;
  bool disable_image_filtering_;
};

}  // namespace skia

#endif  // SKIA_EXT_OPACITY_DRAW_FILTER_H

