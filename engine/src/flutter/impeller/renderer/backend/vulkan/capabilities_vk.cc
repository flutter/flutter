// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/capabilities_vk.h"

#include <algorithm>

#include "impeller/base/validation.h"
#include "impeller/core/formats.h"
#include "impeller/renderer/backend/vulkan/vk.h"

namespace impeller {

static constexpr const char* kInstanceLayer = "ImpellerInstance";

CapabilitiesVK::CapabilitiesVK(bool enable_validations) {
  auto extensions = vk::enumerateInstanceExtensionProperties();
  auto layers = vk::enumerateInstanceLayerProperties();

  if (extensions.result != vk::Result::eSuccess ||
      layers.result != vk::Result::eSuccess) {
    return;
  }

  for (const auto& ext : extensions.value) {
    exts_[kInstanceLayer].insert(ext.extensionName);
  }

  for (const auto& layer : layers.value) {
    const std::string layer_name = layer.layerName;
    auto layer_exts = vk::enumerateInstanceExtensionProperties(layer_name);
    if (layer_exts.result != vk::Result::eSuccess) {
      return;
    }
    for (const auto& layer_ext : layer_exts.value) {
      exts_[layer_name].insert(layer_ext.extensionName);
    }
  }

  validations_enabled_ =
      enable_validations && HasLayer("VK_LAYER_KHRONOS_validation");
  if (enable_validations && !validations_enabled_) {
    FML_LOG(ERROR)
        << "Requested Impeller context creation with validations but the "
           "validation layers could not be found. Expect no Vulkan validation "
           "checks!";
  }
  if (validations_enabled_) {
    FML_LOG(INFO) << "Vulkan validations are enabled.";
  }
  is_valid_ = true;
}

CapabilitiesVK::~CapabilitiesVK() = default;

bool CapabilitiesVK::IsValid() const {
  return is_valid_;
}

bool CapabilitiesVK::AreValidationsEnabled() const {
  return validations_enabled_;
}

std::optional<std::vector<std::string>> CapabilitiesVK::GetEnabledLayers()
    const {
  std::vector<std::string> required;

  if (validations_enabled_) {
    // The presence of this layer is already checked in the ctor.
    required.push_back("VK_LAYER_KHRONOS_validation");
  }

  return required;
}

std::optional<std::vector<std::string>>
CapabilitiesVK::GetEnabledInstanceExtensions() const {
  std::vector<std::string> required;

  if (!HasExtension("VK_KHR_surface")) {
    // Swapchain support is required and this is a dependency of
    // VK_KHR_swapchain.
    VALIDATION_LOG << "Could not find the surface extension.";
    return std::nullopt;
  }
  required.push_back("VK_KHR_surface");

  auto has_wsi = false;
  if (HasExtension("VK_MVK_macos_surface")) {
    required.push_back("VK_MVK_macos_surface");
    has_wsi = true;
  }

  if (HasExtension("VK_EXT_metal_surface")) {
    required.push_back("VK_EXT_metal_surface");
    has_wsi = true;
  }

  if (HasExtension("VK_KHR_portability_enumeration")) {
    required.push_back("VK_KHR_portability_enumeration");
    has_wsi = true;
  }

  if (HasExtension("VK_KHR_win32_surface")) {
    required.push_back("VK_KHR_win32_surface");
    has_wsi = true;
  }

  if (HasExtension("VK_KHR_android_surface")) {
    required.push_back("VK_KHR_android_surface");
    has_wsi = true;
  }

  if (HasExtension("VK_KHR_xcb_surface")) {
    required.push_back("VK_KHR_xcb_surface");
    has_wsi = true;
  }

  if (HasExtension("VK_KHR_xlib_surface")) {
    required.push_back("VK_KHR_xlib_surface");
    has_wsi = true;
  }

  if (HasExtension("VK_KHR_wayland_surface")) {
    required.push_back("VK_KHR_wayland_surface");
    has_wsi = true;
  }

  if (!has_wsi) {
    // Don't really care which WSI extension there is as long there is at least
    // one.
    VALIDATION_LOG << "Could not find a WSI extension.";
    return std::nullopt;
  }

  if (validations_enabled_) {
    if (!HasExtension("VK_EXT_debug_utils")) {
      VALIDATION_LOG << "Requested validations but could not find the "
                        "VK_EXT_debug_utils extension.";
      return std::nullopt;
    }
    required.push_back("VK_EXT_debug_utils");

    if (HasExtension("VK_EXT_validation_features")) {
      // It's valid to not have `VK_EXT_validation_features` available.  That's
      // the case when using AGI as a frame debugger.
      required.push_back("VK_EXT_validation_features");
    }
  }

  return required;
}

static const char* GetDeviceExtensionName(OptionalDeviceExtensionVK ext) {
  switch (ext) {
    case OptionalDeviceExtensionVK::kEXTPipelineCreationFeedback:
      return VK_EXT_PIPELINE_CREATION_FEEDBACK_EXTENSION_NAME;
    case OptionalDeviceExtensionVK::kLast:
      return "Unknown";
  }
  return "Unknown";
}

static void IterateOptionalDeviceExtensions(
    const std::function<void(OptionalDeviceExtensionVK)>& it) {
  if (!it) {
    return;
  }
  for (size_t i = 0;
       i < static_cast<uint32_t>(OptionalDeviceExtensionVK::kLast); i++) {
    it(static_cast<OptionalDeviceExtensionVK>(i));
  }
}

static std::optional<std::set<std::string>> GetSupportedDeviceExtensions(
    const vk::PhysicalDevice& physical_device) {
  auto device_extensions = physical_device.enumerateDeviceExtensionProperties();
  if (device_extensions.result != vk::Result::eSuccess) {
    return std::nullopt;
  }

  std::set<std::string> exts;
  for (const auto& device_extension : device_extensions.value) {
    exts.insert(device_extension.extensionName);
  };

  return exts;
}

std::optional<std::vector<std::string>>
CapabilitiesVK::GetEnabledDeviceExtensions(
    const vk::PhysicalDevice& physical_device) const {
  auto exts = GetSupportedDeviceExtensions(physical_device);

  if (!exts.has_value()) {
    return std::nullopt;
  }

  std::vector<std::string> enabled;

  if (exts->find("VK_KHR_swapchain") == exts->end()) {
    VALIDATION_LOG << "Device does not support the swapchain extension.";
    return std::nullopt;
  }
  enabled.push_back("VK_KHR_swapchain");

  // Required for non-conformant implementations like MoltenVK.
  if (exts->find("VK_KHR_portability_subset") != exts->end()) {
    enabled.push_back("VK_KHR_portability_subset");
  }

#ifdef FML_OS_ANDROID
  if (exts->find("VK_ANDROID_external_memory_android_hardware_buffer") ==
      exts->end()) {
    VALIDATION_LOG
        << "Device does not support "
           "VK_ANDROID_external_memory_android_hardware_buffer extension.";
    return std::nullopt;
  }
  enabled.push_back("VK_ANDROID_external_memory_android_hardware_buffer");
  enabled.push_back("VK_EXT_queue_family_foreign");
#endif

  // Enable all optional extensions if the device supports it.
  IterateOptionalDeviceExtensions([&](auto ext) {
    auto ext_name = GetDeviceExtensionName(ext);
    if (exts->find(ext_name) != exts->end()) {
      enabled.push_back(ext_name);
    }
  });

  return enabled;
}

static bool HasSuitableColorFormat(const vk::PhysicalDevice& device,
                                   vk::Format format) {
  const auto props = device.getFormatProperties(format);
  // This needs to be more comprehensive.
  return !!(props.optimalTilingFeatures &
            vk::FormatFeatureFlagBits::eColorAttachment);
}

static bool HasSuitableDepthStencilFormat(const vk::PhysicalDevice& device,
                                          vk::Format format) {
  const auto props = device.getFormatProperties(format);
  return !!(props.optimalTilingFeatures &
            vk::FormatFeatureFlagBits::eDepthStencilAttachment);
}

static bool PhysicalDeviceSupportsRequiredFormats(
    const vk::PhysicalDevice& device) {
  const auto has_color_format =
      HasSuitableColorFormat(device, vk::Format::eB8G8R8A8Unorm);
  const auto has_stencil_format =
      HasSuitableDepthStencilFormat(device, vk::Format::eS8Uint) ||
      HasSuitableDepthStencilFormat(device, vk::Format::eD32SfloatS8Uint) ||
      HasSuitableDepthStencilFormat(device, vk::Format::eD24UnormS8Uint);
  return has_color_format && has_stencil_format;
}

static bool HasRequiredProperties(const vk::PhysicalDevice& physical_device) {
  auto properties = physical_device.getProperties();
  if (!(properties.limits.framebufferColorSampleCounts &
        (vk::SampleCountFlagBits::e1 | vk::SampleCountFlagBits::e4))) {
    return false;
  }
  return true;
}

static bool HasRequiredQueues(const vk::PhysicalDevice& physical_device) {
  auto queue_flags = vk::QueueFlags{};
  for (const auto& queue : physical_device.getQueueFamilyProperties()) {
    if (queue.queueCount == 0) {
      continue;
    }
    queue_flags |= queue.queueFlags;
  }
  return static_cast<VkQueueFlags>(queue_flags &
                                   (vk::QueueFlagBits::eGraphics |
                                    vk::QueueFlagBits::eCompute |
                                    vk::QueueFlagBits::eTransfer));
}

std::optional<vk::PhysicalDeviceFeatures>
CapabilitiesVK::GetEnabledDeviceFeatures(
    const vk::PhysicalDevice& device) const {
  if (!PhysicalDeviceSupportsRequiredFormats(device)) {
    VALIDATION_LOG << "Device doesn't support the required formats.";
    return std::nullopt;
  }

  if (!HasRequiredProperties(device)) {
    VALIDATION_LOG << "Device doesn't support the required properties.";
    return std::nullopt;
  }

  if (!HasRequiredQueues(device)) {
    VALIDATION_LOG << "Device doesn't support the required queues.";
    return std::nullopt;
  }

  if (!GetEnabledDeviceExtensions(device).has_value()) {
    VALIDATION_LOG << "Device doesn't support the required queues.";
    return std::nullopt;
  }

  const auto device_features = device.getFeatures();

  vk::PhysicalDeviceFeatures required;

  // We require this for enabling wireframes in the playground. But its not
  // necessarily a big deal if we don't have this feature.
  required.fillModeNonSolid = device_features.fillModeNonSolid;

  return required;
}

bool CapabilitiesVK::HasLayer(const std::string& layer) const {
  for (const auto& [found_layer, exts] : exts_) {
    if (found_layer == layer) {
      return true;
    }
  }
  return false;
}

bool CapabilitiesVK::HasExtension(const std::string& ext) const {
  for (const auto& [layer, exts] : exts_) {
    if (exts.find(ext) != exts.end()) {
      return true;
    }
  }
  return false;
}

void CapabilitiesVK::SetOffscreenFormat(PixelFormat pixel_format) const {
  default_color_format_ = pixel_format;
}

bool CapabilitiesVK::SetPhysicalDevice(const vk::PhysicalDevice& device) {
  if (HasSuitableDepthStencilFormat(device, vk::Format::eD32SfloatS8Uint)) {
    default_depth_stencil_format_ = PixelFormat::kD32FloatS8UInt;
  } else if (HasSuitableDepthStencilFormat(device,
                                           vk::Format::eD24UnormS8Uint)) {
    default_depth_stencil_format_ = PixelFormat::kD24UnormS8Uint;
  } else {
    default_depth_stencil_format_ = PixelFormat::kUnknown;
  }

  if (HasSuitableDepthStencilFormat(device, vk::Format::eS8Uint)) {
    default_stencil_format_ = PixelFormat::kS8UInt;
  } else if (default_stencil_format_ != PixelFormat::kUnknown) {
    default_stencil_format_ = default_depth_stencil_format_;
  } else {
    return false;
  }

  device_properties_ = device.getProperties();

  auto physical_properties_2 =
      device.getProperties2<vk::PhysicalDeviceProperties2,
                            vk::PhysicalDeviceSubgroupProperties>();

  // Currently shaders only want access to arithmetic subgroup features.
  // If that changes this needs to get updated, and so does Metal (which right
  // now assumes it from compile time flags based on the MSL target version).

  supports_compute_subgroups_ =
      !!(physical_properties_2.get<vk::PhysicalDeviceSubgroupProperties>()
             .supportedOperations &
         vk::SubgroupFeatureFlagBits::eArithmetic);

  {
    // Query texture support.
    // TODO(jonahwilliams):
    // https://github.com/flutter/flutter/issues/129784
    vk::PhysicalDeviceMemoryProperties memory_properties;
    device.getMemoryProperties(&memory_properties);

    for (auto i = 0u; i < memory_properties.memoryTypeCount; i++) {
      if (memory_properties.memoryTypes[i].propertyFlags &
          vk::MemoryPropertyFlagBits::eLazilyAllocated) {
        supports_device_transient_textures_ = true;
      }
    }
  }

  // Determine the optional device extensions this physical device supports.
  {
    optional_device_extensions_.clear();
    auto exts = GetSupportedDeviceExtensions(device);
    if (!exts.has_value()) {
      return false;
    }
    IterateOptionalDeviceExtensions([&](auto ext) {
      auto ext_name = GetDeviceExtensionName(ext);
      if (exts->find(ext_name) != exts->end()) {
        optional_device_extensions_.insert(ext);
      }
    });
  }

  return true;
}

// |Capabilities|
bool CapabilitiesVK::SupportsOffscreenMSAA() const {
  return true;
}

// |Capabilities|
bool CapabilitiesVK::SupportsImplicitResolvingMSAA() const {
  return false;
}

// |Capabilities|
bool CapabilitiesVK::SupportsSSBO() const {
  return true;
}

// |Capabilities|
bool CapabilitiesVK::SupportsBufferToTextureBlits() const {
  return true;
}

// |Capabilities|
bool CapabilitiesVK::SupportsTextureToTextureBlits() const {
  return true;
}

// |Capabilities|
bool CapabilitiesVK::SupportsFramebufferFetch() const {
  return false;
}

// |Capabilities|
bool CapabilitiesVK::SupportsCompute() const {
  // Vulkan 1.1 requires support for compute.
  return true;
}

// |Capabilities|
bool CapabilitiesVK::SupportsComputeSubgroups() const {
  // Set by |SetPhysicalDevice|.
  return supports_compute_subgroups_;
}

// |Capabilities|
bool CapabilitiesVK::SupportsReadFromResolve() const {
  return false;
}

bool CapabilitiesVK::SupportsDecalSamplerAddressMode() const {
  return true;
}

// |Capabilities|
bool CapabilitiesVK::SupportsDeviceTransientTextures() const {
  return supports_device_transient_textures_;
}

// |Capabilities|
PixelFormat CapabilitiesVK::GetDefaultColorFormat() const {
  return default_color_format_;
}

// |Capabilities|
PixelFormat CapabilitiesVK::GetDefaultStencilFormat() const {
  return default_stencil_format_;
}

// |Capabilities|
PixelFormat CapabilitiesVK::GetDefaultDepthStencilFormat() const {
  return default_depth_stencil_format_;
}

const vk::PhysicalDeviceProperties&
CapabilitiesVK::GetPhysicalDeviceProperties() const {
  return device_properties_;
}

bool CapabilitiesVK::HasOptionalDeviceExtension(
    OptionalDeviceExtensionVK extension) const {
  return optional_device_extensions_.find(extension) !=
         optional_device_extensions_.end();
}

}  // namespace impeller
