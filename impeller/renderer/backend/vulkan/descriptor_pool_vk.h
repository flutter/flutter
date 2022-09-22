// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>

#include "flutter/fml/macros.h"
#include "impeller/renderer/backend/vulkan/vk.h"
#include "vulkan/vulkan_enums.hpp"
#include "vulkan/vulkan_handles.hpp"

namespace impeller {

class DescriptorPoolVK {
 public:
  explicit DescriptorPoolVK(vk::Device device);

  ~DescriptorPoolVK();

  vk::DescriptorPool GetPool();

 private:
  vk::UniqueDescriptorPool pool_;
  bool is_valid_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(DescriptorPoolVK);
};

}  // namespace impeller
