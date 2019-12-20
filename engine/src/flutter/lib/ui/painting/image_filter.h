// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_PAINTING_IMAGE_FILTER_H_
#define FLUTTER_LIB_UI_PAINTING_IMAGE_FILTER_H_

#include "flutter/lib/ui/dart_wrapper.h"
#include "flutter/lib/ui/painting/image.h"
#include "flutter/lib/ui/painting/picture.h"
#include "third_party/skia/include/core/SkImageFilter.h"
#include "third_party/tonic/typed_data/typed_list.h"

namespace flutter {

class ImageFilter : public RefCountedDartWrappable<ImageFilter> {
  DEFINE_WRAPPERTYPEINFO();
  FML_FRIEND_MAKE_REF_COUNTED(ImageFilter);

 public:
  ~ImageFilter() override;
  static fml::RefPtr<ImageFilter> Create();

  void initImage(CanvasImage* image);
  void initPicture(Picture*);
  void initBlur(double sigma_x, double sigma_y);
  void initMatrix(const tonic::Float64List& matrix4, int filter_quality);

  const sk_sp<SkImageFilter>& filter() const { return filter_; }

  static void RegisterNatives(tonic::DartLibraryNatives* natives);

 private:
  ImageFilter();

  sk_sp<SkImageFilter> filter_;
};

}  // namespace flutter

#endif  // FLUTTER_LIB_UI_PAINTING_IMAGE_FILTER_H_
