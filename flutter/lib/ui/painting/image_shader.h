// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_PAINTING_IMAGE_SHADER_H_
#define FLUTTER_LIB_UI_PAINTING_IMAGE_SHADER_H_

#include "flutter/lib/ui/painting/gradient.h"
#include "flutter/lib/ui/painting/image.h"
#include "flutter/lib/ui/painting/matrix.h"
#include "flutter/lib/ui/painting/shader.h"
#include "flutter/tonic/dart_wrappable.h"
#include "flutter/tonic/float64_list.h"
#include "third_party/skia/include/core/SkMatrix.h"
#include "third_party/skia/include/core/SkShader.h"

namespace blink {
class DartLibraryNatives;

class ImageShader : public Shader {
  DEFINE_WRAPPERTYPEINFO();
 public:
  ~ImageShader() override;
  static scoped_refptr<ImageShader> Create();

  void initWithImage(CanvasImage* image,
                     SkShader::TileMode tmx,
                     SkShader::TileMode tmy,
                     const Float64List& matrix4);

  static void RegisterNatives(DartLibraryNatives* natives);

 private:
  ImageShader();
};

} // namespace blink

#endif  // FLUTTER_LIB_UI_PAINTING_IMAGE_SHADER_H_
