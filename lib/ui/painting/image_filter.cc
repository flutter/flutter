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

static void ImageFilter_constructor(Dart_NativeArguments args) {
  UIDartState::ThrowIfUIOperationsProhibited();
  DartCallConstructor(&ImageFilter::Create, args);
}

IMPLEMENT_WRAPPERTYPEINFO(ui, ImageFilter);

#define FOR_EACH_BINDING(V)       \
  V(ImageFilter, initBlur)        \
  V(ImageFilter, initMatrix)      \
  V(ImageFilter, initColorFilter) \
  V(ImageFilter, initComposeFilter)

FOR_EACH_BINDING(DART_NATIVE_CALLBACK)

void ImageFilter::RegisterNatives(tonic::DartLibraryNatives* natives) {
  natives->Register(
      {{"ImageFilter_constructor", ImageFilter_constructor, 1, true},
       FOR_EACH_BINDING(DART_REGISTER_NATIVE)});
}

fml::RefPtr<ImageFilter> ImageFilter::Create() {
  return fml::MakeRefCounted<ImageFilter>();
}

static const std::array<SkSamplingOptions, 4> filter_qualities = {
    SkSamplingOptions(SkFilterMode::kNearest, SkMipmapMode::kNone),
    SkSamplingOptions(SkFilterMode::kLinear, SkMipmapMode::kNone),
    SkSamplingOptions(SkFilterMode::kLinear, SkMipmapMode::kLinear),
    SkSamplingOptions(SkCubicResampler{1 / 3.0f, 1 / 3.0f}),
};

SkSamplingOptions ImageFilter::SamplingFromIndex(int filterQualityIndex) {
  if (filterQualityIndex < 0) {
    return filter_qualities.front();
  } else if (static_cast<size_t>(filterQualityIndex) >=
             filter_qualities.size()) {
    return filter_qualities.back();
  } else {
    return filter_qualities[filterQualityIndex];
  }
}

SkFilterMode ImageFilter::FilterModeFromIndex(int filterQualityIndex) {
  if (filterQualityIndex <= 0) {
    return SkFilterMode::kNearest;
  }
  return SkFilterMode::kLinear;
}

ImageFilter::ImageFilter() {}

ImageFilter::~ImageFilter() {}

void ImageFilter::initBlur(double sigma_x,
                           double sigma_y,
                           SkTileMode tile_mode) {
  filter_ =
      std::make_shared<DlBlurImageFilter>(sigma_x, sigma_y, ToDl(tile_mode));
}

void ImageFilter::initMatrix(const tonic::Float64List& matrix4,
                             int filterQualityIndex) {
  auto sampling = ImageFilter::SamplingFromIndex(filterQualityIndex);
  filter_ =
      std::make_shared<DlMatrixImageFilter>(ToSkMatrix(matrix4), sampling);
}

void ImageFilter::initColorFilter(ColorFilter* colorFilter) {
  filter_ = std::make_shared<DlColorFilterImageFilter>(
      colorFilter ? colorFilter->dl_filter() : nullptr);
}

void ImageFilter::initComposeFilter(ImageFilter* outer, ImageFilter* inner) {
  filter_ = std::make_shared<DlComposeImageFilter>(
      outer ? outer->dl_filter() : nullptr,
      inner ? inner->dl_filter() : nullptr);
}

}  // namespace flutter
