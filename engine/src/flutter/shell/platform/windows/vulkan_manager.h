// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_VULKAN_MANAGER_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_VULKAN_MANAGER_H_

#include <windows.h>

#include <array>
#include <cstdint>
#include <memory>
#include <string>
#include <unordered_set>
#include <vector>

#include "flutter/fml/macros.h"
#include "flutter/vulkan/procs/vulkan_proc_table.h"

namespace flutter {

/// Manages the Vulkan instance, device, and queue for Impeller rendering on
/// Windows.
///
/// This class only initializes Vulkan resources (instance, physical device,
/// logical device, queue) with the extensions required to import shared
/// Direct3D 11 textures as render targets. It creates no VkSurfaceKHR and
/// no swapchain: the shared textures are allocated and presented on the
/// DXGI/DirectComposition side (see |DCompPresenter| and
/// |VulkanImportedImage|).
///
/// Creating a VulkanManager fails and returns nullptr when Vulkan is not
/// usable for this path: no loader, no Vulkan 1.1 device, or no device that
/// can import Direct3D 11 textures. The engine falls back to ANGLE or
/// software rendering in that case.
class VulkanManager {
 public:
  /// Creates a VulkanManager. Returns nullptr if Vulkan is not available or
  /// no device supports Direct3D 11 texture import.
  static std::unique_ptr<VulkanManager> Create();

  ~VulkanManager();

  /// Returns true if a Vulkan runtime is present (vulkan-1.dll loadable).
  static bool IsAvailable();

  /// Returns the Vulkan API version supported by the instance.
  uint32_t GetVulkanVersion() const { return vulkan_version_; }

  /// Returns the Vulkan instance handle.
  VkInstance GetInstance() const { return instance_; }

  /// Returns the selected physical device.
  VkPhysicalDevice GetPhysicalDevice() const { return physical_device_; }

  /// Returns the logical device handle.
  VkDevice GetDevice() const { return device_; }

  /// Returns the graphics queue handle.
  ///
  /// Thread safety: all queue submissions in the Impeller rendering path are
  /// serialized through Impeller's QueueVK internal mutex. Do not submit
  /// directly to this queue outside that path.
  VkQueue GetQueue() const { return queue_; }

  /// Returns the queue family index used for graphics operations.
  uint32_t GetQueueFamilyIndex() const { return queue_family_index_; }

  /// Gets the Vulkan proc table used for function resolution.
  vulkan::VulkanProcTable* GetProcTable() const { return vk_.get(); }

  /// Gets enabled instance extension names. The pointer type matches
  /// FlutterVulkanRendererConfig::enabled_instance_extensions.
  const char** GetEnabledInstanceExtensions(size_t* count);

  /// Gets enabled device extension names. The pointer type matches
  /// FlutterVulkanRendererConfig::enabled_device_extensions.
  const char** GetEnabledDeviceExtensions(size_t* count);

  /// Resolves a Vulkan instance function pointer by name.
  void* GetInstanceProcAddress(VkInstance instance, const char* name) const;

  /// The locally unique identifier of the selected physical device's
  /// adapter. Used to open the same adapter on the DXGI side so that
  /// exported images stay on one GPU. Only valid when Create() succeeded.
  const std::array<uint8_t, VK_LUID_SIZE>& GetDeviceLUID() const {
    return device_luid_;
  }

 private:
  VulkanManager();

  bool Initialize();
  bool SelectPhysicalDevice();
  bool CreateLogicalDevice();

  /// Returns true if |device| can import shared Direct3D 11 textures
  /// (VK_EXTERNAL_MEMORY_HANDLE_TYPE_D3D11_TEXTURE_BIT) as B8G8R8A8 color
  /// attachments and reports a valid adapter LUID.
  bool SupportsD3D11Interop(VkPhysicalDevice device,
                            std::array<uint8_t, VK_LUID_SIZE>* out_luid) const;

  static std::unordered_set<std::string> BuildExtensionSet(
      const std::vector<VkExtensionProperties>& extensions);

  fml::RefPtr<vulkan::VulkanProcTable> vk_;
  uint32_t vulkan_version_ = VK_API_VERSION_1_0;
  VkInstance instance_ = VK_NULL_HANDLE;
  VkPhysicalDevice physical_device_ = VK_NULL_HANDLE;
  VkDevice device_ = VK_NULL_HANDLE;
  VkQueue queue_ = VK_NULL_HANDLE;
  uint32_t queue_family_index_ = 0;
  std::array<uint8_t, VK_LUID_SIZE> device_luid_ = {};

  std::vector<const char*> enabled_instance_extensions_;
  std::vector<const char*> enabled_device_extensions_;
  std::vector<const char*> enabled_layers_;
  std::unordered_set<std::string> available_instance_extensions_;
  std::unordered_set<std::string> available_device_extensions_;

  FML_DISALLOW_COPY_AND_ASSIGN(VulkanManager);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_VULKAN_MANAGER_H_
