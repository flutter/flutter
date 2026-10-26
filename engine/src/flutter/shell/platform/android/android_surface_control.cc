// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/android_surface_control.h"

#include <algorithm>
#include <array>
#include <cstring>
#include <limits>
#include <utility>

#include "flutter/fml/logging.h"

namespace flutter {
namespace android {

namespace {

// Minimum Android SDK API level required for Impeller Vulkan.
constexpr int32_t kMinVulkanAndroidApiLevel = 29;

// Minimum vendor SDK API level required on MediaTek platforms for Impeller
// Vulkan (`ro.vendor.build.version.sdk >= 32`).
constexpr int32_t kMinMediaTekVendorApiLevel = 32;

// Minimum Android ComponentCallbacks2 trim level triggering low-memory warning
// (`TRIM_MEMORY_RUNNING_LOW = 10`, `TRIM_MEMORY_UI_HIDDEN = 20`).
constexpr int kTrimMemoryRunningLow = 10;

// Default Dataspace for ASurfaceTransaction_setColor
// (ADATASPACE_SRGB_LINEAR = 512).
constexpr int32_t kDefaultDataspaceSrgbLinear = 512;

// Default fallback swapchain dimensions when neither surface capabilities nor
// caller dimensions specify a positive extent.
constexpr uint32_t kDefaultSwapchainWidth = 1;
constexpr uint32_t kDefaultSwapchainHeight = 1;

// Minimum swapchain image count requested when surface capabilities report 0.
constexpr uint32_t kMinimumSwapchainImageCount = 2;

// Single image array layer for standard 2D swapchains.
constexpr uint32_t kSingleImageArrayLayer = 1;

// Single mip level for swapchain image layout transition barriers.
constexpr uint32_t kSingleMipLevel = 1;

// Default queue priority for the single graphics/present queue.
constexpr float kDefaultQueuePriority = 1.0f;

// Infinite timeout in nanoseconds for vkAcquireNextImageKHR / vkWaitForFences.
constexpr uint64_t kVulkanInfiniteTimeoutNs =
    std::numeric_limits<uint64_t>::max();

// Boolean true constant in Vulkan (`VK_TRUE = 1`, `VK_FALSE = 0`).
constexpr uint32_t kVkTrue = 1u;
constexpr uint32_t kVkFalse = 0u;

// Default synthetic fence fd returned when HCPP runs in a mock/test environment
// that does not register `vkGetSemaphoreFdKHR` or provides a stubbed fd.
constexpr int kInvalidFenceFd = -1;

// Known bad SoC board names from `android_context_vk_impeller.cc`.
constexpr std::array<const char*, 16> kBadSocs = {
    "exynos7870", "exynos7880", "exynos7872", "exynos7884",
    "exynos7885", "exynos7904", "exynos8890", "exynos8895",
    "exynos9609", "exynos9610", "exynos9611", "exynos9810",
    "exynos9820", "exynos9825", "rk30sdk",    "achilles6",
};

// Required Vulkan instance extensions on Android.
constexpr std::array<const char*, 2> kRequiredInstanceExtensions = {
    "VK_KHR_surface",
    "VK_KHR_android_surface",
};

// Required Vulkan device extensions for Impeller on Android (`CapabilitiesVK`).
constexpr std::array<const char*, 6> kRequiredDeviceExtensions = {
    "VK_KHR_swapchain",
    "VK_ANDROID_external_memory_android_hardware_buffer",
    "VK_KHR_sampler_ycbcr_conversion",
    "VK_KHR_external_memory",
    "VK_EXT_queue_family_foreign",
    "VK_KHR_dedicated_allocation",
};

// Optional external sync extensions enabled when supported by the driver.
constexpr std::array<const char*, 4> kOptionalSyncDeviceExtensions = {
    "VK_KHR_external_fence",
    "VK_KHR_external_fence_fd",
    "VK_KHR_external_semaphore",
    "VK_KHR_external_semaphore_fd",
};

bool HasExtension(const std::vector<VkExtensionPropertiesCompat>& available,
                  const char* target_name) {
  if (target_name == nullptr) {
    return false;
  }
  for (const auto& ext : available) {
    if (std::strcmp(ext.extensionName, target_name) == 0) {
      return true;
    }
  }
  return false;
}

template <typename FnPtr>
FnPtr ResolveSymbolAs(OSLibrary* library, const char* name) {
  if (library == nullptr || name == nullptr) {
    return nullptr;
  }
  return reinterpret_cast<FnPtr>(library->ResolveSymbol(name));
}

bool OpenGLNoOpMakeCurrent(void* /*user_data*/) {
  return true;
}

bool OpenGLNoOpClearCurrent(void* /*user_data*/) {
  return true;
}

bool OpenGLNoOpPresent(void* /*user_data*/) {
  return true;
}

uint32_t OpenGLDefaultFboCallback(void* /*user_data*/) {
  return 0u;
}

void* OpenGLDefaultProcResolver(void* /*user_data*/, const char* /*name*/) {
  return nullptr;
}

}  // namespace

// =============================================================================
// AndroidSurfaceControl
// =============================================================================

AndroidSurfaceControl::AndroidSurfaceControl(
    std::shared_ptr<OSLibraryLoader> library_loader,
    std::shared_ptr<AndroidSurfaceControlProvider> surface_control_provider)
    : library_loader_(library_loader != nullptr
                          ? std::move(library_loader)
                          : std::make_shared<DefaultOSLibraryLoader>()),
      surface_control_provider_(std::move(surface_control_provider)) {
  proc_table_.struct_size = sizeof(FlutterEngineProcTable);
}

AndroidSurfaceControl::AndroidSurfaceControl(const std::string& debug_name,
                                             void* raw_handle)
    : debug_name_(debug_name),
      raw_handle_(raw_handle),
      library_loader_(std::make_shared<DefaultOSLibraryLoader>()) {
  proc_table_.struct_size = sizeof(FlutterEngineProcTable);
}

AndroidSurfaceControl::~AndroidSurfaceControl() {
  std::lock_guard<std::mutex> lock(mutex_);
  TeardownVulkanLocked();
}

bool AndroidSurfaceControl::IsValid() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return raw_handle_ != nullptr || HasAnySurfaceLocked();
}

void* AndroidSurfaceControl::RawHandle() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return raw_handle_;
}

const std::string& AndroidSurfaceControl::DebugName() const {
  return debug_name_;
}

void AndroidSurfaceControl::SetEngineProcTable(
    const FlutterEngineProcTable& proc_table,
    FLUTTER_API_SYMBOL(FlutterEngine) engine) {
  std::lock_guard<std::mutex> lock(mutex_);
  proc_table_ = proc_table;
  engine_ = engine;
}

void AndroidSurfaceControl::SetSystemPropertiesForVulkan(
    const AndroidSystemPropertiesForVulkan& props) {
  std::lock_guard<std::mutex> lock(mutex_);
  system_props_ = props;
}

const AndroidSystemPropertiesForVulkan&
AndroidSurfaceControl::GetSystemPropertiesForVulkan() const {
  return system_props_;
}

AndroidVulkanResolutionStatus AndroidSurfaceControl::EvaluateSystemProperties(
    const AndroidSystemPropertiesForVulkan& props) {
  if (props.force_opengles) {
    return AndroidVulkanResolutionStatus::kForceOpenGLES;
  }
  if (!props.impeller_enabled) {
    return AndroidVulkanResolutionStatus::kImpellerDisabled;
  }
  if (props.api_level < kMinVulkanAndroidApiLevel) {
    return AndroidVulkanResolutionStatus::kApiLevelTooLow;
  }

  // Emulator detection matching `IsDeviceEmulator()` in
  // `android_context_vk_impeller.cc`.
  if (props.has_qemu_pipe || props.ro_hardware == "goldfish" ||
      props.ro_hardware == "ranchu" || props.ro_hardware == "qemu" ||
      props.ro_product_model.find("gphone") != std::string::npos) {
    return AndroidVulkanResolutionStatus::kEmulatorDetected;
  }

  // Huawei device fallback (`ro.com.google.clientidbase == "android-huawei"`).
  if (props.ro_clientidbase == "android-huawei") {
    return AndroidVulkanResolutionStatus::kHuaweiClientIdRejected;
  }

  // MediaTek platform check (`ro.vendor.build.version.sdk < 32` when
  // `ro.vendor.mediatek.platform` is non-empty).
  if (!props.ro_mediatek_platform.empty() && props.vendor_api_level > 0 &&
      props.vendor_api_level < kMinMediaTekVendorApiLevel) {
    return AndroidVulkanResolutionStatus::kMediaTekVendorSdkTooLow;
  }

  // Known bad SoC boards (`kBadSocs`).
  if (!props.ro_product_board.empty()) {
    for (const char* bad_soc : kBadSocs) {
      if (props.ro_product_board == bad_soc) {
        return AndroidVulkanResolutionStatus::kBadSocBoardRejected;
      }
    }
  }

  return AndroidVulkanResolutionStatus::kSelectedVulkan;
}

void AndroidSurfaceControl::PopulateDeferredRendererConfig(
    FlutterRendererConfig* config_out) {
  if (config_out == nullptr) {
    return;
  }
  std::memset(config_out, 0, sizeof(FlutterRendererConfig));
  config_out->type = kDeferred;
  config_out->deferred.struct_size = sizeof(FlutterDeferredRendererConfig);
  config_out->deferred.resolve_callback =
      &AndroidSurfaceControl::ResolveRendererConfigCallback;
}

bool AndroidSurfaceControl::ResolveRendererConfigCallback(
    void* user_data,
    FlutterRendererConfig* config_out) {
  if (user_data == nullptr || config_out == nullptr) {
    return false;
  }
  auto* self = static_cast<AndroidSurfaceControl*>(user_data);
  return self->ResolveRendererConfig(config_out);
}

bool AndroidSurfaceControl::ResolveRendererConfig(
    FlutterRendererConfig* config_out) {
  if (config_out == nullptr) {
    return false;
  }
  std::lock_guard<std::mutex> lock(mutex_);
  std::memset(config_out, 0, sizeof(FlutterRendererConfig));

  if (InitializeVulkanOnRasterThreadLocked()) {
    resolved_renderer_type_ = kVulkan;
    config_out->type = kVulkan;
    config_out->vulkan.struct_size = sizeof(FlutterVulkanRendererConfig);
    config_out->vulkan.version = kVkApiVersion11;
    config_out->vulkan.instance = vk_instance_;
    config_out->vulkan.physical_device = vk_physical_device_;
    config_out->vulkan.device = vk_device_;
    config_out->vulkan.queue_family_index = vk_queue_family_index_;
    config_out->vulkan.queue = vk_queue_;
    config_out->vulkan.enabled_instance_extension_count =
        enabled_instance_extension_ptrs_.size();
    config_out->vulkan.enabled_instance_extensions =
        enabled_instance_extension_ptrs_.empty()
            ? nullptr
            : enabled_instance_extension_ptrs_.data();
    config_out->vulkan.enabled_device_extension_count =
        enabled_device_extension_ptrs_.size();
    config_out->vulkan.enabled_device_extensions =
        enabled_device_extension_ptrs_.empty()
            ? nullptr
            : enabled_device_extension_ptrs_.data();
    config_out->vulkan.get_instance_proc_address_callback =
        &AndroidSurfaceControl::GetInstanceProcAddressCallback;
    config_out->vulkan.get_next_image_callback =
        &AndroidSurfaceControl::GetNextImageCallback;
    config_out->vulkan.present_image_callback =
        &AndroidSurfaceControl::PresentImageCallback;
    config_out->vulkan.external_texture_frame_callback =
        vulkan_external_texture_callback_;
    return true;
  }

  TeardownVulkanLocked();
  return InitializeOpenGLFallbackLocked(config_out);
}

AndroidVulkanResolutionStatus
AndroidSurfaceControl::LastVulkanResolutionStatus() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return last_vulkan_status_;
}

FlutterRendererType AndroidSurfaceControl::ResolvedRendererType() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return resolved_renderer_type_;
}

void* AndroidSurfaceControl::GetVulkanInstance() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return vk_instance_;
}

void* AndroidSurfaceControl::GetVulkanPhysicalDevice() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return vk_physical_device_;
}

void* AndroidSurfaceControl::GetVulkanDevice() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return vk_device_;
}

void* AndroidSurfaceControl::GetVulkanQueue() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return vk_queue_;
}

uint32_t AndroidSurfaceControl::GetVulkanQueueFamilyIndex() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return vk_queue_family_index_;
}

void AndroidSurfaceControl::SetVulkanExternalTextureCallback(
    FlutterVulkanTextureFrameCallback callback) {
  std::lock_guard<std::mutex> lock(mutex_);
  vulkan_external_texture_callback_ = callback;
}

