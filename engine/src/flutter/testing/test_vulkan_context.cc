// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <algorithm>
#include <cassert>
#include <memory>
#include <optional>
#include <string_view>

#include "flutter/flutter_vma/flutter_skia_vma.h"
#include "flutter/fml/logging.h"
#include "flutter/shell/common/context_options.h"
#include "flutter/testing/test_vulkan_context.h"
#include "flutter/vulkan/vulkan_skia_proc_table.h"

#include "flutter/fml/memory/ref_ptr.h"
#include "flutter/fml/native_library.h"
#include "flutter/vulkan/swiftshader_path.h"
#include "third_party/skia/include/gpu/ganesh/GrDirectContext.h"
#include "third_party/skia/include/gpu/ganesh/vk/GrVkDirectContext.h"
#include "third_party/skia/include/gpu/vk/VulkanBackendContext.h"
#include "third_party/skia/include/gpu/vk/VulkanExtensions.h"
#include "vulkan/vulkan_core.h"

namespace flutter::testing {

namespace {

/// The surface extensions Impeller requires of an embedder's instance:
/// VK_KHR_surface plus at least one window-system extension. Neither is used to
/// present here -- the tests render into images -- but Impeller refuses a
/// context without them. Only extensions the ICD offers are returned, so an ICD
/// without them still yields a context for the Skia tests.
std::vector<std::string> SurfaceInstanceExtensions(
    const vulkan::VulkanProcTable& vk) {
  uint32_t count = 0;
  if (vk.EnumerateInstanceExtensionProperties(nullptr, &count, nullptr) !=
          VK_SUCCESS ||
      count == 0) {
    return {};
  }
  std::vector<VkExtensionProperties> properties(count);
  if (vk.EnumerateInstanceExtensionProperties(
          nullptr, &count, properties.data()) != VK_SUCCESS) {
    return {};
  }
  const auto supported = [&](std::string_view name) {
    return std::any_of(properties.begin(), properties.begin() + count,
                       [&](const VkExtensionProperties& p) {
                         return name == p.extensionName;
                       });
  };

  if (!supported(VK_KHR_SURFACE_EXTENSION_NAME)) {
    return {};
  }
  // Any one of them satisfies Impeller; which exist depends on the ICD and the
  // host, so ask for the first that is offered rather than assuming Linux.
  for (const char* wsi : {"VK_KHR_xcb_surface", "VK_KHR_xlib_surface",
                          "VK_KHR_wayland_surface", "VK_KHR_win32_surface",
                          "VK_EXT_metal_surface", "VK_MVK_macos_surface"}) {
    if (supported(wsi)) {
      return {VK_KHR_SURFACE_EXTENSION_NAME, wsi};
    }
  }
  return {};
}

}  // namespace

TestVulkanContext::TestVulkanContext() {
  // ---------------------------------------------------------------------------
  // Initialize basic Vulkan state using the Swiftshader ICD.
  // ---------------------------------------------------------------------------

  const char* vulkan_icd = VULKAN_SO_PATH;

  // TODO(96949): Clean this up and pass a native library directly to
  //              VulkanProcTable.
  if (!fml::NativeLibrary::Create(VULKAN_SO_PATH)) {
    FML_LOG(ERROR) << "Couldn't find Vulkan ICD \"" << vulkan_icd
                   << "\", trying \"libvulkan.so\" instead.";
    vulkan_icd = "libvulkan.so";
  }

  FML_LOG(INFO) << "Using Vulkan ICD: " << vulkan_icd;

  vk_ = fml::MakeRefCounted<vulkan::VulkanProcTable>(vulkan_icd);
  if (!vk_ || !vk_->HasAcquiredMandatoryProcAddresses()) {
    FML_LOG(ERROR) << "Proc table has not acquired mandatory proc addresses.";
    return;
  }

  enabled_instance_extensions_ = SurfaceInstanceExtensions(*vk_);
  application_ = std::make_unique<vulkan::VulkanApplication>(
      *vk_, "Flutter Unittests", enabled_instance_extensions_,
      VK_MAKE_VERSION(1, 0, 0), VK_MAKE_VERSION(1, 1, 0), true);
  if (!application_->IsValid()) {
    FML_LOG(ERROR) << "Failed to initialize basic Vulkan state.";
    return;
  }
  if (!vk_->AreInstanceProcsSetup()) {
    FML_LOG(ERROR) << "Failed to acquire full proc table.";
    return;
  }

  device_ = CreateLogicalDevice();
  if (!device_ || !device_->IsValid()) {
    FML_LOG(ERROR) << "Failed to create compatible logical device.";
    return;
  }

  for (const auto& name : enabled_instance_extensions_) {
    enabled_instance_extension_names_.push_back(name.c_str());
  }
  for (const auto& name : enabled_device_extensions_) {
    enabled_device_extension_names_.push_back(name.c_str());
  }

  // ---------------------------------------------------------------------------
  // Create a Skia context.
  // For creating SkSurfaces from VkImages and snapshotting them, etc.
  // ---------------------------------------------------------------------------

  VkPhysicalDeviceFeatures features;
  if (!device_->GetPhysicalDeviceFeatures(&features)) {
    FML_LOG(ERROR) << "Failed to get physical device features.";

    return;
  }

  auto get_proc = vulkan::CreateSkiaGetProc(vk_);
  if (get_proc == nullptr) {
    FML_LOG(ERROR) << "Failed to create Vulkan getProc for Skia.";
    return;
  }

  sk_sp<skgpu::VulkanMemoryAllocator> allocator =
      flutter::FlutterSkiaVulkanMemoryAllocator::Make(
          VK_MAKE_VERSION(1, 1, 0), application_->GetInstance(),
          device_->GetPhysicalDeviceHandle(), device_->GetHandle(), vk_, true);

  skgpu::VulkanExtensions extensions;

  skgpu::VulkanBackendContext backend_context = {};
  backend_context.fInstance = application_->GetInstance();
  backend_context.fPhysicalDevice = device_->GetPhysicalDeviceHandle();
  backend_context.fDevice = device_->GetHandle();
  backend_context.fQueue = device_->GetQueueHandle();
  backend_context.fGraphicsQueueIndex = device_->GetGraphicsQueueIndex();
  backend_context.fMaxAPIVersion = VK_MAKE_VERSION(1, 1, 0);
  backend_context.fDeviceFeatures = &features;
  backend_context.fVkExtensions = &extensions;
  backend_context.fGetProc = get_proc;
  backend_context.fMemoryAllocator = allocator;

  GrContextOptions options =
      MakeDefaultContextOptions(ContextType::kRender, GrBackendApi::kVulkan);
  options.fReduceOpsTaskSplitting = GrContextOptions::Enable::kNo;
  context_ = GrDirectContexts::MakeVulkan(backend_context, options);
}

std::unique_ptr<vulkan::VulkanDevice> TestVulkanContext::CreateLogicalDevice() {
  const VkInstance instance = application_->GetInstance();
  uint32_t device_count = 0;
  if (vk_->EnumeratePhysicalDevices(instance, &device_count, nullptr) !=
          VK_SUCCESS ||
      device_count == 0) {
    return nullptr;
  }
  std::vector<VkPhysicalDevice> physical_devices(device_count);
  if (vk_->EnumeratePhysicalDevices(instance, &device_count,
                                    physical_devices.data()) != VK_SUCCESS) {
    return nullptr;
  }

  // Impeller's embedder path also requires VK_KHR_swapchain on the device.
  // The proc table cannot enumerate device extensions, so ask for it and fall
  // back to a device without it if the ICD refuses.
  const std::vector<std::vector<std::string>> attempts =
      enabled_instance_extensions_.empty()
          ? std::vector<std::vector<std::string>>{{}}
          : std::vector<std::vector<std::string>>{
                {VK_KHR_SWAPCHAIN_EXTENSION_NAME}, {}};

  for (VkPhysicalDevice physical_device : physical_devices) {
    uint32_t family_count = 0;
    vk_->GetPhysicalDeviceQueueFamilyProperties(physical_device, &family_count,
                                                nullptr);
    std::vector<VkQueueFamilyProperties> families(family_count);
    vk_->GetPhysicalDeviceQueueFamilyProperties(physical_device, &family_count,
                                                families.data());
    uint32_t queue_family = family_count;
    for (uint32_t i = 0; i < family_count; i++) {
      if (families[i].queueFlags & VK_QUEUE_GRAPHICS_BIT) {
        queue_family = i;
        break;
      }
    }
    if (queue_family == family_count) {
      continue;
    }

    const float priority = 1.0f;
    const VkDeviceQueueCreateInfo queue_info = {
        .sType = VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
        .queueFamilyIndex = queue_family,
        .queueCount = 1,
        .pQueuePriorities = &priority,
    };

    for (const auto& extensions : attempts) {
      std::vector<const char*> names;
      names.reserve(extensions.size());
      for (const auto& name : extensions) {
        names.push_back(name.c_str());
      }
      const VkDeviceCreateInfo create_info = {
          .sType = VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO,
          .queueCreateInfoCount = 1,
          .pQueueCreateInfos = &queue_info,
          .enabledExtensionCount = static_cast<uint32_t>(names.size()),
          .ppEnabledExtensionNames = names.data(),
      };
      VkDevice device = VK_NULL_HANDLE;
      if (vk_->CreateDevice(physical_device, &create_info, nullptr, &device) !=
          VK_SUCCESS) {
        continue;
      }
      if (!vk_->SetupDeviceProcAddresses(
              vulkan::VulkanHandle<VkDevice>(device))) {
        vk_->DestroyDevice(device, nullptr);
        continue;
      }
      VkQueue queue = VK_NULL_HANDLE;
      vk_->GetDeviceQueue(device, queue_family, 0, &queue);

      auto result = std::make_unique<vulkan::VulkanDevice>(
          *vk_, vulkan::VulkanHandle<VkPhysicalDevice>(physical_device),
          vulkan::VulkanHandle<VkDevice>(device,
                                         [vk = vk_](VkDevice d) {
                                           vk->DeviceWaitIdle(d);
                                           vk->DestroyDevice(d, nullptr);
                                         }),
          queue_family, vulkan::VulkanHandle<VkQueue>(queue));
      if (!result->IsValid()) {
        continue;
      }
      enabled_device_extensions_ = extensions;
      if (extensions.empty() && !enabled_instance_extensions_.empty()) {
        // Without the device extension Impeller cannot use this context, so
        // the instance list would only mislead it.
        enabled_instance_extensions_.clear();
      }
      return result;
    }
  }
  return nullptr;
}

TestVulkanContext::~TestVulkanContext() {
  if (context_) {
    context_->releaseResourcesAndAbandonContext();
  }
}

std::optional<TestVulkanImage> TestVulkanContext::CreateImage(
    const DlISize& size) const {
  TestVulkanImage result;

  VkImageCreateInfo info = {
      .sType = VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO,
      .pNext = nullptr,
      .flags = 0,
      .imageType = VK_IMAGE_TYPE_2D,
      .format = VK_FORMAT_R8G8B8A8_UNORM,
      .extent = VkExtent3D{static_cast<uint32_t>(size.width),
                           static_cast<uint32_t>(size.height), 1},
      .mipLevels = 1,
      .arrayLayers = 1,
      .samples = VK_SAMPLE_COUNT_1_BIT,
      .tiling = VK_IMAGE_TILING_OPTIMAL,
      .usage = VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT |
               VK_IMAGE_USAGE_TRANSFER_DST_BIT |
               VK_IMAGE_USAGE_TRANSFER_SRC_BIT | VK_IMAGE_USAGE_SAMPLED_BIT,
      .sharingMode = VK_SHARING_MODE_EXCLUSIVE,
      .queueFamilyIndexCount = 0,
      .pQueueFamilyIndices = nullptr,
      .initialLayout = VK_IMAGE_LAYOUT_UNDEFINED,
  };

  VkImage image;
  if (VK_CALL_LOG_ERROR(VK_CALL_LOG_ERROR(
          vk_->CreateImage(device_->GetHandle(), &info, nullptr, &image)))) {
    return std::nullopt;
  }

  result.image_ = vulkan::VulkanHandle<VkImage>(
      image, [&vk = vk_, &device = device_](VkImage image) {
        vk->DestroyImage(device->GetHandle(), image, nullptr);
      });

  VkMemoryRequirements mem_req;
  vk_->GetImageMemoryRequirements(device_->GetHandle(), image, &mem_req);
  VkMemoryAllocateInfo alloc_info{};
  alloc_info.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;
  alloc_info.allocationSize = mem_req.size;
  alloc_info.memoryTypeIndex = static_cast<uint32_t>(__builtin_ctz(
      mem_req.memoryTypeBits & VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT));

  VkDeviceMemory memory;
  if (VK_CALL_LOG_ERROR(vk_->AllocateMemory(device_->GetHandle(), &alloc_info,
                                            nullptr, &memory)) != VK_SUCCESS) {
    return std::nullopt;
  }

  result.memory_ = vulkan::VulkanHandle<VkDeviceMemory>{
      memory, [&vk = vk_, &device = device_](VkDeviceMemory memory) {
        vk->FreeMemory(device->GetHandle(), memory, nullptr);
      }};

  if (VK_CALL_LOG_ERROR(VK_CALL_LOG_ERROR(vk_->BindImageMemory(
          device_->GetHandle(), result.image_, result.memory_, 0)))) {
    return std::nullopt;
  }

  result.context_ =
      fml::RefPtr<TestVulkanContext>(const_cast<TestVulkanContext*>(this));

  return result;
}

sk_sp<GrDirectContext> TestVulkanContext::GetGrDirectContext() const {
  return context_;
}

}  // namespace flutter::testing
