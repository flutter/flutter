// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <cstdint>

#include "flutter/fml/macros.h"
#include "fml/status_or.h"
#include "impeller/renderer/backend/vulkan/device_holder.h"

namespace impeller {

//------------------------------------------------------------------------------
/// @brief      A short-lived fixed-sized descriptor pool. Descriptors
///             from this pool don't need to be freed individually. Instead, the
///             pool must be collected after all the descriptors allocated from
///             it are done being used.
///
///             The pool or it's descriptors may not be accessed from multiple
///             threads.
///
///             Encoders create pools as necessary as they have the same
///             threading and lifecycle restrictions.
class DescriptorPoolVK {
 public:
  explicit DescriptorPoolVK(
      const std::weak_ptr<const DeviceHolder>& device_holder);

  ~DescriptorPoolVK();

  fml::StatusOr<std::vector<vk::DescriptorSet>> AllocateDescriptorSets(
      uint32_t buffer_count,
      uint32_t sampler_count,
      const std::vector<vk::DescriptorSetLayout>& layouts);

 private:
  std::weak_ptr<const DeviceHolder> device_holder_;
  vk::UniqueDescriptorPool pool_ = {};

  DescriptorPoolVK(const DescriptorPoolVK&) = delete;

  DescriptorPoolVK& operator=(const DescriptorPoolVK&) = delete;
};

}  // namespace impeller
