// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/render_target_cache.h"
#include "impeller/renderer/render_target.h"

namespace impeller {

RenderTargetCache::RenderTargetCache(std::shared_ptr<Allocator> allocator)
    : RenderTargetAllocator(std::move(allocator)) {}

void RenderTargetCache::Start() {
  for (auto& td : texture_data_) {
    td.used_this_frame = false;
  }
}

void RenderTargetCache::End() {
  std::vector<TextureData> retain;

  for (const auto& td : texture_data_) {
    if (td.used_this_frame) {
      retain.push_back(td);
    }
  }
  texture_data_.swap(retain);
}

size_t RenderTargetCache::CachedTextureCount() const {
  return texture_data_.size();
}

std::shared_ptr<Texture> RenderTargetCache::CreateTexture(
    const TextureDescriptor& desc) {
  FML_DCHECK(desc.storage_mode != StorageMode::kHostVisible);
  FML_DCHECK(desc.usage &
             static_cast<TextureUsageMask>(TextureUsage::kRenderTarget));

  for (auto& td : texture_data_) {
    const auto other_desc = td.texture->GetTextureDescriptor();
    FML_DCHECK(td.texture != nullptr);
    if (!td.used_this_frame && desc == other_desc) {
      td.used_this_frame = true;
      return td.texture;
    }
  }
  auto result = RenderTargetAllocator::CreateTexture(desc);
  if (result == nullptr) {
    return result;
  }
  texture_data_.push_back(
      TextureData{.used_this_frame = true, .texture = result});
  return result;
}

}  // namespace impeller
