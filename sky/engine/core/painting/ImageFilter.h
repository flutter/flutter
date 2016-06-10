// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_PAINTING_IMAGE_FILTER_H_
#define SKY_ENGINE_CORE_PAINTING_IMAGE_FILTER_H_

#include "base/memory/ref_counted.h"
#include "sky/engine/core/painting/CanvasImage.h"
#include "sky/engine/core/painting/Picture.h"
#include "sky/engine/tonic/dart_wrappable.h"
#include "third_party/skia/include/core/SkImageFilter.h"

namespace blink {

class ImageFilter : public base::RefCountedThreadSafe<ImageFilter>, public DartWrappable {
  DEFINE_WRAPPERTYPEINFO();
 public:
  ~ImageFilter() override;
  static scoped_refptr<ImageFilter> create();

  void initImage(CanvasImage* image);
  void initPicture(Picture*);
  void initBlur(double sigmaX, double sigmaY);

  sk_sp<SkImageFilter> toSkia() { return filter_; }

  static void RegisterNatives(DartLibraryNatives* natives);

 private:
  ImageFilter();

  sk_sp<SkImageFilter> filter_;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_PAINTING_IMAGE_FILTER_H_
