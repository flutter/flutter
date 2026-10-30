// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/android_surface_control.h"

#include <cstring>
#include <memory>
#include <string>
#include <vector>

#include "gtest/gtest.h"

namespace flutter {
namespace android {
namespace testing {

namespace {

// Test constants with explicit rationale.
constexpr int32_t kTestRectLeft = 10;
constexpr int32_t kTestRectTop = 20;
constexpr int32_t kTestRectRight = 110;
constexpr int32_t kTestRectBottom = 220;
constexpr int32_t kExpectedRectWidth = 100;
constexpr int32_t kExpectedRectHeight = 200;

constexpr uint32_t kTestSurfaceWidth = 1080;
constexpr uint32_t kTestSurfaceHeight = 2400;
constexpr uint32_t kResizedSurfaceWidth = 1440;
constexpr uint32_t kResizedSurfaceHeight = 3200;

constexpr FlutterViewId kPrimaryViewId = 0;
constexpr FlutterViewId kSecondaryViewId = 42;

constexpr uintptr_t kDummyNativeWindow1 = 0x1001;
constexpr uintptr_t kDummyNativeWindow2 = 0x1002;
constexpr uintptr_t kDummySurfaceControlHandle = 0x2001;
constexpr uintptr_t kDummyTransactionHandle = 0x3001;
constexpr uintptr_t kDummyHardwareBuffer = 0x4001;
constexpr uintptr_t kDummyEngineHandle = 0x5001;

constexpr int kSimulatedFenceFd = 77;
constexpr int kTrimMemoryRunningLowLevel = 10;
constexpr int kTrimMemoryUiHiddenLevel = 20;
constexpr int kTrimMemoryBelowThresholdLevel = 5;

// Qualcomm Adreno 740 PCI vendor ID and non-blocked driver/API versions.
constexpr uint32_t kValidQualcommVendorId = 0x5143;
constexpr uint32_t kValidDeviceId = 0x07030001;
constexpr uint32_t kDiscreteGpuDeviceType = 2;

// PowerVR / Imagination PCI vendor ID (blocked on all drivers in
// `vulkan_driver_info.h`).
constexpr uint32_t kBlockedImaginationVendorId = 0x1010;

// Mock state for NDK ASurfaceControl / ASurfaceTransaction symbols.
struct MockNdkSurfaceControlEnv {
  int release_count = 0;
  int transaction_delete_count = 0;
  int transaction_apply_count = 0;
  int last_fence_fd = -1;
  void* last_buffer = nullptr;
};

MockNdkSurfaceControlEnv* g_ndk_env = nullptr;

void* StubASurfaceControlCreateFromWindow(void* parent_window,
                                          const char* /*debug_name*/) {
  if (parent_window == nullptr) {
    return nullptr;
  }
  return reinterpret_cast<void*>(kDummySurfaceControlHandle);
}

void* StubASurfaceControlCreate(void* parent_control,
                                const char* /*debug_name*/) {
  if (parent_control == nullptr) {
    return nullptr;
  }
  return reinterpret_cast<void*>(kDummySurfaceControlHandle + 1);
}

void StubASurfaceControlRelease(void* /*surface_control*/) {
  if (g_ndk_env != nullptr) {
    ++g_ndk_env->release_count;
  }
}

void* StubASurfaceTransactionCreate() {
  return reinterpret_cast<void*>(kDummyTransactionHandle);
}

void StubASurfaceTransactionDelete(void* /*transaction*/) {
  if (g_ndk_env != nullptr) {
    ++g_ndk_env->transaction_delete_count;
  }
}

void StubASurfaceTransactionApply(void* /*transaction*/) {
  if (g_ndk_env != nullptr) {
    ++g_ndk_env->transaction_apply_count;
  }
}

void StubASurfaceTransactionReparent(void* /*tx*/,
                                     void* /*sc*/,
                                     void* /*parent*/) {}

void StubASurfaceTransactionSetVisibility(void* /*tx*/,
                                          void* /*sc*/,
                                          int8_t /*vis*/) {}

void StubASurfaceTransactionSetZOrder(void* /*tx*/,
                                      void* /*sc*/,
                                      int32_t /*z*/) {}

void StubASurfaceTransactionSetBuffer(void* /*tx*/,
                                      void* /*sc*/,
                                      void* buffer,
                                      int fence_fd) {
  if (g_ndk_env != nullptr) {
    g_ndk_env->last_buffer = buffer;
    g_ndk_env->last_fence_fd = fence_fd;
  }
}

void StubASurfaceTransactionSetGeometry(
    void* /*tx*/,
    void* /*sc*/,
    const AndroidSurfaceControlRect& /*src*/,
    const AndroidSurfaceControlRect& /*dst*/,
    int32_t /*transform*/) {}

void StubASurfaceTransactionSetBufferAlpha(void* /*tx*/,
                                           void* /*sc*/,
                                           float /*alpha*/) {}

std::shared_ptr<MockOSLibrary> CreateMockNdkAndroidLibrary() {
  auto lib = std::make_shared<MockOSLibrary>();
  lib->RegisterSymbol(
      "ASurfaceControl_createFromWindow",
      reinterpret_cast<void*>(&StubASurfaceControlCreateFromWindow));
  lib->RegisterSymbol("ASurfaceControl_create",
                      reinterpret_cast<void*>(&StubASurfaceControlCreate));
  lib->RegisterSymbol("ASurfaceControl_release",
                      reinterpret_cast<void*>(&StubASurfaceControlRelease));
  lib->RegisterSymbol("ASurfaceTransaction_create",
                      reinterpret_cast<void*>(&StubASurfaceTransactionCreate));
  lib->RegisterSymbol("ASurfaceTransaction_delete",
                      reinterpret_cast<void*>(&StubASurfaceTransactionDelete));
  lib->RegisterSymbol("ASurfaceTransaction_apply",
                      reinterpret_cast<void*>(&StubASurfaceTransactionApply));
  lib->RegisterSymbol(
      "ASurfaceTransaction_reparent",
      reinterpret_cast<void*>(&StubASurfaceTransactionReparent));
  lib->RegisterSymbol(
      "ASurfaceTransaction_setVisibility",
      reinterpret_cast<void*>(&StubASurfaceTransactionSetVisibility));
  lib->RegisterSymbol(
      "ASurfaceTransaction_setZOrder",
      reinterpret_cast<void*>(&StubASurfaceTransactionSetZOrder));
  lib->RegisterSymbol(
      "ASurfaceTransaction_setBuffer",
      reinterpret_cast<void*>(&StubASurfaceTransactionSetBuffer));
  lib->RegisterSymbol(
      "ASurfaceTransaction_setGeometry",
      reinterpret_cast<void*>(&StubASurfaceTransactionSetGeometry));
  lib->RegisterSymbol(
      "ASurfaceTransaction_setBufferAlpha",
      reinterpret_cast<void*>(&StubASurfaceTransactionSetBufferAlpha));
  return lib;
}

// =============================================================================
// Mock Vulkan Driver Environment for kDeferred + Swapchain + HCPP Testing
// =============================================================================

struct MockVulkanEnv {
  uint32_t vendor_id = kValidQualcommVendorId;
  uint32_t device_id = kValidDeviceId;
  uint32_t device_type = kDiscreteGpuDeviceType;
  std::string device_name = "Adreno (TM) 740";
  uint32_t sample_counts = kVkSampleCount1Bit | kVkSampleCount4Bit;
  uint32_t color_format_features = kVkFormatFeatureColorAttachmentBit;
  uint32_t depth_stencil_features = kVkFormatFeatureDepthStencilAttachmentBit;
  uint32_t queue_flags =
      kVkQueueGraphicsBit | kVkQueueComputeBit | kVkQueueTransferBit;
  uint32_t support_ycbcr_feature = 1u;
  uint32_t support_16bit_storage_feature = 1u;
  bool include_ahb_device_extension = true;
  bool include_surface_instance_extension = true;
  bool fail_swapchain_with_native_window_in_use_once = false;
  bool fail_acquire_next_image = false;
  uint32_t reported_surface_transform = 0;  // 0 tests fallback to IDENTITY_BIT
  int exported_semaphore_fd = kSimulatedFenceFd;

