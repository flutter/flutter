// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_VULKAN_QUEUE_SYNC_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_VULKAN_QUEUE_SYNC_H_

#define VK_NO_PROTOTYPES
#include <vulkan/vulkan_core.h>

// Registers the single graphics/compute queue owned by a manager. All host
// access to that queue, including device idle waits, uses one device-local
// lock. Registration must finish before publishing the device to the engine.
// Callers must retain the device lease until an operation returns; unregister
// only after all users have released it. The registry does not own Vulkan
// handles.
void fl_vulkan_queue_sync_register(VkDevice device,
                                   VkQueue queue,
                                   PFN_vkQueueSubmit submit,
                                   PFN_vkQueueWaitIdle queue_wait,
                                   PFN_vkDeviceWaitIdle device_wait);
void fl_vulkan_queue_sync_unregister(VkDevice device, VkQueue queue);

VKAPI_ATTR VkResult VKAPI_CALL
fl_vulkan_queue_submit(VkQueue queue,
                       uint32_t count,
                       const VkSubmitInfo* submits,
                       VkFence fence);
VKAPI_ATTR VkResult VKAPI_CALL fl_vulkan_queue_wait_idle(VkQueue queue);
VKAPI_ATTR VkResult VKAPI_CALL fl_vulkan_device_wait_idle(VkDevice device);

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_VULKAN_QUEUE_SYNC_H_
