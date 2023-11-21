// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_VULKAN_VULKAN_APPLICATION_H_
#define FLUTTER_VULKAN_VULKAN_APPLICATION_H_

#include <memory>
#include <string>
#include <vector>

#include "flutter/fml/macros.h"
#include "flutter/vulkan/procs/vulkan_handle.h"
#include "vulkan_debug_report.h"

namespace vulkan {

static const size_t kGrCacheMaxByteSize = 512 * (1 << 20);

class VulkanDevice;
class VulkanProcTable;

/// Applications using Vulkan acquire a VulkanApplication that attempts to
/// create a VkInstance (with debug reporting optionally enabled).
class VulkanApplication {
 public:
  VulkanApplication(VulkanProcTable& vk,  // NOLINT
                    const std::string& application_name,
                    std::vector<std::string> enabled_extensions,
                    uint32_t application_version = VK_MAKE_VERSION(1, 0, 0),
                    uint32_t api_version = VK_MAKE_VERSION(1, 0, 0),
                    bool enable_validation_layers = false);

  ~VulkanApplication();

  bool IsValid() const;

  uint32_t GetAPIVersion() const;

  const VulkanHandle<VkInstance>& GetInstance() const;

  void ReleaseInstanceOwnership();

  std::unique_ptr<VulkanDevice> AcquireFirstCompatibleLogicalDevice() const;

 private:
  VulkanProcTable& vk_;
  VulkanHandle<VkInstance> instance_;
  uint32_t api_version_;
  std::unique_ptr<VulkanDebugReport> debug_report_;
  bool valid_;
  bool enable_validation_layers_;

  std::vector<VkPhysicalDevice> GetPhysicalDevices() const;
  std::vector<VkExtensionProperties> GetSupportedInstanceExtensions(
      const VulkanProcTable& vk) const;
  bool ExtensionSupported(
      const std::vector<VkExtensionProperties>& supported_extensions,
      const std::string& extension_name);

  FML_DISALLOW_COPY_AND_ASSIGN(VulkanApplication);
};

}  // namespace vulkan

#endif  // FLUTTER_VULKAN_VULKAN_APPLICATION_H_
