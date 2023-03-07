// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/image_filter.h"

#include "flutter/lib/ui/painting/matrix.h"
#include "flutter/lib/ui/ui_dart_state.h"
#include "third_party/tonic/converter/dart_converter.h"
#include "third_party/tonic/dart_args.h"
#include "third_party/tonic/dart_binding_macros.h"
#include "third_party/tonic/dart_library_natives.h"

namespace flutter {

IMPLEMENT_WRAPPERTYPEINFO(ui, ImageFilter);

void ImageFilter::Create(Dart_Handle wrapper) {
  UIDartState::ThrowIfUIOperationsProhibited();
  auto res = fml::MakeRefCounted<ImageFilter>();
  res->AssociateWithDartWrapper(wrapper);
}

static const std::array<DlImageSampling, 4> kFilterQualities = {
    DlImageSampling::kNearestNeighbor,
    DlImageSampling::kLinear,
    DlImageSampling::kMipmapLinear,
    DlImageSampling::kCubic,
};

DlImageSampling ImageFilter::SamplingFromIndex(int filterQualityIndex) {
  if (filterQualityIndex < 0) {
    return kFilterQualities.front();
  } else if (static_cast<size_t>(filterQualityIndex) >=
             kFilterQualities.size()) {
    return kFilterQualities.back();
  } else {
    return kFilterQualities[filterQualityIndex];
  }
}

DlFilterMode ImageFilter::FilterModeFromIndex(int filterQualityIndex) {
  if (filterQualityIndex <= 0) {
    return DlFilterMode::kNearest;
  }
  return DlFilterMode::kLinear;
}

ImageFilter::ImageFilter() {}

ImageFilter::~ImageFilter() {}

void ImageFilter::initBlur(double sigma_x,
                           double sigma_y,
                           SkTileMode tile_mode) {
  filter_ =
      std::make_shared<DlBlurImageFilter>(sigma_x, sigma_y, ToDl(tile_mode));
}

void ImageFilter::initDilate(double radius_x, double radius_y) {
  filter_ = std::make_shared<DlDilateImageFilter>(radius_x, radius_y);
}

void ImageFilter::initErode(double radius_x, double radius_y) {
  filter_ = std::make_shared<DlErodeImageFilter>(radius_x, radius_y);
}

void ImageFilter::initMatrix(const tonic::Float64List& matrix4,
                             int filterQualityIndex) {
  auto sampling = ImageFilter::SamplingFromIndex(filterQualityIndex);
  filter_ =
      std::make_shared<DlMatrixImageFilter>(ToSkMatrix(matrix4), sampling);
}

void ImageFilter::initColorFilter(ColorFilter* colorFilter) {
  FML_DCHECK(colorFilter);
  auto dl_filter = colorFilter->dl_filter();
  // Skia may return nullptr if the colorfilter is a no-op.
  if (dl_filter) {
    filter_ = std::make_shared<DlColorFilterImageFilter>(dl_filter);
  }
}

void ImageFilter::initComposeFilter(ImageFilter* outer, ImageFilter* inner) {
  FML_DCHECK(outer && inner);
  if (!outer->dl_filter()) {
    filter_ = inner->filter();
  } else if (!inner->dl_filter()) {
    filter_ = outer->filter();
  } else {
    filter_ = std::make_shared<DlComposeImageFilter>(outer->dl_filter(),
                                                     inner->dl_filter());
  }
}

}  // namespace flutter
