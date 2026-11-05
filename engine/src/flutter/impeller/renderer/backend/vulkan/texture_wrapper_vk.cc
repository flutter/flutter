// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/texture_wrapper_vk.h"

#include <utility>

#include "flutter/fml/logging.h"
#include "impeller/renderer/backend/vulkan/context_vk.h"
#include "impeller/renderer/backend/vulkan/formats_vk.h"

namespace impeller {

namespace {

/// A texture source over a `VkImage` owned by someone else. Holds the image by
/// value and owns only the view it creates for it.
class WrappedTextureSourceVK final : public TextureSourceVK {
 public:
  WrappedTextureSourceVK(vk::Image image,
                         vk::UniqueImageView image_view,
                         TextureDescriptor desc)
      : TextureSourceVK(desc),
        image_(image),
        image_view_(std::move(image_view)) {}

  ~WrappedTextureSourceVK() override = default;

 private:
  vk::Image GetImage() const override { return image_; }

  vk::ImageView GetImageView() const override { return image_view_.get(); }

  vk::ImageView GetRenderTargetView(uint32_t mip_level,
                                    uint32_t array_layer) const override {
    return image_view_.get();
  }

  bool IsSwapchainImage() const override { return true; }

  vk::Image image_;
  vk::UniqueImageView image_view_;

  WrappedTextureSourceVK(const WrappedTextureSourceVK&) = delete;
  WrappedTextureSourceVK& operator=(const WrappedTextureSourceVK&) = delete;
};

}  // namespace

std::shared_ptr<TextureSourceVK> WrapTextureSourceVK(
    const std::shared_ptr<Context>& context,
    const TextureDescriptor& desc,
    vk::Image image) {
  if (!context || !image) {
    return nullptr;
  }

  vk::ImageViewCreateInfo view_info = {};
  view_info.viewType = vk::ImageViewType::e2D;
  view_info.format = ToVKImageFormat(desc.format);
  view_info.subresourceRange.aspectMask = vk::ImageAspectFlagBits::eColor;
  view_info.subresourceRange.baseMipLevel = 0u;
  view_info.subresourceRange.baseArrayLayer = 0u;
  view_info.subresourceRange.levelCount = 1;
  view_info.subresourceRange.layerCount = 1;
  view_info.image = image;

  auto [result, image_view] =
      ContextVK::Cast(*context).GetDevice().createImageViewUnique(view_info);
  if (result != vk::Result::eSuccess) {
    FML_LOG(ERROR) << "Failed to create image view for wrapped image: "
                   << vk::to_string(result);
    return nullptr;
  }

  return std::make_shared<WrappedTextureSourceVK>(image, std::move(image_view),
                                                  desc);
}

}  // namespace impeller
