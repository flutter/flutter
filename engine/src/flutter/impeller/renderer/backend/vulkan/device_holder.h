// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "impeller/renderer/backend/vulkan/vk.h"

namespace impeller {

class DeviceHolder {
 public:
  virtual ~DeviceHolder() = default;
  virtual const vk::Device& GetDevice() const = 0;
  virtual const vk::PhysicalDevice& GetPhysicalDevice() const = 0;
};

}  // namespace impeller
