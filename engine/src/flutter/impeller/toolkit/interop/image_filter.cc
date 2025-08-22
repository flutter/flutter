// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/toolkit/interop/image_filter.h"

#include "flutter/display_list/effects/dl_image_filters.h"
#include "flutter/display_list/effects/dl_runtime_effect.h"
#include "flutter/impeller/display_list/dl_runtime_effect_impeller.h"
#include "impeller/base/validation.h"

namespace impeller::interop {

ImageFilter::ImageFilter(std::shared_ptr<flutter::DlImageFilter> filter)
    : filter_(std::move(filter)) {}

ImageFilter::~ImageFilter() = default;

ScopedObject<ImageFilter> ImageFilter::MakeBlur(Scalar x_sigma,
                                                Scalar y_sigma,
                                                flutter::DlTileMode tile_mode) {
  auto filter = flutter::DlBlurImageFilter::Make(x_sigma, y_sigma, tile_mode);
  if (!filter) {
    return nullptr;
  }
  return Create<ImageFilter>(std::move(filter));
}

ScopedObject<ImageFilter> ImageFilter::MakeDilate(Scalar x_radius,
                                                  Scalar y_radius) {
  auto filter = flutter::DlDilateImageFilter::Make(x_radius, y_radius);
  if (!filter) {
    return nullptr;
  }
  return Create<ImageFilter>(std::move(filter));
}

ScopedObject<ImageFilter> ImageFilter::MakeErode(Scalar x_radius,
                                                 Scalar y_radius) {
  auto filter = flutter::DlErodeImageFilter::Make(x_radius, y_radius);
  if (!filter) {
    return nullptr;
  }
  return Create<ImageFilter>(std::move(filter));
}

ScopedObject<ImageFilter> ImageFilter::MakeMatrix(
    const Matrix& matrix,
    flutter::DlImageSampling sampling) {
  auto filter = flutter::DlMatrixImageFilter::Make(matrix, sampling);
  if (!filter) {
    return nullptr;
  }
  return Create<ImageFilter>(std::move(filter));
}

ScopedObject<ImageFilter> ImageFilter::MakeFragmentProgram(
    const Context& context,
    const FragmentProgram& program,
    std::vector<std::shared_ptr<flutter::DlColorSource>> samplers,
    std::shared_ptr<std::vector<uint8_t>> uniform_data) {
  auto runtime_stage =
      program.FindRuntimeStage(context.GetContext()->GetRuntimeStageBackend());
  if (!runtime_stage) {
    VALIDATION_LOG << "Could not find runtime stage for backend.";
    return nullptr;
  }
  auto runtime_effect =
      flutter::DlRuntimeEffectImpeller::Make(std::move(runtime_stage));
  if (!runtime_effect) {
    VALIDATION_LOG << "Could not make runtime effect.";
    return nullptr;
  }
  auto filter =
      flutter::DlRuntimeEffectImageFilter::Make(std::move(runtime_effect),  //
                                                std::move(samplers),        //
                                                std::move(uniform_data)     //
      );
  if (!filter) {
    VALIDATION_LOG << "Could not create runtime effect image filter.";
    return nullptr;
  }
  return Create<ImageFilter>(std::move(filter));
}

ScopedObject<ImageFilter> ImageFilter::MakeCompose(const ImageFilter& outer,
                                                   const ImageFilter& inner) {
  auto filter = flutter::DlComposeImageFilter::Make(outer.GetImageFilter(),
                                                    inner.GetImageFilter());
  if (!filter) {
    return nullptr;
  }
  return Create<ImageFilter>(std::move(filter));
}

const std::shared_ptr<flutter::DlImageFilter>& ImageFilter::GetImageFilter()
    const {
  return filter_;
}

}  // namespace impeller::interop
