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

class CanvasGradient : public Shader {
    DEFINE_WRAPPERTYPEINFO();
 public:
  ~CanvasGradient() override;
  static PassRefPtr<CanvasGradient> create(int type,
                                           const Vector<Point>& end_points,
                                           const Vector<SkColor>& colors,
                                           const Vector<float>& color_stops);

 private:
  CanvasGradient(PassRefPtr<SkShader> shader);
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_PAINTING_CANVASGRADIENT_H_
