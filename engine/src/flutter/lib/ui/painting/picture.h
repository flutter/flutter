// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_PAINTING_PICTURE_H_
#define FLUTTER_LIB_UI_PAINTING_PICTURE_H_

#include <variant>

#include "flutter/display_list/display_list.h"
#include "flutter/flow/layers/layer_tree.h"
#include "flutter/lib/ui/dart_wrapper.h"
#include "flutter/lib/ui/painting/image.h"
#include "flutter/lib/ui/ui_dart_state.h"
#include "third_party/skia/include/core/SkPicture.h"

#if IMPELLER_SUPPORTS_RENDERING
#include "impeller/aiks/picture.h"  // nogncheck
#else                               // IMPELLER_SUPPORTS_RENDERING
namespace impeller {
struct Picture;
}  // namespace impeller
#endif                              // !IMPELLER_SUPPORTS_RENDERING

namespace flutter {
class Canvas;

using DisplayListOrPicture =
    std::variant<sk_sp<DisplayList>, std::shared_ptr<const impeller::Picture>>;

class Picture : public RefCountedDartWrappable<Picture> {
  DEFINE_WRAPPERTYPEINFO();
  FML_FRIEND_MAKE_REF_COUNTED(Picture);

 public:
  ~Picture() override;
  static fml::RefPtr<Picture> Create(Dart_Handle dart_handle,
                                     DisplayListOrPicture picture);

  const sk_sp<DisplayList> display_list() const {
    if (std::holds_alternative<sk_sp<DisplayList>>(picture_)) {
      return std::get<sk_sp<DisplayList>>(picture_);
    }
    return nullptr;
  }

  std::shared_ptr<const impeller::Picture> impeller_picture() const {
    if (std::holds_alternative<std::shared_ptr<const impeller::Picture>>(
            picture_)) {
      return std::get<std::shared_ptr<const impeller::Picture>>(picture_);
    }
    return nullptr;
  }

  Dart_Handle toImage(uint32_t width,
                      uint32_t height,
                      Dart_Handle raw_image_callback);

  void toImageSync(uint32_t width,
                   uint32_t height,
                   Dart_Handle raw_image_handle);

  void dispose();

  size_t GetAllocationSize() const;

  static Dart_Handle RasterizeLayerTreeToImage(
      std::unique_ptr<LayerTree> layer_tree,
      Dart_Handle raw_image_callback);

 private:
  explicit Picture(DisplayListOrPicture picture);

  DisplayListOrPicture picture_;

  void RasterizeToImageSync(uint32_t width,
                            uint32_t height,
                            Dart_Handle raw_image_handle);

  Dart_Handle RasterizeToImage(uint32_t width,
                               uint32_t height,
                               Dart_Handle raw_image_callback);

  Dart_Handle DoRasterizeToImage(uint32_t width,
                                 uint32_t height,
                                 Dart_Handle raw_image_callback);
};

}  // namespace flutter

#endif  // FLUTTER_LIB_UI_PAINTING_PICTURE_H_
