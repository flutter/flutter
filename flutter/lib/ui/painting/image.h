// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_PAINTING_IMAGE_H_
#define FLUTTER_LIB_UI_PAINTING_IMAGE_H_

#include "base/memory/ref_counted.h"
#include "flutter/tonic/dart_wrappable.h"
#include "third_party/skia/include/core/SkImage.h"

namespace blink {
class DartLibraryNatives;

class CanvasImage final : public base::RefCountedThreadSafe<CanvasImage>,
                          public DartWrappable {
  DEFINE_WRAPPERTYPEINFO();
 public:
  ~CanvasImage() override;
  static scoped_refptr<CanvasImage> Create() { return new CanvasImage(); }

  int width() { return image_->width(); }
  int height() { return image_->height(); }
  void dispose();

  const sk_sp<SkImage>& image() const { return image_; }
  void set_image(sk_sp<SkImage> image) { image_ = std::move(image); }

  static void RegisterNatives(DartLibraryNatives* natives);

 private:
  CanvasImage();

  sk_sp<SkImage> image_;
};

}  // namespace blink

#endif  // FLUTTER_LIB_UI_PAINTING_IMAGE_H_