void AndroidSurfaceControl::SetOpenGLExternalTextureCallback(
    FlutterOpenGLTextureFrameCallback callback) {
  std::lock_guard<std::mutex> lock(mutex_);
  opengl_external_texture_callback_ = callback;
}

bool AndroidSurfaceControl::InitializeVulkanOnRasterThreadLocked() {
  const AndroidVulkanResolutionStatus prop_status =
      EvaluateSystemProperties(system_props_);
  if (prop_status != AndroidVulkanResolutionStatus::kSelectedVulkan) {
    last_vulkan_status_ = prop_status;
    return false;
  }

  if (library_loader_ == nullptr) {
    last_vulkan_status_ =
        AndroidVulkanResolutionStatus::kVulkanLibraryUnavailable;
    return false;
  }

  vulkan_library_ = library_loader_->Load("libvulkan.so");
  if (vulkan_library_ == nullptr) {
    vulkan_library_ = library_loader_->Load("libvulkan.so.1");
  }
  if (vulkan_library_ == nullptr) {
    last_vulkan_status_ =
        AndroidVulkanResolutionStatus::kVulkanLibraryUnavailable;
    return false;
  }

  vk_get_instance_proc_addr_fn_ = ResolveSymbolAs<PFN_vkGetInstanceProcAddr>(
      vulkan_library_.get(), "vkGetInstanceProcAddr");
  if (vk_get_instance_proc_addr_fn_ == nullptr) {
    last_vulkan_status_ =
        AndroidVulkanResolutionStatus::kVulkanLibraryUnavailable;
    return false;
  }

  auto resolve_global_proc = [this](const char* name) -> void* {
    if (vk_get_instance_proc_addr_fn_ == nullptr) {
      return nullptr;
    }
    void* sym = vk_get_instance_proc_addr_fn_(nullptr, name);
    if (sym == nullptr && vulkan_library_ != nullptr) {
      sym = vulkan_library_->ResolveSymbol(name);
    }
    return sym;
  };

  vk_enumerate_instance_extension_properties_fn_ =
      reinterpret_cast<PFN_vkEnumerateInstanceExtensionProperties>(
          resolve_global_proc("vkEnumerateInstanceExtensionProperties"));
  vk_create_instance_fn_ = reinterpret_cast<PFN_vkCreateInstance>(
      resolve_global_proc("vkCreateInstance"));

  if (vk_enumerate_instance_extension_properties_fn_ == nullptr ||
      vk_create_instance_fn_ == nullptr) {
    last_vulkan_status_ =
        AndroidVulkanResolutionStatus::kVulkanLibraryUnavailable;
    return false;
  }

  uint32_t instance_ext_count = 0;
  if (vk_enumerate_instance_extension_properties_fn_(
          nullptr, &instance_ext_count, nullptr) != kVkSuccess ||
      instance_ext_count == 0) {
    last_vulkan_status_ =
        AndroidVulkanResolutionStatus::kInstanceExtensionsMissing;
    return false;
  }
  std::vector<VkExtensionPropertiesCompat> instance_exts(instance_ext_count);
  if (vk_enumerate_instance_extension_properties_fn_(
          nullptr, &instance_ext_count, instance_exts.data()) != kVkSuccess) {
    last_vulkan_status_ =
        AndroidVulkanResolutionStatus::kInstanceExtensionsMissing;
    return false;
  }

  enabled_instance_extensions_.clear();
  enabled_instance_extension_ptrs_.clear();
  for (const char* req_ext : kRequiredInstanceExtensions) {
    if (!HasExtension(instance_exts, req_ext)) {
      last_vulkan_status_ =
          AndroidVulkanResolutionStatus::kInstanceExtensionsMissing;
      return false;
    }
    enabled_instance_extensions_.emplace_back(req_ext);
  }
  for (const auto& ext : enabled_instance_extensions_) {
    enabled_instance_extension_ptrs_.push_back(ext.c_str());
  }

  VkApplicationInfoCompat app_info = {};
  app_info.sType = kVkStructureTypeApplicationInfo;
  app_info.pApplicationName = "Flutter";
  app_info.applicationVersion = kVkApiVersion11;
  app_info.pEngineName = "Impeller";
  app_info.engineVersion = kVkApiVersion11;
  app_info.apiVersion = kVkApiVersion11;

  VkInstanceCreateInfoCompat instance_info = {};
  instance_info.sType = kVkStructureTypeInstanceCreateInfo;
  instance_info.pApplicationInfo = &app_info;
  instance_info.enabledExtensionCount =
      static_cast<uint32_t>(enabled_instance_extension_ptrs_.size());
  instance_info.ppEnabledExtensionNames =
      enabled_instance_extension_ptrs_.data();

  if (vk_create_instance_fn_(&instance_info, nullptr, &vk_instance_) !=
          kVkSuccess ||
      vk_instance_ == nullptr) {
    last_vulkan_status_ =
        AndroidVulkanResolutionStatus::kInstanceCreationFailed;
    return false;
  }

  auto resolve_instance_proc = [this](const char* name) -> void* {
    if (vk_get_instance_proc_addr_fn_ == nullptr) {
      return nullptr;
    }
    void* sym = vk_get_instance_proc_addr_fn_(vk_instance_, name);
    if (sym == nullptr && vulkan_library_ != nullptr) {
      sym = vulkan_library_->ResolveSymbol(name);
    }
    return sym;
  };

  vk_destroy_instance_fn_ = reinterpret_cast<PFN_vkDestroyInstance>(
      resolve_instance_proc("vkDestroyInstance"));
  vk_enumerate_physical_devices_fn_ =
      reinterpret_cast<PFN_vkEnumeratePhysicalDevices>(
          resolve_instance_proc("vkEnumeratePhysicalDevices"));
  vk_get_physical_device_properties_fn_ =
      reinterpret_cast<PFN_vkGetPhysicalDeviceProperties>(
          resolve_instance_proc("vkGetPhysicalDeviceProperties"));
  vk_get_physical_device_format_properties_fn_ =
      reinterpret_cast<PFN_vkGetPhysicalDeviceFormatProperties>(
          resolve_instance_proc("vkGetPhysicalDeviceFormatProperties"));
  vk_get_physical_device_queue_family_properties_fn_ =
      reinterpret_cast<PFN_vkGetPhysicalDeviceQueueFamilyProperties>(
          resolve_instance_proc("vkGetPhysicalDeviceQueueFamilyProperties"));
  vk_get_physical_device_features_2_fn_ =
      reinterpret_cast<PFN_vkGetPhysicalDeviceFeatures2>(
          resolve_instance_proc("vkGetPhysicalDeviceFeatures2"));
  if (vk_get_physical_device_features_2_fn_ == nullptr) {
    vk_get_physical_device_features_2_fn_ =
        reinterpret_cast<PFN_vkGetPhysicalDeviceFeatures2>(
            resolve_instance_proc("vkGetPhysicalDeviceFeatures2KHR"));
  }
  vk_enumerate_device_extension_properties_fn_ =
      reinterpret_cast<PFN_vkEnumerateDeviceExtensionProperties>(
          resolve_instance_proc("vkEnumerateDeviceExtensionProperties"));
  vk_create_device_fn_ = reinterpret_cast<PFN_vkCreateDevice>(
      resolve_instance_proc("vkCreateDevice"));
  vk_get_device_proc_addr_fn_ = reinterpret_cast<PFN_vkGetDeviceProcAddr>(
      resolve_instance_proc("vkGetDeviceProcAddr"));
  vk_create_android_surface_khr_fn_ =
      reinterpret_cast<PFN_vkCreateAndroidSurfaceKHR>(
          resolve_instance_proc("vkCreateAndroidSurfaceKHR"));
  vk_destroy_surface_khr_fn_ = reinterpret_cast<PFN_vkDestroySurfaceKHR>(
      resolve_instance_proc("vkDestroySurfaceKHR"));
  vk_get_physical_device_surface_capabilities_khr_fn_ =
      reinterpret_cast<PFN_vkGetPhysicalDeviceSurfaceCapabilitiesKHR>(
          resolve_instance_proc("vkGetPhysicalDeviceSurfaceCapabilitiesKHR"));
  vk_get_physical_device_surface_formats_khr_fn_ =
      reinterpret_cast<PFN_vkGetPhysicalDeviceSurfaceFormatsKHR>(
          resolve_instance_proc("vkGetPhysicalDeviceSurfaceFormatsKHR"));

  if (vk_enumerate_physical_devices_fn_ == nullptr ||
      vk_get_physical_device_properties_fn_ == nullptr ||
      vk_get_physical_device_format_properties_fn_ == nullptr ||
      vk_get_physical_device_queue_family_properties_fn_ == nullptr ||
      vk_enumerate_device_extension_properties_fn_ == nullptr ||
      vk_create_device_fn_ == nullptr) {
    last_vulkan_status_ =
        AndroidVulkanResolutionStatus::kVulkanLibraryUnavailable;
    return false;
  }

  uint32_t phys_device_count = 0;
  if (vk_enumerate_physical_devices_fn_(vk_instance_, &phys_device_count,
                                        nullptr) != kVkSuccess ||
      phys_device_count == 0) {
    last_vulkan_status_ = AndroidVulkanResolutionStatus::kNoPhysicalDevice;
    return false;
  }
  std::vector<void*> phys_devices(phys_device_count, nullptr);
  if (vk_enumerate_physical_devices_fn_(vk_instance_, &phys_device_count,
                                        phys_devices.data()) != kVkSuccess ||
      phys_devices[0] == nullptr) {
    last_vulkan_status_ = AndroidVulkanResolutionStatus::kNoPhysicalDevice;
    return false;
  }
  vk_physical_device_ = phys_devices[0];

  // Query VkPhysicalDeviceProperties and check `flutter::VulkanDriverInfo`.
  VkPhysicalDevicePropertiesCompat phys_props = {};
  vk_get_physical_device_properties_fn_(vk_physical_device_, &phys_props);
  const flutter::VulkanDriverInfo driver_info(phys_props);
  if (driver_info.IsKnownBadDriver()) {
    last_vulkan_status_ = AndroidVulkanResolutionStatus::kKnownBadVulkanDriver;
    return false;
  }
  if (driver_info.IsEmulator()) {
    last_vulkan_status_ = AndroidVulkanResolutionStatus::kEmulatorDetected;
    return false;
  }

  // Check required sample counts (`VK_SAMPLE_COUNT_1_BIT |
  // VK_SAMPLE_COUNT_4_BIT`).
  constexpr uint32_t kRequiredSampleCounts =
      kVkSampleCount1Bit | kVkSampleCount4Bit;
  if ((phys_props.limits.framebufferColorSampleCounts &
       kRequiredSampleCounts) != kRequiredSampleCounts) {
    last_vulkan_status_ =
        AndroidVulkanResolutionStatus::kRequiredSampleCountsUnsupported;
    return false;
  }

  // Check required device extensions (`CapabilitiesVK`).
  uint32_t dev_ext_count = 0;
  if (vk_enumerate_device_extension_properties_fn_(vk_physical_device_, nullptr,
                                                   &dev_ext_count,
                                                   nullptr) != kVkSuccess ||
      dev_ext_count == 0) {
    last_vulkan_status_ =
        AndroidVulkanResolutionStatus::kDeviceExtensionsMissing;
    return false;
  }
  std::vector<VkExtensionPropertiesCompat> dev_exts(dev_ext_count);
  if (vk_enumerate_device_extension_properties_fn_(
          vk_physical_device_, nullptr, &dev_ext_count, dev_exts.data()) !=
      kVkSuccess) {
    last_vulkan_status_ =
        AndroidVulkanResolutionStatus::kDeviceExtensionsMissing;
    return false;
  }

  enabled_device_extensions_.clear();
  enabled_device_extension_ptrs_.clear();
  for (const char* req_ext : kRequiredDeviceExtensions) {
    if (!HasExtension(dev_exts, req_ext)) {
      last_vulkan_status_ =
          AndroidVulkanResolutionStatus::kDeviceExtensionsMissing;
      return false;
    }
    enabled_device_extensions_.emplace_back(req_ext);
  }
  for (const char* opt_ext : kOptionalSyncDeviceExtensions) {
    if (HasExtension(dev_exts, opt_ext)) {
      enabled_device_extensions_.emplace_back(opt_ext);
    }
  }
  for (const auto& ext : enabled_device_extensions_) {
    enabled_device_extension_ptrs_.push_back(ext.c_str());
  }

  // Check required color format (`VK_FORMAT_R8G8B8A8_UNORM` optimal tiling
  // color attachment).
  VkFormatPropertiesCompat color_format_props = {};
  vk_get_physical_device_format_properties_fn_(
      vk_physical_device_, kVkFormatR8G8B8A8Unorm, &color_format_props);
  if ((color_format_props.optimalTilingFeatures &
       kVkFormatFeatureColorAttachmentBit) == 0) {
    last_vulkan_status_ =
        AndroidVulkanResolutionStatus::kRequiredColorFormatUnsupported;
    return false;
  }

  // Check required depth-stencil format (`D32_SFLOAT_S8_UINT` or
  // `D24_UNORM_S8_UINT`).
  VkFormatPropertiesCompat d32_s8_props = {};
  VkFormatPropertiesCompat d24_s8_props = {};
  vk_get_physical_device_format_properties_fn_(
      vk_physical_device_, kVkFormatD32SfloatS8Uint, &d32_s8_props);
  vk_get_physical_device_format_properties_fn_(
      vk_physical_device_, kVkFormatD24UnormS8Uint, &d24_s8_props);
  const bool has_depth_stencil =
      ((d32_s8_props.optimalTilingFeatures &
        kVkFormatFeatureDepthStencilAttachmentBit) != 0) ||
      ((d24_s8_props.optimalTilingFeatures &
        kVkFormatFeatureDepthStencilAttachmentBit) != 0);
  if (!has_depth_stencil) {
    last_vulkan_status_ =
        AndroidVulkanResolutionStatus::kRequiredDepthStencilFormatUnsupported;
    return false;
  }

  // Check required queue family flags (`GRAPHICS | COMPUTE | TRANSFER`).
  uint32_t queue_family_count = 0;
  vk_get_physical_device_queue_family_properties_fn_(
      vk_physical_device_, &queue_family_count, nullptr);
  if (queue_family_count == 0) {
    last_vulkan_status_ = AndroidVulkanResolutionStatus::kRequiredQueuesMissing;
    return false;
  }
  std::vector<VkQueueFamilyPropertiesCompat> queue_families(queue_family_count);
  vk_get_physical_device_queue_family_properties_fn_(
      vk_physical_device_, &queue_family_count, queue_families.data());

  uint32_t combined_queue_flags = 0;
  bool found_graphics_queue = false;
  for (uint32_t i = 0; i < queue_family_count; ++i) {
    if (queue_families[i].queueCount == 0) {
      continue;
    }
    combined_queue_flags |= queue_families[i].queueFlags;
    if (!found_graphics_queue &&
        (queue_families[i].queueFlags & kVkQueueGraphicsBit) != 0) {
      vk_queue_family_index_ = i;
      found_graphics_queue = true;
    }
  }
  constexpr uint32_t kRequiredQueueFlags =
      kVkQueueGraphicsBit | kVkQueueComputeBit | kVkQueueTransferBit;
  if (!found_graphics_queue ||
      (combined_queue_flags & kRequiredQueueFlags) != kRequiredQueueFlags) {
    last_vulkan_status_ = AndroidVulkanResolutionStatus::kRequiredQueuesMissing;
    return false;
  }

  // Query and chain physical device features (`samplerYcbcrConversion` and
  // `uniformAndStorageBuffer16BitAccess`).
  VkPhysicalDevice16BitStorageFeaturesCompat storage_16bit_features = {};
  storage_16bit_features.sType =
      kVkStructureTypePhysicalDevice16BitStorageFeatures;
  storage_16bit_features.pNext = nullptr;
  storage_16bit_features.uniformAndStorageBuffer16BitAccess = kVkTrue;

  VkPhysicalDeviceSamplerYcbcrConversionFeaturesCompat ycbcr_features = {};
  ycbcr_features.sType =
      kVkStructureTypePhysicalDeviceSamplerYcbcrConversionFeatures;
  ycbcr_features.pNext = &storage_16bit_features;
  ycbcr_features.samplerYcbcrConversion = kVkTrue;

  VkPhysicalDeviceFeatures2Compat features2 = {};
  features2.sType = kVkStructureTypePhysicalDeviceFeatures2;
  features2.pNext = &ycbcr_features;

  if (vk_get_physical_device_features_2_fn_ != nullptr) {
    ycbcr_features.samplerYcbcrConversion = kVkFalse;
    storage_16bit_features.uniformAndStorageBuffer16BitAccess = kVkFalse;
    vk_get_physical_device_features_2_fn_(vk_physical_device_, &features2);
    if (ycbcr_features.samplerYcbcrConversion == kVkFalse ||
        storage_16bit_features.uniformAndStorageBuffer16BitAccess == kVkFalse) {
      last_vulkan_status_ =
          AndroidVulkanResolutionStatus::kRequiredFeaturesUnsupported;
      return false;
    }
  }

  const float queue_priority = kDefaultQueuePriority;
  VkDeviceQueueCreateInfoCompat queue_info = {};
  queue_info.sType = kVkStructureTypeDeviceQueueCreateInfo;
  queue_info.queueFamilyIndex = vk_queue_family_index_;
  queue_info.queueCount = 1;
  queue_info.pQueuePriorities = &queue_priority;

  VkDeviceCreateInfoCompat device_info = {};
  device_info.sType = kVkStructureTypeDeviceCreateInfo;
  device_info.pNext = &features2;
  device_info.queueCreateInfoCount = 1;
  device_info.pQueueCreateInfos = &queue_info;
  device_info.enabledExtensionCount =
      static_cast<uint32_t>(enabled_device_extension_ptrs_.size());
  device_info.ppEnabledExtensionNames = enabled_device_extension_ptrs_.data();

  if (vk_create_device_fn_(vk_physical_device_, &device_info, nullptr,
                           &vk_device_) != kVkSuccess ||
      vk_device_ == nullptr) {
    last_vulkan_status_ = AndroidVulkanResolutionStatus::kDeviceCreationFailed;
    return false;
  }

  auto resolve_device_proc =
      [this, &resolve_instance_proc](const char* name) -> void* {
    if (vk_get_device_proc_addr_fn_ != nullptr && vk_device_ != nullptr) {
      void* sym = vk_get_device_proc_addr_fn_(vk_device_, name);
      if (sym != nullptr) {
        return sym;
      }
    }
    return resolve_instance_proc(name);
  };

  vk_destroy_device_fn_ = reinterpret_cast<PFN_vkDestroyDevice>(
      resolve_device_proc("vkDestroyDevice"));
  vk_get_device_queue_fn_ = reinterpret_cast<PFN_vkGetDeviceQueue>(
      resolve_device_proc("vkGetDeviceQueue"));
  vk_create_swapchain_khr_fn_ = reinterpret_cast<PFN_vkCreateSwapchainKHR>(
      resolve_device_proc("vkCreateSwapchainKHR"));
  vk_destroy_swapchain_khr_fn_ = reinterpret_cast<PFN_vkDestroySwapchainKHR>(
      resolve_device_proc("vkDestroySwapchainKHR"));
  vk_get_swapchain_images_khr_fn_ =
      reinterpret_cast<PFN_vkGetSwapchainImagesKHR>(
          resolve_device_proc("vkGetSwapchainImagesKHR"));
  vk_acquire_next_image_khr_fn_ = reinterpret_cast<PFN_vkAcquireNextImageKHR>(
      resolve_device_proc("vkAcquireNextImageKHR"));
  vk_queue_present_khr_fn_ = reinterpret_cast<PFN_vkQueuePresentKHR>(
      resolve_device_proc("vkQueuePresentKHR"));
  vk_queue_submit_fn_ =
      reinterpret_cast<PFN_vkQueueSubmit>(resolve_device_proc("vkQueueSubmit"));
  vk_queue_wait_idle_fn_ = reinterpret_cast<PFN_vkQueueWaitIdle>(
      resolve_device_proc("vkQueueWaitIdle"));
  vk_create_fence_fn_ =
      reinterpret_cast<PFN_vkCreateFence>(resolve_device_proc("vkCreateFence"));
  vk_destroy_fence_fn_ = reinterpret_cast<PFN_vkDestroyFence>(
      resolve_device_proc("vkDestroyFence"));
  vk_wait_for_fences_fn_ = reinterpret_cast<PFN_vkWaitForFences>(
      resolve_device_proc("vkWaitForFences"));
  vk_reset_fences_fn_ =
      reinterpret_cast<PFN_vkResetFences>(resolve_device_proc("vkResetFences"));
  vk_create_semaphore_fn_ = reinterpret_cast<PFN_vkCreateSemaphore>(
      resolve_device_proc("vkCreateSemaphore"));
  vk_destroy_semaphore_fn_ = reinterpret_cast<PFN_vkDestroySemaphore>(
      resolve_device_proc("vkDestroySemaphore"));
  vk_get_semaphore_fd_khr_fn_ = reinterpret_cast<PFN_vkGetSemaphoreFdKHR>(
      resolve_device_proc("vkGetSemaphoreFdKHR"));
  vk_create_command_pool_fn_ = reinterpret_cast<PFN_vkCreateCommandPool>(
      resolve_device_proc("vkCreateCommandPool"));
  vk_destroy_command_pool_fn_ = reinterpret_cast<PFN_vkDestroyCommandPool>(
      resolve_device_proc("vkDestroyCommandPool"));
  vk_allocate_command_buffers_fn_ =
      reinterpret_cast<PFN_vkAllocateCommandBuffers>(
          resolve_device_proc("vkAllocateCommandBuffers"));
  vk_reset_command_buffer_fn_ = reinterpret_cast<PFN_vkResetCommandBuffer>(
      resolve_device_proc("vkResetCommandBuffer"));
  vk_begin_command_buffer_fn_ = reinterpret_cast<PFN_vkBeginCommandBuffer>(
      resolve_device_proc("vkBeginCommandBuffer"));
  vk_end_command_buffer_fn_ = reinterpret_cast<PFN_vkEndCommandBuffer>(
      resolve_device_proc("vkEndCommandBuffer"));
  vk_cmd_pipeline_barrier_fn_ = reinterpret_cast<PFN_vkCmdPipelineBarrier>(
      resolve_device_proc("vkCmdPipelineBarrier"));

  if (vk_get_device_queue_fn_ == nullptr) {
    last_vulkan_status_ = AndroidVulkanResolutionStatus::kDeviceCreationFailed;
    return false;
  }

  vk_get_device_queue_fn_(vk_device_, vk_queue_family_index_, 0, &vk_queue_);
  if (vk_queue_ == nullptr) {
    last_vulkan_status_ = AndroidVulkanResolutionStatus::kDeviceCreationFailed;
    return false;
  }

  last_vulkan_status_ = AndroidVulkanResolutionStatus::kSelectedVulkan;
  return true;
}

