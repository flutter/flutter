// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/vulkan/vulkan_proc_table.h"

#include <dlfcn.h>

#include "flutter/fml/logging.h"

#define ACQUIRE_PROC(name, context)                          \
  if (!(name = AcquireProc("vk" #name, context))) {          \
    FML_DLOG(INFO) << "Could not acquire proc: vk" << #name; \
    return false;                                            \
  }

namespace vulkan {

VulkanProcTable::VulkanProcTable()
    : handle_(nullptr), acquired_mandatory_proc_addresses_(false) {
  acquired_mandatory_proc_addresses_ =
      OpenLibraryHandle() && SetupLoaderProcAddresses();
}

VulkanProcTable::~VulkanProcTable() {
  CloseLibraryHandle();
}

bool VulkanProcTable::HasAcquiredMandatoryProcAddresses() const {
  return acquired_mandatory_proc_addresses_;
}

bool VulkanProcTable::IsValid() const {
  return instance_ && device_;
}

bool VulkanProcTable::AreInstanceProcsSetup() const {
  return instance_;
}

bool VulkanProcTable::AreDeviceProcsSetup() const {
  return device_;
}

bool VulkanProcTable::SetupLoaderProcAddresses() {
  if (handle_ == nullptr) {
    return true;
  }

  GetInstanceProcAddr =
#if VULKAN_LINK_STATICALLY
      GetInstanceProcAddr = &vkGetInstanceProcAddr;
#else   // VULKAN_LINK_STATICALLY
      reinterpret_cast<PFN_vkGetInstanceProcAddr>(
          dlsym(handle_, "vkGetInstanceProcAddr"));
#endif  // VULKAN_LINK_STATICALLY

  if (!GetInstanceProcAddr) {
    FML_DLOG(WARNING) << "Could not acquire vkGetInstanceProcAddr.";
    return false;
  }

  VulkanHandle<VkInstance> null_instance(VK_NULL_HANDLE, nullptr);

  ACQUIRE_PROC(CreateInstance, null_instance);
  ACQUIRE_PROC(EnumerateInstanceExtensionProperties, null_instance);
  ACQUIRE_PROC(EnumerateInstanceLayerProperties, null_instance);

  return true;
}

bool VulkanProcTable::SetupInstanceProcAddresses(
    const VulkanHandle<VkInstance>& handle) {
  ACQUIRE_PROC(CreateDevice, handle);
  ACQUIRE_PROC(DestroyDevice, handle);
  ACQUIRE_PROC(DestroyInstance, handle);
  ACQUIRE_PROC(DestroySurfaceKHR, handle);
  ACQUIRE_PROC(EnumerateDeviceLayerProperties, handle);
  ACQUIRE_PROC(EnumeratePhysicalDevices, handle);
  ACQUIRE_PROC(GetDeviceProcAddr, handle);
  ACQUIRE_PROC(GetPhysicalDeviceFeatures, handle);
  ACQUIRE_PROC(GetPhysicalDeviceQueueFamilyProperties, handle);
  ACQUIRE_PROC(GetPhysicalDeviceSurfaceCapabilitiesKHR, handle);
  ACQUIRE_PROC(GetPhysicalDeviceSurfaceFormatsKHR, handle);
  ACQUIRE_PROC(GetPhysicalDeviceSurfacePresentModesKHR, handle);
  ACQUIRE_PROC(GetPhysicalDeviceSurfaceSupportKHR, handle);

#if OS_ANDROID
  ACQUIRE_PROC(CreateAndroidSurfaceKHR, handle);
#endif  // OS_ANDROID

#if OS_FUCHSIA
  [this, &handle]() -> bool {
    ACQUIRE_PROC(CreateMagmaSurfaceKHR, handle);
    ACQUIRE_PROC(GetPhysicalDeviceMagmaPresentationSupportKHR, handle);
    return true;
  }();
#endif  // OS_FUCHSIA

  // The debug report functions are optional. We don't want proc acquisition to
  // fail here because the optional methods were not present (since ACQUIRE_PROC
  // returns false on failure). Wrap the optional proc acquisitions in an
  // anonymous lambda and invoke it. We don't really care about the result since
  // users of Debug reporting functions check for their presence explicitly.
  [this, &handle]() -> bool {
    ACQUIRE_PROC(CreateDebugReportCallbackEXT, handle);
    ACQUIRE_PROC(DestroyDebugReportCallbackEXT, handle);
    return true;
  }();

  instance_ = {handle, nullptr};
  return true;
}

bool VulkanProcTable::SetupDeviceProcAddresses(
    const VulkanHandle<VkDevice>& handle) {
  ACQUIRE_PROC(AcquireNextImageKHR, handle);
  ACQUIRE_PROC(AllocateCommandBuffers, handle);
  ACQUIRE_PROC(AllocateMemory, handle);
  ACQUIRE_PROC(BeginCommandBuffer, handle);
  ACQUIRE_PROC(BindImageMemory, handle);
  ACQUIRE_PROC(CmdPipelineBarrier, handle);
  ACQUIRE_PROC(CreateCommandPool, handle);
  ACQUIRE_PROC(CreateFence, handle);
  ACQUIRE_PROC(CreateImage, handle);
  ACQUIRE_PROC(CreateSemaphore, handle);
  ACQUIRE_PROC(CreateSwapchainKHR, handle);
  ACQUIRE_PROC(DestroyCommandPool, handle);
  ACQUIRE_PROC(DestroyFence, handle);
  ACQUIRE_PROC(DestroyImage, handle);
  ACQUIRE_PROC(DestroySemaphore, handle);
  ACQUIRE_PROC(DestroySwapchainKHR, handle);
  ACQUIRE_PROC(DeviceWaitIdle, handle);
  ACQUIRE_PROC(EndCommandBuffer, handle);
  ACQUIRE_PROC(FreeCommandBuffers, handle);
  ACQUIRE_PROC(FreeMemory, handle);
  ACQUIRE_PROC(GetDeviceQueue, handle);
  ACQUIRE_PROC(GetImageMemoryRequirements, handle);
  ACQUIRE_PROC(GetSwapchainImagesKHR, handle);
  ACQUIRE_PROC(QueuePresentKHR, handle);
  ACQUIRE_PROC(QueueSubmit, handle);
  ACQUIRE_PROC(QueueWaitIdle, handle);
  ACQUIRE_PROC(ResetCommandBuffer, handle);
  ACQUIRE_PROC(ResetFences, handle);
  ACQUIRE_PROC(WaitForFences, handle);
#if OS_FUCHSIA
  ACQUIRE_PROC(GetMemoryFuchsiaHandleKHR, handle);
  ACQUIRE_PROC(ImportSemaphoreFuchsiaHandleKHR, handle);
#endif  // OS_FUCHSIA
  device_ = {handle, nullptr};
  return true;
}

bool VulkanProcTable::OpenLibraryHandle() {
#if VULKAN_LINK_STATICALLY
  static char kDummyLibraryHandle = '\0';
  handle_ = reinterpret_cast<decltype(handle_)>(&kDummyLibraryHandle);
  return true;
#else   // VULKAN_LINK_STATICALLY
  dlerror();  // clear existing errors on thread.
  handle_ = dlopen("libvulkan.so", RTLD_NOW | RTLD_LOCAL);
  if (handle_ == nullptr) {
    FML_DLOG(WARNING) << "Could not open the vulkan library: " << dlerror();
    return false;
  }
  return true;
#endif  // VULKAN_LINK_STATICALLY
}

bool VulkanProcTable::CloseLibraryHandle() {
#if VULKAN_LINK_STATICALLY
  handle_ = nullptr;
  return true;
#else
  if (handle_ != nullptr) {
    dlerror();  // clear existing errors on thread.
    if (dlclose(handle_) != 0) {
      FML_DLOG(ERROR) << "Could not close the vulkan library handle. This "
                         "indicates a leak.";
      FML_DLOG(ERROR) << dlerror();
    }
    handle_ = nullptr;
  }
  return handle_ == nullptr;
#endif
}

PFN_vkVoidFunction VulkanProcTable::AcquireProc(
    const char* proc_name,
    const VulkanHandle<VkInstance>& instance) const {
  if (proc_name == nullptr || !GetInstanceProcAddr) {
    return nullptr;
  }

  // A VK_NULL_HANDLE as the instance is an acceptable parameter.
  return GetInstanceProcAddr(instance, proc_name);
}

PFN_vkVoidFunction VulkanProcTable::AcquireProc(
    const char* proc_name,
    const VulkanHandle<VkDevice>& device) const {
  if (proc_name == nullptr || !device || !GetDeviceProcAddr) {
    return nullptr;
  }

  return GetDeviceProcAddr(device, proc_name);
}

GrVkGetProc VulkanProcTable::CreateSkiaGetProc() const {
  if (!IsValid()) {
    return nullptr;
  }

  return [this](const char* proc_name, VkInstance instance, VkDevice device) {
    if (device != VK_NULL_HANDLE) {
      auto result = AcquireProc(proc_name, {device, nullptr});
      if (result != nullptr) {
        return result;
      }
    }

    return AcquireProc(proc_name, {instance, nullptr});
  };
}

}  // namespace vulkan
