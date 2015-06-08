// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/core/painting/CanvasGradient.h"

#include "base/logging.h"
#include "sky/engine/core/painting/Picture.h"

namespace blink {

PassRefPtr<CanvasGradient> CanvasGradient::create(
    int type,
    const Vector<Point>& end_points,
    const Vector<SkColor>& colors,
    const Vector<float>& color_stops) {
  ASSERT(type == 0);  // Only 1 supported type so far.
  ASSERT(end_points.size() == 2);
  ASSERT(colors.size() == color_stops.size() || color_stops.data() == nullptr);
  SkPoint sk_end_points[2];
  for (int i = 0; i < 2; ++i)
    sk_end_points[i] = end_points[i].sk_point;

  SkShader* shader = SkGradientShader::CreateLinear(
      sk_end_points, colors.data(), color_stops.data(), colors.size(),
      SkShader::kClamp_TileMode);
  return adoptRef(new CanvasGradient(adoptRef(shader)));
}

CanvasGradient::CanvasGradient(PassRefPtr<SkShader> shader)
    : Shader(shader)
{
}

CanvasGradient::~CanvasGradient()
{
}

} // namespace blink
