// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/vulkan_manager.h"

#include <cstring>
#include <string>
#include <vector>

#include "flutter/fml/logging.h"

namespace flutter {

// static
std::unique_ptr<VulkanManager> VulkanManager::Create() {
  auto manager = std::unique_ptr<VulkanManager>(new VulkanManager());
  if (!manager->Initialize()) {
    FML_LOG(WARNING)
        << "Failed to initialize Vulkan. Falling back to OpenGL/Software.";
    return nullptr;
  }
  return manager;
}

// static
bool VulkanManager::IsAvailable() {
  auto vk = fml::MakeRefCounted<vulkan::VulkanProcTable>();
  return vk->HasAcquiredMandatoryProcAddresses();
}

VulkanManager::VulkanManager() = default;

VulkanManager::~VulkanManager() {
  // Wait for all GPU work to complete before destroying resources.
  // Per Vulkan spec VUID-vkDestroyDevice-device-00378, the device must
  // be idle before destruction.
  if (device_ != VK_NULL_HANDLE && vk_ &&
      static_cast<bool>(vk_->DeviceWaitIdle)) {
    vk_->DeviceWaitIdle(device_);
  }

  // Destroy surface before device.
  if (surface_ != VK_NULL_HANDLE) {
    DestroyWindowSurface(surface_);
    surface_ = VK_NULL_HANDLE;
  }

  if (device_ != VK_NULL_HANDLE && vk_ &&
      static_cast<bool>(vk_->DestroyDevice)) {
    vk_->DestroyDevice(device_, nullptr);
    device_ = VK_NULL_HANDLE;
  }

  if (instance_ != VK_NULL_HANDLE && vk_ &&
      static_cast<bool>(vk_->DestroyInstance)) {
    vk_->DestroyInstance(instance_, nullptr);
    instance_ = VK_NULL_HANDLE;
  }
}

bool VulkanManager::Initialize() {
  vk_ = fml::MakeRefCounted<vulkan::VulkanProcTable>();
  if (!vk_->HasAcquiredMandatoryProcAddresses()) {
    FML_LOG(ERROR) << "Failed to load vulkan-1.dll or resolve required "
                      "Vulkan entry points.";
    return false;
  }

  // Query the highest available Vulkan version.
  if (static_cast<bool>(vk_->EnumerateInstanceVersion)) {
    uint32_t api_version = 0;
    if (vk_->EnumerateInstanceVersion(&api_version) == VK_SUCCESS) {
      vulkan_version_ = api_version;
    }
  }

  // Impeller requires Vulkan 1.1 as minimum.
  if (vulkan_version_ < VK_API_VERSION_1_1) {
    FML_LOG(ERROR) << "VulkanManager: Vulkan 1.1 or later is required (found "
                   << VK_VERSION_MAJOR(vulkan_version_) << "."
                   << VK_VERSION_MINOR(vulkan_version_) << ").";
    return false;
  }

  // Required instance extensions for Win32 surface creation.
  enabled_instance_extensions_ = {
      VK_KHR_SURFACE_EXTENSION_NAME,
      VK_KHR_WIN32_SURFACE_EXTENSION_NAME,
  };

  // Verify all required instance extensions are available.
  uint32_t available_ext_count = 0;
  if (vk_->EnumerateInstanceExtensionProperties(nullptr, &available_ext_count,
                                                nullptr) != VK_SUCCESS) {
    FML_LOG(ERROR) << "VulkanManager: Failed to enumerate instance extensions.";
    return false;
  }

  std::vector<VkExtensionProperties> available_extensions(available_ext_count);
  if (vk_->EnumerateInstanceExtensionProperties(nullptr, &available_ext_count,
                                                available_extensions.data()) !=
      VK_SUCCESS) {
    FML_LOG(ERROR) << "VulkanManager: Failed to enumerate instance extensions.";
    return false;
  }

  available_instance_extensions_ = BuildExtensionSet(available_extensions);

  for (const char* required : enabled_instance_extensions_) {
    if (available_instance_extensions_.find(required) ==
        available_instance_extensions_.end()) {
      FML_LOG(ERROR) << "VulkanManager: Required instance extension '"
                     << required << "' not available.";
      return false;
    }
  }

  // Enable validation layers in debug builds if requested.
#if !defined(NDEBUG)
  {
    const char* env = std::getenv("FLUTTER_VULKAN_VALIDATION");
    // Check if the environment variable is set to "1" to enable validation.
    if (env && strcmp(env, "1") == 0) {
      uint32_t layer_count = 0;
      if (vk_->EnumerateInstanceLayerProperties(&layer_count, nullptr) ==
              VK_SUCCESS &&
          layer_count > 0) {
        std::vector<VkLayerProperties> available_layers(layer_count);
        if (vk_->EnumerateInstanceLayerProperties(
                &layer_count, available_layers.data()) == VK_SUCCESS) {
          const char* validation_layer = "VK_LAYER_KHRONOS_validation";
          for (const auto& layer : available_layers) {
            if (strcmp(validation_layer, layer.layerName) == 0) {
              enabled_layers_.push_back(validation_layer);
              FML_LOG(INFO)
                  << "VulkanManager: Enabling Vulkan validation layers.";
              // Also enable the debug utils and validation features extensions
              // required by Impeller's DebugReportVK.
              if (available_instance_extensions_.count(
                      VK_EXT_DEBUG_UTILS_EXTENSION_NAME)) {
                enabled_instance_extensions_.push_back(
                    VK_EXT_DEBUG_UTILS_EXTENSION_NAME);
              }
              if (available_instance_extensions_.count(
                      VK_EXT_VALIDATION_FEATURES_EXTENSION_NAME)) {
                enabled_instance_extensions_.push_back(
                    VK_EXT_VALIDATION_FEATURES_EXTENSION_NAME);
              }
              break;
            }
          }
        }
      }
    }
  }
#endif

  // Create VkInstance.
  VkApplicationInfo app_info = {};
  app_info.sType = VK_STRUCTURE_TYPE_APPLICATION_INFO;
  app_info.pApplicationName = "Flutter";
  app_info.applicationVersion = VK_MAKE_VERSION(1, 0, 0);
  app_info.pEngineName = "Flutter Engine";
  app_info.engineVersion = VK_MAKE_VERSION(1, 0, 0);
  app_info.apiVersion = vulkan_version_;

  VkInstanceCreateInfo instance_info = {};
  instance_info.sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
  instance_info.pApplicationInfo = &app_info;
  instance_info.enabledExtensionCount =
      static_cast<uint32_t>(enabled_instance_extensions_.size());
  instance_info.ppEnabledExtensionNames = enabled_instance_extensions_.data();
  instance_info.enabledLayerCount =
      static_cast<uint32_t>(enabled_layers_.size());
  instance_info.ppEnabledLayerNames =
      enabled_layers_.empty() ? nullptr : enabled_layers_.data();

  VkResult result = vk_->CreateInstance(&instance_info, nullptr, &instance_);
  if (result != VK_SUCCESS) {
    FML_LOG(ERROR) << "VulkanManager: Failed to create VkInstance (result="
                   << result << ").";
    return false;
  }

  if (!vk_->SetupInstanceProcAddresses(
          vulkan::VulkanHandle<VkInstance>(instance_))) {
    FML_LOG(ERROR) << "VulkanManager: Failed to setup instance proc addresses.";
    return false;
  }

  if (!SelectPhysicalDevice()) {
    FML_LOG(ERROR) << "VulkanManager: No suitable Vulkan physical device.";
    return false;
  }

  if (!CreateLogicalDevice()) {
    FML_LOG(ERROR) << "VulkanManager: Failed to create Vulkan logical device.";
    return false;
  }

  // Log the selected device.
  if (static_cast<bool>(vk_->GetPhysicalDeviceProperties)) {
    VkPhysicalDeviceProperties props;
    vk_->GetPhysicalDeviceProperties(physical_device_, &props);
    FML_DLOG(INFO) << "VulkanManager: Using Vulkan device: "
                   << props.deviceName;
  }

  return true;
}

bool VulkanManager::SelectPhysicalDevice() {
  uint32_t device_count = 0;
  if (vk_->EnumeratePhysicalDevices(instance_, &device_count, nullptr) !=
          VK_SUCCESS ||
      device_count == 0) {
    FML_LOG(ERROR) << "VulkanManager: No Vulkan physical devices found.";
    return false;
  }

  std::vector<VkPhysicalDevice> devices(device_count);
  if (vk_->EnumeratePhysicalDevices(instance_, &device_count, devices.data()) !=
      VK_SUCCESS) {
    FML_LOG(ERROR) << "VulkanManager: Failed to enumerate physical devices.";
    return false;
  }

  // Resolve vkGetPhysicalDeviceWin32PresentationSupportKHR for checking
  // that a queue family can present to Win32 windows.
  auto get_proc = vk_->NativeGetInstanceProcAddr();
  auto vkGetWin32PresentSupport =
      reinterpret_cast<PFN_vkGetPhysicalDeviceWin32PresentationSupportKHR>(
          get_proc(instance_,
                   "vkGetPhysicalDeviceWin32PresentationSupportKHR"));

  struct DeviceCandidate {
    VkPhysicalDevice device;
    uint32_t queue_family;
    VkPhysicalDeviceType type;
  };

  std::vector<DeviceCandidate> candidates;

  for (const auto& device : devices) {
    uint32_t queue_family_count = 0;
    vk_->GetPhysicalDeviceQueueFamilyProperties(device, &queue_family_count,
                                                nullptr);
    std::vector<VkQueueFamilyProperties> queue_families(queue_family_count);
    vk_->GetPhysicalDeviceQueueFamilyProperties(device, &queue_family_count,
                                                queue_families.data());

    // Find a queue family that supports both graphics and Win32 presentation.
    for (uint32_t i = 0; i < queue_family_count; i++) {
      if (!(queue_families[i].queueFlags & VK_QUEUE_GRAPHICS_BIT)) {
        continue;
      }
      // Check Win32 presentation support if the function is available.
      if (vkGetWin32PresentSupport && !vkGetWin32PresentSupport(device, i)) {
        continue;
      }

      VkPhysicalDeviceProperties props;
      vk_->GetPhysicalDeviceProperties(device, &props);

      candidates.push_back({device, i, props.deviceType});
      break;  // Use the first suitable queue family for this device.
    }
  }

  if (candidates.empty()) {
    FML_LOG(ERROR) << "VulkanManager: No device with graphics + presentation "
                      "queue support found.";
    return false;
  }

  // Prefer discrete > integrated > other.
  const DeviceCandidate* best = &candidates[0];
  for (const auto& c : candidates) {
    if (c.type == VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU) {
      best = &c;
      break;
    }
    if (c.type == VK_PHYSICAL_DEVICE_TYPE_INTEGRATED_GPU &&
        best->type != VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU) {
      best = &c;
    }
  }

  physical_device_ = best->device;
  queue_family_index_ = best->queue_family;

  return true;
}

bool VulkanManager::CreateLogicalDevice() {
  float queue_priority = 1.0f;

  VkDeviceQueueCreateInfo queue_create_info = {};
  queue_create_info.sType = VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO;
  queue_create_info.queueFamilyIndex = queue_family_index_;
  queue_create_info.queueCount = 1;
  queue_create_info.pQueuePriorities = &queue_priority;

  // Required device extensions.
  enabled_device_extensions_ = {
      VK_KHR_SWAPCHAIN_EXTENSION_NAME,
  };

  // Verify required device extensions are available.
  uint32_t ext_count = 0;
  if (vk_->EnumerateDeviceExtensionProperties(
          physical_device_, nullptr, &ext_count, nullptr) != VK_SUCCESS) {
    FML_LOG(ERROR) << "Failed to enumerate device extension count.";
    return false;
  }

  std::vector<VkExtensionProperties> available_exts(ext_count);
  if (vk_->EnumerateDeviceExtensionProperties(
          physical_device_, nullptr, &ext_count, available_exts.data()) !=
      VK_SUCCESS) {
    FML_LOG(ERROR) << "Failed to enumerate device extensions.";
    return false;
  }

  available_device_extensions_ = BuildExtensionSet(available_exts);

  for (const char* required : enabled_device_extensions_) {
    if (available_device_extensions_.find(required) ==
        available_device_extensions_.end()) {
      FML_LOG(ERROR) << "VulkanManager: Required device extension '" << required
                     << "' not available.";
      return false;
    }
  }

  // Enable optional extensions that Impeller checks for.
  // VK_EXT_pipeline_creation_feedback provides shader compilation diagnostics.
  if (available_device_extensions_.count(
          VK_EXT_PIPELINE_CREATION_FEEDBACK_EXTENSION_NAME)) {
    enabled_device_extensions_.push_back(
        VK_EXT_PIPELINE_CREATION_FEEDBACK_EXTENSION_NAME);
  }

  // Query device features using the Vulkan 1.1 pNext chain approach.
  auto get_proc = vk_->NativeGetInstanceProcAddr();

  VkPhysicalDevice16BitStorageFeatures storage_16bit = {};
  storage_16bit.sType =
      VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_16BIT_STORAGE_FEATURES;

  VkPhysicalDeviceFeatures2 device_features2 = {};
  device_features2.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FEATURES_2;
  device_features2.pNext = &storage_16bit;

  auto vkGetPhysicalDeviceFeatures2 =
      reinterpret_cast<PFN_vkGetPhysicalDeviceFeatures2>(
          get_proc(instance_, "vkGetPhysicalDeviceFeatures2"));
  if (vkGetPhysicalDeviceFeatures2) {
    vkGetPhysicalDeviceFeatures2(physical_device_, &device_features2);
  } else {
    vk_->GetPhysicalDeviceFeatures(physical_device_,
                                   &device_features2.features);
  }

  VkDeviceCreateInfo device_info = {};
  device_info.sType = VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO;
  device_info.pNext = &device_features2;
  device_info.queueCreateInfoCount = 1;
  device_info.pQueueCreateInfos = &queue_create_info;
  device_info.enabledExtensionCount =
      static_cast<uint32_t>(enabled_device_extensions_.size());
  device_info.ppEnabledExtensionNames = enabled_device_extensions_.data();
  device_info.pEnabledFeatures = nullptr;

  VkResult result =
      vk_->CreateDevice(physical_device_, &device_info, nullptr, &device_);
  if (result != VK_SUCCESS) {
    FML_LOG(ERROR) << "VulkanManager: Failed to create VkDevice (result="
                   << result << ").";
    return false;
  }

  if (!vk_->SetupDeviceProcAddresses(vulkan::VulkanHandle<VkDevice>(device_))) {
    FML_LOG(ERROR) << "VulkanManager: Failed to setup device proc addresses.";
    return false;
  }

  vk_->GetDeviceQueue(device_, queue_family_index_, 0, &queue_);
  if (queue_ == VK_NULL_HANDLE) {
    FML_LOG(ERROR) << "VulkanManager: Failed to get device queue.";
    return false;
  }

  return true;
}

const char* const* VulkanManager::GetEnabledInstanceExtensions(
    size_t* count) const {
  FML_DCHECK(count != nullptr);
  *count = enabled_instance_extensions_.size();
  return enabled_instance_extensions_.data();
}

const char* const* VulkanManager::GetEnabledDeviceExtensions(
    size_t* count) const {
  FML_DCHECK(count != nullptr);
  *count = enabled_device_extensions_.size();
  return enabled_device_extensions_.data();
}

void* VulkanManager::GetInstanceProcAddress(VkInstance instance,
                                            const char* name) const {
  if (!vk_) {
    return nullptr;
  }
  auto get_proc = vk_->NativeGetInstanceProcAddr();
  if (!get_proc) {
    return nullptr;
  }
  return reinterpret_cast<void*>(get_proc(instance, name));
}

VkSurfaceKHR VulkanManager::CreateWindowSurface(HWND hwnd) {
  if (instance_ == VK_NULL_HANDLE || hwnd == nullptr) {
    return VK_NULL_HANDLE;
  }

  VkWin32SurfaceCreateInfoKHR create_info = {};
  create_info.sType = VK_STRUCTURE_TYPE_WIN32_SURFACE_CREATE_INFO_KHR;
  create_info.hinstance = GetModuleHandle(nullptr);
  create_info.hwnd = hwnd;

  VkSurfaceKHR surface = VK_NULL_HANDLE;
  if (!vk_->CreateWin32SurfaceKHR) {
    FML_LOG(ERROR) << "VulkanManager: vkCreateWin32SurfaceKHR not available.";
    return VK_NULL_HANDLE;
  }

  VkResult result =
      vk_->CreateWin32SurfaceKHR(instance_, &create_info, nullptr, &surface);
  if (result != VK_SUCCESS) {
    FML_LOG(ERROR) << "VulkanManager: Failed to create Win32 surface (result="
                   << result << ").";
    return VK_NULL_HANDLE;
  }

  return surface;
}

void VulkanManager::DestroyWindowSurface(VkSurfaceKHR surface) {
  if (instance_ == VK_NULL_HANDLE || surface == VK_NULL_HANDLE) {
    return;
  }

  if (vk_->DestroySurfaceKHR) {
    vk_->DestroySurfaceKHR(instance_, surface, nullptr);
  }
}

bool VulkanManager::InitializeSurface(HWND hwnd) {
  if (!hwnd || instance_ == VK_NULL_HANDLE) {
    return false;
  }

  if (surface_hwnd_ == hwnd && surface_ != VK_NULL_HANDLE) {
    return true;  // Already initialized for this window.
  }

  // Destroy old surface if switching windows.
  if (surface_ != VK_NULL_HANDLE) {
    DestroyWindowSurface(surface_);
    surface_ = VK_NULL_HANDLE;
  }

  surface_hwnd_ = hwnd;
  surface_ = CreateWindowSurface(hwnd);
  if (surface_ == VK_NULL_HANDLE) {
    FML_LOG(ERROR) << "VulkanManager::InitializeSurface: "
                      "Failed to create VkSurfaceKHR.";
    return false;
  }

  FML_DLOG(INFO) << "VulkanManager: VkSurfaceKHR created for HWND.";
  return true;
}

// static
std::unordered_set<std::string> VulkanManager::BuildExtensionSet(
    const std::vector<VkExtensionProperties>& extensions) {
  std::unordered_set<std::string> result;
  result.reserve(extensions.size());
  for (const auto& ext : extensions) {
    result.insert(ext.extensionName);
  }
  return result;
}

}  // namespace flutter
