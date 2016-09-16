// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "vulkan_backbuffer.h"

#include <limits>

namespace vulkan {

VulkanBackbuffer::VulkanBackbuffer(VulkanProcTable& p_vk,
                                   VulkanHandle<VkDevice>& device,
                                   VulkanHandle<VkCommandPool>& pool,
                                   VulkanHandle<VkImage> image)
    : vk(p_vk),
      device_(device),
      pool_(pool),
      image_(std::move(image)),
      valid_(false) {
  if (!device_ || !pool_ || !image_) {
    return;
  }

  if (!CreateSemaphores()) {
    return;
  }

  if (!CreateTransitionBuffers()) {
    return;
  }

  if (!CreateFences()) {
    return;
  }

  valid_ = true;
}

VulkanBackbuffer::~VulkanBackbuffer() {
  WaitFences();
}

bool VulkanBackbuffer::IsValid() const {
  return valid_;
}

bool VulkanBackbuffer::CreateSemaphores() {
  const VkSemaphoreCreateInfo create_info = {
      .sType = VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO,
      .pNext = nullptr,
      .flags = 0,
  };

  auto semaphore_collect = [this](VkSemaphore semaphore) {
    vk.destroySemaphore(device_, semaphore, nullptr);
  };

  for (size_t i = 0; i < semaphores_.size(); i++) {
    VkSemaphore semaphore = VK_NULL_HANDLE;

    if (vk.createSemaphore(device_, &create_info, nullptr, &semaphore) !=
        VK_SUCCESS) {
      return false;
    }

    semaphores_[i] = {semaphore, semaphore_collect};
  }

  return true;
}

bool VulkanBackbuffer::CreateTransitionBuffers() {
  const VkCommandBufferAllocateInfo allocate_info = {
      .sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO,
      .pNext = nullptr,
      .commandPool = pool_,
      .level = VK_COMMAND_BUFFER_LEVEL_PRIMARY,
      .commandBufferCount = 1,
  };

  auto buffer_collect = [this](VkCommandBuffer buffer) {
    vk.freeCommandBuffers(device_, pool_, 1, &buffer);
  };

  for (size_t i = 0; i < transition_buffers_.size(); i++) {
    VkCommandBuffer buffer = VK_NULL_HANDLE;

    if (vk.allocateCommandBuffers(device_, &allocate_info, &buffer) !=
        VK_SUCCESS) {
      return false;
    }

    transition_buffers_[i] = {buffer, buffer_collect};
  }

  return true;
}

bool VulkanBackbuffer::CreateFences() {
  const VkFenceCreateInfo create_info = {
      .sType = VK_STRUCTURE_TYPE_FENCE_CREATE_INFO,
      .pNext = nullptr,
      .flags = VK_FENCE_CREATE_SIGNALED_BIT,
  };

  auto fence_collect = [this](VkFence fence) {
    vk.destroyFence(device_, fence, nullptr);
  };

  for (size_t i = 0; i < use_fences_.size(); i++) {
    VkFence fence = VK_NULL_HANDLE;

    if (vk.createFence(device_, &create_info, nullptr, &fence) != VK_SUCCESS) {
      return false;
    }

    use_fences_[i] = {fence, fence_collect};
  }

  return true;
}

void VulkanBackbuffer::WaitFences() {
  VkFence fences[use_fences_.size()];

  for (size_t i = 0; i < use_fences_.size(); i++) {
    fences[i] = use_fences_[i];
  }

  vk.waitForFences(device_, static_cast<uint32_t>(use_fences_.size()), fences,
                   true, std::numeric_limits<uint64_t>::max());
}

}  // namespace vulkan
