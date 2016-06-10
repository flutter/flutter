// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/painting/ImageFilter.h"

#include "sky/engine/tonic/dart_args.h"
#include "sky/engine/tonic/dart_binding_macros.h"
#include "sky/engine/tonic/dart_converter.h"
#include "sky/engine/tonic/dart_library_natives.h"
#include "third_party/skia/include/effects/SkBlurImageFilter.h"
#include "third_party/skia/include/effects/SkImageSource.h"
#include "third_party/skia/include/effects/SkPictureImageFilter.h"

namespace blink {

static void ImageFilter_constructor(Dart_NativeArguments args) {
  DartCallConstructor(&ImageFilter::create, args);
}

IMPLEMENT_WRAPPERTYPEINFO(ui, ImageFilter);

#define FOR_EACH_BINDING(V) \
  V(ImageFilter, initImage) \
  V(ImageFilter, initPicture) \
  V(ImageFilter, initBlur)

FOR_EACH_BINDING(DART_NATIVE_CALLBACK)

void ImageFilter::RegisterNatives(DartLibraryNatives* natives) {
  natives->Register({
    { "ImageFilter_constructor", ImageFilter_constructor, 1, true },
FOR_EACH_BINDING(DART_REGISTER_NATIVE)
  });
}

scoped_refptr<ImageFilter> ImageFilter::create() {
  return new ImageFilter();
}

ImageFilter::ImageFilter() {
}

ImageFilter::~ImageFilter() {
}

void ImageFilter::initImage(CanvasImage* image) {
  filter_ = SkImageSource::Make(image->image());
}

void ImageFilter::initPicture(Picture* picture) {
  filter_ = SkPictureImageFilter::Make(picture->toSkia());
}

void ImageFilter::initBlur(double sigmaX, double sigmaY) {
  filter_ = SkBlurImageFilter::Make(sigmaX, sigmaY, nullptr);
}

} // namespace blink
