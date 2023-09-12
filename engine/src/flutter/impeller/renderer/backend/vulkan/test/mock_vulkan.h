// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <functional>
#include <string>
#include <vector>

#include "impeller/renderer/backend/vulkan/context_vk.h"

namespace impeller {
namespace testing {

std::shared_ptr<std::vector<std::string>> GetMockVulkanFunctions(
    VkDevice device);

//------------------------------------------------------------------------------
/// @brief      Create a Vulkan context with Vulkan functions mocked. The caller
///             is given a chance to tinker on the settings right before a
///             context is created.
///
/// @param[in]  settings_callback  The settings callback
///
/// @return     A context if one can be created.
///
std::shared_ptr<ContextVK> CreateMockVulkanContext(
    const std::function<void(ContextVK::Settings&)>& settings_callback =
        nullptr);

}  // namespace testing
}  // namespace impeller
