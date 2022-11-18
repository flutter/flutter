// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/texture_vk.h"

namespace impeller {

TextureVK::TextureVK(TextureDescriptor desc,
                     ContextVK* context,
                     std::unique_ptr<TextureInfoVK> texture_info)
    : Texture(desc),
      context_(context),
      texture_info_(std::move(texture_info)) {}

TextureVK::~TextureVK() {
  if (!IsWrapped() && IsValid()) {
    const auto& texture = texture_info_->allocated_texture;
    vmaDestroyImage(*texture.backing_allocation.allocator, texture.image,
                    texture.backing_allocation.allocation);
  }
}

void TextureVK::SetLabel(std::string_view label) {
  context_->SetDebugName(GetImage(), label);
}

bool TextureVK::OnSetContents(const uint8_t* contents,
                              size_t length,
                              size_t slice) {
  if (IsWrapped()) {
    FML_LOG(ERROR) << "Cannot set contents of a wrapped texture";
    return false;
  }

  if (!IsValid() || !contents) {
    return false;
  }

  const auto& desc = GetTextureDescriptor();

  // Out of bounds access.
  if (length != desc.GetByteSizeOfBaseMipLevel()) {
    VALIDATION_LOG << "illegal to set contents for invalid size";
    return false;
  }

  // currently we are only supporting 2d textures, no cube textures etc.
  auto mapping = texture_info_->allocated_texture.staging_buffer.GetMapping();

  if (mapping) {
    memcpy(mapping, contents, length);
    return true;
  } else {
    return false;
  }
}

bool TextureVK::OnSetContents(std::shared_ptr<const fml::Mapping> mapping,
                              size_t slice) {
  // Vulkan has no threading restrictions. So we can pass this data along to the
  // client rendering API immediately.
  return OnSetContents(mapping->GetMapping(), mapping->GetSize(), slice);
}

bool TextureVK::IsValid() const {
  switch (texture_info_->backing_type) {
    case TextureBackingTypeVK::kUnknownType:
      return false;
    case TextureBackingTypeVK::kAllocatedTexture:
      return texture_info_->allocated_texture.image;
    case TextureBackingTypeVK::kWrappedTexture:
      return texture_info_->wrapped_texture.swapchain_image;
  }
}

ISize TextureVK::GetSize() const {
  return GetTextureDescriptor().size;
}

TextureInfoVK* TextureVK::GetTextureInfo() const {
  return texture_info_.get();
}

bool TextureVK::IsWrapped() const {
  return texture_info_->backing_type == TextureBackingTypeVK::kWrappedTexture;
}

vk::ImageView TextureVK::GetImageView() const {
  switch (texture_info_->backing_type) {
    case TextureBackingTypeVK::kUnknownType:
      return nullptr;
    case TextureBackingTypeVK::kAllocatedTexture:
      return vk::ImageView{texture_info_->allocated_texture.image_view};
    case TextureBackingTypeVK::kWrappedTexture:
      return texture_info_->wrapped_texture.swapchain_image->GetImageView();
  }
}

vk::Image TextureVK::GetImage() const {
  switch (texture_info_->backing_type) {
    case TextureBackingTypeVK::kUnknownType:
      FML_CHECK(false) << "Unknown texture backing type";
    case TextureBackingTypeVK::kAllocatedTexture:
      return vk::Image{texture_info_->allocated_texture.image};
    case TextureBackingTypeVK::kWrappedTexture:
      return texture_info_->wrapped_texture.swapchain_image->GetImage();
  }
}

vk::Buffer TextureVK::GetStagingBuffer() const {
  switch (texture_info_->backing_type) {
    case TextureBackingTypeVK::kUnknownType:
      FML_CHECK(false) << "Unknown texture backing type";
      return nullptr;
    case TextureBackingTypeVK::kAllocatedTexture:
      return texture_info_->allocated_texture.staging_buffer.GetBufferHandle();
    case TextureBackingTypeVK::kWrappedTexture:
      FML_CHECK(false) << "Wrapped textures do not have staging buffers";
      return nullptr;
  }
}

}  // namespace impeller
