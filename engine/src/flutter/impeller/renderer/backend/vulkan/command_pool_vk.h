// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>
#include <set>
#include <thread>

#include "flutter/fml/macros.h"
#include "impeller/base/thread.h"
#include "impeller/renderer/backend/vulkan/device_holder.h"
#include "impeller/renderer/backend/vulkan/shared_object_vk.h"
#include "impeller/renderer/backend/vulkan/vk.h"

namespace impeller {

class ContextVK;

class CommandPoolVK {
 public:
  static std::shared_ptr<CommandPoolVK> GetThreadLocal(
      const ContextVK* context);

  static void ClearAllPools(const ContextVK* context);

  ~CommandPoolVK();

  bool IsValid() const;

  void Reset();

  vk::CommandPool GetGraphicsCommandPool() const;

  vk::UniqueCommandBuffer CreateGraphicsCommandBuffer();

  void CollectGraphicsCommandBuffer(vk::UniqueCommandBuffer buffer);

 private:
  const std::thread::id owner_id_;
  std::weak_ptr<const DeviceHolder> device_holder_;
  vk::UniqueCommandPool graphics_pool_;
  Mutex buffers_to_collect_mutex_;
  std::set<SharedHandleVK<vk::CommandBuffer>> buffers_to_collect_
      IPLR_GUARDED_BY(buffers_to_collect_mutex_);
  bool is_valid_ = false;

  explicit CommandPoolVK(const ContextVK* context);

  void GarbageCollectBuffersIfAble() IPLR_REQUIRES(buffers_to_collect_mutex_);

  FML_DISALLOW_COPY_AND_ASSIGN(CommandPoolVK);
};

}  // namespace impeller