bool AndroidSurfaceControl::InitializeOpenGLFallbackLocked(
    FlutterRendererConfig* config_out) {
  if (config_out == nullptr) {
    return false;
  }
  if (library_loader_ != nullptr) {
    if (egl_library_ == nullptr) {
      egl_library_ = library_loader_->Load("libEGL.so");
    }
    if (gles_library_ == nullptr) {
      gles_library_ = library_loader_->Load("libGLESv2.so");
    }
  }

  resolved_renderer_type_ = kOpenGL;
  config_out->type = kOpenGL;
  config_out->open_gl.struct_size = sizeof(FlutterOpenGLRendererConfig);
  config_out->open_gl.make_current = &OpenGLNoOpMakeCurrent;
  config_out->open_gl.clear_current = &OpenGLNoOpClearCurrent;
  config_out->open_gl.present = &OpenGLNoOpPresent;
  config_out->open_gl.fbo_callback = &OpenGLDefaultFboCallback;
  config_out->open_gl.make_resource_current = &OpenGLNoOpMakeCurrent;
  config_out->open_gl.fbo_reset_after_present = true;
  config_out->open_gl.gl_proc_resolver = &OpenGLDefaultProcResolver;
  config_out->open_gl.external_texture_frame_callback =
      opengl_external_texture_callback_;
  return true;
}

// =============================================================================
// Per-FlutterViewId Surface Lifecycle
// =============================================================================

bool AndroidSurfaceControl::SurfaceCreated(FlutterViewId view_id,
                                           void* native_window,
                                           void* surface_control,
                                           uint32_t width,
                                           uint32_t height) {
  if (native_window == nullptr) {
    return false;
  }
  std::lock_guard<std::mutex> lock(mutex_);
  auto& state = view_surfaces_[view_id];
  if (state.native_window != nullptr && state.native_window != native_window) {
    DestroyVulkanSwapchainLocked(state);
    DestroyVulkanSurfaceLocked(state);
  }
  state.view_id = view_id;
  state.native_window = native_window;
  state.surface_control = surface_control;
  state.width = width;
  state.height = height;
  state.vk_pre_transform = kVkSurfaceTransformIdentityBitKhr;
  state.swapchain_needs_recreation = true;
  active_acquire_view_id_ = view_id;
  return true;
}

