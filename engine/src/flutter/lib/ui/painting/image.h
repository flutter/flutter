// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_PAINTING_IMAGE_H_
#define FLUTTER_LIB_UI_PAINTING_IMAGE_H_

#include "flutter/flow/skia_gpu_object.h"
#include "flutter/lib/ui/dart_wrapper.h"
#include "flutter/lib/ui/ui_dart_state.h"
#include "third_party/skia/include/core/SkImage.h"

namespace tonic {
class DartLibraryNatives;
}  // namespace tonic

namespace flutter {

class CanvasImage final : public RefCountedDartWrappable<CanvasImage> {
  DEFINE_WRAPPERTYPEINFO();
  FML_FRIEND_MAKE_REF_COUNTED(CanvasImage);

 public:
  ~CanvasImage() override;
  static fml::RefPtr<CanvasImage> Create() {
    return fml::MakeRefCounted<CanvasImage>();
  }

  int width() { return image_.get()->width(); }

  int height() { return image_.get()->height(); }

  Dart_Handle toByteData(int format, Dart_Handle callback);

  void dispose();

  sk_sp<SkImage> image() const { return image_.get(); }
  void set_image(flutter::SkiaGPUObject<SkImage> image) {
    image_ = std::move(image);
  }

  size_t GetAllocationSize() const override;

  static void RegisterNatives(tonic::DartLibraryNatives* natives);

 private:
  CanvasImage();

  flutter::SkiaGPUObject<SkImage> image_;
};

}  // namespace flutter

#endif  // FLUTTER_LIB_UI_PAINTING_IMAGE_H_
