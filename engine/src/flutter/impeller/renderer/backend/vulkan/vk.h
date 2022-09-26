// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/logging.h"
#include "impeller/base/validation.h"

#define VK_NO_PROTOTYPES

#if !defined(NDEBUG)
#define VULKAN_HPP_ASSERT FML_CHECK
#else
#define VULKAN_HPP_ASSERT(ignored) \
  {}
#endif

#define VULKAN_HPP_NAMESPACE impeller::vk
#define VULKAN_HPP_ASSERT_ON_RESULT(ignored) \
  { [[maybe_unused]] auto res = (ignored); }
#define VULKAN_HPP_NO_EXCEPTIONS
#include "vulkan/vulkan.hpp"

static_assert(VK_HEADER_VERSION >= 215,
              "Vulkan headers are must not be too old.");

#ifdef VMA_STATIC_VULKAN_FUNCTIONS
#undef VMA_STATIC_VULKAN_FUNCTIONS
#endif  // VMA_STATIC_VULKAN_FUNCTIONS

#ifdef VMA_DYNAMIC_VULKAN_FUNCTIONS
#undef VMA_DYNAMIC_VULKAN_FUNCTIONS
#endif  // VMA_DYNAMIC_VULKAN_FUNCTIONS

#define VMA_STATIC_VULKAN_FUNCTIONS 0
#define VMA_DYNAMIC_VULKAN_FUNCTIONS 1
#include "vk_mem_alloc.h"

namespace impeller {

const uint32_t kMaxFramesInFlight = 2;

struct QueueVK {
  size_t family = 0;
  size_t index = 0;
};

}  // namespace impeller
