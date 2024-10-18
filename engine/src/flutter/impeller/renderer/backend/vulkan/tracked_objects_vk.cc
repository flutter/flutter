// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/tracked_objects_vk.h"

#include "impeller/renderer/backend/vulkan/gpu_tracer_vk.h"

namespace impeller {

TrackedObjectsVK::TrackedObjectsVK(
    const std::weak_ptr<const ContextVK>& context,
    const std::shared_ptr<CommandPoolVK>& pool,
    std::unique_ptr<GPUProbe> probe)
    : desc_pool_(context), probe_(std::move(probe)) {
  if (!pool) {
    return;
  }
  auto buffer = pool->CreateCommandBuffer();
  if (!buffer) {
    return;
  }
  pool_ = pool;
  buffer_ = std::move(buffer);
  is_valid_ = true;
}

TrackedObjectsVK::~TrackedObjectsVK() {
  if (!buffer_) {
    return;
  }
  pool_->CollectCommandBuffer(std::move(buffer_));
}

bool TrackedObjectsVK::IsValid() const {
  return is_valid_;
}

void TrackedObjectsVK::Track(std::shared_ptr<SharedObjectVK> object) {
  if (!object) {
    return;
  }
  tracked_objects_.insert(std::move(object));
}

void TrackedObjectsVK::Track(std::shared_ptr<const DeviceBuffer> buffer) {
  if (!buffer) {
    return;
  }
  tracked_buffers_.insert(std::move(buffer));
}

bool TrackedObjectsVK::IsTracking(
    const std::shared_ptr<const DeviceBuffer>& buffer) const {
  if (!buffer) {
    return false;
  }
  return tracked_buffers_.find(buffer) != tracked_buffers_.end();
}

void TrackedObjectsVK::Track(std::shared_ptr<const TextureSourceVK> texture) {
  if (!texture) {
    return;
  }
  tracked_textures_.insert(std::move(texture));
}

bool TrackedObjectsVK::IsTracking(
    const std::shared_ptr<const TextureSourceVK>& texture) const {
  if (!texture) {
    return false;
  }
  return tracked_textures_.find(texture) != tracked_textures_.end();
}

vk::CommandBuffer TrackedObjectsVK::GetCommandBuffer() const {
  return *buffer_;
}

DescriptorPoolVK& TrackedObjectsVK::GetDescriptorPool() {
  return desc_pool_;
}

GPUProbe& TrackedObjectsVK::GetGPUProbe() const {
  return *probe_.get();
}

}  // namespace impeller
