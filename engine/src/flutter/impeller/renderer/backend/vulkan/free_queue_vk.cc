// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/free_queue_vk.h"

#include <utility>
#include "fml/trace_event.h"

namespace impeller {

FreeQueueVK::FreeQueueVK(std::weak_ptr<DeviceHolderVK> device_holder)
    : device_holder_(std::move(device_holder)) {}

FreeQueueVK::~FreeQueueVK() = default;

void FreeQueueVK::PushEntry(vk::UniqueFence fence,
                            const fml::closure& callback) {
  std::unique_lock lock(entry_mutex_);
  entries_.push_back(Entry{.fence = std::move(fence), .callback = callback});
}

void FreeQueueVK::PopEntries() {
  TRACE_EVENT0("flutter", "FreeQueueVK::PopEntries")
  auto device_holder = device_holder_.lock();
  if (!device_holder) {
    return;
  }

  std::unique_lock lock(entry_mutex_);
  size_t erase_count = 0;
  for (const Entry& entry : entries_) {
    // Perform a wait with a 0ms timeout. This will only check if the
    // fence has already been signaled and should not block to wait
    // for the fence. If the fence is not signaled, then vk::Result::eTimeout is
    // returned.
    vk::Result result = device_holder->GetDevice().waitForFences(
        1, &entry.fence.get(), false, 0);
    if (result == vk::Result::eSuccess) {
      if (entry.callback) {
        entry.callback();
      }
      erase_count++;
    } else {
      break;
    }
  }

  if (erase_count > 0) {
    entries_.erase(entries_.begin(), entries_.begin() + erase_count);
  }
}

}  // namespace impeller
