// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_VULKAN_VULKAN_DEVICE_H_
#define FLUTTER_VULKAN_VULKAN_DEVICE_H_

#include <vector>

#include "flutter/fml/compiler_specific.h"
#include "flutter/fml/macros.h"
#include "vulkan_handle.h"

namespace vulkan {

class VulkanProcTable;
class VulkanSurface;

class VulkanDevice {
 public:
  VulkanDevice(VulkanProcTable& vk,
               VulkanHandle<VkPhysicalDevice> physical_device,
               bool enable_validation_layers);

  ~VulkanDevice();

  bool IsValid() const;

  const VulkanHandle<VkDevice>& GetHandle() const;

  const VulkanHandle<VkPhysicalDevice>& GetPhysicalDeviceHandle() const;

  const VulkanHandle<VkQueue>& GetQueueHandle() const;

  const VulkanHandle<VkCommandPool>& GetCommandPool() const;

  uint32_t GetGraphicsQueueIndex() const;

  void ReleaseDeviceOwnership();

  [[nodiscard]] bool GetSurfaceCapabilities(
      const VulkanSurface& surface,
      VkSurfaceCapabilitiesKHR* capabilities) const;

  [[nodiscard]] bool GetPhysicalDeviceFeatures(
      VkPhysicalDeviceFeatures* features) const;

  [[nodiscard]] bool GetPhysicalDeviceFeaturesSkia(
      uint32_t* /* mask of GrVkFeatureFlags */ features) const;

  [[nodiscard]] int ChooseSurfaceFormat(const VulkanSurface& surface,
                                        std::vector<VkFormat> desired_formats,
                                        VkSurfaceFormatKHR* format) const;

  [[nodiscard]] bool ChoosePresentMode(const VulkanSurface& surface,
                                       VkPresentModeKHR* present_mode) const;

  [[nodiscard]] bool QueueSubmit(
      std::vector<VkPipelineStageFlags> wait_dest_pipeline_stages,
      const std::vector<VkSemaphore>& wait_semaphores,
      const std::vector<VkSemaphore>& signal_semaphores,
      const std::vector<VkCommandBuffer>& command_buffers,
      const VulkanHandle<VkFence>& fence) const;

  [[nodiscard]] bool WaitIdle() const;

 private:
  VulkanProcTable& vk;
  VulkanHandle<VkPhysicalDevice> physical_device_;
  VulkanHandle<VkDevice> device_;
  VulkanHandle<VkQueue> queue_;
  VulkanHandle<VkCommandPool> command_pool_;
  uint32_t graphics_queue_index_;
  bool valid_;
  bool enable_validation_layers_;

  std::vector<VkQueueFamilyProperties> GetQueueFamilyProperties() const;

  FML_DISALLOW_COPY_AND_ASSIGN(VulkanDevice);
};

}  // namespace vulkan

#endif  // FLUTTER_VULKAN_VULKAN_DEVICE_H_
