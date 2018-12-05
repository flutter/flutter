// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/vulkan/vulkan_device.h"

#include <limits>
#include <map>
#include <vector>

#include "flutter/vulkan/vulkan_proc_table.h"
#include "flutter/vulkan/vulkan_surface.h"
#include "flutter/vulkan/vulkan_utilities.h"
#include "third_party/skia/include/gpu/vk/GrVkBackendContext.h"

namespace vulkan {

constexpr auto kVulkanInvalidGraphicsQueueIndex =
    std::numeric_limits<uint32_t>::max();

static uint32_t FindGraphicsQueueIndex(
    const std::vector<VkQueueFamilyProperties>& properties) {
  for (uint32_t i = 0, count = static_cast<uint32_t>(properties.size());
       i < count; i++) {
    if (properties[i].queueFlags & VK_QUEUE_GRAPHICS_BIT) {
      return i;
    }
  }
  return kVulkanInvalidGraphicsQueueIndex;
}

VulkanDevice::VulkanDevice(VulkanProcTable& p_vk,
                           VulkanHandle<VkPhysicalDevice> physical_device)
    : vk(p_vk),
      physical_device_(std::move(physical_device)),
      graphics_queue_index_(std::numeric_limits<uint32_t>::max()),
      valid_(false) {
  if (!physical_device_ || !vk.AreInstanceProcsSetup()) {
    return;
  }

  graphics_queue_index_ = FindGraphicsQueueIndex(GetQueueFamilyProperties());

  if (graphics_queue_index_ == kVulkanInvalidGraphicsQueueIndex) {
    FML_DLOG(INFO) << "Could not find the graphics queue index.";
    return;
  }

  const float priorities[1] = {1.0f};

  const VkDeviceQueueCreateInfo queue_create = {
      .sType = VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
      .pNext = nullptr,
      .flags = 0,
      .queueFamilyIndex = graphics_queue_index_,
      .queueCount = 1,
      .pQueuePriorities = priorities,
  };

  const char* extensions[] = {
#if OS_ANDROID
    VK_KHR_SWAPCHAIN_EXTENSION_NAME,
#endif
#if OS_FUCHSIA
    VK_KHR_EXTERNAL_MEMORY_EXTENSION_NAME,
    VK_KHR_EXTERNAL_MEMORY_FUCHSIA_EXTENSION_NAME,
    VK_KHR_EXTERNAL_SEMAPHORE_EXTENSION_NAME,
    VK_KHR_EXTERNAL_SEMAPHORE_FUCHSIA_EXTENSION_NAME,
#endif
  };

  auto enabled_layers = DeviceLayersToEnable(vk, physical_device_);

  const char* layers[enabled_layers.size()];

  for (size_t i = 0; i < enabled_layers.size(); i++) {
    layers[i] = enabled_layers[i].c_str();
  }

  const VkDeviceCreateInfo create_info = {
      .sType = VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO,
      .pNext = nullptr,
      .flags = 0,
      .queueCreateInfoCount = 1,
      .pQueueCreateInfos = &queue_create,
      .enabledLayerCount = static_cast<uint32_t>(enabled_layers.size()),
      .ppEnabledLayerNames = layers,
      .enabledExtensionCount = sizeof(extensions) / sizeof(const char*),
      .ppEnabledExtensionNames = extensions,
      .pEnabledFeatures = nullptr,
  };

  VkDevice device = VK_NULL_HANDLE;

  if (VK_CALL_LOG_ERROR(vk.CreateDevice(physical_device_, &create_info, nullptr,
                                        &device)) != VK_SUCCESS) {
    FML_DLOG(INFO) << "Could not create device.";
    return;
  }

  device_ = {device,
             [this](VkDevice device) { vk.DestroyDevice(device, nullptr); }};

  if (!vk.SetupDeviceProcAddresses(device_)) {
    FML_DLOG(INFO) << "Could not setup device proc addresses.";
    return;
  }

  VkQueue queue = VK_NULL_HANDLE;

  vk.GetDeviceQueue(device_, graphics_queue_index_, 0, &queue);

  if (queue == VK_NULL_HANDLE) {
    FML_DLOG(INFO) << "Could not get the device queue handle.";
    return;
  }

  queue_ = queue;

  const VkCommandPoolCreateInfo command_pool_create_info = {
      .sType = VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO,
      .pNext = nullptr,
      .flags = VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT,
      .queueFamilyIndex = 0,
  };

  VkCommandPool command_pool = VK_NULL_HANDLE;
  if (VK_CALL_LOG_ERROR(vk.CreateCommandPool(device_, &command_pool_create_info,
                                             nullptr, &command_pool)) !=
      VK_SUCCESS) {
    FML_DLOG(INFO) << "Could not create the command pool.";
    return;
  }

  command_pool_ = {command_pool, [this](VkCommandPool pool) {
                     vk.DestroyCommandPool(device_, pool, nullptr);
                   }};

  valid_ = true;
}

VulkanDevice::~VulkanDevice() {
  FML_ALLOW_UNUSED_LOCAL(WaitIdle());
}

bool VulkanDevice::IsValid() const {
  return valid_;
}

bool VulkanDevice::WaitIdle() const {
  return VK_CALL_LOG_ERROR(vk.DeviceWaitIdle(device_)) == VK_SUCCESS;
}

const VulkanHandle<VkDevice>& VulkanDevice::GetHandle() const {
  return device_;
}

void VulkanDevice::ReleaseDeviceOwnership() {
  device_.ReleaseOwnership();
}

const VulkanHandle<VkPhysicalDevice>& VulkanDevice::GetPhysicalDeviceHandle()
    const {
  return physical_device_;
}

const VulkanHandle<VkQueue>& VulkanDevice::GetQueueHandle() const {
  return queue_;
}

const VulkanHandle<VkCommandPool>& VulkanDevice::GetCommandPool() const {
  return command_pool_;
}

uint32_t VulkanDevice::GetGraphicsQueueIndex() const {
  return graphics_queue_index_;
}

bool VulkanDevice::GetSurfaceCapabilities(
    const VulkanSurface& surface,
    VkSurfaceCapabilitiesKHR* capabilities) const {
#if OS_ANDROID
  if (!surface.IsValid() || capabilities == nullptr) {
    return false;
  }

  bool success =
      VK_CALL_LOG_ERROR(vk.GetPhysicalDeviceSurfaceCapabilitiesKHR(
          physical_device_, surface.Handle(), capabilities)) == VK_SUCCESS;

  if (!success) {
    return false;
  }

  // Check if the physical device surface capabilities are valid. If so, there
  // is nothing more to do.
  if (capabilities->currentExtent.width != 0xFFFFFFFF &&
      capabilities->currentExtent.height != 0xFFFFFFFF) {
    return true;
  }

  // Ask the native surface for its size as a fallback.
  SkISize size = surface.GetSize();

  if (size.width() == 0 || size.height() == 0) {
    return false;
  }

  capabilities->currentExtent.width = size.width();
  capabilities->currentExtent.height = size.height();
  return true;
#else
  return false;
#endif
}

bool VulkanDevice::GetPhysicalDeviceFeatures(
    VkPhysicalDeviceFeatures* features) const {
  if (features == nullptr || !physical_device_) {
    return false;
  }
  vk.GetPhysicalDeviceFeatures(physical_device_, features);
  return true;
}

bool VulkanDevice::GetPhysicalDeviceFeaturesSkia(uint32_t* sk_features) const {
  if (sk_features == nullptr) {
    return false;
  }

  VkPhysicalDeviceFeatures features;

  if (!GetPhysicalDeviceFeatures(&features)) {
    return false;
  }

  uint32_t flags = 0;

  if (features.geometryShader) {
    flags |= kGeometryShader_GrVkFeatureFlag;
  }
  if (features.dualSrcBlend) {
    flags |= kDualSrcBlend_GrVkFeatureFlag;
  }
  if (features.sampleRateShading) {
    flags |= kSampleRateShading_GrVkFeatureFlag;
  }

  *sk_features = flags;
  return true;
}

std::vector<VkQueueFamilyProperties> VulkanDevice::GetQueueFamilyProperties()
    const {
  uint32_t count = 0;

  vk.GetPhysicalDeviceQueueFamilyProperties(physical_device_, &count, nullptr);

  std::vector<VkQueueFamilyProperties> properties;
  properties.resize(count, {});

  vk.GetPhysicalDeviceQueueFamilyProperties(physical_device_, &count,
                                            properties.data());

  return properties;
}

int VulkanDevice::ChooseSurfaceFormat(const VulkanSurface& surface,
                                      std::vector<VkFormat> desired_formats,
                                      VkSurfaceFormatKHR* format) const {
#if OS_ANDROID
  if (!surface.IsValid() || format == nullptr) {
    return -1;
  }

  uint32_t format_count = 0;
  if (VK_CALL_LOG_ERROR(vk.GetPhysicalDeviceSurfaceFormatsKHR(
          physical_device_, surface.Handle(), &format_count, nullptr)) !=
      VK_SUCCESS) {
    return -1;
  }

  if (format_count == 0) {
    return -1;
  }

  VkSurfaceFormatKHR formats[format_count];
  if (VK_CALL_LOG_ERROR(vk.GetPhysicalDeviceSurfaceFormatsKHR(
          physical_device_, surface.Handle(), &format_count, formats)) !=
      VK_SUCCESS) {
    return -1;
  }

  std::map<VkFormat, VkSurfaceFormatKHR> supported_formats;
  for (uint32_t i = 0; i < format_count; i++) {
    supported_formats[formats[i].format] = formats[i];
  }

  // Try to find the first supported format in the list of desired formats.
  for (size_t i = 0; i < desired_formats.size(); ++i) {
    auto found = supported_formats.find(desired_formats[i]);
    if (found != supported_formats.end()) {
      *format = found->second;
      return static_cast<int>(i);
    }
  }
#endif
  return -1;
}

bool VulkanDevice::ChoosePresentMode(const VulkanSurface& surface,
                                     VkPresentModeKHR* present_mode) const {
  if (!surface.IsValid() || present_mode == nullptr) {
    return false;
  }

  // https://github.com/LunarG/VulkanSamples/issues/98 indicates that
  // VK_PRESENT_MODE_FIFO_KHR is preferable on mobile platforms. The problems
  // mentioned in the ticket w.r.t the application being faster that the refresh
  // rate of the screen should not be faced by any Flutter platforms as they are
  // powered by Vsync pulses instead of depending the the submit to block.
  // However, for platforms that don't have VSync providers setup, it is better
  // to fall back to FIFO. For platforms that do have VSync providers, there
  // should be little difference. In case there is a need for a mode other than
  // FIFO, availability checks must be performed here before returning the
  // result. FIFO is always present.
  *present_mode = VK_PRESENT_MODE_FIFO_KHR;
  return true;
}

bool VulkanDevice::QueueSubmit(
    std::vector<VkPipelineStageFlags> wait_dest_pipeline_stages,
    const std::vector<VkSemaphore>& wait_semaphores,
    const std::vector<VkSemaphore>& signal_semaphores,
    const std::vector<VkCommandBuffer>& command_buffers,
    const VulkanHandle<VkFence>& fence) const {
  if (wait_semaphores.size() != wait_dest_pipeline_stages.size()) {
    return false;
  }

  const VkSubmitInfo submit_info = {
      .sType = VK_STRUCTURE_TYPE_SUBMIT_INFO,
      .pNext = nullptr,
      .waitSemaphoreCount = static_cast<uint32_t>(wait_semaphores.size()),
      .pWaitSemaphores = wait_semaphores.data(),
      .pWaitDstStageMask = wait_dest_pipeline_stages.data(),
      .commandBufferCount = static_cast<uint32_t>(command_buffers.size()),
      .pCommandBuffers = command_buffers.data(),
      .signalSemaphoreCount = static_cast<uint32_t>(signal_semaphores.size()),
      .pSignalSemaphores = signal_semaphores.data(),
  };

  if (VK_CALL_LOG_ERROR(vk.QueueSubmit(queue_, 1, &submit_info, fence)) !=
      VK_SUCCESS) {
    return false;
  }

  return true;
}

}  // namespace vulkan
