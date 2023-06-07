// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <functional>
#include <optional>
#include <set>

#include "flutter/fml/macros.h"
#include "impeller/renderer/backend/vulkan/command_pool_vk.h"
#include "impeller/renderer/backend/vulkan/descriptor_pool_vk.h"
#include "impeller/renderer/backend/vulkan/device_holder.h"
#include "impeller/renderer/backend/vulkan/queue_vk.h"
#include "impeller/renderer/backend/vulkan/shared_object_vk.h"
#include "impeller/renderer/backend/vulkan/vk.h"

namespace impeller {

namespace testing {
class BlitCommandVkTest_BlitCopyTextureToTextureCommandVK_Test;
class BlitCommandVkTest_BlitCopyTextureToBufferCommandVK_Test;
class BlitCommandVkTest_BlitCopyBufferToTextureCommandVK_Test;
class BlitCommandVkTest_BlitGenerateMipmapCommandVK_Test;
}  // namespace testing

class ContextVK;
class DeviceBuffer;
class Buffer;
class Texture;
class TextureSourceVK;
class TrackedObjectsVK;
class FenceWaiterVK;

class CommandEncoderVK {
 public:
  using SubmitCallback = std::function<void(bool)>;

  ~CommandEncoderVK();

  bool IsValid() const;

  bool Submit(SubmitCallback callback = {});

  bool Track(std::shared_ptr<SharedObjectVK> object);

  bool Track(std::shared_ptr<const Buffer> buffer);

  bool IsTracking(const std::shared_ptr<const Buffer>& texture) const;

  bool Track(const std::shared_ptr<const Texture>& texture);

  bool IsTracking(const std::shared_ptr<const Texture>& texture) const;

  bool Track(std::shared_ptr<const TextureSourceVK> texture);

  vk::CommandBuffer GetCommandBuffer() const;

  void PushDebugGroup(const char* label) const;

  void PopDebugGroup() const;

  void InsertDebugMarker(const char* label) const;

  std::optional<vk::DescriptorSet> AllocateDescriptorSet(
      const vk::DescriptorSetLayout& layout);

 private:
  friend class ContextVK;
  friend class ::impeller::testing::
      BlitCommandVkTest_BlitCopyTextureToTextureCommandVK_Test;
  friend class ::impeller::testing::
      BlitCommandVkTest_BlitCopyTextureToBufferCommandVK_Test;
  friend class ::impeller::testing::
      BlitCommandVkTest_BlitGenerateMipmapCommandVK_Test;
  friend class ::impeller::testing::
      BlitCommandVkTest_BlitCopyBufferToTextureCommandVK_Test;

  std::weak_ptr<const DeviceHolder> device_holder_;
  std::shared_ptr<QueueVK> queue_;
  std::shared_ptr<FenceWaiterVK> fence_waiter_;
  std::shared_ptr<TrackedObjectsVK> tracked_objects_;
  bool is_valid_ = false;

  CommandEncoderVK(const std::weak_ptr<const DeviceHolder>& device_holder,
                   const std::shared_ptr<QueueVK>& queue,
                   const std::shared_ptr<CommandPoolVK>& pool,
                   std::shared_ptr<FenceWaiterVK> fence_waiter);

  void Reset();

  FML_DISALLOW_COPY_AND_ASSIGN(CommandEncoderVK);
};

}  // namespace impeller
