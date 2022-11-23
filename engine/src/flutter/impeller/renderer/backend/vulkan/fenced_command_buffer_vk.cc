// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/fenced_command_buffer_vk.h"

#include <memory>

#include "impeller/base/validation.h"
#include "impeller/renderer/backend/vulkan/deletion_queue_vk.h"

namespace impeller {

static vk::CommandBuffer CreateCommandBuffer(vk::Device device,
                                             vk::CommandPool pool) {
  vk::CommandBufferAllocateInfo allocate_info;
  allocate_info.setLevel(vk::CommandBufferLevel::ePrimary);
  allocate_info.setCommandBufferCount(1);
  allocate_info.setCommandPool(pool);

  auto res = device.allocateCommandBuffers(allocate_info);
  if (res.result != vk::Result::eSuccess) {
    VALIDATION_LOG << "Failed to allocate command buffer: "
                   << vk::to_string(res.result);
    return nullptr;
  }

  return res.value[0];
}

FencedCommandBufferVK::FencedCommandBufferVK(vk::Device device,
                                             vk::Queue queue,
                                             vk::CommandPool command_pool)
    : device_(device),
      queue_(queue),
      command_pool_(command_pool),
      deletion_queue_(std::make_unique<DeletionQueueVK>()) {
  command_buffer_ = CreateCommandBuffer(device_, command_pool_);
}

vk::CommandBuffer FencedCommandBufferVK::Get() const {
  return command_buffer_;
}

vk::CommandBuffer FencedCommandBufferVK::GetSingleUseChild() {
  auto child = CreateCommandBuffer(device_, command_pool_);
  children_.push_back(child);
  return child;
}

FencedCommandBufferVK::~FencedCommandBufferVK() {
  if (!submitted_) {
    VALIDATION_LOG
        << "FencedCommandBufferVK is being destroyed without being submitted.";
  }
  device_.freeCommandBuffers(command_pool_, children_);
}

bool FencedCommandBufferVK::Submit() {
  if (submitted_) {
    VALIDATION_LOG << "Command buffer already submitted.";
    return false;
  }

  children_.push_back(command_buffer_);

  auto fence_res = device_.createFenceUnique(vk::FenceCreateInfo());
  if (fence_res.result != vk::Result::eSuccess) {
    VALIDATION_LOG << "Failed to create fence: "
                   << vk::to_string(fence_res.result);
    return false;
  }
  vk::UniqueFence fence = std::move(fence_res.value);

  vk::SubmitInfo submit_info;
  submit_info.setCommandBuffers(children_);
  auto res = queue_.submit(submit_info, *fence);
  if (res != vk::Result::eSuccess) {
    VALIDATION_LOG << "Failed to submit command buffer: " << vk::to_string(res);
    return false;
  }

  auto wait = device_.waitForFences(fence.get(), true, UINT64_MAX);
  if (wait != vk::Result::eSuccess) {
    VALIDATION_LOG << "Failed to wait for fence: " << vk::to_string(wait);
    return false;
  }

  // cleanup all the resources held by the command buffer and its children.
  deletion_queue_->Flush();

  submitted_ = true;
  return true;
}

DeletionQueueVK* FencedCommandBufferVK::GetDeletionQueue() const {
  return deletion_queue_.get();
}

}  // namespace impeller
