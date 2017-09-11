// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_PAINTING_GRADIENT_H_
#define FLUTTER_LIB_UI_PAINTING_GRADIENT_H_

#include "flutter/lib/ui/painting/shader.h"
#include "lib/tonic/dart_wrappable.h"
#include "lib/tonic/typed_data/float32_list.h"
#include "lib/tonic/typed_data/int32_list.h"
#include "third_party/skia/include/effects/SkGradientShader.h"

namespace tonic {
class DartLibraryNatives;
}  // namspace tonic

namespace blink {

static_assert(SkShader::kTileModeCount == 3, "Need to update tile mode enum");

class CanvasGradient : public Shader {
  DEFINE_WRAPPERTYPEINFO();
  FRIEND_MAKE_REF_COUNTED(CanvasGradient);

 public:
  ~CanvasGradient() override;
  static fxl::RefPtr<CanvasGradient> Create();

  void initLinear(const tonic::Float32List& end_points,
                  const tonic::Int32List& colors,
                  const tonic::Float32List& color_stops,
                  SkShader::TileMode tile_mode);

  void initRadial(double center_x,
                  double center_y,
                  double radius,
                  const tonic::Int32List& colors,
                  const tonic::Float32List& color_stops,
                  SkShader::TileMode tile_mode);

  static void RegisterNatives(tonic::DartLibraryNatives* natives);

 private:
  CanvasGradient();
};

}  // namespace blink

#endif  // FLUTTER_LIB_UI_PAINTING_GRADIENT_H_
