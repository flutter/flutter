// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <vector>

#include "flutter/fml/macros.h"
#include "impeller/renderer/backend/vulkan/shared_object_vk.h"
#include "impeller/renderer/backend/vulkan/vk.h"

namespace impeller {

class ContextVK;
class DeviceBuffer;
class Texture;

class CommandEncoderVK {
 public:
  ~CommandEncoderVK();

  bool IsValid() const;

  bool Submit();

  bool Track(std::shared_ptr<SharedObjectVK> object);

  bool Track(std::shared_ptr<const DeviceBuffer> buffer);

  bool Track(std::shared_ptr<const Texture> texture);

  const vk::CommandBuffer& GetCommandBuffer() const;

  void PushDebugGroup(const char* label) const;

  void PopDebugGroup() const;

 private:
  friend class ContextVK;

  vk::Device device_ = {};
  vk::Queue queue_ = {};
  vk::UniqueCommandBuffer command_buffer_;
  std::vector<std::shared_ptr<SharedObjectVK>> tracked_objects_;
  std::vector<std::shared_ptr<const DeviceBuffer>> tracked_buffers_;
  std::vector<std::shared_ptr<const Texture>> tracked_textures_;
  bool is_valid_ = false;

  CommandEncoderVK(vk::Device device, vk::Queue queue, vk::CommandPool pool);

  void Reset();

  FML_DISALLOW_COPY_AND_ASSIGN(CommandEncoderVK);
};

}  // namespace impeller
