// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/texture_vk.h"

namespace impeller {

TextureVK::TextureVK(TextureDescriptor desc,
                     ContextVK& context,
                     const VmaAllocator& allocator,
                     VkImage image,
                     VmaAllocation allocation,
                     VmaAllocationInfo allocation_info)
    : Texture(desc),
      context_(context),
      allocator_(allocator),
      image_(image),
      allocation_(allocation),
      allocation_info_(allocation_info) {}

TextureVK::~TextureVK() {
  if (image_) {
    vmaDestroyImage(allocator_, image_, allocation_);
  }
}

void TextureVK::SetLabel(std::string_view label) {
  context_.SetDebugName(vk::Image{image_}, label);
}

bool TextureVK::OnSetContents(const uint8_t* contents,
                              size_t length,
                              size_t slice) {
  if (!image_ || !contents) {
    return false;
  }

  const auto& desc = GetTextureDescriptor();

  // Out of bounds access.
  if (length != desc.GetByteSizeOfBaseMipLevel()) {
    VALIDATION_LOG << "illegal to set contents for invalid size";
    return false;
  }

  // currently we are only supporting 2d textures, no cube textures etc.
  memcpy(allocation_info_.pMappedData, contents, length);

  return true;
}

bool TextureVK::OnSetContents(std::shared_ptr<const fml::Mapping> mapping,
                              size_t slice) {
  // Vulkan has no threading restrictions. So we can pass this data along to the
  // client rendering API immediately.
  return OnSetContents(mapping->GetMapping(), mapping->GetSize(), slice);
}

bool TextureVK::IsValid() const {
  return image_;
}

ISize TextureVK::GetSize() const {
  return GetTextureDescriptor().size;
}

}  // namespace impeller
