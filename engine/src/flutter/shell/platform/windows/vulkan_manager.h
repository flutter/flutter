// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_VULKAN_MANAGER_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_VULKAN_MANAGER_H_

#include <windows.h>

#include <cstdint>
#include <memory>
#include <string>
#include <unordered_set>
#include <vector>

#include "flutter/fml/macros.h"
#include "flutter/vulkan/procs/vulkan_proc_table.h"

namespace flutter {

/// Manages Vulkan instance, device, and queue for Flutter rendering on Windows.
///
/// This class handles only Vulkan resource initialization (instance, physical
/// device, logical device, queue) and platform surface creation (VkSurfaceKHR
/// from HWND). All swapchain management, frame throttling, synchronization,
/// and resource lifecycle are handled by Impeller's KHR swapchain
/// implementation internally - identical to the Android Vulkan path.
///
/// Creating a VulkanManager may fail if Vulkan is not available on the system
/// (e.g. no vulkan-1.dll or no supported GPU). In that case, Create() returns
/// nullptr and the engine should fall back to ANGLE/OpenGL or software.
class VulkanManager {
 public:
  /// Creates a VulkanManager. Returns nullptr if Vulkan is not available.
  static std::unique_ptr<VulkanManager> Create();

  ~VulkanManager();

  /// Returns true if Vulkan runtime is present (vulkan-1.dll loadable).
  static bool IsAvailable();

  /// Returns the Vulkan API version supported by the device.
  uint32_t GetVulkanVersion() const { return vulkan_version_; }

  /// Returns the Vulkan instance handle.
  VkInstance GetInstance() const { return instance_; }

  /// Returns the selected physical device.
  VkPhysicalDevice GetPhysicalDevice() const { return physical_device_; }

  /// Returns the logical device handle.
  VkDevice GetDevice() const { return device_; }

  /// Returns the graphics queue handle.
  ///
  /// Thread safety: All queue submissions in the Impeller rendering path are
  /// serialized through Impeller's QueueVK internal mutex. Do not submit
  /// directly to this queue outside that path.
  VkQueue GetQueue() const { return queue_; }

  /// Returns the queue family index used for graphics operations.
  uint32_t GetQueueFamilyIndex() const { return queue_family_index_; }

  /// Gets the Vulkan proc table for function resolution.
  vulkan::VulkanProcTable* GetProcTable() const { return vk_.get(); }

  /// Gets enabled instance extension names.
  const char* const* GetEnabledInstanceExtensions(size_t* count) const;

  /// Gets enabled device extension names.
  const char* const* GetEnabledDeviceExtensions(size_t* count) const;

  /// Resolves a Vulkan instance function pointer by name.
  void* GetInstanceProcAddress(VkInstance instance, const char* name) const;

  /// Creates a VkSurfaceKHR for the given Win32 HWND.
  VkSurfaceKHR CreateWindowSurface(HWND hwnd);

  /// Destroys a previously created VkSurfaceKHR.
  void DestroyWindowSurface(VkSurfaceKHR surface);

  /// Creates and stores a VkSurfaceKHR for the given HWND.
  /// The surface is passed to Impeller via the embedder config and
  /// Impeller manages the KHR swapchain internally.
  bool InitializeSurface(HWND hwnd);

  /// Returns the VkSurfaceKHR, or VK_NULL_HANDLE if not initialized.
  VkSurfaceKHR GetSurface() const { return surface_; }

  /// Returns the VkSurfaceKHR and relinquishes ownership. After this
  /// call, the VulkanManager will no longer destroy the surface - the
  /// caller (Impeller) is responsible for its lifetime.
  VkSurfaceKHR ReleaseSurface() {
    VkSurfaceKHR s = surface_;
    surface_ = VK_NULL_HANDLE;
    return s;
  }

  /// Returns the HWND the surface is bound to, or nullptr.
  HWND GetSurfaceWindow() const { return surface_hwnd_; }

 private:
  VulkanManager();

  bool Initialize();
  bool SelectPhysicalDevice();
  bool CreateLogicalDevice();

  static std::unordered_set<std::string> BuildExtensionSet(
      const std::vector<VkExtensionProperties>& extensions);

  fml::RefPtr<vulkan::VulkanProcTable> vk_;

  VkInstance instance_ = VK_NULL_HANDLE;
  VkPhysicalDevice physical_device_ = VK_NULL_HANDLE;
  VkDevice device_ = VK_NULL_HANDLE;
  VkQueue queue_ = VK_NULL_HANDLE;
  uint32_t queue_family_index_ = UINT32_MAX;
  uint32_t vulkan_version_ = VK_API_VERSION_1_0;

  std::vector<const char*> enabled_instance_extensions_;
  std::vector<const char*> enabled_device_extensions_;
  std::vector<const char*> enabled_layers_;

  std::unordered_set<std::string> available_instance_extensions_;
  std::unordered_set<std::string> available_device_extensions_;

  // VkSurfaceKHR for the window - ownership is transferred to Impeller
  // via ReleaseSurface(). After that call, surface_ is VK_NULL_HANDLE
  // and the destructor will skip destroying it.
  VkSurfaceKHR surface_ = VK_NULL_HANDLE;
  HWND surface_hwnd_ = nullptr;

  FML_DISALLOW_COPY_AND_ASSIGN(VulkanManager);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_VULKAN_MANAGER_H_
