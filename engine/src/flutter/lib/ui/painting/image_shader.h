// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_PAINTING_IMAGE_SHADER_H_
#define FLUTTER_LIB_UI_PAINTING_IMAGE_SHADER_H_

#include "flutter/lib/ui/dart_wrapper.h"
#include "flutter/lib/ui/painting/gradient.h"
#include "flutter/lib/ui/painting/image.h"
#include "flutter/lib/ui/painting/matrix.h"
#include "flutter/lib/ui/painting/shader.h"
#include "third_party/skia/include/core/SkMatrix.h"
#include "third_party/skia/include/core/SkShader.h"
#include "third_party/tonic/typed_data/typed_list.h"

namespace tonic {
class DartLibraryNatives;
}  // namespace tonic

namespace flutter {

class ImageShader : public Shader {
  DEFINE_WRAPPERTYPEINFO();
  FML_FRIEND_MAKE_REF_COUNTED(ImageShader);

 public:
  ~ImageShader() override;
  static fml::RefPtr<ImageShader> Create();

  Dart_Handle initWithImage(CanvasImage* image,
                            SkTileMode tmx,
                            SkTileMode tmy,
                            int filter_quality_index,
                            tonic::Float64List& matrix4);

  std::shared_ptr<DlColorSource> shader(DlImageSampling) override;

  static void RegisterNatives(tonic::DartLibraryNatives* natives);

  int width();
  int height();

 private:
  ImageShader();

  flutter::SkiaGPUObject<SkImage> sk_image_;
  bool sampling_is_locked_;

  flutter::SkiaGPUObject<DlImageColorSource> cached_shader_;
};

}  // namespace flutter

#endif  // FLUTTER_LIB_UI_PAINTING_IMAGE_SHADER_H_
