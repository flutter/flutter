// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "impeller/geometry/size.h"
#include "impeller/renderer/backend/vulkan/formats_vk.h"
#include "impeller/renderer/backend/vulkan/texture_source_vk.h"
#include "impeller/renderer/backend/vulkan/vk.h"

namespace impeller {

class SwapchainImageVK final : public TextureSourceVK {
 public:
  SwapchainImageVK(TextureDescriptor desc,
                   const vk::Device& device,
                   vk::Image image);

  // |TextureSourceVK|
  ~SwapchainImageVK() override;

  bool IsValid() const;

  PixelFormat GetPixelFormat() const;

  ISize GetSize() const;

  // |TextureSourceVK|
  vk::Image GetImage() const override;

  std::shared_ptr<Texture> GetMSAATexture() const;

  bool HasMSAATexture() const;

  // |TextureSourceVK|
  vk::ImageView GetImageView() const override;

  void SetMSAATexture(std::shared_ptr<Texture> msaa_tex);

 private:
  vk::Image image_ = VK_NULL_HANDLE;
  vk::UniqueImageView image_view_ = {};
  std::shared_ptr<Texture> msaa_tex_;
  bool is_valid_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(SwapchainImageVK);
};

}  // namespace impeller
