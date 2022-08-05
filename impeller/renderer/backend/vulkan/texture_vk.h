// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "impeller/base/backend_cast.h"
#include "impeller/renderer/backend/vulkan/context_vk.h"
#include "impeller/renderer/backend/vulkan/vk.h"
#include "impeller/renderer/texture.h"

namespace impeller {

class TextureVK final : public Texture, public BackendCast<TextureVK, Texture> {
 public:
  TextureVK(TextureDescriptor desc,
            ContextVK& context,
            const VmaAllocator& allocator,
            VkImage image,
            VmaAllocation allocation,
            VmaAllocationInfo allocation_info);

  // |Texture|
  ~TextureVK() override;

 private:
  ContextVK& context_;
  const VmaAllocator& allocator_;
  VkImage image_;
  VmaAllocation allocation_;
  VmaAllocationInfo allocation_info_;

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
