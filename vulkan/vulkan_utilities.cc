// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/vulkan/vulkan_utilities.h"

#include <algorithm>
#include <unordered_set>

namespace vulkan {

bool IsDebuggingEnabled() {
#if OS_FUCHSIA
  return false;
#endif

#ifndef NDEBUG
  return true;
#else
  return false;
#endif
}

static std::vector<std::string> InstanceOrDeviceLayersToEnable(
    const VulkanProcTable& vk,
    VkPhysicalDevice physical_device) {
  if (!IsDebuggingEnabled()) {
    return {};
  }

  // NOTE: The loader is sensitive to the ordering here. Please do not rearrange
  // this list.
  const std::vector<std::string> candidates = {
      "VK_LAYER_GOOGLE_threading",      "VK_LAYER_LUNARG_parameter_validation",
      "VK_LAYER_LUNARG_object_tracker", "VK_LAYER_LUNARG_core_validation",
      "VK_LAYER_LUNARG_device_limits",  "VK_LAYER_LUNARG_image",
      "VK_LAYER_LUNARG_swapchain",      "VK_LAYER_GOOGLE_unique_objects"};

  uint32_t count = 0;

  if (physical_device == VK_NULL_HANDLE) {
    if (VK_CALL_LOG_ERROR(vk.EnumerateInstanceLayerProperties(
            &count, nullptr)) != VK_SUCCESS) {
      return {};
    }
  } else {
    if (VK_CALL_LOG_ERROR(vk.EnumerateDeviceLayerProperties(
            physical_device, &count, nullptr)) != VK_SUCCESS) {
      return {};
    }
  }

  std::vector<VkLayerProperties> properties;
  properties.resize(count);

  if (physical_device == VK_NULL_HANDLE) {
    if (VK_CALL_LOG_ERROR(vk.EnumerateInstanceLayerProperties(
            &count, properties.data())) != VK_SUCCESS) {
      return {};
    }
  } else {
    if (VK_CALL_LOG_ERROR(vk.EnumerateDeviceLayerProperties(
            physical_device, &count, properties.data())) != VK_SUCCESS) {
      return {};
    }
  }

  std::unordered_set<std::string> available_extensions;

  for (size_t i = 0; i < count; i++) {
    available_extensions.emplace(properties[i].layerName);
  }

  std::vector<std::string> available_candidates;

  for (const auto& candidate : candidates) {
    auto found = available_extensions.find(candidate);
    if (found != available_extensions.end()) {
      available_candidates.emplace_back(candidate);
    }
  }

  return available_candidates;
}

std::vector<std::string> InstanceLayersToEnable(const VulkanProcTable& vk) {
  return InstanceOrDeviceLayersToEnable(vk, VK_NULL_HANDLE);
}

std::vector<std::string> DeviceLayersToEnable(
    const VulkanProcTable& vk,
    const VulkanHandle<VkPhysicalDevice>& physical_device) {
  if (!physical_device) {
    return {};
  }

  return InstanceOrDeviceLayersToEnable(vk, physical_device);
}

}  // namespace vulkan
