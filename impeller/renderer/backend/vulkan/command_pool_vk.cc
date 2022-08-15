// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/command_pool_vk.h"

namespace impeller {

std::unique_ptr<CommandPoolVK> CommandPoolVK::Create(vk::Device device,
                                                     uint32_t queue_index) {
  vk::CommandPoolCreateInfo create_info;
  create_info.setQueueFamilyIndex(queue_index);

  auto res = device.createCommandPoolUnique(create_info);
  if (res.result != vk::Result::eSuccess) {
    FML_CHECK(false) << "Failed to create command pool: "
                     << vk::to_string(res.result);
    return nullptr;
  }

  return std::make_unique<CommandPoolVK>(std::move(res.value));
}

vk::CommandPool CommandPoolVK::Get() const {
  return *command_pool_;
}

CommandPoolVK::CommandPoolVK(vk::UniqueCommandPool command_pool)
    : command_pool_(std::move(command_pool)) {}

CommandPoolVK::~CommandPoolVK() = default;

}  // namespace impeller
