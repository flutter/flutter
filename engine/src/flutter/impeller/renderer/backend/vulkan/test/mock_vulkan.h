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

class MockVulkanContextBuilder {
 public:
  MockVulkanContextBuilder();

  //------------------------------------------------------------------------------
  /// @brief      Create a Vulkan context with Vulkan functions mocked. The
  ///             caller is given a chance to tinker on the settings right
  ///             before a context is created.
  ///
  /// @return     A context if one can be created.
  ///
  std::shared_ptr<ContextVK> Build();

  /// A callback that allows the modification of the ContextVK::Settings before
  /// the context is made.
  MockVulkanContextBuilder& SetSettingsCallback(
      const std::function<void(ContextVK::Settings&)>& settings_callback) {
    settings_callback_ = settings_callback;
    return *this;
  }

  MockVulkanContextBuilder& SetInstanceExtensions(
      const std::vector<std::string>& instance_extensions) {
    instance_extensions_ = instance_extensions;
    return *this;
  }

  MockVulkanContextBuilder& SetInstanceLayers(
      const std::vector<std::string>& instance_layers) {
    instance_layers_ = instance_layers;
    return *this;
  }

 private:
  std::function<void(ContextVK::Settings&)> settings_callback_;
  std::vector<std::string> instance_extensions_;
  std::vector<std::string> instance_layers_;
};

}  // namespace testing
}  // namespace impeller
