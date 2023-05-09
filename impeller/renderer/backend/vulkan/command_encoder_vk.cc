// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/command_encoder_vk.h"

#include "flutter/fml/closure.h"
#include "flutter/fml/trace_event.h"
#include "impeller/renderer/backend/vulkan/context_vk.h"
#include "impeller/renderer/backend/vulkan/fence_waiter_vk.h"
#include "impeller/renderer/backend/vulkan/texture_vk.h"

namespace impeller {

class TrackedObjectsVK {
 public:
  explicit TrackedObjectsVK(std::weak_ptr<const DeviceHolder> device_holder,
                            const std::shared_ptr<CommandPoolVK>& pool)
      : desc_pool_(device_holder) {
    if (!pool) {
      return;
    }
    auto buffer = pool->CreateGraphicsCommandBuffer();
    if (!buffer) {
      return;
    }
    pool_ = pool;
    buffer_ = std::move(buffer);
    is_valid_ = true;
  }

  ~TrackedObjectsVK() {
    if (!buffer_) {
      return;
    }
    auto pool = pool_.lock();
    if (!pool) {
      VALIDATION_LOG
          << "Command pool died before a command buffer could be recycled.";
      // The buffer can not be freed if its command pool has been destroyed.
      buffer_.release();
      return;
    }
    pool->CollectGraphicsCommandBuffer(std::move(buffer_));
  }

  bool IsValid() const { return is_valid_; }

  void Track(std::shared_ptr<SharedObjectVK> object) {
    if (!object) {
      return;
    }
    tracked_objects_.insert(std::move(object));
  }

  void Track(std::shared_ptr<const DeviceBuffer> buffer) {
    if (!buffer) {
      return;
    }
    tracked_buffers_.insert(std::move(buffer));
  }

  bool IsTracking(const std::shared_ptr<const DeviceBuffer>& buffer) const {
    if (!buffer) {
      return false;
    }
    return tracked_buffers_.find(buffer) != tracked_buffers_.end();
  }

  void Track(std::shared_ptr<const TextureSourceVK> texture) {
    if (!texture) {
      return;
    }
    tracked_textures_.insert(std::move(texture));
  }

  bool IsTracking(const std::shared_ptr<const TextureSourceVK>& texture) const {
    if (!texture) {
      return false;
    }
    return tracked_textures_.find(texture) != tracked_textures_.end();
  }

  vk::CommandBuffer GetCommandBuffer() const { return *buffer_; }

  DescriptorPoolVK& GetDescriptorPool() { return desc_pool_; }

