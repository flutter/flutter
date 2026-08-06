// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/vulkan_manager.h"

#include <cstring>
#include <string>
#include <vector>

#include "flutter/fml/logging.h"

namespace flutter {

namespace {

// The Windows Vulkan loader. VulkanProcTable's default constructor loads
// the Linux library name, so the name must be spelled out here.
constexpr char kVulkanLoaderLibraryName[] = "vulkan-1.dll";

}  // namespace

// static
std::unique_ptr<VulkanManager> VulkanManager::Create() {
  auto manager = std::unique_ptr<VulkanManager>(new VulkanManager());
  if (!manager->Initialize()) {
    FML_LOG(WARNING) << "Failed to initialize Vulkan for Direct3D 11 interop. "
                        "Falling back to ANGLE or software rendering.";
    return nullptr;
  }
  return manager;
}

// static
bool VulkanManager::IsAvailable() {
  auto vk =
      fml::MakeRefCounted<vulkan::VulkanProcTable>(kVulkanLoaderLibraryName);
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

// static
std::unordered_set<std::string> VulkanManager::BuildExtensionSet(
    const std::vector<VkExtensionProperties>& extensions) {
  std::unordered_set<std::string> set;
  for (const auto& ext : extensions) {
    set.insert(ext.extensionName);
  }
  return set;
}

bool VulkanManager::Initialize() {
  vk_ = fml::MakeRefCounted<vulkan::VulkanProcTable>(kVulkanLoaderLibraryName);
  if (!vk_->HasAcquiredMandatoryProcAddresses()) {
    FML_LOG(ERROR) << "Failed to load vulkan-1.dll or resolve required "
                      "Vulkan entry points.";
    return false;
  }

  // Query the highest available Vulkan version. vkEnumerateInstanceVersion
  // is resolved through the loader directly (with a null instance, as the
  // spec requires for global commands); it only exists on Vulkan 1.1+
  // loaders, and its absence means a 1.0 loader.
  auto global_get_proc = vk_->NativeGetInstanceProcAddr();
  auto enumerate_instance_version =
      reinterpret_cast<PFN_vkEnumerateInstanceVersion>(
          global_get_proc(nullptr, "vkEnumerateInstanceVersion"));
  if (enumerate_instance_version) {
    uint32_t api_version = 0;
    if (enumerate_instance_version(&api_version) == VK_SUCCESS) {
      vulkan_version_ = api_version;
    }
  }

  // Impeller requires Vulkan 1.1 at minimum; so does querying the device
  // LUID and external memory capabilities used below.
  if (vulkan_version_ < VK_API_VERSION_1_1) {
    FML_LOG(ERROR) << "VulkanManager: Vulkan 1.1 or later is required (found "
                   << VK_VERSION_MAJOR(vulkan_version_) << "."
                   << VK_VERSION_MINOR(vulkan_version_) << ").";
    return false;
  }

  // No instance extensions are required: presentation happens on the DXGI
  // side, so no VK_KHR_surface / VK_KHR_win32_surface, and the external
  // memory capability queries are core in Vulkan 1.1.
  enabled_instance_extensions_ = {};

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

  // Enable validation layers in debug builds if requested.
#if !defined(NDEBUG)
  {
    const char* env = std::getenv("FLUTTER_VULKAN_VALIDATION");
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
              // Also enable the debug utils and validation features
              // extensions required by Impeller's DebugReportVK.
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

  // Create the VkInstance.
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
  instance_info.ppEnabledExtensionNames =
      enabled_instance_extensions_.empty()
          ? nullptr
          : enabled_instance_extensions_.data();
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
    FML_LOG(ERROR) << "VulkanManager: No Vulkan device supports Direct3D 11 "
                      "image export.";
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

bool VulkanManager::SupportsD3D11Interop(
    VkPhysicalDevice device,
    std::array<uint8_t, VK_LUID_SIZE>* out_luid) const {
  auto get_proc = vk_->NativeGetInstanceProcAddr();

  // The adapter LUID identifies the same GPU on the DXGI side. Without a
  // valid LUID the exported images could land on a different adapter.
  auto vkGetPhysicalDeviceProperties2 =
      reinterpret_cast<PFN_vkGetPhysicalDeviceProperties2>(
          get_proc(instance_, "vkGetPhysicalDeviceProperties2"));
  if (!vkGetPhysicalDeviceProperties2) {
    return false;
  }

  VkPhysicalDeviceIDProperties id_props = {};
  id_props.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_ID_PROPERTIES;

  VkPhysicalDeviceProperties2 props2 = {};
  props2.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PROPERTIES_2;
  props2.pNext = &id_props;
  vkGetPhysicalDeviceProperties2(device, &props2);

  if (!id_props.deviceLUIDValid) {
    FML_DLOG(INFO) << "VulkanManager: '" << props2.properties.deviceName
                   << "' reports no valid adapter LUID.";
    return false;
  }
  if (out_luid) {
    std::memcpy(out_luid->data(), id_props.deviceLUID, VK_LUID_SIZE);
  }

  // The render targets must be exportable as Direct3D 11 textures.
  auto vkGetPhysicalDeviceImageFormatProperties2 =
      reinterpret_cast<PFN_vkGetPhysicalDeviceImageFormatProperties2>(
          get_proc(instance_, "vkGetPhysicalDeviceImageFormatProperties2"));
  if (!vkGetPhysicalDeviceImageFormatProperties2) {
    return false;
  }

  VkPhysicalDeviceExternalImageFormatInfo external_info = {};
  external_info.sType =
      VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_EXTERNAL_IMAGE_FORMAT_INFO;
  external_info.handleType = VK_EXTERNAL_MEMORY_HANDLE_TYPE_D3D11_TEXTURE_BIT;

  VkPhysicalDeviceImageFormatInfo2 format_info = {};
  format_info.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_IMAGE_FORMAT_INFO_2;
  format_info.pNext = &external_info;
  format_info.format = VK_FORMAT_B8G8R8A8_UNORM;
  format_info.type = VK_IMAGE_TYPE_2D;
  format_info.tiling = VK_IMAGE_TILING_OPTIMAL;
  // Color attachment and transfer source only: the exported image is the
  // resolve target of the onscreen pass and the source of the Direct3D
  // copy. Input attachment usage is deliberately absent; drivers commonly
  // reject it for externally exportable images, and framebuffer fetch is
  // not used on the exported image.
  format_info.usage =
      VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT | VK_IMAGE_USAGE_TRANSFER_SRC_BIT;

  VkExternalImageFormatProperties external_props = {};
  external_props.sType = VK_STRUCTURE_TYPE_EXTERNAL_IMAGE_FORMAT_PROPERTIES;

  VkImageFormatProperties2 format_props = {};
  format_props.sType = VK_STRUCTURE_TYPE_IMAGE_FORMAT_PROPERTIES_2;
  format_props.pNext = &external_props;

  VkResult format_result = vkGetPhysicalDeviceImageFormatProperties2(
      device, &format_info, &format_props);
  if (format_result != VK_SUCCESS) {
    FML_DLOG(INFO) << "VulkanManager: '" << props2.properties.deviceName
                   << "' rejects exportable image creation (result="
                   << format_result << ").";
    return false;
  }

  // Windows drivers report Direct3D 11 texture memory as importable into
  // Vulkan, not exportable from it (observed on AMD as DEDICATED_ONLY |
  // IMPORTABLE). The interop therefore allocates the shared texture on the
  // Direct3D side and imports it here, which is also the canonical
  // direction used by other Vulkan-on-Windows compositor integrations.
  constexpr VkExternalMemoryFeatureFlags kRequiredFeatures =
      VK_EXTERNAL_MEMORY_FEATURE_IMPORTABLE_BIT;
  VkExternalMemoryFeatureFlags features =
      external_props.externalMemoryProperties.externalMemoryFeatures;
  if ((features & kRequiredFeatures) != kRequiredFeatures) {
    FML_DLOG(INFO) << "VulkanManager: '" << props2.properties.deviceName
                   << "' cannot import Direct3D 11 textures (features="
                   << features << ").";
    return false;
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

  struct DeviceCandidate {
    VkPhysicalDevice device;
    uint32_t queue_family;
    VkPhysicalDeviceType type;
    std::array<uint8_t, VK_LUID_SIZE> luid;
  };

  std::vector<DeviceCandidate> candidates;

  for (const auto& device : devices) {
    // The device must be able to export render targets to Direct3D 11.
    std::array<uint8_t, VK_LUID_SIZE> luid = {};
    if (!SupportsD3D11Interop(device, &luid)) {
      continue;
    }

    uint32_t queue_family_count = 0;
    vk_->GetPhysicalDeviceQueueFamilyProperties(device, &queue_family_count,
                                                nullptr);
    std::vector<VkQueueFamilyProperties> queue_families(queue_family_count);
    vk_->GetPhysicalDeviceQueueFamilyProperties(device, &queue_family_count,
                                                queue_families.data());

    for (uint32_t i = 0; i < queue_family_count; i++) {
      if (!(queue_families[i].queueFlags & VK_QUEUE_GRAPHICS_BIT)) {
        continue;
      }

      VkPhysicalDeviceProperties props;
      vk_->GetPhysicalDeviceProperties(device, &props);

      candidates.push_back({device, i, props.deviceType, luid});
      break;  // Use the first graphics queue family for this device.
    }
  }

  if (candidates.empty()) {
    FML_LOG(ERROR) << "VulkanManager: No device with a graphics queue and "
                      "Direct3D 11 export support found.";
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
  device_luid_ = best->luid;

  return true;
}

bool VulkanManager::CreateLogicalDevice() {
  float queue_priority = 1.0f;

  VkDeviceQueueCreateInfo queue_create_info = {};
  queue_create_info.sType = VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO;
  queue_create_info.queueFamilyIndex = queue_family_index_;
  queue_create_info.queueCount = 1;
  queue_create_info.pQueuePriorities = &queue_priority;

  // Extensions required to export images to Direct3D 11 and coordinate
  // access with the DXGI side through the shared texture's keyed mutex.
  // VK_KHR_external_memory and VK_KHR_dedicated_allocation are core in
  // Vulkan 1.1 and need no explicit enablement.
  enabled_device_extensions_ = {
      VK_KHR_EXTERNAL_MEMORY_WIN32_EXTENSION_NAME,
      VK_KHR_WIN32_KEYED_MUTEX_EXTENSION_NAME,
  };

  auto instance_get_proc = vk_->NativeGetInstanceProcAddr();
  auto enumerate_device_extensions =
      reinterpret_cast<PFN_vkEnumerateDeviceExtensionProperties>(
          instance_get_proc(instance_, "vkEnumerateDeviceExtensionProperties"));
  if (!enumerate_device_extensions) {
    FML_LOG(ERROR) << "Failed to resolve device extension enumeration.";
    return false;
  }

  uint32_t ext_count = 0;
  if (enumerate_device_extensions(physical_device_, nullptr, &ext_count,
                                  nullptr) != VK_SUCCESS) {
    FML_LOG(ERROR) << "Failed to enumerate device extension count.";
    return false;
  }

  std::vector<VkExtensionProperties> available_exts(ext_count);
  if (enumerate_device_extensions(physical_device_, nullptr, &ext_count,
                                  available_exts.data()) != VK_SUCCESS) {
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
  // VK_EXT_pipeline_creation_feedback provides shader compilation
  // diagnostics.
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

const char** VulkanManager::GetEnabledInstanceExtensions(size_t* count) {
  FML_DCHECK(count != nullptr);
  *count = enabled_instance_extensions_.size();
  return enabled_instance_extensions_.data();
}

const char** VulkanManager::GetEnabledDeviceExtensions(size_t* count) {
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

}  // namespace flutter