bool AndroidSurfaceControl::SurfaceCreated(void* native_window,
                                           uint32_t width,
                                           uint32_t height) {
  return SurfaceCreated(kAndroidImplicitViewId, native_window, nullptr, width,
                        height);
}

bool AndroidSurfaceControl::SurfaceWindowChanged(FlutterViewId view_id,
                                                 void* native_window,
                                                 void* surface_control,
                                                 uint32_t width,
                                                 uint32_t height) {
  if (native_window == nullptr) {
    SurfaceDestroyed(view_id);
    return false;
  }
  std::lock_guard<std::mutex> lock(mutex_);
  auto& state = view_surfaces_[view_id];
  DestroyVulkanSwapchainLocked(state);
  DestroyVulkanSurfaceLocked(state);
  state.view_id = view_id;
  state.native_window = native_window;
  state.surface_control = surface_control;
  if (width > 0) {
    state.width = width;
  }
  if (height > 0) {
    state.height = height;
  }
  state.vk_pre_transform = kVkSurfaceTransformIdentityBitKhr;
  state.swapchain_needs_recreation = true;
  active_acquire_view_id_ = view_id;
  return true;
}

bool AndroidSurfaceControl::SurfaceChanged(FlutterViewId view_id,
                                           uint32_t width,
                                           uint32_t height) {
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = view_surfaces_.find(view_id);
  if (it == view_surfaces_.end() || it->second.native_window == nullptr) {
    return false;
  }
  it->second.width = width;
  it->second.height = height;
  it->second.swapchain_needs_recreation = true;
  return true;
}

bool AndroidSurfaceControl::SurfaceChanged(uint32_t width, uint32_t height) {
  return SurfaceChanged(kAndroidImplicitViewId, width, height);
}

void AndroidSurfaceControl::SurfaceDestroyed(FlutterViewId view_id) {
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = view_surfaces_.find(view_id);
  if (it != view_surfaces_.end()) {
    DestroyVulkanSwapchainLocked(it->second);
    DestroyVulkanSurfaceLocked(it->second);
    view_surfaces_.erase(it);
  }
  if (!HasAnySurfaceLocked()) {
    DispatchLowMemoryWarningLocked();
  }
}

void AndroidSurfaceControl::SurfaceDestroyed() {
  SurfaceDestroyed(kAndroidImplicitViewId);
}

void AndroidSurfaceControl::OnTrimMemory(int level) {
  if (level < kTrimMemoryRunningLow) {
    return;
  }
  std::lock_guard<std::mutex> lock(mutex_);
  DispatchLowMemoryWarningLocked();
}

size_t AndroidSurfaceControl::LowMemoryWarningCount() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return low_memory_warning_count_;
}

bool AndroidSurfaceControl::HasSurface(FlutterViewId view_id) const {
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = view_surfaces_.find(view_id);
  return it != view_surfaces_.end() && it->second.native_window != nullptr;
}

void* AndroidSurfaceControl::GetNativeWindow(FlutterViewId view_id) const {
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = view_surfaces_.find(view_id);
  return it != view_surfaces_.end() ? it->second.native_window : nullptr;
}

void* AndroidSurfaceControl::GetASurfaceControl(FlutterViewId view_id) const {
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = view_surfaces_.find(view_id);
  return it != view_surfaces_.end() ? it->second.surface_control : nullptr;
}

uint32_t AndroidSurfaceControl::GetSurfaceWidth(FlutterViewId view_id) const {
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = view_surfaces_.find(view_id);
  return it != view_surfaces_.end() ? it->second.width : 0u;
}

uint32_t AndroidSurfaceControl::GetSurfaceHeight(FlutterViewId view_id) const {
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = view_surfaces_.find(view_id);
  return it != view_surfaces_.end() ? it->second.height : 0u;
}

bool AndroidSurfaceControl::HasAnySurfaceLocked() const {
  for (const auto& [view_id, state] : view_surfaces_) {
    if (state.native_window != nullptr) {
      return true;
    }
  }
  return false;
}

void AndroidSurfaceControl::DispatchLowMemoryWarningLocked() {
  ++low_memory_warning_count_;
  if (proc_table_.NotifyLowMemoryWarning != nullptr && engine_ != nullptr) {
    proc_table_.NotifyLowMemoryWarning(engine_);
  }
}

// =============================================================================
// Vulkan Swapchain, PresentImage, and HCPP Fence Export
// =============================================================================

bool AndroidSurfaceControl::EnsureSwapchainForViewLocked(
    PerViewSurfaceState& state,
    uint32_t requested_width,
    uint32_t requested_height) {
  if (state.native_window == nullptr || vk_instance_ == nullptr ||
      vk_physical_device_ == nullptr || vk_device_ == nullptr) {
    return false;
  }

  // Guard required Vulkan function pointers at entry.
  if (vk_create_android_surface_khr_fn_ == nullptr ||
      vk_get_physical_device_surface_capabilities_khr_fn_ == nullptr ||
      vk_create_swapchain_khr_fn_ == nullptr ||
      vk_get_swapchain_images_khr_fn_ == nullptr) {
    return false;
  }

  if (state.vk_surface == 0) {
    VkAndroidSurfaceCreateInfoKHRCompat surface_info = {};
    surface_info.sType = kVkStructureTypeAndroidSurfaceCreateInfoKhr;
    surface_info.window = state.native_window;
    if (vk_create_android_surface_khr_fn_(vk_instance_, &surface_info, nullptr,
                                          &state.vk_surface) != kVkSuccess ||
        state.vk_surface == 0) {
      state.vk_surface = 0;
      return false;
    }
  }

  if (state.vk_swapchain != 0 && !state.swapchain_needs_recreation) {
    return true;
  }

  VkSurfaceCapabilitiesKHRCompat caps = {};
  caps.currentTransform = kVkSurfaceTransformIdentityBitKhr;
  caps.supportedTransforms = kVkSurfaceTransformIdentityBitKhr;
  caps.supportedCompositeAlpha = kVkCompositeAlphaOpaqueBitKhr;
  if (vk_get_physical_device_surface_capabilities_khr_fn_(
          vk_physical_device_, state.vk_surface, &caps) != kVkSuccess) {
    return false;
  }

  uint32_t chosen_format = kVkFormatR8G8B8A8Unorm;
  uint32_t chosen_color_space = kVkColorSpaceSrgbNonlinearKhr;
  if (vk_get_physical_device_surface_formats_khr_fn_ != nullptr) {
    uint32_t format_count = 0;
    if (vk_get_physical_device_surface_formats_khr_fn_(
            vk_physical_device_, state.vk_surface, &format_count, nullptr) ==
            kVkSuccess &&
        format_count > 0) {
      std::vector<VkSurfaceFormatKHRCompat> formats(format_count);
      if (vk_get_physical_device_surface_formats_khr_fn_(
              vk_physical_device_, state.vk_surface, &format_count,
              formats.data()) == kVkSuccess) {
        chosen_format = formats[0].format;
        chosen_color_space = formats[0].colorSpace;
        for (const auto& fmt : formats) {
          if (fmt.format == kVkFormatR8G8B8A8Unorm) {
            chosen_format = fmt.format;
            chosen_color_space = fmt.colorSpace;
            break;
          }
        }
      }
    }
  }

  uint32_t extent_width = requested_width > 0 ? requested_width : state.width;
  uint32_t extent_height =
      requested_height > 0 ? requested_height : state.height;
  if (extent_width == 0 && caps.currentExtent.width > 0 &&
      caps.currentExtent.width != std::numeric_limits<uint32_t>::max()) {
    extent_width = caps.currentExtent.width;
  }
  if (extent_height == 0 && caps.currentExtent.height > 0 &&
      caps.currentExtent.height != std::numeric_limits<uint32_t>::max()) {
    extent_height = caps.currentExtent.height;
  }
  if (extent_width == 0) {
    extent_width = kDefaultSwapchainWidth;
  }
  if (extent_height == 0) {
    extent_height = kDefaultSwapchainHeight;
  }

  // Always set swapchain preTransform to
  // `VK_SURFACE_TRANSFORM_IDENTITY_BIT_KHR` matching
  // `KHRSwapchainImplVK::Create` (`khr_swapchain_impl_vk.cc:176`) so
  // SurfaceFlinger handles display rotation when the render pass is unrotated.
  uint32_t pre_transform = kVkSurfaceTransformIdentityBitKhr;
  state.vk_pre_transform = pre_transform;

  // Match `ChooseAlphaCompositionMode` (`khr_swapchain_impl_vk.cc:97-113`):
  // prefer Inherit (0x8), then PreMultiplied (0x2), then PostMultiplied (0x4),
  // then Opaque (0x1).
  uint32_t composite_alpha = kVkCompositeAlphaOpaqueBitKhr;
  if ((caps.supportedCompositeAlpha & kVkCompositeAlphaInheritBitKhr) != 0) {
    composite_alpha = kVkCompositeAlphaInheritBitKhr;
  } else if ((caps.supportedCompositeAlpha &
              kVkCompositeAlphaPreMultipliedBitKhr) != 0) {
    composite_alpha = kVkCompositeAlphaPreMultipliedBitKhr;
  } else if ((caps.supportedCompositeAlpha &
              kVkCompositeAlphaPostMultipliedBitKhr) != 0) {
    composite_alpha = kVkCompositeAlphaPostMultipliedBitKhr;
  } else if ((caps.supportedCompositeAlpha & kVkCompositeAlphaOpaqueBitKhr) !=
             0) {
    composite_alpha = kVkCompositeAlphaOpaqueBitKhr;
  }

  const uint32_t min_image_count =
      std::max(caps.minImageCount, kMinimumSwapchainImageCount);

  VkSwapchainCreateInfoKHRCompat swapchain_info = {};
  swapchain_info.sType = kVkStructureTypeSwapchainCreateInfoKhr;
  swapchain_info.surface = state.vk_surface;
  swapchain_info.minImageCount = min_image_count;
  swapchain_info.imageFormat = chosen_format;
  swapchain_info.imageColorSpace = chosen_color_space;
  swapchain_info.imageExtent = {extent_width, extent_height};
  swapchain_info.imageArrayLayers = kSingleImageArrayLayer;
  swapchain_info.imageUsage =
      kVkImageUsageColorAttachmentBit | kVkImageUsageTransferSrcBit |
      kVkImageUsageTransferDstBit | kVkImageUsageSampledBit;
  swapchain_info.imageSharingMode = kVkSharingModeExclusive;
  swapchain_info.preTransform = pre_transform;
  swapchain_info.compositeAlpha = composite_alpha;
  swapchain_info.presentMode = kVkPresentModeFifoKhr;
  swapchain_info.clipped = kVkTrue;
  swapchain_info.oldSwapchain = state.vk_swapchain;

  uint64_t new_swapchain = 0;
  int32_t res = vk_create_swapchain_khr_fn_(vk_device_, &swapchain_info,
                                            nullptr, &new_swapchain);

  // Decouple swapchain destruction from `VkSurfaceKHR` destruction on
  // `VK_ERROR_NATIVE_WINDOW_IN_USE_KHR` (or when `oldSwapchain` is rejected):
  // destroy only the old swapchain and retry with `oldSwapchain = 0` without
  // destroying `state.vk_surface`.
  if (res == kVkErrorNativeWindowInUseKhr ||
      (res != kVkSuccess && state.vk_swapchain != 0)) {
    DestroyVulkanSwapchainLocked(state);
    swapchain_info.oldSwapchain = 0;
    res = vk_create_swapchain_khr_fn_(vk_device_, &swapchain_info, nullptr,
                                      &new_swapchain);
  }

  if (res != kVkSuccess || new_swapchain == 0) {
    return false;
  }

  if (state.vk_swapchain != 0 && state.vk_swapchain != new_swapchain) {
    DestroyVulkanSwapchainLocked(state);
  }

  state.vk_swapchain = new_swapchain;
  state.vk_surface_format = chosen_format;
  state.width = extent_width;
  state.height = extent_height;
  state.swapchain_needs_recreation = false;

  uint32_t image_count = 0;
  if (vk_get_swapchain_images_khr_fn_(vk_device_, state.vk_swapchain,
                                      &image_count, nullptr) != kVkSuccess ||
      image_count == 0) {
    DestroyVulkanSwapchainLocked(state);
    return false;
  }
  state.swapchain_images.resize(image_count, 0);
  if (vk_get_swapchain_images_khr_fn_(
          vk_device_, state.vk_swapchain, &image_count,
          state.swapchain_images.data()) != kVkSuccess) {
    DestroyVulkanSwapchainLocked(state);
    return false;
  }

  // Allocate per-view synchronization and command resources if needed.
  if (state.acquire_fence == 0 && vk_create_fence_fn_ != nullptr) {
    VkFenceCreateInfoCompat fence_info = {};
    fence_info.sType = kVkStructureTypeFenceCreateInfo;
    vk_create_fence_fn_(vk_device_, &fence_info, nullptr, &state.acquire_fence);
  }
  if (state.render_complete_semaphore == 0 &&
      vk_create_semaphore_fn_ != nullptr) {
    VkSemaphoreCreateInfoCompat sem_info = {};
    sem_info.sType = kVkStructureTypeSemaphoreCreateInfo;
    vk_create_semaphore_fn_(vk_device_, &sem_info, nullptr,
                            &state.render_complete_semaphore);
  }
  if (state.command_pool == 0 && vk_create_command_pool_fn_ != nullptr) {
    VkCommandPoolCreateInfoCompat pool_info = {};
    pool_info.sType = kVkStructureTypeCommandPoolCreateInfo;
    pool_info.flags = kVkCommandPoolCreateResetCommandBufferBit;
    pool_info.queueFamilyIndex = vk_queue_family_index_;
    vk_create_command_pool_fn_(vk_device_, &pool_info, nullptr,
                               &state.command_pool);
  }
  if (state.command_pool != 0 && vk_allocate_command_buffers_fn_ != nullptr &&
      state.command_buffers.size() != state.swapchain_images.size()) {
    state.command_buffers.assign(state.swapchain_images.size(), nullptr);
    VkCommandBufferAllocateInfoCompat alloc_info = {};
    alloc_info.sType = kVkStructureTypeCommandBufferAllocateInfo;
    alloc_info.commandPool = state.command_pool;
    alloc_info.level = kVkCommandBufferLevelPrimary;
    alloc_info.commandBufferCount =
        static_cast<uint32_t>(state.command_buffers.size());
    vk_allocate_command_buffers_fn_(vk_device_, &alloc_info,
                                    state.command_buffers.data());
  }

  return true;
}

