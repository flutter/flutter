// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_COMMAND_ENCODER_VK_H_
#define FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_COMMAND_ENCODER_VK_H_

#include <cstdint>
#include <functional>
#include <optional>

#include "impeller/renderer/backend/vulkan/command_pool_vk.h"
#include "impeller/renderer/backend/vulkan/command_queue_vk.h"
#include "impeller/renderer/backend/vulkan/context_vk.h"
#include "impeller/renderer/backend/vulkan/descriptor_pool_vk.h"
#include "impeller/renderer/backend/vulkan/device_holder_vk.h"
#include "impeller/renderer/backend/vulkan/queue_vk.h"
#include "impeller/renderer/backend/vulkan/shared_object_vk.h"
#include "impeller/renderer/backend/vulkan/vk.h"

namespace impeller {

class ContextVK;
class DeviceBuffer;
class Buffer;
class Texture;
class TextureSourceVK;
class TrackedObjectsVK;
class FenceWaiterVK;
class GPUProbe;

class CommandEncoderFactoryVK {
 public:
  explicit CommandEncoderFactoryVK(
      const std::weak_ptr<const ContextVK>& context);

  std::shared_ptr<CommandEncoderVK> Create();

  void SetLabel(const std::string& label);

 private:
  std::weak_ptr<const ContextVK> context_;
  std::optional<std::string> label_;

  CommandEncoderFactoryVK(const CommandEncoderFactoryVK&) = delete;

  CommandEncoderFactoryVK& operator=(const CommandEncoderFactoryVK&) = delete;
};

class CommandEncoderVK {
 public:
  using SubmitCallback = std::function<void(bool)>;

  // Visible for testing.
  CommandEncoderVK(std::weak_ptr<const DeviceHolderVK> device_holder,
                   std::shared_ptr<TrackedObjectsVK> tracked_objects,
                   const std::shared_ptr<QueueVK>& queue,
                   std::shared_ptr<FenceWaiterVK> fence_waiter);

  ~CommandEncoderVK();

  bool IsValid() const;

  bool Track(std::shared_ptr<SharedObjectVK> object);

  bool Track(std::shared_ptr<const DeviceBuffer> buffer);

  bool IsTracking(const std::shared_ptr<const DeviceBuffer>& texture) const;

  bool Track(const std::shared_ptr<const Texture>& texture);

  bool IsTracking(const std::shared_ptr<const Texture>& texture) const;

  bool Track(std::shared_ptr<const TextureSourceVK> texture);

  vk::CommandBuffer GetCommandBuffer() const;

  void PushDebugGroup(std::string_view label) const;

  void PopDebugGroup() const;

  void InsertDebugMarker(std::string_view label) const;

  bool EndCommandBuffer() const;

  fml::StatusOr<vk::DescriptorSet> AllocateDescriptorSets(
      const vk::DescriptorSetLayout& layout,
      const ContextVK& context);

 private:
  friend class ContextVK;
  friend class CommandQueueVK;

  std::weak_ptr<const DeviceHolderVK> device_holder_;
  std::shared_ptr<TrackedObjectsVK> tracked_objects_;
  std::shared_ptr<QueueVK> queue_;
  const std::shared_ptr<FenceWaiterVK> fence_waiter_;
  std::shared_ptr<HostBuffer> host_buffer_;
  bool is_valid_ = true;

  void Reset();

  CommandEncoderVK(const CommandEncoderVK&) = delete;

  CommandEncoderVK& operator=(const CommandEncoderVK&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_COMMAND_ENCODER_VK_H_
