// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_PAINTING_CANVASIMAGE_H_
#define SKY_ENGINE_CORE_PAINTING_CANVASIMAGE_H_

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
  static scoped_refptr<CanvasImage> create() { return new CanvasImage(); }

  int width();
  int height();
  void dispose();

  sk_sp<SkImage> image() const { return image_; }
  void setImage(sk_sp<SkImage> image) { image_ = image; }

  static void RegisterNatives(DartLibraryNatives* natives);

 private:
  CanvasImage();

  sk_sp<SkImage> image_;
};

}  // namespace blink

#endif  // SKY_ENGINE_CORE_PAINTING_CANVASIMAGE_H_