bool AndroidSurfaceControl::AcquireNextImageForView(
    FlutterViewId view_id,
    const FlutterFrameInfo* frame_info,
    FlutterVulkanImage* image_out) {
  if (image_out == nullptr) {
    return false;
  }
  std::memset(image_out, 0, sizeof(FlutterVulkanImage));
  image_out->struct_size = sizeof(FlutterVulkanImage);

  std::lock_guard<std::mutex> lock(mutex_);
  auto it = view_surfaces_.find(view_id);
  if (it == view_surfaces_.end() || it->second.native_window == nullptr) {
    return false;
  }

  if (vk_acquire_next_image_khr_fn_ == nullptr) {
    return false;
  }

  const uint32_t req_width = frame_info != nullptr ? frame_info->size.width : 0;
  const uint32_t req_height =
      frame_info != nullptr ? frame_info->size.height : 0;

  PerViewSurfaceState& state = it->second;
  if (!EnsureSwapchainForViewLocked(state, req_width, req_height)) {
    return false;
  }

  uint32_t image_index = 0;
  int32_t res = vk_acquire_next_image_khr_fn_(
      vk_device_, state.vk_swapchain, kVulkanInfiniteTimeoutNs, 0,
      state.acquire_fence, &image_index);

  if (res == kVkErrorOutOfDateKhr || res == kVkErrorSurfaceLostKhr) {
    state.swapchain_needs_recreation = true;
    if (res == kVkErrorSurfaceLostKhr) {
      DestroyVulkanSwapchainLocked(state);
      DestroyVulkanSurfaceLocked(state);
    }
    if (!EnsureSwapchainForViewLocked(state, req_width, req_height)) {
      return false;
    }
    res = vk_acquire_next_image_khr_fn_(vk_device_, state.vk_swapchain,
                                        kVulkanInfiniteTimeoutNs, 0,
                                        state.acquire_fence, &image_index);
  }

  if (res != kVkSuccess && res != kVkSuboptimalKhr) {
    return false;
  }
  if (res == kVkSuboptimalKhr) {
    state.swapchain_needs_recreation = true;
  }

  if (state.acquire_fence != 0 && vk_wait_for_fences_fn_ != nullptr &&
      vk_reset_fences_fn_ != nullptr) {
    vk_wait_for_fences_fn_(vk_device_, 1, &state.acquire_fence, kVkTrue,
                           kVulkanInfiniteTimeoutNs);
    vk_reset_fences_fn_(vk_device_, 1, &state.acquire_fence);
  }

  if (image_index >= state.swapchain_images.size()) {
    return false;
  }

  state.current_image_index = image_index;
  state.has_acquired_image = true;
  active_acquire_view_id_ = view_id;

  image_out->image = state.swapchain_images[image_index];
  image_out->format = state.vk_surface_format;
  return true;
}

FlutterVulkanImage AndroidSurfaceControl::GetNextImageCallback(
    void* user_data,
    const FlutterFrameInfo* frame_info) {
  FlutterVulkanImage result = {};
  result.struct_size = sizeof(FlutterVulkanImage);
  if (user_data == nullptr) {
    return result;
  }
  auto* self = static_cast<AndroidSurfaceControl*>(user_data);
  FlutterViewId target_view = kAndroidImplicitViewId;
  {
    std::lock_guard<std::mutex> lock(self->mutex_);
    target_view = self->active_acquire_view_id_;
  }
  self->AcquireNextImageForView(target_view, frame_info, &result);
  return result;
}

bool AndroidSurfaceControl::PresentImageForView(
    FlutterViewId view_id,
    const FlutterVulkanImage* image) {
  if (image == nullptr || image->image == 0) {
    return false;
  }

  std::lock_guard<std::mutex> lock(mutex_);
  if (vk_device_ == nullptr || vk_queue_ == nullptr ||
      vk_queue_present_khr_fn_ == nullptr) {
    return false;
  }

  auto it = view_surfaces_.find(view_id);
  if (it == view_surfaces_.end() || it->second.vk_swapchain == 0 ||
      it->second.swapchain_images.empty()) {
    return false;
  }
  PerViewSurfaceState& state = it->second;

  uint32_t image_index = state.current_image_index;
  for (uint32_t i = 0; i < state.swapchain_images.size(); ++i) {
    if (state.swapchain_images[i] == image->image) {
      image_index = i;
      break;
    }
  }
  if (image_index >= state.swapchain_images.size()) {
    return false;
  }

  // Transition the swapchain image from `oldLayout = VK_IMAGE_LAYOUT_GENERAL`
  // (`kVkImageLayoutGeneral`) to `newLayout = VK_IMAGE_LAYOUT_PRESENT_SRC_KHR`
  // (`kVkImageLayoutPresentSrcKhr`). Using `VK_IMAGE_LAYOUT_GENERAL` matches
  // the layout left by Impeller's offscreen-to-swapchain blit and prevents
  // `VUID-vkCmdDraw-None-09600`.
  VkImageMemoryBarrierCompat barrier = {};
  barrier.sType = kVkStructureTypeImageMemoryBarrier;
  barrier.srcAccessMask = kVkAccessColorAttachmentWriteBit;
  barrier.dstAccessMask = kVkAccessMemoryReadBit;
  barrier.oldLayout = kVkImageLayoutGeneral;
  barrier.newLayout = kVkImageLayoutPresentSrcKhr;
  barrier.srcQueueFamilyIndex = kVkQueueFamilyIgnored;
  barrier.dstQueueFamilyIndex = kVkQueueFamilyIgnored;
  barrier.image = image->image;
  barrier.subresourceRange.aspectMask = kVkImageAspectColorBit;
  barrier.subresourceRange.baseMipLevel = 0;
  barrier.subresourceRange.levelCount = kSingleMipLevel;
  barrier.subresourceRange.baseArrayLayer = 0;
  barrier.subresourceRange.layerCount = kSingleImageArrayLayer;

  last_present_barrier_old_layout_ = barrier.oldLayout;
  last_present_barrier_new_layout_ = barrier.newLayout;

  bool signaled_semaphore = false;
  if (image_index < state.command_buffers.size() &&
      state.command_buffers[image_index] != nullptr &&
      vk_begin_command_buffer_fn_ != nullptr &&
      vk_cmd_pipeline_barrier_fn_ != nullptr &&
      vk_end_command_buffer_fn_ != nullptr && vk_queue_submit_fn_ != nullptr) {
    void* cmd = state.command_buffers[image_index];
    if (vk_reset_command_buffer_fn_ != nullptr) {
      vk_reset_command_buffer_fn_(cmd, 0);
    }
    VkCommandBufferBeginInfoCompat begin_info = {};
    begin_info.sType = kVkStructureTypeCommandBufferBeginInfo;
    begin_info.flags = kVkCommandBufferUsageOneTimeSubmitBit;
    if (vk_begin_command_buffer_fn_(cmd, &begin_info) == kVkSuccess) {
      vk_cmd_pipeline_barrier_fn_(cmd, kVkPipelineStageColorAttachmentOutputBit,
                                  kVkPipelineStageBottomOfPipeBit, 0, 0,
                                  nullptr, 0, nullptr, 1, &barrier);
      if (vk_end_command_buffer_fn_(cmd) == kVkSuccess) {
        VkSubmitInfoCompat submit_info = {};
        submit_info.sType = kVkStructureTypeSubmitInfo;
        submit_info.commandBufferCount = 1;
        submit_info.pCommandBuffers = &cmd;
        if (state.render_complete_semaphore != 0) {
          submit_info.signalSemaphoreCount = 1;
          submit_info.pSignalSemaphores = &state.render_complete_semaphore;
          signaled_semaphore = true;
        }
        if (vk_queue_submit_fn_(vk_queue_, 1, &submit_info, 0) != kVkSuccess) {
          return false;
        }
      }
    }
  }

  VkPresentInfoKHRCompat present_info = {};
  present_info.sType = kVkStructureTypePresentInfoKhr;
  if (signaled_semaphore && state.render_complete_semaphore != 0) {
    present_info.waitSemaphoreCount = 1;
    present_info.pWaitSemaphores = &state.render_complete_semaphore;
  }
  present_info.swapchainCount = 1;
  present_info.pSwapchains = &state.vk_swapchain;
  present_info.pImageIndices = &image_index;

  const int32_t present_res =
      vk_queue_present_khr_fn_(vk_queue_, &present_info);
  state.has_acquired_image = false;

  if (present_res == kVkErrorOutOfDateKhr || present_res == kVkSuboptimalKhr) {
    state.swapchain_needs_recreation = true;
    return present_res == kVkSuboptimalKhr;
  }
  if (present_res == kVkErrorSurfaceLostKhr) {
    DestroyVulkanSwapchainLocked(state);
    DestroyVulkanSurfaceLocked(state);
    return false;
  }

  return present_res == kVkSuccess;
}

bool AndroidSurfaceControl::PresentImageCallback(
    void* user_data,
    const FlutterVulkanImage* image) {
  if (user_data == nullptr || image == nullptr) {
    return false;
  }
  auto* self = static_cast<AndroidSurfaceControl*>(user_data);
  FlutterViewId target_view = kAndroidImplicitViewId;
  {
    std::lock_guard<std::mutex> lock(self->mutex_);
    target_view = self->active_acquire_view_id_;
  }
  return self->PresentImageForView(target_view, image);
}

void* AndroidSurfaceControl::GetInstanceProcAddressCallback(
    void* user_data,
    FlutterVulkanInstanceHandle instance,
    const char* name) {
  if (user_data == nullptr || name == nullptr) {
    return nullptr;
  }
  auto* self = static_cast<AndroidSurfaceControl*>(user_data);
  std::lock_guard<std::mutex> lock(self->mutex_);
  if (self->vk_get_instance_proc_addr_fn_ == nullptr) {
    return nullptr;
  }
  if (std::strcmp(name, "vkGetInstanceProcAddr") == 0) {
    return reinterpret_cast<void*>(self->vk_get_instance_proc_addr_fn_);
  }
  void* sym = self->vk_get_instance_proc_addr_fn_(instance, name);
  if (sym == nullptr && instance == nullptr && self->vk_instance_ != nullptr) {
    sym = self->vk_get_instance_proc_addr_fn_(self->vk_instance_, name);
  }
  if (sym == nullptr && self->vk_device_ != nullptr &&
      self->vk_get_device_proc_addr_fn_ != nullptr) {
    sym = self->vk_get_device_proc_addr_fn_(self->vk_device_, name);
  }
  if (sym == nullptr && self->vulkan_library_ != nullptr) {
    sym = self->vulkan_library_->ResolveSymbol(name);
  }
  return sym;
}

