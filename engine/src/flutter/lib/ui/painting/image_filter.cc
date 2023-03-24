// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/image_filter.h"

#include "flutter/lib/ui/floating_point.h"
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
                           DlTileMode tile_mode) {
  filter_ = DlBlurImageFilter::Make(SafeNarrow(sigma_x), SafeNarrow(sigma_y),
                                    tile_mode);
}

void ImageFilter::initDilate(double radius_x, double radius_y) {
  filter_ =
      DlDilateImageFilter::Make(SafeNarrow(radius_x), SafeNarrow(radius_y));
}

void ImageFilter::initErode(double radius_x, double radius_y) {
  filter_ =
      DlErodeImageFilter::Make(SafeNarrow(radius_x), SafeNarrow(radius_y));
}

void ImageFilter::initMatrix(const tonic::Float64List& matrix4,
                             int filterQualityIndex) {
  auto sampling = ImageFilter::SamplingFromIndex(filterQualityIndex);
  filter_ = DlMatrixImageFilter::Make(ToSkMatrix(matrix4), sampling);
}

void ImageFilter::initColorFilter(ColorFilter* colorFilter) {
  FML_DCHECK(colorFilter);
  filter_ = DlColorFilterImageFilter::Make(colorFilter->filter());
}

void ImageFilter::initComposeFilter(ImageFilter* outer, ImageFilter* inner) {
  FML_DCHECK(outer && inner);
  filter_ = DlComposeImageFilter::Make(outer->filter(), inner->filter());
}

}  // namespace flutter
