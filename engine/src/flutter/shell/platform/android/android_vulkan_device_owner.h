// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_VULKAN_DEVICE_OWNER_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_VULKAN_DEVICE_OWNER_H_

#include <vulkan/vulkan.h>

#include <cstdint>
#include <functional>
#include <memory>
#include <string>
#include <vector>

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/android/vulkan_queue_guard/vulkan_queue_guard.h"

namespace flutter {

/// @brief Reference-counted owner of the Vulkan instance, physical device,
/// logical device, and graphics queue shared across an AndroidSurfaceManager
/// and any engines (primary or spawned within an engine group) bound to it.
///
/// Registers the instance, device, and queue with VulkanQueueGuard on
/// construction and executes the 4-step guarded teardown protocol in its
/// destructor after the last reference is released.
class VulkanDeviceOwner {
 public:
  using DestructionCallback = std::function<void()>;

  VulkanDeviceOwner(void* vulkan_lib_handle,
                    VkInstance instance,
                    VkPhysicalDevice physical_device,
                    VkDevice device,
                    VkQueue queue,
                    uint32_t graphics_queue_family_index,
                    uint32_t api_version,
                    std::vector<std::string> enabled_instance_extensions,
                    std::vector<std::string> enabled_device_extensions,
                    PFN_vkGetInstanceProcAddr raw_get_instance_proc_addr_fn,
                    PFN_vkDestroyDevice destroy_device_fn,
                    PFN_vkDestroyInstance destroy_instance_fn);

  ~VulkanDeviceOwner();

  VkInstance GetInstance() const { return instance_; }
  VkPhysicalDevice GetPhysicalDevice() const { return physical_device_; }
  VkDevice GetDevice() const { return device_; }
  VkQueue GetQueue() const { return queue_; }
  uint32_t GetGraphicsQueueFamilyIndex() const {
    return graphics_queue_family_index_;
  }
  uint32_t GetApiVersion() const { return api_version_; }

  const std::vector<std::string>& GetEnabledInstanceExtensions() const {
    return enabled_instance_extensions_;
  }
  const std::vector<std::string>& GetEnabledDeviceExtensions() const {
    return enabled_device_extensions_;
  }

  /// @brief Returns the raw unguarded PFN_vkGetInstanceProcAddr function
  /// pointer.
  PFN_vkGetInstanceProcAddr GetRawInstanceProcAddr() const {
    return raw_get_instance_proc_addr_fn_;
  }

  /// @brief Returns the guard-wrapped PFN_vkGetInstanceProcAddr trampoline.
  PFN_vkGetInstanceProcAddr GetGuardedInstanceProcAddr() const {
    return VulkanQueueGuard::GetInstanceProcAddrTrampoline();
  }

  /// @brief Resolves a function pointer through the guard trampoline.
  PFN_vkVoidFunction ResolveGuardedProc(const char* name) const {
    auto trampoline = VulkanQueueGuard::GetInstanceProcAddrTrampoline();
    return trampoline ? trampoline(instance_, name) : nullptr;
  }

  /// @brief Registers a callback invoked at the end of ~VulkanDeviceOwner() for
  /// lifetime verification in unit tests.
  void SetDestructionCallbackForTesting(DestructionCallback callback);

 private:
  void* vulkan_lib_handle_ = nullptr;
  VkInstance instance_ = VK_NULL_HANDLE;
  VkPhysicalDevice physical_device_ = VK_NULL_HANDLE;
  VkDevice device_ = VK_NULL_HANDLE;
  VkQueue queue_ = VK_NULL_HANDLE;
  uint32_t graphics_queue_family_index_ = 0;
  uint32_t api_version_ = VK_API_VERSION_1_1;
  std::vector<std::string> enabled_instance_extensions_;
  std::vector<std::string> enabled_device_extensions_;
  PFN_vkGetInstanceProcAddr raw_get_instance_proc_addr_fn_ = nullptr;
  PFN_vkDestroyDevice destroy_device_fn_ = nullptr;
  PFN_vkDestroyInstance destroy_instance_fn_ = nullptr;
  DestructionCallback destruction_callback_for_testing_;

  FML_DISALLOW_COPY_AND_ASSIGN(VulkanDeviceOwner);
};

namespace android {
using ::flutter::VulkanDeviceOwner;
}  // namespace android

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_VULKAN_DEVICE_OWNER_H_