int AndroidSurfaceControl::ExportHcppAcquireFenceFd(
    FlutterViewId view_id,
    uint64_t image_handle,
    AndroidSurfaceTransaction* transaction,
    AndroidSurfaceControl* surface_node,
    void* hardware_buffer) {
  std::lock_guard<std::mutex> lock(mutex_);
  if (vk_device_ == nullptr || vk_queue_ == nullptr ||
      vk_create_semaphore_fn_ == nullptr || vk_queue_submit_fn_ == nullptr ||
      vk_get_semaphore_fd_khr_fn_ == nullptr) {
    last_exported_hcpp_fence_fd_ = kInvalidFenceFd;
    return kInvalidFenceFd;
  }

  PerViewSurfaceState& state = view_surfaces_[view_id];
  if (state.hcpp_export_semaphore == 0) {
    VkExportSemaphoreCreateInfoCompat export_info = {};
    export_info.sType = kVkStructureTypeExportSemaphoreCreateInfo;
    export_info.handleTypes = kVkExternalSemaphoreHandleTypeSyncFdBit;

    VkSemaphoreCreateInfoCompat sem_info = {};
    sem_info.sType = kVkStructureTypeSemaphoreCreateInfo;
    sem_info.pNext = &export_info;

    if (vk_create_semaphore_fn_(vk_device_, &sem_info, nullptr,
                                &state.hcpp_export_semaphore) != kVkSuccess ||
        state.hcpp_export_semaphore == 0) {
      last_exported_hcpp_fence_fd_ = kInvalidFenceFd;
      return kInvalidFenceFd;
    }
  }

  // Submit a queue barrier signaling the exportable semaphore so the exported
  // sync_file fd reflects all prior rendering commands on `vk_queue_`.
  void* cmd = nullptr;
  if (!state.command_buffers.empty()) {
    cmd = state.command_buffers[0];
  }
  if (cmd != nullptr && image_handle != 0 &&
      vk_begin_command_buffer_fn_ != nullptr &&
      vk_cmd_pipeline_barrier_fn_ != nullptr &&
      vk_end_command_buffer_fn_ != nullptr) {
    if (vk_reset_command_buffer_fn_ != nullptr) {
      vk_reset_command_buffer_fn_(cmd, 0);
    }
    VkCommandBufferBeginInfoCompat begin_info = {};
    begin_info.sType = kVkStructureTypeCommandBufferBeginInfo;
    begin_info.flags = kVkCommandBufferUsageOneTimeSubmitBit;
    if (vk_begin_command_buffer_fn_(cmd, &begin_info) == kVkSuccess) {
      VkImageMemoryBarrierCompat barrier = {};
      barrier.sType = kVkStructureTypeImageMemoryBarrier;
      barrier.srcAccessMask = kVkAccessColorAttachmentWriteBit;
      barrier.dstAccessMask = kVkAccessMemoryReadBit;
      barrier.oldLayout = kVkImageLayoutGeneral;
      barrier.newLayout = kVkImageLayoutPresentSrcKhr;
      barrier.srcQueueFamilyIndex = kVkQueueFamilyIgnored;
      barrier.dstQueueFamilyIndex = kVkQueueFamilyIgnored;
      barrier.image = image_handle;
      barrier.subresourceRange.aspectMask = kVkImageAspectColorBit;
      barrier.subresourceRange.levelCount = kSingleMipLevel;
      barrier.subresourceRange.layerCount = kSingleImageArrayLayer;
      vk_cmd_pipeline_barrier_fn_(cmd, kVkPipelineStageColorAttachmentOutputBit,
                                  kVkPipelineStageBottomOfPipeBit, 0, 0,
                                  nullptr, 0, nullptr, 1, &barrier);
      vk_end_command_buffer_fn_(cmd);
    }
  }

  VkSubmitInfoCompat submit_info = {};
  submit_info.sType = kVkStructureTypeSubmitInfo;
  if (cmd != nullptr && image_handle != 0) {
    submit_info.commandBufferCount = 1;
    submit_info.pCommandBuffers = &cmd;
  }
  submit_info.signalSemaphoreCount = 1;
  submit_info.pSignalSemaphores = &state.hcpp_export_semaphore;

  if (vk_queue_submit_fn_(vk_queue_, 1, &submit_info, 0) != kVkSuccess) {
    last_exported_hcpp_fence_fd_ = kInvalidFenceFd;
    return kInvalidFenceFd;
  }

  VkSemaphoreGetFdInfoKHRCompat get_fd_info = {};
  get_fd_info.sType = kVkStructureTypeSemaphoreGetFdInfoKhr;
  get_fd_info.semaphore = state.hcpp_export_semaphore;
  get_fd_info.handleType = kVkExternalSemaphoreHandleTypeSyncFdBit;

  int exported_fd = kInvalidFenceFd;
  if (vk_get_semaphore_fd_khr_fn_(vk_device_, &get_fd_info, &exported_fd) !=
      kVkSuccess) {
    last_exported_hcpp_fence_fd_ = kInvalidFenceFd;
    return kInvalidFenceFd;
  }

  last_exported_hcpp_fence_fd_ = exported_fd;
  if (transaction != nullptr && surface_node != nullptr) {
    transaction->SetBuffer(surface_node, hardware_buffer, exported_fd);
  }
  return exported_fd;
}

// =============================================================================
// Compositor Backing Store & Present View Callbacks
// =============================================================================

bool AndroidSurfaceControl::CreateBackingStore(
    const FlutterBackingStoreConfig* config,
    FlutterBackingStore* backing_store_out) {
  if (config == nullptr || backing_store_out == nullptr) {
    return false;
  }

  const FlutterViewId view_id = config->view_id;
  if (!HasSurface(view_id)) {
    return false;
  }

  std::memset(backing_store_out, 0, sizeof(FlutterBackingStore));
  backing_store_out->struct_size = sizeof(FlutterBackingStore);

  const FlutterRendererType renderer = ResolvedRendererType();
  if (renderer == kVulkan) {
    FlutterFrameInfo frame_info = {};
    frame_info.struct_size = sizeof(FlutterFrameInfo);
    frame_info.size.width = static_cast<uint32_t>(config->size.width);
    frame_info.size.height = static_cast<uint32_t>(config->size.height);

    auto* owned_image = new FlutterVulkanImage{};
    if (!AcquireNextImageForView(view_id, &frame_info, owned_image)) {
      delete owned_image;
      return false;
    }

    backing_store_out->type = kFlutterBackingStoreTypeVulkan;
    backing_store_out->user_data = owned_image;
    backing_store_out->vulkan.struct_size = sizeof(FlutterVulkanBackingStore);
    backing_store_out->vulkan.image = owned_image;
    backing_store_out->vulkan.user_data = owned_image;
    backing_store_out->vulkan.destruction_callback = [](void* user_data) {
      delete static_cast<FlutterVulkanImage*>(user_data);
    };
    return true;
  }

  // OpenGL ES backing store (default framebuffer 0).
  backing_store_out->type = kFlutterBackingStoreTypeOpenGL;
  backing_store_out->open_gl.type = kFlutterOpenGLTargetTypeFramebuffer;
  backing_store_out->open_gl.framebuffer.target = 0;
  backing_store_out->open_gl.framebuffer.name = 0;
  backing_store_out->open_gl.framebuffer.user_data = nullptr;
  backing_store_out->open_gl.framebuffer.destruction_callback =
      [](void* /*user_data*/) {};
  return true;
}

bool AndroidSurfaceControl::CollectBackingStore(
    const FlutterBackingStore* backing_store) {
  if (backing_store == nullptr) {
    return false;
  }
  if (backing_store->type == kFlutterBackingStoreTypeVulkan &&
      backing_store->vulkan.destruction_callback != nullptr) {
    backing_store->vulkan.destruction_callback(backing_store->vulkan.user_data);
  } else if (backing_store->type == kFlutterBackingStoreTypeOpenGL &&
             backing_store->open_gl.type ==
                 kFlutterOpenGLTargetTypeFramebuffer &&
             backing_store->open_gl.framebuffer.destruction_callback !=
                 nullptr) {
    backing_store->open_gl.framebuffer.destruction_callback(
        backing_store->open_gl.framebuffer.user_data);
  }
  return true;
}

bool AndroidSurfaceControl::PresentLayers(const FlutterLayer** layers,
                                          size_t layers_count) {
  FlutterPresentViewInfo info = {};
  info.struct_size = sizeof(FlutterPresentViewInfo);
  info.view_id = kAndroidImplicitViewId;
  info.layers = layers;
  info.layers_count = layers_count;
  return PresentView(&info);
}

bool AndroidSurfaceControl::PresentView(const FlutterPresentViewInfo* info) {
  if (info == nullptr) {
    return false;
  }
  if (!HasSurface(info->view_id)) {
    return false;
  }

  const FlutterRendererType renderer = ResolvedRendererType();
  for (size_t i = 0; i < info->layers_count; ++i) {
    const FlutterLayer* layer =
        info->layers != nullptr ? info->layers[i] : nullptr;
    if (layer == nullptr ||
        layer->type != kFlutterLayerContentTypeBackingStore ||
        layer->backing_store == nullptr) {
      continue;
    }
    if (renderer == kVulkan &&
        layer->backing_store->type == kFlutterBackingStoreTypeVulkan &&
        layer->backing_store->vulkan.image != nullptr) {
      if (!PresentImageForView(info->view_id,
                               layer->backing_store->vulkan.image)) {
        return false;
      }
      // If the view has an attached ASurfaceControl and HCPP semaphore export
      // is available, export the acquire fence fd for SurfaceFlinger.
      if (GetASurfaceControl(info->view_id) != nullptr) {
        ExportHcppAcquireFenceFd(info->view_id,
                                 layer->backing_store->vulkan.image->image);
      }
    }
  }
  return true;
}

// =============================================================================
// Inspection & Cleanup Helpers
// =============================================================================

uint32_t AndroidSurfaceControl::LastPresentBarrierOldLayout() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return last_present_barrier_old_layout_;
}

uint32_t AndroidSurfaceControl::LastPresentBarrierNewLayout() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return last_present_barrier_new_layout_;
}

uint32_t AndroidSurfaceControl::LastSwapchainPreTransform(
    FlutterViewId view_id) const {
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = view_surfaces_.find(view_id);
  return it != view_surfaces_.end() ? it->second.vk_pre_transform
                                    : kVkSurfaceTransformIdentityBitKhr;
}

size_t AndroidSurfaceControl::VulkanSurfaceDestroyCount() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return vk_surface_destroy_count_;
}

size_t AndroidSurfaceControl::VulkanSwapchainDestroyCount() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return vk_swapchain_destroy_count_;
}

int AndroidSurfaceControl::LastExportedHcppFenceFd() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return last_exported_hcpp_fence_fd_;
}

void AndroidSurfaceControl::DestroyVulkanSwapchainLocked(
    PerViewSurfaceState& state) {
  if (vk_device_ == nullptr) {
    state.vk_swapchain = 0;
    state.swapchain_images.clear();
    return;
  }
  if (vk_queue_ != nullptr && vk_queue_wait_idle_fn_ != nullptr) {
    vk_queue_wait_idle_fn_(vk_queue_);
  }
  if (state.acquire_fence != 0 && vk_destroy_fence_fn_ != nullptr) {
    vk_destroy_fence_fn_(vk_device_, state.acquire_fence, nullptr);
    state.acquire_fence = 0;
  }
  if (state.render_complete_semaphore != 0 &&
      vk_destroy_semaphore_fn_ != nullptr) {
    vk_destroy_semaphore_fn_(vk_device_, state.render_complete_semaphore,
                             nullptr);
    state.render_complete_semaphore = 0;
  }
  if (state.hcpp_export_semaphore != 0 && vk_destroy_semaphore_fn_ != nullptr) {
    vk_destroy_semaphore_fn_(vk_device_, state.hcpp_export_semaphore, nullptr);
    state.hcpp_export_semaphore = 0;
  }
  if (state.command_pool != 0 && vk_destroy_command_pool_fn_ != nullptr) {
    vk_destroy_command_pool_fn_(vk_device_, state.command_pool, nullptr);
    state.command_pool = 0;
  }
  state.command_buffers.clear();
  if (state.vk_swapchain != 0 && vk_destroy_swapchain_khr_fn_ != nullptr) {
    vk_destroy_swapchain_khr_fn_(vk_device_, state.vk_swapchain, nullptr);
    ++vk_swapchain_destroy_count_;
    state.vk_swapchain = 0;
  }
  state.swapchain_images.clear();
  state.has_acquired_image = false;
}

