// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "impeller/base/thread.h"
#include "impeller/renderer/backend/vulkan/formats_vk.h"
#include "impeller/renderer/backend/vulkan/vk.h"
#include "impeller/renderer/texture_descriptor.h"

namespace impeller {

class TextureSourceVK {
 public:
  virtual ~TextureSourceVK();

  const TextureDescriptor& GetTextureDescriptor() const;

  virtual bool SetContents(const TextureDescriptor& desc,
                           const uint8_t* contents,
                           size_t length,
                           size_t slice);

  virtual vk::Image GetImage() const = 0;

  virtual vk::ImageView GetImageView() const = 0;

  bool SetLayout(const LayoutTransition& transition) const;

  vk::ImageLayout SetLayoutWithoutEncoding(vk::ImageLayout layout) const;

  vk::ImageLayout GetLayout() const;

 protected:
  const TextureDescriptor desc_;

  explicit TextureSourceVK(TextureDescriptor desc);

 private:
  mutable RWMutex layout_mutex_;
  mutable vk::ImageLayout layout_ IPLR_GUARDED_BY(layout_mutex_) =
      vk::ImageLayout::eUndefined;
};

}  // namespace impeller
