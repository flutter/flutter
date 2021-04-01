// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/image_shader.h"
#include "flutter/lib/ui/painting/image_filter.h"

#include "flutter/lib/ui/ui_dart_state.h"
#include "third_party/tonic/converter/dart_converter.h"
#include "third_party/tonic/dart_args.h"
#include "third_party/tonic/dart_binding_macros.h"
#include "third_party/tonic/dart_library_natives.h"

using tonic::ToDart;

namespace flutter {

static void ImageShader_constructor(Dart_NativeArguments args) {
  DartCallConstructor(&ImageShader::Create, args);
}

IMPLEMENT_WRAPPERTYPEINFO(ui, ImageShader);

#define FOR_EACH_BINDING(V) V(ImageShader, initWithImage)

FOR_EACH_BINDING(DART_NATIVE_CALLBACK)

void ImageShader::RegisterNatives(tonic::DartLibraryNatives* natives) {
  natives->Register(
      {{"ImageShader_constructor", ImageShader_constructor, 1, true},
       FOR_EACH_BINDING(DART_REGISTER_NATIVE)});
}

fml::RefPtr<ImageShader> ImageShader::Create() {
  return fml::MakeRefCounted<ImageShader>();
}

void ImageShader::initWithImage(CanvasImage* image,
                                SkTileMode tmx,
                                SkTileMode tmy,
                                int filter_quality_index,
                                const tonic::Float64List& matrix4) {
  if (!image) {
    Dart_ThrowException(
        ToDart("ImageShader constructor called with non-genuine Image."));
    return;
  }
  sk_image_ = image->image();
  tmx_ = tmx;
  tmy_ = tmy;
  local_matrix_ = ToSkMatrix(matrix4);
  if (filter_quality_index >= 0) {
    cached_sampling_ = ImageFilter::SamplingFromIndex(filter_quality_index);
    sampling_is_locked_ = true;
  } else {
    sampling_is_locked_ = false;
  }
}

sk_sp<SkShader> ImageShader::shader(SkSamplingOptions sampling) {
  if (sampling_is_locked_) {
    sampling = cached_sampling_;
  }
  if (!cached_shader_.get() || cached_sampling_ != sampling) {
    cached_sampling_ = sampling;
    cached_shader_ = UIDartState::CreateGPUObject(
        sk_image_->makeShader(tmx_, tmy_, sampling, &local_matrix_));
  }
  return cached_shader_.get();
}

ImageShader::ImageShader() = default;

ImageShader::~ImageShader() = default;

}  // namespace flutter
