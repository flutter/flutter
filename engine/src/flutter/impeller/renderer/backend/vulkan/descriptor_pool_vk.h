// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <optional>
#include <queue>

#include "flutter/fml/macros.h"
#include "impeller/renderer/backend/vulkan/device_holder.h"
#include "impeller/renderer/backend/vulkan/vk.h"

namespace impeller {

//------------------------------------------------------------------------------
/// @brief      A short-lived dynamically-sized descriptor pool. Descriptors
///             from this pool don't need to be freed individually. Instead, the
///             pool must be collected after all the descriptors allocated from
///             it are done being used.
///
///             The pool or it's descriptors may not be accessed from multiple
///             threads.
///
///             Encoders create pools as necessary as they have the same
///             threading and lifecycle restrictions.
///
class DescriptorPoolVK {
 public:
  explicit DescriptorPoolVK(
      const std::weak_ptr<const DeviceHolder>& device_holder);

  ~DescriptorPoolVK();

  std::optional<vk::DescriptorSet> AllocateDescriptorSet(
      const vk::DescriptorSetLayout& layout);

 private:
  std::weak_ptr<const DeviceHolder> device_holder_;
  uint32_t pool_size_ = 31u;
  std::queue<vk::UniqueDescriptorPool> pools_;

  std::optional<vk::DescriptorPool> GetDescriptorPool();

  bool GrowPool();

  FML_DISALLOW_COPY_AND_ASSIGN(DescriptorPoolVK);
};

}  // namespace impeller