void AndroidSurfaceControl::DestroyVulkanSurfaceLocked(
    PerViewSurfaceState& state) {
  if (state.vk_surface != 0 && vk_instance_ != nullptr &&
      vk_destroy_surface_khr_fn_ != nullptr) {
    vk_destroy_surface_khr_fn_(vk_instance_, state.vk_surface, nullptr);
    ++vk_surface_destroy_count_;
  }
  state.vk_surface = 0;
}

void AndroidSurfaceControl::TeardownVulkanLocked() {
  for (auto& [view_id, state] : view_surfaces_) {
    DestroyVulkanSwapchainLocked(state);
    DestroyVulkanSurfaceLocked(state);
  }
  if (vk_device_ != nullptr && vk_destroy_device_fn_ != nullptr) {
    vk_destroy_device_fn_(vk_device_, nullptr);
  }
  vk_device_ = nullptr;
  vk_queue_ = nullptr;
  vk_physical_device_ = nullptr;

  if (vk_instance_ != nullptr && vk_destroy_instance_fn_ != nullptr) {
    vk_destroy_instance_fn_(vk_instance_, nullptr);
  }
  vk_instance_ = nullptr;
}

// =============================================================================
// DefaultAndroidSurfaceControl
// =============================================================================

DefaultAndroidSurfaceControl::DefaultAndroidSurfaceControl(
    void* handle,
    std::string debug_name,
    const DefaultAndroidSurfaceControlProvider::ProcTable& procs)
    : AndroidSurfaceControl(debug_name, handle),
      handle_(handle),
      debug_name_(std::move(debug_name)),
      procs_(procs) {}

DefaultAndroidSurfaceControl::~DefaultAndroidSurfaceControl() {
  if (handle_ != nullptr && procs_.release != nullptr) {
    procs_.release(handle_);
    handle_ = nullptr;
  }
}

bool DefaultAndroidSurfaceControl::IsValid() const {
  return handle_ != nullptr;
}

void* DefaultAndroidSurfaceControl::RawHandle() const {
  return handle_;
}

const std::string& DefaultAndroidSurfaceControl::DebugName() const {
  return debug_name_;
}

// =============================================================================
// DefaultAndroidSurfaceTransaction
// =============================================================================

DefaultAndroidSurfaceTransaction::DefaultAndroidSurfaceTransaction(
    void* handle,
    const DefaultAndroidSurfaceControlProvider::ProcTable& procs)
    : handle_(handle), procs_(procs) {}

DefaultAndroidSurfaceTransaction::~DefaultAndroidSurfaceTransaction() {
  if (handle_ != nullptr && procs_.transaction_delete != nullptr) {
    procs_.transaction_delete(handle_);
    handle_ = nullptr;
  }
}

bool DefaultAndroidSurfaceTransaction::IsValid() const {
  return handle_ != nullptr;
}

void DefaultAndroidSurfaceTransaction::SetStatsTargetSurface(
    AndroidSurfaceControl* surface) {
  stats_target_surface_ = surface != nullptr ? surface->RawHandle() : nullptr;
}

void DefaultAndroidSurfaceTransaction::Apply() {
  if (handle_ == nullptr || procs_.transaction_apply == nullptr) {
    return;
  }

  if (pending_on_complete_ && procs_.transaction_set_on_complete != nullptr) {
    auto* ctx = new CallbackContext{std::move(pending_on_complete_), nullptr,
                                    procs_, stats_target_surface_};
    pending_on_complete_ = nullptr;
    procs_.transaction_set_on_complete(
        handle_, ctx, &DefaultAndroidSurfaceTransaction::OnCompleteThunk);
  }

  if (pending_on_commit_ && procs_.transaction_set_on_commit != nullptr) {
    auto* ctx = new CallbackContext{nullptr, std::move(pending_on_commit_),
                                    procs_, stats_target_surface_};
    pending_on_commit_ = nullptr;
    procs_.transaction_set_on_commit(
        handle_, ctx, &DefaultAndroidSurfaceTransaction::OnCommitThunk);
  }

  procs_.transaction_apply(handle_);
}

void DefaultAndroidSurfaceTransaction::Reparent(
    AndroidSurfaceControl* child,
    AndroidSurfaceControl* new_parent) {
  if (handle_ == nullptr || child == nullptr || !child->IsValid() ||
      procs_.transaction_reparent == nullptr) {
    return;
  }
  void* parent_handle = (new_parent != nullptr && new_parent->IsValid())
                            ? new_parent->RawHandle()
                            : nullptr;
  procs_.transaction_reparent(handle_, child->RawHandle(), parent_handle);
}

void DefaultAndroidSurfaceTransaction::SetVisibility(
    AndroidSurfaceControl* surface,
    AndroidSurfaceControlVisibility visibility) {
  if (handle_ == nullptr || surface == nullptr || !surface->IsValid() ||
      procs_.transaction_set_visibility == nullptr) {
    return;
  }
  procs_.transaction_set_visibility(handle_, surface->RawHandle(),
                                    static_cast<int8_t>(visibility));
}

void DefaultAndroidSurfaceTransaction::SetZOrder(AndroidSurfaceControl* surface,
                                                 int32_t z_order) {
  if (handle_ == nullptr || surface == nullptr || !surface->IsValid() ||
      procs_.transaction_set_z_order == nullptr) {
    return;
  }
  procs_.transaction_set_z_order(handle_, surface->RawHandle(), z_order);
}

void DefaultAndroidSurfaceTransaction::SetBuffer(AndroidSurfaceControl* surface,
                                                 void* hardware_buffer,
                                                 int acquire_fence_fd) {
  if (handle_ == nullptr || surface == nullptr || !surface->IsValid() ||
      procs_.transaction_set_buffer == nullptr) {
    return;
  }
  if (stats_target_surface_ == nullptr) {
    stats_target_surface_ = surface->RawHandle();
  }
  procs_.transaction_set_buffer(handle_, surface->RawHandle(), hardware_buffer,
                                acquire_fence_fd);
}

void DefaultAndroidSurfaceTransaction::SetGeometry(
    AndroidSurfaceControl* surface,
    const AndroidSurfaceControlRect& source,
    const AndroidSurfaceControlRect& destination,
    AndroidSurfaceControlTransform transform) {
  if (handle_ == nullptr || surface == nullptr || !surface->IsValid() ||
      procs_.transaction_set_geometry == nullptr) {
    return;
  }
  procs_.transaction_set_geometry(handle_, surface->RawHandle(), source,
                                  destination, static_cast<int32_t>(transform));
}

void DefaultAndroidSurfaceTransaction::SetBufferAlpha(
    AndroidSurfaceControl* surface,
    float alpha) {
  if (handle_ == nullptr || surface == nullptr || !surface->IsValid() ||
      procs_.transaction_set_buffer_alpha == nullptr) {
    return;
  }
  const float clamped_alpha = std::clamp(alpha, 0.0f, 1.0f);
  procs_.transaction_set_buffer_alpha(handle_, surface->RawHandle(),
                                      clamped_alpha);
}

void DefaultAndroidSurfaceTransaction::SetColor(
    AndroidSurfaceControl* surface,
    const AndroidSurfaceControlColor& color) {
  if (handle_ == nullptr || surface == nullptr || !surface->IsValid() ||
      procs_.transaction_set_color == nullptr) {
    return;
  }
  procs_.transaction_set_color(handle_, surface->RawHandle(), color.r, color.g,
                               color.b, color.a, kDefaultDataspaceSrgbLinear);
}

void DefaultAndroidSurfaceTransaction::SetFrameRate(
    AndroidSurfaceControl* surface,
    float frame_rate,
    int8_t compatibility) {
  if (handle_ == nullptr || surface == nullptr || !surface->IsValid() ||
      procs_.transaction_set_frame_rate == nullptr) {
    return;
  }
  procs_.transaction_set_frame_rate(handle_, surface->RawHandle(), frame_rate,
                                    compatibility);
}

void DefaultAndroidSurfaceTransaction::SetEnableBackPressure(
    AndroidSurfaceControl* surface,
    bool enable) {
  if (handle_ == nullptr || surface == nullptr || !surface->IsValid() ||
      procs_.transaction_set_enable_back_pressure == nullptr) {
    return;
  }
  procs_.transaction_set_enable_back_pressure(handle_, surface->RawHandle(),
                                              enable);
}

void DefaultAndroidSurfaceTransaction::SetOnCompleteCallback(
    OnCompleteCallback callback) {
  pending_on_complete_ = std::move(callback);
}

void DefaultAndroidSurfaceTransaction::SetOnCommitCallback(
    OnCommitCallback callback) {
  pending_on_commit_ = std::move(callback);
}

AndroidSurfaceControlStats DefaultAndroidSurfaceTransaction::ExtractStats(
    const DefaultAndroidSurfaceControlProvider::ProcTable& procs,
    void* stats,
    void* surface_handle) {
  AndroidSurfaceControlStats out;
  if (stats == nullptr) {
    return out;
  }
  if (procs.stats_get_latch_time != nullptr) {
    out.latch_time_nanos = procs.stats_get_latch_time(stats);
  }
  if (procs.stats_get_present_fence_fd != nullptr) {
    out.present_fence_fd = procs.stats_get_present_fence_fd(stats);
  }
  if (surface_handle != nullptr) {
    if (procs.stats_get_acquire_time != nullptr) {
      out.acquire_time_nanos =
          procs.stats_get_acquire_time(stats, surface_handle);
    }
    if (procs.stats_get_previous_release_fence_fd != nullptr) {
      out.previous_release_fence_fd =
          procs.stats_get_previous_release_fence_fd(stats, surface_handle);
    }
  }
  return out;
}

void DefaultAndroidSurfaceTransaction::OnCompleteThunk(void* context,
                                                       void* stats) {
  std::unique_ptr<CallbackContext> ctx(static_cast<CallbackContext*>(context));
  if (ctx && ctx->on_complete) {
    AndroidSurfaceControlStats extracted =
        ExtractStats(ctx->procs, stats, ctx->target_surface_handle);
    ctx->on_complete(extracted);
  }
}

void DefaultAndroidSurfaceTransaction::OnCommitThunk(void* context,
                                                     void* stats) {
  std::unique_ptr<CallbackContext> ctx(static_cast<CallbackContext*>(context));
  if (ctx && ctx->on_commit) {
    AndroidSurfaceControlStats extracted =
        ExtractStats(ctx->procs, stats, ctx->target_surface_handle);
    ctx->on_commit(extracted);
  }
}

// =============================================================================
// DefaultAndroidSurfaceControlProvider
// =============================================================================

DefaultAndroidSurfaceControlProvider::DefaultAndroidSurfaceControlProvider(
    std::shared_ptr<OSLibraryLoader> loader) {
  if (!loader) {
    loader = std::make_shared<DefaultOSLibraryLoader>();
  }
  android_library_ = loader->Load("libandroid.so");
  if (!android_library_) {
    return;
  }

  procs_.create_from_window =
      ResolveSymbolAs<ASurfaceControlCreateFromWindowFn>(
          android_library_.get(), "ASurfaceControl_createFromWindow");
  procs_.create = ResolveSymbolAs<ASurfaceControlCreateFn>(
      android_library_.get(), "ASurfaceControl_create");
  procs_.release = ResolveSymbolAs<ASurfaceControlReleaseFn>(
      android_library_.get(), "ASurfaceControl_release");
  procs_.transaction_create = ResolveSymbolAs<ASurfaceTransactionCreateFn>(
      android_library_.get(), "ASurfaceTransaction_create");
  procs_.transaction_delete = ResolveSymbolAs<ASurfaceTransactionDeleteFn>(
      android_library_.get(), "ASurfaceTransaction_delete");
  procs_.transaction_apply = ResolveSymbolAs<ASurfaceTransactionApplyFn>(
      android_library_.get(), "ASurfaceTransaction_apply");
  procs_.transaction_reparent = ResolveSymbolAs<ASurfaceTransactionReparentFn>(
      android_library_.get(), "ASurfaceTransaction_reparent");
  procs_.transaction_set_visibility =
      ResolveSymbolAs<ASurfaceTransactionSetVisibilityFn>(
          android_library_.get(), "ASurfaceTransaction_setVisibility");
  procs_.transaction_set_z_order =
      ResolveSymbolAs<ASurfaceTransactionSetZOrderFn>(
          android_library_.get(), "ASurfaceTransaction_setZOrder");
  procs_.transaction_set_buffer =
      ResolveSymbolAs<ASurfaceTransactionSetBufferFn>(
          android_library_.get(), "ASurfaceTransaction_setBuffer");
  procs_.transaction_set_geometry =
      ResolveSymbolAs<ASurfaceTransactionSetGeometryFn>(
          android_library_.get(), "ASurfaceTransaction_setGeometry");
  procs_.transaction_set_buffer_alpha =
      ResolveSymbolAs<ASurfaceTransactionSetBufferAlphaFn>(
          android_library_.get(), "ASurfaceTransaction_setBufferAlpha");
  procs_.transaction_set_color = ResolveSymbolAs<ASurfaceTransactionSetColorFn>(
      android_library_.get(), "ASurfaceTransaction_setColor");
  procs_.transaction_set_frame_rate =
      ResolveSymbolAs<ASurfaceTransactionSetFrameRateFn>(
          android_library_.get(), "ASurfaceTransaction_setFrameRate");
  procs_.transaction_set_enable_back_pressure =
      ResolveSymbolAs<ASurfaceTransactionSetEnableBackPressureFn>(
          android_library_.get(), "ASurfaceTransaction_setEnableBackPressure");
  procs_.transaction_set_on_complete =
      ResolveSymbolAs<ASurfaceTransactionSetOnCompleteFn>(
          android_library_.get(), "ASurfaceTransaction_setOnComplete");
  procs_.transaction_set_on_commit =
      ResolveSymbolAs<ASurfaceTransactionSetOnCommitFn>(
          android_library_.get(), "ASurfaceTransaction_setOnCommit");
  procs_.stats_get_acquire_time =
      ResolveSymbolAs<ASurfaceTransactionStatsGetAcquireTimeFn>(
          android_library_.get(), "ASurfaceTransactionStats_getAcquireTime");
  procs_.stats_get_previous_release_fence_fd =
      ResolveSymbolAs<ASurfaceTransactionStatsGetPreviousReleaseFenceFdFn>(
          android_library_.get(),
          "ASurfaceTransactionStats_getPreviousReleaseFenceFd");
  procs_.stats_get_latch_time =
      ResolveSymbolAs<ASurfaceTransactionStatsGetLatchTimeFn>(
          android_library_.get(), "ASurfaceTransactionStats_getLatchTime");
  procs_.stats_get_present_fence_fd =
      ResolveSymbolAs<ASurfaceTransactionStatsGetPresentFenceFdFn>(
          android_library_.get(), "ASurfaceTransactionStats_getPresentFenceFd");
}

