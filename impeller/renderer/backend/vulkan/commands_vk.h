// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "impeller/renderer/backend/vulkan/context_vk.h"
#include "impeller/renderer/backend/vulkan/fenced_command_buffer_vk.h"

// Set of common utility commands for Vulkan.
namespace impeller {

class TransitionImageLayoutCommandVK {
 public:
  TransitionImageLayoutCommandVK(vk::Image image,
                                 vk::ImageLayout old_layout,
                                 vk::ImageLayout new_layout,
                                 uint32_t mip_levels);

  ~TransitionImageLayoutCommandVK();

  bool Submit(FencedCommandBufferVK* command_buffer);

 private:
  vk::Image image_;
  vk::ImageLayout old_layout_;
  vk::ImageLayout new_layout_;
  uint32_t mip_levels_;

  FML_DISALLOW_COPY_AND_ASSIGN(TransitionImageLayoutCommandVK);
};

}  // namespace impeller
