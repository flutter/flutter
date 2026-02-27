// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_LIMITS_VK_H_
#define FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_LIMITS_VK_H_

#include <stdint.h>

namespace impeller {

// Maximum size to use VMA image suballocation. Any allocation greater than or
// equal to this value will use a dedicated VkDeviceMemory.
//
// This value was taken from ANGLE.
constexpr size_t kImageSizeThresholdForDedicatedMemoryAllocation =
    4 * 1024 * 1024;

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_LIMITS_VK_H_
