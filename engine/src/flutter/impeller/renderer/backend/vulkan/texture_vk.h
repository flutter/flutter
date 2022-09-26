// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "impeller/base/backend_cast.h"
#include "impeller/renderer/backend/vulkan/context_vk.h"
#include "impeller/renderer/backend/vulkan/swapchain_vk.h"
#include "impeller/renderer/backend/vulkan/vk.h"
#include "impeller/renderer/texture.h"

namespace impeller {

enum class TextureBackingTypeVK {
  kUnknownType,
  kAllocatedTexture,
  kWrappedTexture,
};

struct WrappedTextureInfoVK {
  SwapchainImageVK* swapchain_image = nullptr;
  uint32_t frame_num = 0;
};

struct AllocatedTextureInfoVK {
  VmaAllocator* allocator = nullptr;
  VmaAllocation allocation = nullptr;
  VmaAllocationInfo allocation_info = {};
  VkImage image = nullptr;
};

struct TextureInfoVK {
  TextureBackingTypeVK backing_type;
  union {
    WrappedTextureInfoVK wrapped_texture;
    AllocatedTextureInfoVK allocated_texture;
  };
};

class TextureVK final : public Texture, public BackendCast<TextureVK, Texture> {
 public:
  TextureVK(TextureDescriptor desc,
            ContextVK* context,
            std::unique_ptr<TextureInfoVK> texture_info);

  // |Texture|
  ~TextureVK() override;

  bool IsWrapped() const;

  vk::Image GetImage() const;

  TextureInfoVK* GetTextureInfo() const;

 private:
  ContextVK* context_;
  std::unique_ptr<TextureInfoVK> texture_info_;

  // |Texture|
  void SetLabel(std::string_view label) override;

  // |Texture|
  bool OnSetContents(const uint8_t* contents,
                     size_t length,
                     size_t slice) override;

  // |Texture|
  bool OnSetContents(std::shared_ptr<const fml::Mapping> mapping,
                     size_t slice) override;

  // |Texture|
  bool IsValid() const override;

  // |Texture|
  ISize GetSize() const override;

  FML_DISALLOW_COPY_AND_ASSIGN(TextureVK);
};

}  // namespace impeller