DefaultAndroidSurfaceControlProvider::~DefaultAndroidSurfaceControlProvider() =
    default;

bool DefaultAndroidSurfaceControlProvider::IsAvailable() const {
  return procs_.IsComplete();
}

std::unique_ptr<AndroidSurfaceControl>
DefaultAndroidSurfaceControlProvider::CreateFromWindow(
    void* native_window,
    const std::string& debug_name) {
  if (!IsAvailable() || native_window == nullptr) {
    return nullptr;
  }
  void* handle = procs_.create_from_window(native_window, debug_name.c_str());
  if (handle == nullptr) {
    return nullptr;
  }
  return std::make_unique<DefaultAndroidSurfaceControl>(handle, debug_name,
                                                        procs_);
}

std::unique_ptr<AndroidSurfaceControl>
DefaultAndroidSurfaceControlProvider::CreateFromParent(
    AndroidSurfaceControl* parent,
    const std::string& debug_name) {
  if (!IsAvailable() || parent == nullptr || !parent->IsValid()) {
    return nullptr;
  }
  void* handle = procs_.create(parent->RawHandle(), debug_name.c_str());
  if (handle == nullptr) {
    return nullptr;
  }
  return std::make_unique<DefaultAndroidSurfaceControl>(handle, debug_name,
                                                        procs_);
}

std::unique_ptr<AndroidSurfaceTransaction>
DefaultAndroidSurfaceControlProvider::CreateTransaction() {
  if (!IsAvailable()) {
    return nullptr;
  }
  void* handle = procs_.transaction_create();
  if (handle == nullptr) {
    return nullptr;
  }
  return std::make_unique<DefaultAndroidSurfaceTransaction>(handle, procs_);
}

// =============================================================================
// InMemoryAndroidSurfaceControl
// =============================================================================

InMemoryAndroidSurfaceControl::InMemoryAndroidSurfaceControl(
    uint64_t id,
    std::string debug_name,
    void* parent_window,
    InMemoryAndroidSurfaceControl* parent_control)
    : AndroidSurfaceControl(debug_name, reinterpret_cast<void*>(id)),
      id_(id),
      parent_window_(parent_window),
      parent_control_(parent_control) {
  state_.debug_name = std::move(debug_name);
}

InMemoryAndroidSurfaceControl::~InMemoryAndroidSurfaceControl() = default;

bool InMemoryAndroidSurfaceControl::IsValid() const {
  return id_ != 0;
}

void* InMemoryAndroidSurfaceControl::RawHandle() const {
  return reinterpret_cast<void*>(static_cast<uintptr_t>(id_));
}

const std::string& InMemoryAndroidSurfaceControl::DebugName() const {
  return state_.debug_name;
}

// =============================================================================
// InMemoryAndroidSurfaceTransaction
// =============================================================================

InMemoryAndroidSurfaceTransaction::InMemoryAndroidSurfaceTransaction(
    const AndroidSurfaceControlStats& simulated_stats)
    : simulated_stats_(simulated_stats) {}

InMemoryAndroidSurfaceTransaction::~InMemoryAndroidSurfaceTransaction() =
    default;

bool InMemoryAndroidSurfaceTransaction::IsValid() const {
  return true;
}

void InMemoryAndroidSurfaceTransaction::Apply() {
  for (const auto& op : pending_ops_) {
    op();
  }
  pending_ops_.clear();
  applied_ = true;

  if (on_commit_) {
    auto cb = std::move(on_commit_);
    on_commit_ = nullptr;
    cb(simulated_stats_);
  }

  if (on_complete_) {
    auto cb = std::move(on_complete_);
    on_complete_ = nullptr;
    cb(simulated_stats_);
  }
}

void InMemoryAndroidSurfaceTransaction::Reparent(
    AndroidSurfaceControl* child,
    AndroidSurfaceControl* new_parent) {
  if (child == nullptr || !child->IsValid()) {
    return;
  }
  auto* mem_child = static_cast<InMemoryAndroidSurfaceControl*>(child);
  auto* mem_parent =
      (new_parent != nullptr && new_parent->IsValid())
          ? static_cast<InMemoryAndroidSurfaceControl*>(new_parent)
          : nullptr;
  pending_ops_.emplace_back(
      [mem_child, mem_parent]() { mem_child->set_parent_control(mem_parent); });
}

void InMemoryAndroidSurfaceTransaction::SetVisibility(
    AndroidSurfaceControl* surface,
    AndroidSurfaceControlVisibility visibility) {
  if (surface == nullptr || !surface->IsValid()) {
    return;
  }
  auto* mem_surface = static_cast<InMemoryAndroidSurfaceControl*>(surface);
  pending_ops_.emplace_back([mem_surface, visibility]() {
    mem_surface->mutable_state().visible =
        (visibility == AndroidSurfaceControlVisibility::kShow);
  });
}

void InMemoryAndroidSurfaceTransaction::SetZOrder(
    AndroidSurfaceControl* surface,
    int32_t z_order) {
  if (surface == nullptr || !surface->IsValid()) {
    return;
  }
  auto* mem_surface = static_cast<InMemoryAndroidSurfaceControl*>(surface);
  pending_ops_.emplace_back([mem_surface, z_order]() {
    mem_surface->mutable_state().z_order = z_order;
  });
}

void InMemoryAndroidSurfaceTransaction::SetBuffer(
    AndroidSurfaceControl* surface,
    void* hardware_buffer,
    int acquire_fence_fd) {
  if (surface == nullptr || !surface->IsValid()) {
    return;
  }
  auto* mem_surface = static_cast<InMemoryAndroidSurfaceControl*>(surface);
  pending_ops_.emplace_back([mem_surface, hardware_buffer, acquire_fence_fd]() {
    mem_surface->mutable_state().current_hardware_buffer = hardware_buffer;
    mem_surface->mutable_state().current_acquire_fence_fd = acquire_fence_fd;
  });
}

void InMemoryAndroidSurfaceTransaction::SetGeometry(
    AndroidSurfaceControl* surface,
    const AndroidSurfaceControlRect& source,
    const AndroidSurfaceControlRect& destination,
    AndroidSurfaceControlTransform transform) {
  if (surface == nullptr || !surface->IsValid()) {
    return;
  }
  auto* mem_surface = static_cast<InMemoryAndroidSurfaceControl*>(surface);
  pending_ops_.emplace_back([mem_surface, source, destination, transform]() {
    mem_surface->mutable_state().source_rect = source;
    mem_surface->mutable_state().dest_rect = destination;
    mem_surface->mutable_state().transform = transform;
  });
}

void InMemoryAndroidSurfaceTransaction::SetBufferAlpha(
    AndroidSurfaceControl* surface,
    float alpha) {
  if (surface == nullptr || !surface->IsValid()) {
    return;
  }
  auto* mem_surface = static_cast<InMemoryAndroidSurfaceControl*>(surface);
  const float clamped_alpha = std::clamp(alpha, 0.0f, 1.0f);
  pending_ops_.emplace_back([mem_surface, clamped_alpha]() {
    mem_surface->mutable_state().alpha = clamped_alpha;
  });
}

void InMemoryAndroidSurfaceTransaction::SetColor(
    AndroidSurfaceControl* surface,
    const AndroidSurfaceControlColor& color) {
  if (surface == nullptr || !surface->IsValid()) {
    return;
  }
  auto* mem_surface = static_cast<InMemoryAndroidSurfaceControl*>(surface);
  pending_ops_.emplace_back([mem_surface, color]() {
    mem_surface->mutable_state().color = color;
    mem_surface->mutable_state().has_color = true;
  });
}

void InMemoryAndroidSurfaceTransaction::SetFrameRate(
    AndroidSurfaceControl* surface,
    float frame_rate,
    int8_t compatibility) {
  if (surface == nullptr || !surface->IsValid()) {
    return;
  }
  auto* mem_surface = static_cast<InMemoryAndroidSurfaceControl*>(surface);
  pending_ops_.emplace_back([mem_surface, frame_rate, compatibility]() {
    mem_surface->mutable_state().requested_frame_rate = frame_rate;
    mem_surface->mutable_state().frame_rate_compatibility = compatibility;
  });
}

void InMemoryAndroidSurfaceTransaction::SetEnableBackPressure(
    AndroidSurfaceControl* surface,
    bool enable) {
  if (surface == nullptr || !surface->IsValid()) {
    return;
  }
  auto* mem_surface = static_cast<InMemoryAndroidSurfaceControl*>(surface);
  pending_ops_.emplace_back([mem_surface, enable]() {
    mem_surface->mutable_state().enable_back_pressure = enable;
  });
}

void InMemoryAndroidSurfaceTransaction::SetOnCompleteCallback(
    OnCompleteCallback callback) {
  on_complete_ = std::move(callback);
}

void InMemoryAndroidSurfaceTransaction::SetOnCommitCallback(
    OnCommitCallback callback) {
  on_commit_ = std::move(callback);
}

// =============================================================================
// InMemoryAndroidSurfaceControlProvider
// =============================================================================

InMemoryAndroidSurfaceControlProvider::InMemoryAndroidSurfaceControlProvider(
    bool available)
    : available_(available) {}

InMemoryAndroidSurfaceControlProvider::
    ~InMemoryAndroidSurfaceControlProvider() = default;

bool InMemoryAndroidSurfaceControlProvider::IsAvailable() const {
  return available_;
}

std::unique_ptr<AndroidSurfaceControl>
InMemoryAndroidSurfaceControlProvider::CreateFromWindow(
    void* native_window,
    const std::string& debug_name) {
  if (!available_ || native_window == nullptr) {
    return nullptr;
  }
  const uint64_t id = next_id_++;
  return std::make_unique<InMemoryAndroidSurfaceControl>(
      id, debug_name, native_window, nullptr);
}

std::unique_ptr<AndroidSurfaceControl>
InMemoryAndroidSurfaceControlProvider::CreateFromParent(
    AndroidSurfaceControl* parent,
    const std::string& debug_name) {
  if (!available_ || parent == nullptr || !parent->IsValid()) {
    return nullptr;
  }
  auto* mem_parent = static_cast<InMemoryAndroidSurfaceControl*>(parent);
  const uint64_t id = next_id_++;
  return std::make_unique<InMemoryAndroidSurfaceControl>(id, debug_name,
                                                         nullptr, mem_parent);
}

std::unique_ptr<AndroidSurfaceTransaction>
InMemoryAndroidSurfaceControlProvider::CreateTransaction() {
  if (!available_) {
    return nullptr;
  }
  ++created_transactions_;
  return std::make_unique<InMemoryAndroidSurfaceTransaction>(simulated_stats_);
}

}  // namespace android
}  // namespace flutter
