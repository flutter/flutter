// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/image_shader.h"
#include "flutter/lib/ui/painting/image_filter.h"

#include "flutter/lib/ui/painting/display_list_image_gpu.h"
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

Dart_Handle ImageShader::initWithImage(CanvasImage* image,
                                       SkTileMode tmx,
                                       SkTileMode tmy,
                                       int filter_quality_index,
                                       tonic::Float64List& matrix4) {
  if (!image) {
    matrix4.Release();
    return ToDart("ImageShader constructor called with non-genuine Image.");
  }

  if (image->image()->owning_context() != DlImage::OwningContext::kIO) {
    matrix4.Release();
    // TODO(dnfield): it should be possible to support this
    // https://github.com/flutter/flutter/issues/105085
    return ToDart("ImageShader constructor with GPU image is not supported.");
  }

  auto raw_sk_image = image->image()->skia_image();
  if (!raw_sk_image) {
    matrix4.Release();
    return ToDart("ImageShader constructor with Impeller is not supported.");
  }
  sk_image_ = UIDartState::CreateGPUObject(std::move(raw_sk_image));
  SkMatrix local_matrix = ToSkMatrix(matrix4);
  matrix4.Release();
  sampling_is_locked_ = filter_quality_index >= 0;
  DlImageSampling sampling =
      sampling_is_locked_ ? ImageFilter::SamplingFromIndex(filter_quality_index)
                          : DlImageSampling::kLinear;
  cached_shader_ = UIDartState::CreateGPUObject(sk_make_sp<DlImageColorSource>(
      sk_image_.skia_object(), ToDl(tmx), ToDl(tmy), sampling, &local_matrix));
  return Dart_Null();
}

std::shared_ptr<DlColorSource> ImageShader::shader(DlImageSampling sampling) {
  if (sampling_is_locked_) {
    sampling = cached_shader_.skia_object()->sampling();
  }
  // It might seem that if the sampling is locked we can just return the
  // cached version, but since we need to hold the cached shader in a
  // Skia GPU wrapper, and that wrapper requires an sk_sp<>, we are holding
  // an sk_sp<> version of the shared object and we need a shared_ptr version.
  // So, either way, we need the with_sampling() method to shared_ptr'ify
  // our copy.
  // If we can get rid of the need for the GPU unref queue, then this can all
  // be simplified down to just a shared_ptr.
  return cached_shader_.skia_object()->with_sampling(sampling);
}

int ImageShader::width() {
  return sk_image_.skia_object()->width();
}

int ImageShader::height() {
  return sk_image_.skia_object()->height();
}

ImageShader::ImageShader() = default;

ImageShader::~ImageShader() = default;

}  // namespace flutter
