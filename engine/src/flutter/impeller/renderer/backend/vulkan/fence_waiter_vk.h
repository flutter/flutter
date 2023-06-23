// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <condition_variable>
#include <memory>
#include <thread>
#include <vector>

#include "flutter/fml/closure.h"
#include "flutter/fml/macros.h"
#include "impeller/base/thread.h"
#include "impeller/renderer/backend/vulkan/device_holder.h"
#include "impeller/renderer/backend/vulkan/shared_object_vk.h"
#include "impeller/renderer/backend/vulkan/vk.h"

namespace impeller {

class ContextVK;
class WaitSetEntry;

using WaitSet = std::vector<std::shared_ptr<WaitSetEntry>>;

class FenceWaiterVK {
 public:
  ~FenceWaiterVK();

  bool IsValid() const;

  void Terminate();

  bool AddFence(vk::UniqueFence fence, const fml::closure& callback);

 private:
  friend class ContextVK;

  std::weak_ptr<DeviceHolder> device_holder_;
  std::unique_ptr<std::thread> waiter_thread_;
  std::mutex wait_set_mutex_;
  std::condition_variable wait_set_cv_;
  WaitSet wait_set_;
  bool terminate_ = false;
  bool is_valid_ = false;

  explicit FenceWaiterVK(std::weak_ptr<DeviceHolder> device_holder);

  void Main();

  FML_DISALLOW_COPY_AND_ASSIGN(FenceWaiterVK);
};

}  // namespace impeller
