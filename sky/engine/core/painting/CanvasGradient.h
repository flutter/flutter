// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_PAINTING_CANVASGRADIENT_H_
#define SKY_ENGINE_CORE_PAINTING_CANVASGRADIENT_H_

#include "sky/engine/core/painting/CanvasColor.h"
#include "sky/engine/core/painting/Point.h"
#include "sky/engine/core/painting/Shader.h"
#include "sky/engine/tonic/dart_wrappable.h"
#include "third_party/skia/include/effects/SkGradientShader.h"

namespace blink {
class DartLibraryNatives;

template <>
struct DartConverter<SkShader::TileMode> : public DartConverterInteger<SkShader::TileMode> {};

static_assert(SkShader::kTileModeCount == 3, "Need to update tile mode enum");

class CanvasGradient : public Shader {
  DEFINE_WRAPPERTYPEINFO();
 public:
  ~CanvasGradient() override;
  static scoped_refptr<CanvasGradient> create();

  void initLinear(const std::vector<Point>& end_points,
                  const std::vector<CanvasColor>& colors,
                  const std::vector<float>& color_stops,
                  SkShader::TileMode tile_mode);

  void initRadial(const Point& center,
                  double radius,
                  const std::vector<CanvasColor>& colors,
                  const std::vector<float>& color_stops,
                  SkShader::TileMode tile_mode);

  static void RegisterNatives(DartLibraryNatives* natives);

 private:
  CanvasGradient();
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_PAINTING_CANVASGRADIENT_H_
