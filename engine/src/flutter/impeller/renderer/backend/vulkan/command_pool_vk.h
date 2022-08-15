// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "impeller/renderer/backend/vulkan/vk.h"

namespace impeller {

class CommandPoolVK {
 public:
  static std::unique_ptr<CommandPoolVK> Create(vk::Device device,
                                               uint32_t queue_index);

  explicit CommandPoolVK(vk::UniqueCommandPool command_pool);

  ~CommandPoolVK();

  vk::CommandPool Get() const;

 private:
  vk::UniqueCommandPool command_pool_;

  FML_DISALLOW_COPY_AND_ASSIGN(CommandPoolVK);
};

}  // namespace impeller
