// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "vulkan_application.h"

#include <utility>
#include <vector>

#include "vulkan_device.h"
#include "vulkan_proc_table.h"
#include "vulkan_utilities.h"

namespace vulkan {

VulkanApplication::VulkanApplication(
    VulkanProcTable& p_vk,  // NOLINT
    const std::string& application_name,
    std::vector<std::string> enabled_extensions,
    uint32_t application_version,
    uint32_t api_version,
    bool enable_validation_layers)
    : vk(p_vk),
      api_version_(api_version),
      valid_(false),
      enable_validation_layers_(enable_validation_layers) {
  // Check if we want to enable debugging.
  std::vector<VkExtensionProperties> supported_extensions =
      GetSupportedInstanceExtensions(vk);
  bool enable_instance_debugging =
      enable_validation_layers_ &&
      ExtensionSupported(supported_extensions,
                         VulkanDebugReport::DebugExtensionName());

  // Configure extensions.

  if (enable_instance_debugging) {
    enabled_extensions.emplace_back(VulkanDebugReport::DebugExtensionName());
  }
#if OS_FUCHSIA
  if (ExtensionSupported(supported_extensions,
                         VK_KHR_EXTERNAL_MEMORY_CAPABILITIES_EXTENSION_NAME)) {
    // VK_KHR_get_physical_device_properties2 is a dependency of the memory
    // capabilities extension, so the validation layers require that it be
    // enabled.
    enabled_extensions.emplace_back(
        VK_KHR_GET_PHYSICAL_DEVICE_PROPERTIES_2_EXTENSION_NAME);
    enabled_extensions.emplace_back(
        VK_KHR_EXTERNAL_MEMORY_CAPABILITIES_EXTENSION_NAME);
  }
#endif

  const char* extensions[enabled_extensions.size()];

  for (size_t i = 0; i < enabled_extensions.size(); i++) {
    extensions[i] = enabled_extensions[i].c_str();
  }

  // Configure layers.

  const std::vector<std::string> enabled_layers =
      InstanceLayersToEnable(vk, enable_validation_layers_);

  const char* layers[enabled_layers.size()];

  for (size_t i = 0; i < enabled_layers.size(); i++) {
    layers[i] = enabled_layers[i].c_str();
  }

  // Configure init structs.

  const VkApplicationInfo info = {
      .sType = VK_STRUCTURE_TYPE_APPLICATION_INFO,
      .pNext = nullptr,
      .pApplicationName = application_name.c_str(),
      .applicationVersion = application_version,
      .pEngineName = "FlutterEngine",
      .engineVersion = VK_MAKE_VERSION(1, 0, 0),
      .apiVersion = api_version_,
  };

  const VkInstanceCreateInfo create_info = {
      .sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
      .pNext = nullptr,
      .flags = 0,
      .pApplicationInfo = &info,
      .enabledLayerCount = static_cast<uint32_t>(enabled_layers.size()),
      .ppEnabledLayerNames = layers,
      .enabledExtensionCount = static_cast<uint32_t>(enabled_extensions.size()),
      .ppEnabledExtensionNames = extensions,
  };

  // Perform initialization.

  VkInstance instance = VK_NULL_HANDLE;

  if (VK_CALL_LOG_ERROR(vk.CreateInstance(&create_info, nullptr, &instance)) !=
      VK_SUCCESS) {
    FML_DLOG(INFO) << "Could not create application instance.";
    return;
  }

  // Now that we have an instance, setup instance proc table entries.
  if (!vk.SetupInstanceProcAddresses(instance)) {
    FML_DLOG(INFO) << "Could not setup instance proc addresses.";
    return;
  }

  instance_ = {instance, [this](VkInstance i) {
                 FML_DLOG(INFO) << "Destroying Vulkan instance";
                 vk.DestroyInstance(i, nullptr);
               }};

  if (enable_instance_debugging) {
    auto debug_report = std::make_unique<VulkanDebugReport>(vk, instance_);
    if (!debug_report->IsValid()) {
      FML_DLOG(INFO) << "Vulkan debugging was enabled but could not be setup "
                        "for this instance.";
    } else {
      debug_report_ = std::move(debug_report);
      FML_DLOG(INFO) << "Debug reporting is enabled.";
    }
  }

  valid_ = true;
}

VulkanApplication::~VulkanApplication() = default;

bool VulkanApplication::IsValid() const {
  return valid_;
}

uint32_t VulkanApplication::GetAPIVersion() const {
  return api_version_;
}

const VulkanHandle<VkInstance>& VulkanApplication::GetInstance() const {
  return instance_;
}

void VulkanApplication::ReleaseInstanceOwnership() {
  instance_.ReleaseOwnership();
}

std::vector<VkPhysicalDevice> VulkanApplication::GetPhysicalDevices() const {
  if (!IsValid()) {
    return {};
  }

  uint32_t device_count = 0;
  if (VK_CALL_LOG_ERROR(vk.EnumeratePhysicalDevices(instance_, &device_count,
                                                    nullptr)) != VK_SUCCESS) {
    FML_DLOG(INFO) << "Could not enumerate physical device.";
    return {};
  }

  if (device_count == 0) {
    // No available devices.
    FML_DLOG(INFO) << "No physical devices found.";
    return {};
  }

  std::vector<VkPhysicalDevice> physical_devices;

  physical_devices.resize(device_count);

  if (VK_CALL_LOG_ERROR(vk.EnumeratePhysicalDevices(
          instance_, &device_count, physical_devices.data())) != VK_SUCCESS) {
    FML_DLOG(INFO) << "Could not enumerate physical device.";
    return {};
  }

  return physical_devices;
}

std::unique_ptr<VulkanDevice>
VulkanApplication::AcquireFirstCompatibleLogicalDevice() const {
  for (auto device_handle : GetPhysicalDevices()) {
    auto logical_device = std::make_unique<VulkanDevice>(
        vk, device_handle, enable_validation_layers_);
    if (logical_device->IsValid()) {
      return logical_device;
    }
  }
  FML_DLOG(INFO) << "Could not acquire compatible logical device.";
  return nullptr;
}

std::vector<VkExtensionProperties>
VulkanApplication::GetSupportedInstanceExtensions(
    const VulkanProcTable& vk) const {
  if (!vk.EnumerateInstanceExtensionProperties) {
    return std::vector<VkExtensionProperties>();
  }

  uint32_t count = 0;
  if (VK_CALL_LOG_ERROR(vk.EnumerateInstanceExtensionProperties(
          nullptr, &count, nullptr)) != VK_SUCCESS) {
    return std::vector<VkExtensionProperties>();
  }

  if (count == 0) {
    return std::vector<VkExtensionProperties>();
  }

  std::vector<VkExtensionProperties> properties;
  properties.resize(count);
  if (VK_CALL_LOG_ERROR(vk.EnumerateInstanceExtensionProperties(
          nullptr, &count, properties.data())) != VK_SUCCESS) {
    return std::vector<VkExtensionProperties>();
  }

  return properties;
}

bool VulkanApplication::ExtensionSupported(
    const std::vector<VkExtensionProperties>& supported_instance_extensions,
    std::string extension_name) {
  uint32_t count = supported_instance_extensions.size();
  for (size_t i = 0; i < count; i++) {
    if (strncmp(supported_instance_extensions[i].extensionName,
                extension_name.c_str(), extension_name.size()) == 0) {
      return true;
    }
  }

  return false;
}

}  // namespace vulkan
