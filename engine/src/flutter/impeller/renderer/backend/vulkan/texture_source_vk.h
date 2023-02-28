// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "impeller/renderer/backend/vulkan/vk.h"
#include "impeller/renderer/texture_descriptor.h"

namespace impeller {

class TextureSourceVK {
 public:
  virtual ~TextureSourceVK() = default;

  virtual bool SetContents(const TextureDescriptor& desc,
                           const uint8_t* contents,
                           size_t length,
                           size_t slice);

  virtual vk::Image GetVKImage() const = 0;

  virtual vk::ImageView GetVKImageView() const = 0;
};

}  // namespace impeller
