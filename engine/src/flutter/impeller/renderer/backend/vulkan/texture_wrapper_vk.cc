// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/texture_wrapper_vk.h"

#include <utility>

#include "flutter/fml/logging.h"
#include "impeller/renderer/backend/vulkan/context_vk.h"
#include "impeller/renderer/backend/vulkan/formats_vk.h"
#include "impeller/renderer/backend/vulkan/texture_source_vk.h"
#include "impeller/renderer/backend/vulkan/texture_vk.h"

namespace impeller {

namespace {

class WrappedTextureSourceVK final : public TextureSourceVK {
 public:
  explicit WrappedTextureSourceVK(vk::Image image,
                                  vk::UniqueImageView image_view,
                                  TextureDescriptor desc,
                                  std::function<void()> deletion_proc)
      : TextureSourceVK(desc),
        image_(image),
        image_view_(std::move(image_view)),
        deletion_proc_(std::move(deletion_proc)) {}

  ~WrappedTextureSourceVK() override {
    image_view_.reset();
    if (deletion_proc_) {
      deletion_proc_();
    }
  }

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
  std::function<void()> deletion_proc_;
};

}  // namespace

std::shared_ptr<Texture> WrapTextureVK(const std::shared_ptr<Context>& context,
                                       TextureDescriptor desc,
                                       vk::Image image,
                                       std::function<void()> deletion_proc) {
  if (!context || !context->IsValid() || !image) {
    return nullptr;
  }

  const auto& context_vk = ContextVK::Cast(*context);

  vk::ImageViewCreateInfo view_info = {};
  view_info.viewType = vk::ImageViewType::e2D;
  view_info.format = ToVKImageFormat(desc.format);
  view_info.subresourceRange.aspectMask = ToImageAspectFlags(desc.format);
  view_info.subresourceRange.baseMipLevel = 0u;
  view_info.subresourceRange.baseArrayLayer = 0u;
  view_info.subresourceRange.levelCount = desc.mip_count;
  view_info.subresourceRange.layerCount = 1;
  view_info.image = image;

  auto [result, image_view] =
      context_vk.GetDevice().createImageViewUnique(view_info);
  if (result != vk::Result::eSuccess) {
    FML_LOG(ERROR) << "Failed to create image view for provided Vulkan image: "
                   << vk::to_string(result);
    return nullptr;
  }

  auto source = std::make_shared<WrappedTextureSourceVK>(
      image, std::move(image_view), desc, std::move(deletion_proc));

  return std::make_shared<TextureVK>(context, std::move(source));
}

}  // namespace impeller
