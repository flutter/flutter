// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_PAINTING_IMAGE_FILTER_H_
#define SKY_ENGINE_CORE_PAINTING_IMAGE_FILTER_H_

#include "sky/engine/core/painting/CanvasImage.h"
#include "sky/engine/core/painting/Picture.h"
#include "sky/engine/tonic/dart_wrappable.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/wtf/ThreadSafeRefCounted.h"
#include "third_party/skia/include/core/SkImageFilter.h"

namespace blink {

class ImageFilter : public ThreadSafeRefCounted<ImageFilter>, public DartWrappable {
  DEFINE_WRAPPERTYPEINFO();
 public:
  ~ImageFilter() override;
  static PassRefPtr<ImageFilter> create();

  void initImage(CanvasImage* image);
  void initPicture(Picture*);
  void initBlur(double sigmaX, double sigmaY);

  SkImageFilter* toSkia() { return filter_.get(); }

  static void RegisterNatives(DartLibraryNatives* natives);

 private:
  ImageFilter();

  RefPtr<SkImageFilter> filter_;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_PAINTING_IMAGE_FILTER_H_