 private:
  DescriptorPoolVK desc_pool_;
  std::weak_ptr<CommandPoolVK> pool_;
  vk::UniqueCommandBuffer buffer_;
  std::set<std::shared_ptr<SharedObjectVK>> tracked_objects_;
  std::set<std::shared_ptr<const DeviceBuffer>> tracked_buffers_;
  std::set<std::shared_ptr<const TextureSourceVK>> tracked_textures_;
  bool is_valid_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(TrackedObjectsVK);
};

CommandEncoderVK::CommandEncoderVK(
    std::weak_ptr<const DeviceHolder> device_holder,
    const std::shared_ptr<QueueVK>& queue,
    const std::shared_ptr<CommandPoolVK>& pool,
    std::shared_ptr<FenceWaiterVK> fence_waiter)
    : fence_waiter_(std::move(fence_waiter)),
      tracked_objects_(
          std::make_shared<TrackedObjectsVK>(device_holder, pool)) {
  if (!fence_waiter_ || !tracked_objects_->IsValid() || !queue) {
    return;
  }
  vk::CommandBufferBeginInfo begin_info;
  begin_info.flags = vk::CommandBufferUsageFlagBits::eOneTimeSubmit;
  if (tracked_objects_->GetCommandBuffer().begin(begin_info) !=
      vk::Result::eSuccess) {
    VALIDATION_LOG << "Could not begin command buffer.";
    return;
  }
  device_holder_ = device_holder;
  queue_ = queue;
  is_valid_ = true;
}

CommandEncoderVK::~CommandEncoderVK() = default;

bool CommandEncoderVK::IsValid() const {
  return is_valid_;
}

bool CommandEncoderVK::Submit() {
  if (!IsValid()) {
    return false;
  }

  // Success or failure, you only get to submit once.
  fml::ScopedCleanupClosure reset([&]() { Reset(); });

  InsertDebugMarker("QueueSubmit");

  auto command_buffer = GetCommandBuffer();

  if (command_buffer.end() != vk::Result::eSuccess) {
    return false;
  }
  std::shared_ptr<const DeviceHolder> strong_device = device_holder_.lock();
  if (!strong_device) {
    return false;
  }
  auto [fence_result, fence] = strong_device->GetDevice().createFenceUnique({});
  if (fence_result != vk::Result::eSuccess) {
    return false;
  }

  vk::SubmitInfo submit_info;
  std::vector<vk::CommandBuffer> buffers = {command_buffer};
  submit_info.setCommandBuffers(buffers);
  if (queue_->Submit(submit_info, *fence) != vk::Result::eSuccess) {
    return false;
  }

  return fence_waiter_->AddFence(
      std::move(fence), [tracked_objects = std::move(tracked_objects_)] {
        // Nothing to do, we just drop the tracked objects on the floor.
      });
}

vk::CommandBuffer CommandEncoderVK::GetCommandBuffer() const {
  if (tracked_objects_) {
    return tracked_objects_->GetCommandBuffer();
  }
  return {};
}

void CommandEncoderVK::Reset() {
  tracked_objects_.reset();

  queue_ = nullptr;
  device_holder_ = {};
  is_valid_ = false;
}

bool CommandEncoderVK::Track(std::shared_ptr<SharedObjectVK> object) {
  if (!IsValid()) {
    return false;
  }
  tracked_objects_->Track(std::move(object));
  return true;
}

bool CommandEncoderVK::Track(std::shared_ptr<const DeviceBuffer> buffer) {
  if (!IsValid()) {
    return false;
  }
  tracked_objects_->Track(std::move(buffer));
  return true;
}

bool CommandEncoderVK::IsTracking(
    const std::shared_ptr<const DeviceBuffer>& buffer) const {
  if (!IsValid()) {
    return false;
  }
  return tracked_objects_->IsTracking(buffer);
}

bool CommandEncoderVK::Track(std::shared_ptr<const TextureSourceVK> texture) {
  if (!IsValid()) {
    return false;
  }
  tracked_objects_->Track(std::move(texture));
  return true;
}

bool CommandEncoderVK::Track(const std::shared_ptr<const Texture>& texture) {
  if (!IsValid()) {
    return false;
  }
  if (!texture) {
    return true;
  }
  return Track(TextureVK::Cast(*texture).GetTextureSource());
}

bool CommandEncoderVK::IsTracking(
    const std::shared_ptr<const Texture>& texture) const {
  if (!IsValid()) {
    return false;
  }
  std::shared_ptr<const TextureSourceVK> source =
      TextureVK::Cast(*texture).GetTextureSource();
  return tracked_objects_->IsTracking(source);
}

std::optional<vk::DescriptorSet> CommandEncoderVK::AllocateDescriptorSet(
    const vk::DescriptorSetLayout& layout) {
  if (!IsValid()) {
    return std::nullopt;
  }
  return tracked_objects_->GetDescriptorPool().AllocateDescriptorSet(layout);
}

void CommandEncoderVK::PushDebugGroup(const char* label) const {
  if (!HasValidationLayers()) {
    return;
  }
  vk::DebugUtilsLabelEXT label_info;
  label_info.pLabelName = label;
  if (auto command_buffer = GetCommandBuffer()) {
    command_buffer.beginDebugUtilsLabelEXT(label_info);
  }
}

void CommandEncoderVK::PopDebugGroup() const {
  if (!HasValidationLayers()) {
    return;
  }
  if (auto command_buffer = GetCommandBuffer()) {
    command_buffer.endDebugUtilsLabelEXT();
  }
}

void CommandEncoderVK::InsertDebugMarker(const char* label) const {
  if (!HasValidationLayers()) {
    return;
  }
  vk::DebugUtilsLabelEXT label_info;
  label_info.pLabelName = label;
  if (auto command_buffer = GetCommandBuffer()) {
    command_buffer.insertDebugUtilsLabelEXT(label_info);
  }
  if (queue_) {
    queue_->InsertDebugMarker(label);
  }
}

}  // namespace impeller
