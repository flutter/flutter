// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "vulkan_window.h"

namespace vulkan {

VulkanWindow::VulkanWindow(std::unique_ptr<VulkanSurface> platform_surface)
    : valid_(false), platform_surface_(std::move(platform_surface)) {
  if (platform_surface_ == nullptr || !platform_surface_->IsValid()) {
    return;
  }

  if (!vk.IsValid()) {
    return;
  }

  if (!CreateInstance()) {
    return;
  }

  if (!CreateSurface()) {
    return;
  }

  if (!SelectPhysicalDevice()) {
    return;
  }

  if (!CreateLogicalDevice()) {
    return;
  }

  if (!CreateSwapChain()) {
    return;
  }

  if (!AcquireDeviceQueue()) {
    return;
  }

  if (!CreateCommandPool()) {
    return;
  }

  if (!SetupBuffers()) {
    return;
  }

  valid_ = true;
}

VulkanWindow::~VulkanWindow() = default;

bool VulkanWindow::IsValid() const {
  return valid_;
}

bool VulkanWindow::CreateInstance() {
  const VkApplicationInfo info = {
      .sType = VK_STRUCTURE_TYPE_APPLICATION_INFO,
      .pNext = nullptr,
      .pApplicationName = "FlutterEngine",
      .applicationVersion = VK_MAKE_VERSION(1, 0, 0),
      .pEngineName = "FlutterEngine",
      .engineVersion = VK_MAKE_VERSION(1, 0, 0),
      .apiVersion = VK_MAKE_VERSION(1, 0, 0),
  };

  const char* extensions[] = {
      VK_KHR_SURFACE_EXTENSION_NAME, platform_surface_->ExtensionName(),
  };

  const VkInstanceCreateInfo create_info = {
      .sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
      .pNext = nullptr,
      .flags = 0,
      .pApplicationInfo = &info,
      .enabledLayerCount = 0,
      .ppEnabledLayerNames = nullptr,
      .enabledExtensionCount = sizeof(extensions) / sizeof(const char*),
      .ppEnabledExtensionNames = extensions,
  };

  VkInstance instance = VK_NULL_HANDLE;
  if (vk.createInstance(&create_info, nullptr, &instance) != VK_SUCCESS) {
    return false;
  }

  instance_ = {instance,
               [this](VkInstance i) { vk.destroyInstance(i, nullptr); }};

  return true;
}

bool VulkanWindow::CreateSurface() {
  if (!instance_) {
    return false;
  }

  VkSurfaceKHR surface = platform_surface_->CreateSurfaceHandle(vk, instance_);

  if (surface == VK_NULL_HANDLE) {
    return false;
  }

  surface_ = {surface, [this](VkSurfaceKHR surface) {
                vk.destroySurfaceKHR(instance_, surface, nullptr);
              }};

  return true;
}

bool VulkanWindow::SelectPhysicalDevice() {
  if (instance_ == nullptr) {
    return false;
  }

  uint32_t device_count = 0;
  if (vk.enumeratePhysicalDevices(instance_, &device_count, nullptr) !=
      VK_SUCCESS) {
    return false;
  }

  if (device_count == 0) {
    // No available devices.
    return false;
  }

  VkPhysicalDevice devices[device_count];

  if (vk.enumeratePhysicalDevices(instance_, &device_count, devices) !=
      VK_SUCCESS) {
    return false;
  }

  // Pick the first one available.
  physical_device_ = {devices[0], {}};
  return true;
}

bool VulkanWindow::CreateLogicalDevice() {
  if (physical_device_ == nullptr) {
    return false;
  }

  float priorities[] = {1.0f};

  const VkDeviceQueueCreateInfo queue_create = {
      .sType = VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
      .pNext = nullptr,
      .flags = 0,
      .queueFamilyIndex = 0,
      .queueCount = 1,
      .pQueuePriorities = priorities,
  };

  const char* extensions[] = {
      VK_KHR_SWAPCHAIN_EXTENSION_NAME,
  };

  const VkDeviceCreateInfo create_info = {
      .sType = VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO,
      .pNext = nullptr,
      .flags = 0,
      .queueCreateInfoCount = 1,
      .pQueueCreateInfos = &queue_create,
      .enabledLayerCount = 0,
      .ppEnabledLayerNames = nullptr,
      .enabledExtensionCount = sizeof(extensions) / sizeof(const char*),
      .ppEnabledExtensionNames = extensions,
      .pEnabledFeatures = nullptr,
  };

  VkDevice device = VK_NULL_HANDLE;

  if (vk.createDevice(physical_device_, &create_info, nullptr, &device) !=
      VK_SUCCESS) {
    return false;
  }

  device_ = {device,
             [this](VkDevice device) { vk.destroyDevice(device, nullptr); }};

  return true;
}

bool VulkanWindow::AcquireDeviceQueue() {
  if (device_ == nullptr) {
    return false;
  }

  VkQueue queue = VK_NULL_HANDLE;
  vk.getDeviceQueue(device_, 0, 0, &queue);

  if (queue == VK_NULL_HANDLE) {
    return false;
  }

  queue_ = {queue, {}};

  return true;
}

std::pair<bool, VkSurfaceFormatKHR> VulkanWindow::ChooseSurfaceFormat() {
  if (!physical_device_ || !surface_) {
    return {false, {}};
  }

  uint32_t format_count = 0;
  if (vk.getPhysicalDeviceSurfaceFormatsKHR(
          physical_device_, surface_, &format_count, nullptr) != VK_SUCCESS) {
    return {false, {}};
  }

  if (format_count == 0) {
    return {false, {}};
  }

  VkSurfaceFormatKHR formats[format_count];
  if (vk.getPhysicalDeviceSurfaceFormatsKHR(
          physical_device_, surface_, &format_count, formats) != VK_SUCCESS) {
    return {false, {}};
  }

  for (uint32_t i = 0; i < format_count; i++) {
    if (formats[i].format == VK_FORMAT_R8G8B8A8_UNORM) {
      return {true, formats[i]};
    }
  }

  return {false, {}};
}

std::pair<bool, VkPresentModeKHR> VulkanWindow::ChoosePresentMode() {
  if (!physical_device_ || !surface_) {
    return {false, {}};
  }

  uint32_t modes_count = 0;

  if (vk.getPhysicalDeviceSurfacePresentModesKHR(
          physical_device_, surface_, &modes_count, nullptr) != VK_SUCCESS) {
    return {false, {}};
  }

  if (modes_count == 0) {
    return {false, {}};
  }

  VkPresentModeKHR modes[modes_count];

  if (vk.getPhysicalDeviceSurfacePresentModesKHR(
          physical_device_, surface_, &modes_count, modes) != VK_SUCCESS) {
    return {false, {}};
  }

  for (uint32_t i = 0; i < modes_count; i++) {
    if (modes[i] == VK_PRESENT_MODE_MAILBOX_KHR) {
      return {true, modes[i]};
    }
  }

  return {true, VK_PRESENT_MODE_FIFO_KHR};
}

bool VulkanWindow::CreateSwapChain() {
  if (!device_ || !surface_) {
    return false;
  }

  // Query Capabilities

  VkSurfaceCapabilitiesKHR capabilities = {0};
  if (vk.getPhysicalDeviceSurfaceCapabilitiesKHR(physical_device_, surface_,
                                                 &capabilities) != VK_SUCCESS) {
    return false;
  }

  // Query Format

  VkSurfaceFormatKHR format = {};
  bool query_result = false;

  std::tie(query_result, format) = ChooseSurfaceFormat();

  if (!query_result) {
    return false;
  }

  // Query Present Mode

  VkPresentModeKHR presentMode = VK_PRESENT_MODE_FIFO_KHR;
  std::tie(query_result, presentMode) = ChoosePresentMode();

  if (!query_result) {
    return false;
  }

  // Construct the Swapchain

  const VkSwapchainCreateInfoKHR create_info = {
      .sType = VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR,
      .pNext = nullptr,
      .flags = 0,
      .surface = surface_,
      .minImageCount = capabilities.minImageCount,
      .imageFormat = format.format,
      .imageColorSpace = format.colorSpace,
      .imageExtent = capabilities.currentExtent,
      .imageArrayLayers = 1,
      .imageUsage = VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT,
      .imageSharingMode = VK_SHARING_MODE_EXCLUSIVE,
      .queueFamilyIndexCount = 0,
      .pQueueFamilyIndices = nullptr,
      .preTransform = VK_SURFACE_TRANSFORM_IDENTITY_BIT_KHR,
      .compositeAlpha = VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR,
      .presentMode = presentMode,
      .clipped = VK_FALSE,
      .oldSwapchain = VK_NULL_HANDLE,
  };

  VkSwapchainKHR swapchain = VK_NULL_HANDLE;

  if (vk.createSwapchainKHR(device_, &create_info, nullptr, &swapchain) !=
      VK_SUCCESS) {
    return false;
  }

  swapchain_ = {swapchain, [this](VkSwapchainKHR swapchain) {
                  vk.destroySwapchainKHR(device_, swapchain, nullptr);
                }};

  return true;
}

bool VulkanWindow::SetupBuffers() {
  if (!device_ || !swapchain_) {
    return false;
  }

  uint32_t count = 0;
  if (vk.getSwapchainImagesKHR(device_, swapchain_, &count, nullptr) !=
      VK_SUCCESS) {
    return false;
  }

  if (count == 0) {
    return false;
  }

  VkImage images[count];

  if (vk.getSwapchainImagesKHR(device_, swapchain_, &count, images) !=
      VK_SUCCESS) {
    return false;
  }

  if (count == 0) {
    return false;
  }

  auto image_collector = [](VkImage image) {
    // We are only just getting references to images owned by the swapchain.
    // There is no ownership change.
  };

  backbuffers_.clear();

  for (uint32_t i = 0; i < count; i++) {
    std::unique_ptr<VulkanBackbuffer> backbuffer(new VulkanBackbuffer(
        vk, device_, command_pool_, {images[i], image_collector}));

    if (!backbuffer->IsValid()) {
      return false;
    }

    backbuffers_.emplace_back(std::move(backbuffer));
  }

  return true;
}

bool VulkanWindow::CreateCommandPool() {
  if (!device_) {
    return false;
  }

  const VkCommandPoolCreateInfo create_info = {
      .sType = VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO,
      .pNext = nullptr,
      .flags = VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT,
      .queueFamilyIndex = 0,
  };

  VkCommandPool command_pool = VK_NULL_HANDLE;
  if (vk.createCommandPool(device_, &create_info, nullptr, &command_pool) !=
      VK_SUCCESS) {
    return false;
  }

  command_pool_ = {command_pool, [this](VkCommandPool pool) {
                     vk.destroyCommandPool(device_, pool, nullptr);
                   }};
  return true;
}

}  // namespace vulkan
