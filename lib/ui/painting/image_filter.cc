// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/image_filter.h"

#include "flutter/lib/ui/painting/matrix.h"
#include "third_party/skia/include/effects/SkBlurImageFilter.h"
#include "third_party/skia/include/effects/SkImageSource.h"
#include "third_party/skia/include/effects/SkPictureImageFilter.h"
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

#define FOR_EACH_BINDING(V)   \
  V(ImageFilter, initImage)   \
  V(ImageFilter, initPicture) \
  V(ImageFilter, initBlur)    \
  V(ImageFilter, initMatrix)

FOR_EACH_BINDING(DART_NATIVE_CALLBACK)

void ImageFilter::RegisterNatives(tonic::DartLibraryNatives* natives) {
  natives->Register(
      {{"ImageFilter_constructor", ImageFilter_constructor, 1, true},
       FOR_EACH_BINDING(DART_REGISTER_NATIVE)});
}

fml::RefPtr<ImageFilter> ImageFilter::Create() {
  return fml::MakeRefCounted<ImageFilter>();
}

ImageFilter::ImageFilter() {}

ImageFilter::~ImageFilter() {}

void ImageFilter::initImage(CanvasImage* image) {
  filter_ = SkImageSource::Make(image->image());
}

void ImageFilter::initPicture(Picture* picture) {
  filter_ = SkPictureImageFilter::Make(picture->picture());
}

void ImageFilter::initBlur(double sigma_x, double sigma_y) {
  filter_ = SkBlurImageFilter::Make(sigma_x, sigma_y, nullptr, nullptr,
                                    SkBlurImageFilter::kClamp_TileMode);
}

void ImageFilter::initMatrix(const tonic::Float64List& matrix4,
                             int filterQuality) {
  filter_ = SkImageFilter::MakeMatrixFilter(
      ToSkMatrix(matrix4), static_cast<SkFilterQuality>(filterQuality),
      nullptr);
}

}  // namespace flutter
