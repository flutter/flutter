// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_PAINTING_PICTURE_H_
#define FLUTTER_LIB_UI_PAINTING_PICTURE_H_

#include "flutter/flow/skia_gpu_object.h"
#include "flutter/lib/ui/dart_wrapper.h"
#include "flutter/lib/ui/painting/image.h"
#include "third_party/skia/include/core/SkPicture.h"

namespace tonic {
class DartLibraryNatives;
}  // namespace tonic

namespace blink {
class Canvas;

class Picture : public RefCountedDartWrappable<Picture> {
  DEFINE_WRAPPERTYPEINFO();
  FML_FRIEND_MAKE_REF_COUNTED(Picture);

 public:
  ~Picture() override;
  static fml::RefPtr<Picture> Create(flow::SkiaGPUObject<SkPicture> picture);

  sk_sp<SkPicture> picture() const { return picture_.get(); }

  fml::RefPtr<CanvasImage> toImage(int width, int height);

  void dispose();

  size_t GetAllocationSize() override;

  static void RegisterNatives(tonic::DartLibraryNatives* natives);

 private:
  explicit Picture(flow::SkiaGPUObject<SkPicture> picture);

  flow::SkiaGPUObject<SkPicture> picture_;
};

}  // namespace blink

#endif  // FLUTTER_LIB_UI_PAINTING_PICTURE_H_
