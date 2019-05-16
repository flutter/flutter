// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_PAINTING_GRADIENT_H_
#define FLUTTER_LIB_UI_PAINTING_GRADIENT_H_

#include "flutter/lib/ui/dart_wrapper.h"
#include "flutter/lib/ui/painting/matrix.h"
#include "flutter/lib/ui/painting/shader.h"
#include "third_party/skia/include/effects/SkGradientShader.h"
#include "third_party/tonic/typed_data/typed_list.h"

namespace tonic {
class DartLibraryNatives;
}  // namespace tonic

namespace flutter {

// TODO: update this if/when Skia adds Decal mode skbug.com/7638
static_assert(kSkTileModeCount >= 3, "Need to update tile mode enum");

class CanvasGradient : public Shader {
  DEFINE_WRAPPERTYPEINFO();
  FML_FRIEND_MAKE_REF_COUNTED(CanvasGradient);

 public:
  ~CanvasGradient() override;
  static fml::RefPtr<CanvasGradient> Create();

  void initLinear(const tonic::Float32List& end_points,
                  const tonic::Int32List& colors,
                  const tonic::Float32List& color_stops,
                  SkTileMode tile_mode,
                  const tonic::Float64List& matrix4);

  void initRadial(double center_x,
                  double center_y,
                  double radius,
                  const tonic::Int32List& colors,
                  const tonic::Float32List& color_stops,
                  SkTileMode tile_mode,
                  const tonic::Float64List& matrix4);

  void initSweep(double center_x,
                 double center_y,
                 const tonic::Int32List& colors,
                 const tonic::Float32List& color_stops,
                 SkTileMode tile_mode,
                 double start_angle,
                 double end_angle,
                 const tonic::Float64List& matrix4);

  void initTwoPointConical(double start_x,
                           double start_y,
                           double start_radius,
                           double end_x,
                           double end_y,
                           double end_radius,
                           const tonic::Int32List& colors,
                           const tonic::Float32List& color_stops,
                           SkTileMode tile_mode,
                           const tonic::Float64List& matrix4);

  static void RegisterNatives(tonic::DartLibraryNatives* natives);

 private:
  CanvasGradient();
};

}  // namespace flutter

#endif  // FLUTTER_LIB_UI_PAINTING_GRADIENT_H_