  uint64_t next_handle = 0x8000;
  size_t create_swapchain_calls = 0;
  size_t queue_submit_calls = 0;
  size_t queue_present_calls = 0;
  size_t get_semaphore_fd_calls = 0;
};

MockVulkanEnv* g_vk_env = nullptr;

int32_t StubVkEnumerateInstanceExtensionProperties(
    const char* /*layer_name*/,
    uint32_t* count,
    VkExtensionPropertiesCompat* props) {
  std::vector<std::string> exts = {"VK_KHR_surface"};
  if (g_vk_env == nullptr || g_vk_env->include_surface_instance_extension) {
    exts.emplace_back("VK_KHR_android_surface");
  }
  if (props == nullptr) {
    *count = static_cast<uint32_t>(exts.size());
    return kVkSuccess;
  }
  const uint32_t to_write =
      std::min(*count, static_cast<uint32_t>(exts.size()));
  for (uint32_t i = 0; i < to_write; ++i) {
    std::memset(&props[i], 0, sizeof(VkExtensionPropertiesCompat));
    std::strncpy(props[i].extensionName, exts[i].c_str(),
                 kVkMaxExtensionNameSize - 1);
    props[i].specVersion = 1;
  }
  *count = to_write;
  return kVkSuccess;
}

int32_t StubVkCreateInstance(const VkInstanceCreateInfoCompat* /*create_info*/,
                             const void* /*allocator*/,
                             void** instance_out) {
  *instance_out = reinterpret_cast<void*>(0x7001);
  return kVkSuccess;
}

void StubVkDestroyInstance(void* /*instance*/, const void* /*allocator*/) {}

int32_t StubVkEnumeratePhysicalDevices(void* /*instance*/,
                                       uint32_t* count,
                                       void** physical_devices) {
  if (physical_devices == nullptr) {
    *count = 1;
    return kVkSuccess;
  }
  if (*count >= 1) {
    physical_devices[0] = reinterpret_cast<void*>(0x7002);
    *count = 1;
  }
  return kVkSuccess;
}

void StubVkGetPhysicalDeviceProperties(
    void* /*physical_device*/,
    VkPhysicalDevicePropertiesCompat* props) {
  std::memset(props, 0, sizeof(VkPhysicalDevicePropertiesCompat));
  props->apiVersion = kVkApiVersion11;
  props->driverVersion = kVkApiVersion11;
  props->vendorID =
      g_vk_env != nullptr ? g_vk_env->vendor_id : kValidQualcommVendorId;
  props->deviceID = g_vk_env != nullptr ? g_vk_env->device_id : kValidDeviceId;
  props->deviceType =
      g_vk_env != nullptr ? g_vk_env->device_type : kDiscreteGpuDeviceType;
  const std::string name =
      g_vk_env != nullptr ? g_vk_env->device_name : "Adreno (TM) 740";
  std::strncpy(props->deviceName, name.c_str(),
               kVkMaxPhysicalDeviceNameSize - 1);
  props->limits.framebufferColorSampleCounts =
      g_vk_env != nullptr ? g_vk_env->sample_counts
                          : (kVkSampleCount1Bit | kVkSampleCount4Bit);
}

void StubVkGetPhysicalDeviceFormatProperties(void* /*physical_device*/,
                                             uint32_t format,
                                             VkFormatPropertiesCompat* props) {
  std::memset(props, 0, sizeof(VkFormatPropertiesCompat));
  if (format == kVkFormatR8G8B8A8Unorm) {
    props->optimalTilingFeatures = g_vk_env != nullptr
                                       ? g_vk_env->color_format_features
                                       : kVkFormatFeatureColorAttachmentBit;
  } else if (format == kVkFormatD32SfloatS8Uint ||
             format == kVkFormatD24UnormS8Uint) {
    props->optimalTilingFeatures =
        g_vk_env != nullptr ? g_vk_env->depth_stencil_features
                            : kVkFormatFeatureDepthStencilAttachmentBit;
  }
}

void StubVkGetPhysicalDeviceQueueFamilyProperties(
    void* /*physical_device*/,
    uint32_t* count,
    VkQueueFamilyPropertiesCompat* props) {
  if (props == nullptr) {
    *count = 1;
    return;
  }
  if (*count >= 1) {
    std::memset(&props[0], 0, sizeof(VkQueueFamilyPropertiesCompat));
    props[0].queueCount = 1;
    props[0].queueFlags =
        g_vk_env != nullptr
            ? g_vk_env->queue_flags
            : (kVkQueueGraphicsBit | kVkQueueComputeBit | kVkQueueTransferBit);
    *count = 1;
  }
}

void StubVkGetPhysicalDeviceFeatures2(
    void* /*physical_device*/,
    VkPhysicalDeviceFeatures2Compat* features) {
  void* next = features != nullptr ? features->pNext : nullptr;
  while (next != nullptr) {
    auto* header = static_cast<uint32_t*>(next);
    if (*header ==
        kVkStructureTypePhysicalDeviceSamplerYcbcrConversionFeatures) {
      auto* ycbcr =
          static_cast<VkPhysicalDeviceSamplerYcbcrConversionFeaturesCompat*>(
              next);
      ycbcr->samplerYcbcrConversion =
          g_vk_env != nullptr ? g_vk_env->support_ycbcr_feature : 1u;
      next = ycbcr->pNext;
    } else if (*header == kVkStructureTypePhysicalDevice16BitStorageFeatures) {
      auto* storage =
          static_cast<VkPhysicalDevice16BitStorageFeaturesCompat*>(next);
      storage->uniformAndStorageBuffer16BitAccess =
          g_vk_env != nullptr ? g_vk_env->support_16bit_storage_feature : 1u;
      next = storage->pNext;
    } else {
      break;
    }
  }
}

int32_t StubVkEnumerateDeviceExtensionProperties(
    void* /*physical_device*/,
    const char* /*layer_name*/,
    uint32_t* count,
    VkExtensionPropertiesCompat* props) {
  std::vector<std::string> exts = {
      "VK_KHR_swapchain",
      "VK_KHR_sampler_ycbcr_conversion",
      "VK_KHR_external_memory",
      "VK_EXT_queue_family_foreign",
      "VK_KHR_dedicated_allocation",
      "VK_KHR_external_semaphore",
      "VK_KHR_external_semaphore_fd",
  };
  if (g_vk_env == nullptr || g_vk_env->include_ahb_device_extension) {
    exts.emplace_back("VK_ANDROID_external_memory_android_hardware_buffer");
  }
  if (props == nullptr) {
    *count = static_cast<uint32_t>(exts.size());
    return kVkSuccess;
  }
  const uint32_t to_write =
      std::min(*count, static_cast<uint32_t>(exts.size()));
  for (uint32_t i = 0; i < to_write; ++i) {
    std::memset(&props[i], 0, sizeof(VkExtensionPropertiesCompat));
    std::strncpy(props[i].extensionName, exts[i].c_str(),
                 kVkMaxExtensionNameSize - 1);
    props[i].specVersion = 1;
  }
  *count = to_write;
  return kVkSuccess;
}

int32_t StubVkCreateDevice(void* /*physical_device*/,
                           const VkDeviceCreateInfoCompat* /*create_info*/,
                           const void* /*allocator*/,
                           void** device_out) {
  *device_out = reinterpret_cast<void*>(0x7003);
  return kVkSuccess;
}

void StubVkDestroyDevice(void* /*device*/, const void* /*allocator*/) {}

void StubVkGetDeviceQueue(void* /*device*/,
                          uint32_t /*queue_family_index*/,
                          uint32_t /*queue_index*/,
                          void** queue_out) {
  *queue_out = reinterpret_cast<void*>(0x7004);
}

int32_t StubVkCreateAndroidSurfaceKHR(
    void* /*instance*/,
    const VkAndroidSurfaceCreateInfoKHRCompat* /*create_info*/,
    const void* /*allocator*/,
    uint64_t* surface_out) {
  *surface_out = g_vk_env != nullptr ? ++g_vk_env->next_handle : 0x8001;
  return kVkSuccess;
}

void StubVkDestroySurfaceKHR(void* /*instance*/,
                             uint64_t /*surface*/,
                             const void* /*allocator*/) {}

int32_t StubVkGetPhysicalDeviceSurfaceCapabilitiesKHR(
    void* /*physical_device*/,
    uint64_t /*surface*/,
    VkSurfaceCapabilitiesKHRCompat* caps) {
  std::memset(caps, 0, sizeof(VkSurfaceCapabilitiesKHRCompat));
  caps->minImageCount = 2;
  caps->maxImageCount = 4;
  caps->currentExtent = {kTestSurfaceWidth, kTestSurfaceHeight};
  caps->currentTransform =
      g_vk_env != nullptr ? g_vk_env->reported_surface_transform : 0;
  caps->supportedTransforms = kVkSurfaceTransformIdentityBitKhr;
  caps->supportedCompositeAlpha = kVkCompositeAlphaOpaqueBitKhr;
  return kVkSuccess;
}

int32_t StubVkGetPhysicalDeviceSurfaceFormatsKHR(
    void* /*physical_device*/,
    uint64_t /*surface*/,
    uint32_t* count,
    VkSurfaceFormatKHRCompat* formats) {
  if (formats == nullptr) {
    *count = 1;
    return kVkSuccess;
  }
  if (*count >= 1) {
    formats[0].format = kVkFormatR8G8B8A8Unorm;
    formats[0].colorSpace = kVkColorSpaceSrgbNonlinearKhr;
    *count = 1;
  }
  return kVkSuccess;
}

int32_t StubVkCreateSwapchainKHR(
    void* /*device*/,
    const VkSwapchainCreateInfoKHRCompat* /*create_info*/,
    const void* /*allocator*/,
    uint64_t* swapchain_out) {
  if (g_vk_env != nullptr) {
    ++g_vk_env->create_swapchain_calls;
    if (g_vk_env->fail_swapchain_with_native_window_in_use_once) {
      g_vk_env->fail_swapchain_with_native_window_in_use_once = false;
      return kVkErrorNativeWindowInUseKhr;
    }
  }
  *swapchain_out = g_vk_env != nullptr ? ++g_vk_env->next_handle : 0x8100;
  return kVkSuccess;
}

void StubVkDestroySwapchainKHR(void* /*device*/,
                               uint64_t /*swapchain*/,
                               const void* /*allocator*/) {}

int32_t StubVkGetSwapchainImagesKHR(void* /*device*/,
                                    uint64_t /*swapchain*/,
                                    uint32_t* count,
                                    uint64_t* images) {
  if (images == nullptr) {
    *count = 2;
    return kVkSuccess;
  }
  if (*count >= 2) {
    images[0] = 0x9001;
    images[1] = 0x9002;
    *count = 2;
  }
  return kVkSuccess;
}

int32_t StubVkAcquireNextImageKHR(void* /*device*/,
                                  uint64_t /*swapchain*/,
                                  uint64_t /*timeout*/,
                                  uint64_t /*semaphore*/,
                                  uint64_t /*fence*/,
                                  uint32_t* image_index_out) {
  if (g_vk_env != nullptr && g_vk_env->fail_acquire_next_image) {
    return kVkErrorSurfaceLostKhr;
  }
  *image_index_out = 0;
  return kVkSuccess;
}

int32_t StubVkQueuePresentKHR(void* /*queue*/,
                              const VkPresentInfoKHRCompat* /*present_info*/) {
  if (g_vk_env != nullptr) {
    ++g_vk_env->queue_present_calls;
  }
  return kVkSuccess;
}

int32_t StubVkQueueSubmit(void* /*queue*/,
                          uint32_t /*submit_count*/,
                          const VkSubmitInfoCompat* /*submits*/,
                          uint64_t /*fence*/) {
  if (g_vk_env != nullptr) {
    ++g_vk_env->queue_submit_calls;
  }
  return kVkSuccess;
}

int32_t StubVkQueueWaitIdle(void* /*queue*/) {
  return kVkSuccess;
}

int32_t StubVkCreateFence(void* /*device*/,
                          const VkFenceCreateInfoCompat* /*create_info*/,
                          const void* /*allocator*/,
                          uint64_t* fence_out) {
  *fence_out = g_vk_env != nullptr ? ++g_vk_env->next_handle : 0x8200;
  return kVkSuccess;
}

void StubVkDestroyFence(void* /*device*/,
                        uint64_t /*fence*/,
                        const void* /*allocator*/) {}

int32_t StubVkWaitForFences(void* /*device*/,
                            uint32_t /*fence_count*/,
                            const uint64_t* /*fences*/,
                            uint32_t /*wait_all*/,
                            uint64_t /*timeout*/) {
  return kVkSuccess;
}

int32_t StubVkResetFences(void* /*device*/,
                          uint32_t /*fence_count*/,
                          const uint64_t* /*fences*/) {
  return kVkSuccess;
}

int32_t StubVkCreateSemaphore(
    void* /*device*/,
    const VkSemaphoreCreateInfoCompat* /*create_info*/,
    const void* /*allocator*/,
    uint64_t* semaphore_out) {
  *semaphore_out = g_vk_env != nullptr ? ++g_vk_env->next_handle : 0x8300;
  return kVkSuccess;
}

void StubVkDestroySemaphore(void* /*device*/,
                            uint64_t /*semaphore*/,
                            const void* /*allocator*/) {}

int32_t StubVkGetSemaphoreFdKHR(void* /*device*/,
                                const VkSemaphoreGetFdInfoKHRCompat* /*info*/,
                                int* fd_out) {
  if (g_vk_env != nullptr) {
    ++g_vk_env->get_semaphore_fd_calls;
    *fd_out = g_vk_env->exported_semaphore_fd;
  } else {
    *fd_out = kSimulatedFenceFd;
  }
  return kVkSuccess;
}

int32_t StubVkCreateCommandPool(
    void* /*device*/,
    const VkCommandPoolCreateInfoCompat* /*create_info*/,
    const void* /*allocator*/,
    uint64_t* pool_out) {
  *pool_out = g_vk_env != nullptr ? ++g_vk_env->next_handle : 0x8400;
  return kVkSuccess;
}

void StubVkDestroyCommandPool(void* /*device*/,
                              uint64_t /*command_pool*/,
                              const void* /*allocator*/) {}

int32_t StubVkAllocateCommandBuffers(
    void* /*device*/,
    const VkCommandBufferAllocateInfoCompat* alloc_info,
    void** command_buffers_out) {
  for (uint32_t i = 0; i < alloc_info->commandBufferCount; ++i) {
    command_buffers_out[i] =
        reinterpret_cast<void*>(static_cast<uintptr_t>(0x8500 + i));
  }
  return kVkSuccess;
}

int32_t StubVkResetCommandBuffer(void* /*command_buffer*/, uint32_t /*flags*/) {
  return kVkSuccess;
}

int32_t StubVkBeginCommandBuffer(
    void* /*command_buffer*/,
    const VkCommandBufferBeginInfoCompat* /*begin_info*/) {
  return kVkSuccess;
}

int32_t StubVkEndCommandBuffer(void* /*command_buffer*/) {
  return kVkSuccess;
}

void StubVkCmdPipelineBarrier(
    void* /*command_buffer*/,
    uint32_t /*src_stage_mask*/,
    uint32_t /*dst_stage_mask*/,
    uint32_t /*dependency_flags*/,
    uint32_t /*memory_barrier_count*/,
    const void* /*memory_barriers*/,
    uint32_t /*buffer_memory_barrier_count*/,
    const void* /*buffer_memory_barriers*/,
    uint32_t /*image_memory_barrier_count*/,
    const VkImageMemoryBarrierCompat* /*image_memory_barriers*/) {}

void* StubVkGetInstanceProcAddr(void* /*instance*/, const char* /*name*/);

void* StubVkGetDeviceProcAddr(void* device, const char* name) {
  return StubVkGetInstanceProcAddr(device, name);
}

void* StubVkGetInstanceProcAddr(void* /*instance*/, const char* name) {
  if (name == nullptr) {
    return nullptr;
  }
  const std::string sym(name);
  if (sym == "vkGetInstanceProcAddr") {
    // Real Android libvulkan.so returns nullptr for
    // vkGetInstanceProcAddr(nullptr, "vkGetInstanceProcAddr"); verify
    // AndroidSurfaceControl::GetInstanceProcAddressCallback returns the
    // resolved function pointer directly.
    return nullptr;
  }
  if (sym == "vkEnumerateInstanceExtensionProperties") {
    return reinterpret_cast<void*>(&StubVkEnumerateInstanceExtensionProperties);
  }
  if (sym == "vkCreateInstance") {
    return reinterpret_cast<void*>(&StubVkCreateInstance);
  }
  if (sym == "vkDestroyInstance") {
    return reinterpret_cast<void*>(&StubVkDestroyInstance);
  }
  if (sym == "vkEnumeratePhysicalDevices") {
    return reinterpret_cast<void*>(&StubVkEnumeratePhysicalDevices);
  }
  if (sym == "vkGetPhysicalDeviceProperties") {
    return reinterpret_cast<void*>(&StubVkGetPhysicalDeviceProperties);
  }
  if (sym == "vkGetPhysicalDeviceFormatProperties") {
    return reinterpret_cast<void*>(&StubVkGetPhysicalDeviceFormatProperties);
  }
  if (sym == "vkGetPhysicalDeviceQueueFamilyProperties") {
    return reinterpret_cast<void*>(
        &StubVkGetPhysicalDeviceQueueFamilyProperties);
  }
  if (sym == "vkGetPhysicalDeviceFeatures2" ||
      sym == "vkGetPhysicalDeviceFeatures2KHR") {
    return reinterpret_cast<void*>(&StubVkGetPhysicalDeviceFeatures2);
  }
  if (sym == "vkEnumerateDeviceExtensionProperties") {
    return reinterpret_cast<void*>(&StubVkEnumerateDeviceExtensionProperties);
  }
  if (sym == "vkCreateDevice") {
    return reinterpret_cast<void*>(&StubVkCreateDevice);
  }
  if (sym == "vkDestroyDevice") {
    return reinterpret_cast<void*>(&StubVkDestroyDevice);
  }
  if (sym == "vkGetDeviceProcAddr") {
    return reinterpret_cast<void*>(&StubVkGetDeviceProcAddr);
  }
  if (sym == "vkGetDeviceQueue") {
    return reinterpret_cast<void*>(&StubVkGetDeviceQueue);
  }
  if (sym == "vkCreateAndroidSurfaceKHR") {
    return reinterpret_cast<void*>(&StubVkCreateAndroidSurfaceKHR);
  }
  if (sym == "vkDestroySurfaceKHR") {
    return reinterpret_cast<void*>(&StubVkDestroySurfaceKHR);
  }
  if (sym == "vkGetPhysicalDeviceSurfaceCapabilitiesKHR") {
    return reinterpret_cast<void*>(
        &StubVkGetPhysicalDeviceSurfaceCapabilitiesKHR);
  }
  if (sym == "vkGetPhysicalDeviceSurfaceFormatsKHR") {
    return reinterpret_cast<void*>(&StubVkGetPhysicalDeviceSurfaceFormatsKHR);
  }
  if (sym == "vkCreateSwapchainKHR") {
    return reinterpret_cast<void*>(&StubVkCreateSwapchainKHR);
  }
  if (sym == "vkDestroySwapchainKHR") {
    return reinterpret_cast<void*>(&StubVkDestroySwapchainKHR);
  }
  if (sym == "vkGetSwapchainImagesKHR") {
    return reinterpret_cast<void*>(&StubVkGetSwapchainImagesKHR);
  }
  if (sym == "vkAcquireNextImageKHR") {
    return reinterpret_cast<void*>(&StubVkAcquireNextImageKHR);
  }
  if (sym == "vkQueuePresentKHR") {
    return reinterpret_cast<void*>(&StubVkQueuePresentKHR);
  }
  if (sym == "vkQueueSubmit") {
    return reinterpret_cast<void*>(&StubVkQueueSubmit);
  }
  if (sym == "vkQueueWaitIdle") {
    return reinterpret_cast<void*>(&StubVkQueueWaitIdle);
  }
  if (sym == "vkCreateFence") {
    return reinterpret_cast<void*>(&StubVkCreateFence);
  }
  if (sym == "vkDestroyFence") {
    return reinterpret_cast<void*>(&StubVkDestroyFence);
  }
  if (sym == "vkWaitForFences") {
    return reinterpret_cast<void*>(&StubVkWaitForFences);
  }
  if (sym == "vkResetFences") {
    return reinterpret_cast<void*>(&StubVkResetFences);
  }
  if (sym == "vkCreateSemaphore") {
    return reinterpret_cast<void*>(&StubVkCreateSemaphore);
  }
  if (sym == "vkDestroySemaphore") {
    return reinterpret_cast<void*>(&StubVkDestroySemaphore);
  }
  if (sym == "vkGetSemaphoreFdKHR") {
    return reinterpret_cast<void*>(&StubVkGetSemaphoreFdKHR);
  }
  if (sym == "vkCreateCommandPool") {
    return reinterpret_cast<void*>(&StubVkCreateCommandPool);
  }
  if (sym == "vkDestroyCommandPool") {
    return reinterpret_cast<void*>(&StubVkDestroyCommandPool);
  }
  if (sym == "vkAllocateCommandBuffers") {
    return reinterpret_cast<void*>(&StubVkAllocateCommandBuffers);
  }
  if (sym == "vkResetCommandBuffer") {
    return reinterpret_cast<void*>(&StubVkResetCommandBuffer);
  }
  if (sym == "vkBeginCommandBuffer") {
    return reinterpret_cast<void*>(&StubVkBeginCommandBuffer);
  }
  if (sym == "vkEndCommandBuffer") {
    return reinterpret_cast<void*>(&StubVkEndCommandBuffer);
  }
  if (sym == "vkCmdPipelineBarrier") {
    return reinterpret_cast<void*>(&StubVkCmdPipelineBarrier);
  }
  return nullptr;
}

std::shared_ptr<MockOSLibraryLoader> CreateMockVulkanLibraryLoader() {
  auto loader = std::make_shared<MockOSLibraryLoader>();
  auto vk_lib = std::make_shared<MockOSLibrary>();
  vk_lib->RegisterSymbol("vkGetInstanceProcAddr",
                         reinterpret_cast<void*>(&StubVkGetInstanceProcAddr));
  loader->RegisterLibrary("libvulkan.so", vk_lib);
  loader->RegisterLibrary("libEGL.so", std::make_shared<MockOSLibrary>());
  loader->RegisterLibrary("libGLESv2.so", std::make_shared<MockOSLibrary>());
  return loader;
}

}  // namespace

// =============================================================================
// Type & InMemory SurfaceControl / Transaction Tests
// =============================================================================

TEST(AndroidSurfaceControlTest, RectAndStatsAndColorEquality) {
  AndroidSurfaceControlRect rect = {kTestRectLeft, kTestRectTop, kTestRectRight,
                                    kTestRectBottom};
  EXPECT_EQ(rect.Width(), kExpectedRectWidth);
  EXPECT_EQ(rect.Height(), kExpectedRectHeight);
  EXPECT_TRUE(rect.IsValid());

  AndroidSurfaceControlRect invalid_rect = {kTestRectRight, kTestRectBottom,
                                            kTestRectLeft, kTestRectTop};
  EXPECT_FALSE(invalid_rect.IsValid());
  EXPECT_NE(rect, invalid_rect);

  AndroidSurfaceControlStats stats1 = {100LL, 3, 200LL, 4};
  AndroidSurfaceControlStats stats2 = {100LL, 3, 200LL, 4};
  EXPECT_EQ(stats1, stats2);

  AndroidSurfaceControlColor color1 = {0.2f, 0.4f, 0.6f, 1.0f};
  AndroidSurfaceControlColor color2 = {0.2f, 0.4f, 0.6f, 1.0f};
  EXPECT_EQ(color1, color2);
}

TEST(AndroidSurfaceControlTest, InMemoryProviderAndTransactionOperations) {
  InMemoryAndroidSurfaceControlProvider provider(true);
  EXPECT_TRUE(provider.IsAvailable());

  auto root = provider.CreateFromWindow(
      reinterpret_cast<void*>(kDummyNativeWindow1), "root_surface");
  ASSERT_NE(root, nullptr);
  EXPECT_TRUE(root->IsValid());
  EXPECT_EQ(root->DebugName(), "root_surface");

  auto child = provider.CreateFromParent(root.get(), "child_surface");
  ASSERT_NE(child, nullptr);
  EXPECT_TRUE(child->IsValid());

  AndroidSurfaceControlStats expected_stats = {111LL, 12, 222LL, 13};
  provider.SetSimulatedStats(expected_stats);

  auto tx = provider.CreateTransaction();
  ASSERT_NE(tx, nullptr);

  tx->SetVisibility(child.get(), AndroidSurfaceControlVisibility::kHide);
  tx->SetZOrder(child.get(), 5);
  tx->SetBuffer(child.get(), reinterpret_cast<void*>(kDummyHardwareBuffer),
                kSimulatedFenceFd);
  tx->SetGeometry(child.get(), {0, 0, 100, 100}, {10, 10, 110, 110},
                  AndroidSurfaceControlTransform::kRotate90);
  tx->SetBufferAlpha(child.get(), 1.5f);  // Clamped to 1.0f.
  tx->SetColor(child.get(), {0.1f, 0.2f, 0.3f, 1.0f});
  tx->SetFrameRate(child.get(), 120.0f, 1);
  tx->SetEnableBackPressure(child.get(), true);

  bool commit_called = false;
  bool complete_called = false;
  tx->SetOnCommitCallback([&](const AndroidSurfaceControlStats& stats) {
    commit_called = true;
    EXPECT_EQ(stats, expected_stats);
  });
  tx->SetOnCompleteCallback([&](const AndroidSurfaceControlStats& stats) {
    complete_called = true;
    EXPECT_EQ(stats, expected_stats);
  });

  tx->Apply();
  EXPECT_TRUE(commit_called);
  EXPECT_TRUE(complete_called);

  auto* mem_child = static_cast<InMemoryAndroidSurfaceControl*>(child.get());
  EXPECT_FALSE(mem_child->state().visible);
  EXPECT_EQ(mem_child->state().z_order, 5);
  EXPECT_EQ(mem_child->state().current_hardware_buffer,
            reinterpret_cast<void*>(kDummyHardwareBuffer));
  EXPECT_EQ(mem_child->state().current_acquire_fence_fd, kSimulatedFenceFd);
  EXPECT_EQ(mem_child->state().transform,
            AndroidSurfaceControlTransform::kRotate90);
  EXPECT_FLOAT_EQ(mem_child->state().alpha, 1.0f);
  EXPECT_TRUE(mem_child->state().has_color);
  EXPECT_FLOAT_EQ(mem_child->state().requested_frame_rate, 120.0f);
  EXPECT_TRUE(mem_child->state().enable_back_pressure);
}

TEST(AndroidSurfaceControlTest, DefaultProviderResolvesNdkSymbols) {
  MockNdkSurfaceControlEnv ndk_env;
  g_ndk_env = &ndk_env;

  auto loader = std::make_shared<MockOSLibraryLoader>();
  loader->RegisterLibrary("libandroid.so", CreateMockNdkAndroidLibrary());

  DefaultAndroidSurfaceControlProvider provider(loader);
  EXPECT_TRUE(provider.IsAvailable());

  auto surface = provider.CreateFromWindow(
      reinterpret_cast<void*>(kDummyNativeWindow1), "ndk_root");
  ASSERT_NE(surface, nullptr);
  EXPECT_TRUE(surface->IsValid());

  auto tx = provider.CreateTransaction();
  ASSERT_NE(tx, nullptr);
  tx->SetBuffer(surface.get(), reinterpret_cast<void*>(kDummyHardwareBuffer),
                kSimulatedFenceFd);
  tx->Apply();

  EXPECT_EQ(ndk_env.last_buffer, reinterpret_cast<void*>(kDummyHardwareBuffer));
  EXPECT_EQ(ndk_env.last_fence_fd, kSimulatedFenceFd);
  EXPECT_EQ(ndk_env.transaction_apply_count, 1);

  tx.reset();
  surface.reset();
  EXPECT_EQ(ndk_env.transaction_delete_count, 1);
  EXPECT_EQ(ndk_env.release_count, 1);

  g_ndk_env = nullptr;
}

// =============================================================================
// Per-FlutterViewId Surface Lifecycle & Low Memory Warning Tests
// =============================================================================

TEST(AndroidSurfaceControlTest,
     PerViewSurfacesAreKeyedByFlutterViewIdAndTriggerLowMemoryOnLastDestroy) {
  AndroidSurfaceControl controller(CreateMockVulkanLibraryLoader());

  static size_t s_low_memory_calls = 0;
  s_low_memory_calls = 0;
  FlutterEngineProcTable procs = {};
  procs.struct_size = sizeof(FlutterEngineProcTable);
  procs.NotifyLowMemoryWarning = [](FLUTTER_API_SYMBOL(FlutterEngine) engine) {
    if (engine != nullptr) {
      ++s_low_memory_calls;
    }
    return kSuccess;
  };
  controller.SetEngineProcTable(
      procs,
      reinterpret_cast<FLUTTER_API_SYMBOL(FlutterEngine)>(kDummyEngineHandle));

  EXPECT_TRUE(controller.SurfaceCreated(
      kPrimaryViewId, reinterpret_cast<void*>(kDummyNativeWindow1), nullptr,
      kTestSurfaceWidth, kTestSurfaceHeight));
  EXPECT_TRUE(controller.SurfaceCreated(
      kSecondaryViewId, reinterpret_cast<void*>(kDummyNativeWindow2),
      reinterpret_cast<void*>(kDummySurfaceControlHandle), kResizedSurfaceWidth,
      kResizedSurfaceHeight));

  EXPECT_TRUE(controller.HasSurface(kPrimaryViewId));
  EXPECT_TRUE(controller.HasSurface(kSecondaryViewId));
  EXPECT_EQ(controller.GetNativeWindow(kPrimaryViewId),
            reinterpret_cast<void*>(kDummyNativeWindow1));
  EXPECT_EQ(controller.GetNativeWindow(kSecondaryViewId),
            reinterpret_cast<void*>(kDummyNativeWindow2));
  EXPECT_EQ(controller.GetASurfaceControl(kSecondaryViewId),
            reinterpret_cast<void*>(kDummySurfaceControlHandle));

  // Destroying primary view while secondary view is still visible must NOT
  // emit NotifyLowMemoryWarning.
  controller.SurfaceDestroyed(kPrimaryViewId);
  EXPECT_FALSE(controller.HasSurface(kPrimaryViewId));
  EXPECT_TRUE(controller.HasSurface(kSecondaryViewId));
  EXPECT_EQ(s_low_memory_calls, 0u);

  // Destroying the last visible view MUST emit NotifyLowMemoryWarning.
  controller.SurfaceDestroyed(kSecondaryViewId);
  EXPECT_FALSE(controller.HasSurface(kSecondaryViewId));
  EXPECT_EQ(s_low_memory_calls, 1u);

  // OnTrimMemory below threshold is ignored; >= TRIM_MEMORY_RUNNING_LOW (10)
  // and TRIM_MEMORY_UI_HIDDEN (20) emit NotifyLowMemoryWarning.
  controller.OnTrimMemory(kTrimMemoryBelowThresholdLevel);
  EXPECT_EQ(s_low_memory_calls, 1u);
  controller.OnTrimMemory(kTrimMemoryRunningLowLevel);
  EXPECT_EQ(s_low_memory_calls, 2u);
  controller.OnTrimMemory(kTrimMemoryUiHiddenLevel);
  EXPECT_EQ(s_low_memory_calls, 3u);
}

// =============================================================================
// kDeferred Renderer Resolution Tests (System Properties + VulkanDriverInfo +
// CapabilitiesVK)
// =============================================================================

TEST(AndroidSurfaceControlTest,
     DeferredRendererSystemPropertiesRejectEmulatorsHuaweiMediaTekAndBadSocs) {
  AndroidSystemPropertiesForVulkan base_props;

  // 1. Emulator via ro.hardware = "ranchu"
  {
    auto props = base_props;
    props.ro_hardware = "ranchu";
    EXPECT_EQ(AndroidSurfaceControl::EvaluateSystemProperties(props),
              AndroidVulkanResolutionStatus::kEmulatorDetected);
  }
  // 2. Emulator via ro.product.model containing "gphone"
  {
    auto props = base_props;
    props.ro_product_model = "sdk_gphone64_arm64";
    EXPECT_EQ(AndroidSurfaceControl::EvaluateSystemProperties(props),
              AndroidVulkanResolutionStatus::kEmulatorDetected);
  }
  // 3. Emulator via /dev/qemu_pipe
  {
    auto props = base_props;
    props.has_qemu_pipe = true;
    EXPECT_EQ(AndroidSurfaceControl::EvaluateSystemProperties(props),
              AndroidVulkanResolutionStatus::kEmulatorDetected);
  }
  // 4. Huawei clientidbase
  {
    auto props = base_props;
    props.ro_clientidbase = "android-huawei";
    EXPECT_EQ(AndroidSurfaceControl::EvaluateSystemProperties(props),
              AndroidVulkanResolutionStatus::kHuaweiClientIdRejected);
  }
  // 5. MediaTek vendor SDK < 32
  {
    auto props = base_props;
    props.ro_mediatek_platform = "MT6853";
    props.vendor_api_level = 31;
    EXPECT_EQ(AndroidSurfaceControl::EvaluateSystemProperties(props),
              AndroidVulkanResolutionStatus::kMediaTekVendorSdkTooLow);
  }
  // 6. Known bad SoC board (`kBadSocs`)
  {
    auto props = base_props;
    props.ro_product_board = "exynos9810";
    EXPECT_EQ(AndroidSurfaceControl::EvaluateSystemProperties(props),
              AndroidVulkanResolutionStatus::kBadSocBoardRejected);
  }
}

TEST(AndroidSurfaceControlTest,
     DeferredRendererFallsBackToOpenGLOnKnownBadDriverOrMissingCapabilities) {
  // 1. Known bad Vulkan driver via `flutter::VulkanDriverInfo` (Imagination /
  // PowerVR).
  {
    MockVulkanEnv vk_env;
    vk_env.vendor_id = kBlockedImaginationVendorId;
    g_vk_env = &vk_env;

    AndroidSurfaceControl controller(CreateMockVulkanLibraryLoader());
    FlutterRendererConfig config = {};
    controller.PopulateDeferredRendererConfig(&config);
    ASSERT_EQ(config.type, kDeferred);
    ASSERT_NE(config.deferred.resolve_callback, nullptr);

    FlutterRendererConfig resolved = {};
    EXPECT_TRUE(config.deferred.resolve_callback(&controller, &resolved));
    EXPECT_EQ(resolved.type, kOpenGL);
    EXPECT_EQ(controller.LastVulkanResolutionStatus(),
              AndroidVulkanResolutionStatus::kKnownBadVulkanDriver);
    g_vk_env = nullptr;
  }

  // 2. Missing `VK_ANDROID_external_memory_android_hardware_buffer` extension.
  {
    MockVulkanEnv vk_env;
    vk_env.include_ahb_device_extension = false;
    g_vk_env = &vk_env;

    AndroidSurfaceControl controller(CreateMockVulkanLibraryLoader());
    FlutterRendererConfig resolved = {};
    EXPECT_TRUE(controller.ResolveRendererConfig(&resolved));
    EXPECT_EQ(resolved.type, kOpenGL);
    EXPECT_EQ(controller.LastVulkanResolutionStatus(),
              AndroidVulkanResolutionStatus::kDeviceExtensionsMissing);
    g_vk_env = nullptr;
  }

  // 3. Unsupported required sample counts (`VK_SAMPLE_COUNT_4_BIT` missing).
  {
    MockVulkanEnv vk_env;
    vk_env.sample_counts = kVkSampleCount1Bit;
    g_vk_env = &vk_env;

    AndroidSurfaceControl controller(CreateMockVulkanLibraryLoader());
    FlutterRendererConfig resolved = {};
    EXPECT_TRUE(controller.ResolveRendererConfig(&resolved));
    EXPECT_EQ(resolved.type, kOpenGL);
    EXPECT_EQ(controller.LastVulkanResolutionStatus(),
              AndroidVulkanResolutionStatus::kRequiredSampleCountsUnsupported);
    g_vk_env = nullptr;
  }

  // 4. Unsupported depth-stencil attachment format.
  {
    MockVulkanEnv vk_env;
    vk_env.depth_stencil_features = 0;
    g_vk_env = &vk_env;

    AndroidSurfaceControl controller(CreateMockVulkanLibraryLoader());
    FlutterRendererConfig resolved = {};
    EXPECT_TRUE(controller.ResolveRendererConfig(&resolved));
    EXPECT_EQ(resolved.type, kOpenGL);
    EXPECT_EQ(
        controller.LastVulkanResolutionStatus(),
        AndroidVulkanResolutionStatus::kRequiredDepthStencilFormatUnsupported);
    g_vk_env = nullptr;
  }

  // 5. Missing required queue flags (`COMPUTE` missing).
  {
    MockVulkanEnv vk_env;
    vk_env.queue_flags = kVkQueueGraphicsBit | kVkQueueTransferBit;
    g_vk_env = &vk_env;

    AndroidSurfaceControl controller(CreateMockVulkanLibraryLoader());
    FlutterRendererConfig resolved = {};
    EXPECT_TRUE(controller.ResolveRendererConfig(&resolved));
    EXPECT_EQ(resolved.type, kOpenGL);
    EXPECT_EQ(controller.LastVulkanResolutionStatus(),
              AndroidVulkanResolutionStatus::kRequiredQueuesMissing);
    g_vk_env = nullptr;
  }

  // 6. Missing `samplerYcbcrConversion` physical device feature.
  {
    MockVulkanEnv vk_env;
    vk_env.support_ycbcr_feature = 0u;
    g_vk_env = &vk_env;

    AndroidSurfaceControl controller(CreateMockVulkanLibraryLoader());
    FlutterRendererConfig resolved = {};
    EXPECT_TRUE(controller.ResolveRendererConfig(&resolved));
    EXPECT_EQ(resolved.type, kOpenGL);
    EXPECT_EQ(controller.LastVulkanResolutionStatus(),
              AndroidVulkanResolutionStatus::kRequiredFeaturesUnsupported);
    g_vk_env = nullptr;
  }
}

TEST(AndroidSurfaceControlTest,
     DeferredRendererResolvesVulkanInSinglePassAndPresentsFromGeneralLayout) {
  MockVulkanEnv vk_env;
  vk_env.fail_swapchain_with_native_window_in_use_once = true;
  vk_env.reported_surface_transform =
      0x2u;  // VK_SURFACE_TRANSFORM_ROTATE_90_BIT_KHR -> must still use
             // IDENTITY_BIT_KHR
  g_vk_env = &vk_env;

  AndroidSurfaceControl controller(CreateMockVulkanLibraryLoader());
  FlutterRendererConfig deferred_config = {};
  controller.PopulateDeferredRendererConfig(&deferred_config);
  ASSERT_EQ(deferred_config.type, kDeferred);

  FlutterRendererConfig resolved = {};
  ASSERT_TRUE(
      deferred_config.deferred.resolve_callback(&controller, &resolved));
  EXPECT_EQ(resolved.type, kVulkan);
  EXPECT_EQ(controller.LastVulkanResolutionStatus(),
            AndroidVulkanResolutionStatus::kSelectedVulkan);
  EXPECT_NE(resolved.vulkan.instance, nullptr);
  EXPECT_NE(resolved.vulkan.physical_device, nullptr);
  EXPECT_NE(resolved.vulkan.device, nullptr);
  EXPECT_NE(resolved.vulkan.queue, nullptr);
  EXPECT_EQ(controller.GetVulkanInstance(), resolved.vulkan.instance);
  EXPECT_EQ(controller.GetVulkanPhysicalDevice(),
            resolved.vulkan.physical_device);
  EXPECT_EQ(controller.GetVulkanDevice(), resolved.vulkan.device);
  EXPECT_EQ(controller.GetVulkanQueue(), resolved.vulkan.queue);
  EXPECT_EQ(resolved.vulkan.get_instance_proc_address_callback(
                &controller, nullptr, "vkGetInstanceProcAddr"),
            reinterpret_cast<void*>(&StubVkGetInstanceProcAddr));

  // Attach native window and acquire next image. Because
  // `fail_swapchain_with_native_window_in_use_once` is true, swapchain creation
  // must retry without destroying the VkSurfaceKHR.
  ASSERT_TRUE(controller.SurfaceCreated(
      kPrimaryViewId, reinterpret_cast<void*>(kDummyNativeWindow1),
      reinterpret_cast<void*>(kDummySurfaceControlHandle), kTestSurfaceWidth,
      kTestSurfaceHeight));

  FlutterFrameInfo frame_info = {};
  frame_info.struct_size = sizeof(FlutterFrameInfo);
  frame_info.size = {kTestSurfaceWidth, kTestSurfaceHeight};

  FlutterVulkanImage acquired =
      resolved.vulkan.get_next_image_callback(&controller, &frame_info);
  EXPECT_NE(acquired.image, 0u);
  EXPECT_EQ(vk_env.create_swapchain_calls, 2u);
  EXPECT_EQ(controller.VulkanSurfaceDestroyCount(), 0u);
  EXPECT_EQ(controller.LastSwapchainPreTransform(kPrimaryViewId),
            kVkSurfaceTransformIdentityBitKhr);

  // PresentImage must transition from `VK_IMAGE_LAYOUT_GENERAL` to
  // `VK_IMAGE_LAYOUT_PRESENT_SRC_KHR` (avoiding VUID-vkCmdDraw-None-09600).
  EXPECT_TRUE(resolved.vulkan.present_image_callback(&controller, &acquired));
  EXPECT_EQ(controller.LastPresentBarrierOldLayout(), kVkImageLayoutGeneral);
  EXPECT_EQ(controller.LastPresentBarrierNewLayout(),
            kVkImageLayoutPresentSrcKhr);
  EXPECT_EQ(vk_env.queue_present_calls, 1u);

  // HCPP acquire sync fd export via `vkGetSemaphoreFdKHR` and attachment to
  // `AndroidSurfaceTransaction`.
  InMemoryAndroidSurfaceControlProvider sc_provider(true);
  auto sc_node = sc_provider.CreateFromWindow(
      reinterpret_cast<void*>(kDummyNativeWindow1), "hcpp_node");
  auto tx = sc_provider.CreateTransaction();

  const int exported_fd = controller.ExportHcppAcquireFenceFd(
      kPrimaryViewId, acquired.image, tx.get(), sc_node.get(),
      reinterpret_cast<void*>(kDummyHardwareBuffer));
  EXPECT_EQ(exported_fd, kSimulatedFenceFd);
  EXPECT_EQ(controller.LastExportedHcppFenceFd(), kSimulatedFenceFd);
  EXPECT_EQ(vk_env.get_semaphore_fd_calls, 1u);

  tx->Apply();
  auto* mem_sc = static_cast<InMemoryAndroidSurfaceControl*>(sc_node.get());
  EXPECT_EQ(mem_sc->state().current_acquire_fence_fd, kSimulatedFenceFd);
  EXPECT_EQ(mem_sc->state().current_hardware_buffer,
            reinterpret_cast<void*>(kDummyHardwareBuffer));

  g_vk_env = nullptr;
}

TEST(AndroidSurfaceControlTest,
     CreateBackingStoreReturnsFalseWhenSurfaceMissingOrLostMidFrame) {
  MockVulkanEnv vk_env;
  g_vk_env = &vk_env;

  AndroidSurfaceControl controller(CreateMockVulkanLibraryLoader());
  FlutterRendererConfig resolved = {};
  ASSERT_TRUE(controller.ResolveRendererConfig(&resolved));
  ASSERT_EQ(resolved.type, kVulkan);

  FlutterBackingStoreConfig bs_config = {};
  bs_config.struct_size = sizeof(FlutterBackingStoreConfig);
  bs_config.size = {static_cast<double>(kTestSurfaceWidth),
                    static_cast<double>(kTestSurfaceHeight)};
  bs_config.view_id = kPrimaryViewId;

  FlutterBackingStore bs = {};
  // No surface attached yet -> must return false.
  EXPECT_FALSE(controller.CreateBackingStore(&bs_config, &bs));

  // Attach surface, then simulate mid-frame surface loss during acquire.
  ASSERT_TRUE(controller.SurfaceCreated(
      kPrimaryViewId, reinterpret_cast<void*>(kDummyNativeWindow1), nullptr,
      kTestSurfaceWidth, kTestSurfaceHeight));
  vk_env.fail_acquire_next_image = true;
  EXPECT_FALSE(controller.CreateBackingStore(&bs_config, &bs));

  // Recover surface acquire -> CreateBackingStore and CollectBackingStore
  // succeed.
  vk_env.fail_acquire_next_image = false;
  EXPECT_TRUE(controller.CreateBackingStore(&bs_config, &bs));
  EXPECT_EQ(bs.type, kFlutterBackingStoreTypeVulkan);
  EXPECT_TRUE(controller.CollectBackingStore(&bs));

  g_vk_env = nullptr;
}

}  // namespace testing
}  // namespace android
}  // namespace flutter
