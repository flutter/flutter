// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_PAINTING_PICTURE_H_
#define FLUTTER_LIB_UI_PAINTING_PICTURE_H_

#include "flutter/display_list/display_list.h"
#include "flutter/flow/skia_gpu_object.h"
#include "flutter/lib/ui/dart_wrapper.h"
#include "flutter/lib/ui/painting/image.h"
#include "flutter/lib/ui/ui_dart_state.h"
#include "third_party/skia/include/core/SkPicture.h"

namespace tonic {
class DartLibraryNatives;
}  // namespace tonic

namespace flutter {
class Canvas;

class Picture : public RefCountedDartWrappable<Picture> {
  DEFINE_WRAPPERTYPEINFO();
  FML_FRIEND_MAKE_REF_COUNTED(Picture);

 public:
  ~Picture() override;
  static fml::RefPtr<Picture> Create(
      Dart_Handle dart_handle,
      flutter::SkiaGPUObject<DisplayList> display_list);

  sk_sp<DisplayList> display_list() const {
    return display_list_.skia_object();
  }

  Dart_Handle toImage(uint32_t width,
                      uint32_t height,
                      Dart_Handle raw_image_callback);

  void dispose();

  size_t GetAllocationSize() const override;

  static void RegisterNatives(tonic::DartLibraryNatives* natives);

  static Dart_Handle RasterizeToImage(sk_sp<DisplayList> display_list,
                                      uint32_t width,
                                      uint32_t height,
                                      Dart_Handle raw_image_callback);

  static Dart_Handle RasterizeToImage(
      std::function<void(SkCanvas*)> draw_callback,
      uint32_t width,
      uint32_t height,
      Dart_Handle raw_image_callback);

 private:
  explicit Picture(flutter::SkiaGPUObject<DisplayList> display_list);

  flutter::SkiaGPUObject<DisplayList> display_list_;
};

}  // namespace flutter

#endif  // FLUTTER_LIB_UI_PAINTING_PICTURE_H_
