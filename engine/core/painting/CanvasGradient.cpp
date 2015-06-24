// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/painting/CanvasGradient.h"

namespace blink {

PassRefPtr<CanvasGradient> CanvasGradient::create() {
  return adoptRef(new CanvasGradient());
}

void CanvasGradient::initLinear(const Vector<Point>& end_points,
                                const Vector<SkColor>& colors,
                                const Vector<float>& color_stops,
                                SkShader::TileMode tile_mode) {
  ASSERT(end_points.size() == 2);
  ASSERT(colors.size() == color_stops.size() || color_stops.data() == nullptr);
  SkPoint sk_end_points[2];
  for (int i = 0; i < 2; ++i)
    sk_end_points[i] = end_points[i].sk_point;

  SkShader* shader = SkGradientShader::CreateLinear(
      sk_end_points, colors.data(), color_stops.data(), colors.size(),
      tile_mode);
  set_shader(adoptRef(shader));
}

void CanvasGradient::initRadial(const Point& center,
                                double radius,
                                const Vector<SkColor>& colors,
                                const Vector<float>& color_stops,
                                SkShader::TileMode tile_mode) {
  ASSERT(colors.size() == color_stops.size() || color_stops.data() == nullptr);

  SkShader* shader = SkGradientShader::CreateRadial(
      center.sk_point, radius, colors.data(), color_stops.data(), colors.size(),
      tile_mode);
  set_shader(adoptRef(shader));
}

CanvasGradient::CanvasGradient()
    : Shader(nullptr)
{
}

CanvasGradient::~CanvasGradient()
{
}

}  // namespace blink
