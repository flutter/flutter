// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_FENCE_WAITER_VK_H_
#define FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_FENCE_WAITER_VK_H_

#include <condition_variable>
#include <functional>
#include <memory>
#include <thread>
#include <vector>

#include "impeller/renderer/backend/vulkan/device_holder_vk.h"
#include "third_party/abseil-cpp/absl/status/status.h"

namespace impeller {

class ContextVK;
class WaitSetEntry;

using WaitSet = std::vector<std::shared_ptr<WaitSetEntry>>;

class FenceWaiterVK {
 public:
  ~FenceWaiterVK();

  bool IsValid() const;

  void Terminate();

  /// @brief Invokes the [submit_callback] synchronously and adds the fence to
  ///        the wait set if it succeeds.  The [completion_callback] will be
  ///        called when the submitted command completes and the fence is
  ///        signaled (true), or when the submission fails after device loss
  ///        (false). A rejected submission does not invoke this callback.
  absl::Status AddFence(
      vk::UniqueFence fence,
      const std::function<absl::Status(vk::Fence)>& submit_callback,
      std::function<void(bool signaled)> completion_callback);

 private:
  friend class ContextVK;

  std::weak_ptr<DeviceHolderVK> device_holder_;
  std::unique_ptr<std::thread> waiter_thread_;
  std::mutex wait_set_mutex_;
  std::condition_variable wait_set_cv_;
  WaitSet wait_set_;
  bool terminate_ = false;
  bool device_lost_ = false;

  explicit FenceWaiterVK(std::weak_ptr<DeviceHolderVK> device_holder);

  void Main();

  bool Wait();
  void DrainAfterDeviceLoss(const vk::Device& device);
  void WaitUntilEmpty();

  FenceWaiterVK(const FenceWaiterVK&) = delete;

  FenceWaiterVK& operator=(const FenceWaiterVK&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_FENCE_WAITER_VK_H_
