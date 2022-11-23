// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>

#include "flutter/fml/macros.h"
#include "impeller/renderer/backend/vulkan/deletion_queue_vk.h"
#include "impeller/renderer/backend/vulkan/vk.h"

namespace impeller {

class FencedCommandBufferVK {
 public:
  FencedCommandBufferVK(vk::Device device,
                        vk::Queue queue,
                        vk::CommandPool command_pool);

  ~FencedCommandBufferVK();

  vk::CommandBuffer Get() const;

  vk::CommandBuffer GetSingleUseChild();

  // this is a blocking call that waits for the fence to be signaled.
  bool Submit();

  DeletionQueueVK* GetDeletionQueue() const;

 private:
  vk::Device device_;
  vk::Queue queue_;
  vk::CommandPool command_pool_;
  std::unique_ptr<DeletionQueueVK> deletion_queue_;
  vk::CommandBuffer command_buffer_;
  std::vector<vk::CommandBuffer> children_;
  bool submitted_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(FencedCommandBufferVK);
};

}  // namespace impeller
