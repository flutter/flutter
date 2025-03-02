// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_FREE_QUEUE_VK_H_
#define FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_FREE_QUEUE_VK_H_

#include <memory>
#include <mutex>

#include "fml/closure.h"
#include "impeller/renderer/backend/vulkan/device_holder_vk.h"
#include "vulkan/vulkan_handles.hpp"

namespace impeller {

/// Storage for pairs of a GPU resources and a fence that signals when
/// the resources may be released.
///
/// To handle safe shutdown of the vulkan context, the device should waitIdle
/// before destructing any instances of this class. This ensures that all fences
/// would have signaled already.
class FreeQueueVK {
 public:
  explicit FreeQueueVK(std::weak_ptr<DeviceHolderVK> device_holder);

  ~FreeQueueVK();

  /// Push a new fence and closure into this free queue.
  ///
  /// This operation is thread safe.
  void PushEntry(vk::UniqueFence fence, const fml::closure& callback);

  /// Remove signaled fences from the free queue until an unsignaled fence
  /// is deteceted.
  ///
  /// This operation is thread safe.
  void PopEntries();

 private:
  FreeQueueVK(FreeQueueVK&&) = delete;

  FreeQueueVK(const FreeQueueVK&) = delete;

  struct Entry {
    vk::UniqueFence fence;
    fml::closure callback;
  };

  std::mutex entry_mutex_;
  std::weak_ptr<DeviceHolderVK> device_holder_;
  std::vector<Entry> entries_;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_FREE_QUEUE_VK_H_
