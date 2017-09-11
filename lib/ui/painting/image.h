// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_PAINTING_IMAGE_H_
#define FLUTTER_LIB_UI_PAINTING_IMAGE_H_

#include "lib/tonic/dart_wrappable.h"
#include "third_party/skia/include/core/SkImage.h"

namespace tonic {
class DartLibraryNatives;
}  // namespace tonic

namespace blink {

class CanvasImage final : public fxl::RefCountedThreadSafe<CanvasImage>,
                          public tonic::DartWrappable {
  DEFINE_WRAPPERTYPEINFO();
  FRIEND_MAKE_REF_COUNTED(CanvasImage);

 public:
  ~CanvasImage() override;
  static fxl::RefPtr<CanvasImage> Create() {
    return fxl::MakeRefCounted<CanvasImage>();
  }

  int width() { return image_->width(); }
  int height() { return image_->height(); }
  void dispose();

  const sk_sp<SkImage>& image() const { return image_; }
  void set_image(sk_sp<SkImage> image) { image_ = std::move(image); }

  virtual size_t GetAllocationSize() override;

  static void RegisterNatives(tonic::DartLibraryNatives* natives);

 private:
  CanvasImage();

  sk_sp<SkImage> image_;
};

}  // namespace blink

#endif  // FLUTTER_LIB_UI_PAINTING_IMAGE_H_
