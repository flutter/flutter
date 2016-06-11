// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_PAINTING_IMAGESHADER_H_
#define SKY_ENGINE_CORE_PAINTING_IMAGESHADER_H_

#include "sky/engine/core/painting/CanvasGradient.h"
#include "sky/engine/core/painting/CanvasImage.h"
#include "sky/engine/core/painting/Shader.h"
#include "sky/engine/tonic/dart_wrappable.h"
#include "sky/engine/core/painting/Matrix.h"
#include "sky/engine/tonic/float64_list.h"
#include "third_party/skia/include/core/SkShader.h"
#include "third_party/skia/include/core/SkMatrix.h"

namespace blink {
class DartLibraryNatives;

class ImageShader : public Shader {
    DEFINE_WRAPPERTYPEINFO();
 public:
  ~ImageShader() override;
  static scoped_refptr<ImageShader> create();

  void initWithImage(CanvasImage* image,
                     SkShader::TileMode tmx,
                     SkShader::TileMode tmy,
                     const Float64List& matrix4);

  static void RegisterNatives(DartLibraryNatives* natives);

 private:
  ImageShader();
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_PAINTING_IMAGESHADER_H_
