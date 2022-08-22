// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_SNAPSHOT_DELEGATE_H_
#define FLUTTER_LIB_UI_SNAPSHOT_DELEGATE_H_

#include <string>

#include "flutter/common/graphics/texture.h"
#include "flutter/display_list/display_list.h"
#include "third_party/skia/include/core/SkImage.h"
#include "third_party/skia/include/core/SkPicture.h"
#include "third_party/skia/include/core/SkPromiseImageTexture.h"
#include "third_party/skia/include/gpu/GrContextThreadSafeProxy.h"

namespace flutter {

class SnapshotDelegate {
 public:
  struct GpuImageResult {
    GpuImageResult(const GrBackendTexture& p_texture,
                   sk_sp<GrDirectContext> p_context,
                   sk_sp<SkImage> p_image = nullptr,
                   const std::string& p_error = "")
        : texture(p_texture),
          context(std::move(p_context)),
          image(std::move(p_image)),
          error(p_error) {}

    const GrBackendTexture texture;
    // If texture.isValid() == true, this is a pointer to a GrDirectContext that
    // can be used to create an image from the texture.
    sk_sp<GrDirectContext> context;
    // If MakeGpuImage could not create a GPU resident image, a raster copy
    // is available in this member and texture.isValid() is false.
    sk_sp<SkImage> image;

    // A non-empty string containing an error message if neither a GPU backed
    // texture nor a raster backed image could be created.
    const std::string error;
  };

  //----------------------------------------------------------------------------
  /// @brief      Gets the registry of external textures currently in use by the
  ///             rasterizer. These textures may be updated at a cadence
  ///             different from that of the Flutter application. When an
  ///             external texture is referenced in the Flutter layer tree, that
  ///             texture is composited within the Flutter layer tree.
  ///
  /// @return     A pointer to the external texture registry.
  ///
  virtual std::shared_ptr<TextureRegistry> GetTextureRegistry() = 0;

  virtual std::unique_ptr<GpuImageResult> MakeGpuImage(
      sk_sp<DisplayList> display_list,
      const SkImageInfo& image_info) = 0;

  virtual sk_sp<SkImage> MakeRasterSnapshot(
      std::function<void(SkCanvas*)> draw_callback,
      SkISize picture_size) = 0;

  virtual sk_sp<SkImage> MakeRasterSnapshot(sk_sp<SkPicture> picture,
                                            SkISize picture_size) = 0;

  virtual sk_sp<SkImage> ConvertToRasterImage(sk_sp<SkImage> image) = 0;
};

}  // namespace flutter

#endif  // FLUTTER_LIB_UI_SNAPSHOT_DELEGATE_H_
