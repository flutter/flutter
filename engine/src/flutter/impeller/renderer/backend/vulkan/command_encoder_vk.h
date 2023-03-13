// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <optional>
#include <set>

#include "flutter/fml/macros.h"
#include "impeller/renderer/backend/vulkan/command_pool_vk.h"
#include "impeller/renderer/backend/vulkan/descriptor_pool_vk.h"
#include "impeller/renderer/backend/vulkan/shared_object_vk.h"
#include "impeller/renderer/backend/vulkan/vk.h"

namespace impeller {

class ContextVK;
class DeviceBuffer;
class Texture;
class TextureSourceVK;
class TrackedObjectsVK;
class FenceWaiterVK;

class CommandEncoderVK {
 public:
  ~CommandEncoderVK();

  bool IsValid() const;

  bool Submit();

  bool Track(std::shared_ptr<SharedObjectVK> object);

  bool Track(std::shared_ptr<const DeviceBuffer> buffer);

  bool Track(const std::shared_ptr<const Texture>& texture);

  bool Track(std::shared_ptr<const TextureSourceVK> texture);

  vk::CommandBuffer GetCommandBuffer() const;

  void PushDebugGroup(const char* label) const;

  void PopDebugGroup() const;

  void InsertDebugMarker(const char* label) const;

  std::optional<vk::DescriptorSet> AllocateDescriptorSet(
      const vk::DescriptorSetLayout& layout);

 private:
  friend class ContextVK;

  vk::Device device_ = {};
  vk::Queue queue_ = {};

  std::shared_ptr<FenceWaiterVK> fence_waiter_;
  std::shared_ptr<TrackedObjectsVK> tracked_objects_;
  bool is_valid_ = false;

  CommandEncoderVK(vk::Device device,
                   vk::Queue queue,
                   const std::shared_ptr<CommandPoolVK>& pool,
                   std::shared_ptr<FenceWaiterVK> fence_waiter);

  void Reset();

  FML_DISALLOW_COPY_AND_ASSIGN(CommandEncoderVK);
};

}  // namespace impeller
