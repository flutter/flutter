// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_PAINTING_IMAGE_FILTER_H_
#define FLUTTER_LIB_UI_PAINTING_IMAGE_FILTER_H_

#include "base/memory/ref_counted.h"
#include "flutter/lib/ui/painting/image.h"
#include "flutter/lib/ui/painting/picture.h"
#include "flutter/tonic/dart_wrappable.h"
#include "third_party/skia/include/core/SkImageFilter.h"

namespace blink {

class ImageFilter : public base::RefCountedThreadSafe<ImageFilter>,
                    public DartWrappable {
  DEFINE_WRAPPERTYPEINFO();
 public:
  ~ImageFilter() override;
  static scoped_refptr<ImageFilter> Create();

  void initImage(CanvasImage* image);
  void initPicture(Picture*);
  void initBlur(double sigma_x, double sigma_y);

  const sk_sp<SkImageFilter>& filter() { return filter_; }

  static void RegisterNatives(DartLibraryNatives* natives);

 private:
  ImageFilter();

  sk_sp<SkImageFilter> filter_;
};

} // namespace blink

#endif  // FLUTTER_LIB_UI_PAINTING_IMAGE_FILTER_H_
