// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_VULKAN_VULKAN_BACKBUFFER_H_
#define FLUTTER_VULKAN_VULKAN_BACKBUFFER_H_

#include <array>

#include "lib/ftl/macros.h"
#include "vulkan_proc_table.h"
#include "vulkan_handle.h"

namespace vulkan {

class VulkanBackbuffer {
 public:
  VulkanBackbuffer(VulkanProcTable& vk,
                   VulkanHandle<VkDevice>& device,
                   VulkanHandle<VkCommandPool>& pool,
                   VulkanHandle<VkImage> image);

  ~VulkanBackbuffer();

  bool IsValid() const;

 private:
  VulkanProcTable& vk;
  VulkanHandle<VkDevice>& device_;
  VulkanHandle<VkCommandPool>& pool_;
  VulkanHandle<VkImage> image_;

  bool valid_;

  std::array<VulkanHandle<VkSemaphore>, 2> semaphores_;
  std::array<VulkanHandle<VkCommandBuffer>, 2> transition_buffers_;
  std::array<VulkanHandle<VkFence>, 2> use_fences_;

  bool CreateSemaphores();

  bool CreateTransitionBuffers();

  bool CreateFences();

  void WaitFences();

  FTL_DISALLOW_COPY_AND_ASSIGN(VulkanBackbuffer);
};

}  // namespace vulkan

#endif  // FLUTTER_VULKAN_VULKAN_BACKBUFFER_H_
