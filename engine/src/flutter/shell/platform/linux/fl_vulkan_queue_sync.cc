// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_vulkan_queue_sync.h"

#include <map>
#include <memory>
#include <mutex>

namespace {
struct Dispatch {
  std::mutex mutex;
  PFN_vkQueueSubmit submit;
  PFN_vkQueueWaitIdle queue_wait;
  PFN_vkDeviceWaitIdle device_wait;
};

std::mutex registry_mutex;
std::map<VkQueue, std::shared_ptr<Dispatch>> queues;
std::map<VkDevice, std::shared_ptr<Dispatch>> devices;

template <typename Handle>
std::shared_ptr<Dispatch> lookup(
    const std::map<Handle, std::shared_ptr<Dispatch>>& registry,
    Handle handle) {
  std::lock_guard<std::mutex> lock(registry_mutex);
  auto it = registry.find(handle);
  return it == registry.end() ? nullptr : it->second;
}
}  // namespace

void fl_vulkan_queue_sync_register(VkDevice device,
                                   VkQueue queue,
                                   PFN_vkQueueSubmit submit,
                                   PFN_vkQueueWaitIdle queue_wait,
                                   PFN_vkDeviceWaitIdle device_wait) {
  auto dispatch = std::make_shared<Dispatch>();
  dispatch->submit = submit;
  dispatch->queue_wait = queue_wait;
  dispatch->device_wait = device_wait;
  std::lock_guard<std::mutex> lock(registry_mutex);
  queues.emplace(queue, dispatch);
  devices.emplace(device, dispatch);
}

void fl_vulkan_queue_sync_unregister(VkDevice device, VkQueue queue) {
  std::lock_guard<std::mutex> lock(registry_mutex);
  queues.erase(queue);
  devices.erase(device);
}

VKAPI_ATTR VkResult VKAPI_CALL
fl_vulkan_queue_submit(VkQueue queue,
                       uint32_t count,
                       const VkSubmitInfo* submits,
                       VkFence fence) {
  auto dispatch = lookup(queues, queue);
  if (!dispatch) {
    return VK_ERROR_INITIALIZATION_FAILED;
  }
  // Never hold the registry lock while entering the driver. An idle wait on
  // another engine's device must not delay this device's next frame submission.
  std::lock_guard<std::mutex> lock(dispatch->mutex);
  return dispatch->submit(queue, count, submits, fence);
}

VKAPI_ATTR VkResult VKAPI_CALL fl_vulkan_queue_wait_idle(VkQueue queue) {
  auto dispatch = lookup(queues, queue);
  if (!dispatch) {
    return VK_ERROR_INITIALIZATION_FAILED;
  }
  std::lock_guard<std::mutex> lock(dispatch->mutex);
  return dispatch->queue_wait(queue);
}

VKAPI_ATTR VkResult VKAPI_CALL fl_vulkan_device_wait_idle(VkDevice device) {
  auto dispatch = lookup(devices, device);
  if (!dispatch) {
    return VK_ERROR_INITIALIZATION_FAILED;
  }
  std::lock_guard<std::mutex> lock(dispatch->mutex);
  return dispatch->device_wait(device);
}
