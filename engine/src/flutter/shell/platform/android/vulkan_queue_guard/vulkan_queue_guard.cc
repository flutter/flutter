// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/vulkan_queue_guard/vulkan_queue_guard.h"

#include <atomic>
#include <cstring>
#include <unordered_map>
#include <unordered_set>
#include <utility>

#include "flutter/fml/logging.h"

namespace flutter {
namespace android {

namespace {

class DefaultGuardMutexImpl final : public GuardMutexImpl {
 public:
  void lock() override { mutex_.lock(); }
  void unlock() override { mutex_.unlock(); }

 private:
  std::mutex mutex_;
};

struct GuardedProcs {
  PFN_vkGetDeviceProcAddr get_device_proc_addr = nullptr;
  PFN_vkQueueSubmit queue_submit = nullptr;
  PFN_vkQueueSubmit2 queue_submit_2 = nullptr;
  PFN_vkQueueSubmit2KHR queue_submit_2_khr = nullptr;
  PFN_vkQueueWaitIdle queue_wait_idle = nullptr;
  PFN_vkQueuePresentKHR queue_present_khr = nullptr;
  PFN_vkQueueBindSparse queue_bind_sparse = nullptr;
  PFN_vkQueueInsertDebugUtilsLabelEXT queue_insert_debug_utils_label_ext =
      nullptr;
  PFN_vkQueueBeginDebugUtilsLabelEXT queue_begin_debug_utils_label_ext =
      nullptr;
  PFN_vkQueueEndDebugUtilsLabelEXT queue_end_debug_utils_label_ext = nullptr;
  PFN_vkDeviceWaitIdle device_wait_idle = nullptr;
};

struct DeviceEntry {
  VkInstance instance = VK_NULL_HANDLE;
  VkDevice device = VK_NULL_HANDLE;
  std::vector<VkQueue> queues;
  PFN_vkGetInstanceProcAddr real_get_instance_proc_addr = nullptr;
  PFN_vkGetDeviceProcAddr real_get_device_proc_addr = nullptr;
  GuardedProcs procs;
  GuardMutex queue_mutex;
  bool destroyed = false;
};

struct GuardRegistry {
  std::mutex registry_mutex;
  PFN_vkGetInstanceProcAddr null_instance_proc_addr = nullptr;
  std::unordered_map<VkInstance, PFN_vkGetInstanceProcAddr> instance_proc_addrs;
  std::unordered_map<VkDevice, std::shared_ptr<DeviceEntry>> device_entries;
  std::unordered_map<VkQueue, std::shared_ptr<DeviceEntry>> queue_entries;
  std::unordered_set<VkInstance> tombstoned_instances;
  std::unordered_set<VkDevice> tombstoned_devices;
  std::unordered_set<VkQueue> tombstoned_queues;
  GuardedProcs fallback_procs;
  std::atomic<uint64_t> queue_submit_count{0};
  VulkanQueueGuard::MutexFactory mutex_factory;
  VulkanQueueGuard::BeforeQueueLockHook before_queue_lock_hook;
};

GuardRegistry& GetRegistry() {
  static GuardRegistry* s_registry = new GuardRegistry();
  return *s_registry;
}

void UpdateFallbackProcLocked(GuardRegistry& reg,
                              const char* name,
                              PFN_vkVoidFunction fn) {
  if (fn == nullptr || name == nullptr) {
    return;
  }
  if (std::strcmp(name, "vkGetDeviceProcAddr") == 0) {
    reg.fallback_procs.get_device_proc_addr =
        reinterpret_cast<PFN_vkGetDeviceProcAddr>(fn);
  } else if (std::strcmp(name, "vkQueueSubmit") == 0) {
    reg.fallback_procs.queue_submit = reinterpret_cast<PFN_vkQueueSubmit>(fn);
  } else if (std::strcmp(name, "vkQueueSubmit2") == 0) {
    reg.fallback_procs.queue_submit_2 =
        reinterpret_cast<PFN_vkQueueSubmit2>(fn);
  } else if (std::strcmp(name, "vkQueueSubmit2KHR") == 0) {
    reg.fallback_procs.queue_submit_2_khr =
        reinterpret_cast<PFN_vkQueueSubmit2KHR>(fn);
  } else if (std::strcmp(name, "vkQueueWaitIdle") == 0) {
    reg.fallback_procs.queue_wait_idle =
        reinterpret_cast<PFN_vkQueueWaitIdle>(fn);
  } else if (std::strcmp(name, "vkQueuePresentKHR") == 0) {
    reg.fallback_procs.queue_present_khr =
        reinterpret_cast<PFN_vkQueuePresentKHR>(fn);
  } else if (std::strcmp(name, "vkQueueBindSparse") == 0) {
    reg.fallback_procs.queue_bind_sparse =
        reinterpret_cast<PFN_vkQueueBindSparse>(fn);
  } else if (std::strcmp(name, "vkQueueInsertDebugUtilsLabelEXT") == 0) {
    reg.fallback_procs.queue_insert_debug_utils_label_ext =
        reinterpret_cast<PFN_vkQueueInsertDebugUtilsLabelEXT>(fn);
  } else if (std::strcmp(name, "vkQueueBeginDebugUtilsLabelEXT") == 0) {
    reg.fallback_procs.queue_begin_debug_utils_label_ext =
        reinterpret_cast<PFN_vkQueueBeginDebugUtilsLabelEXT>(fn);
  } else if (std::strcmp(name, "vkQueueEndDebugUtilsLabelEXT") == 0) {
    reg.fallback_procs.queue_end_debug_utils_label_ext =
        reinterpret_cast<PFN_vkQueueEndDebugUtilsLabelEXT>(fn);
  } else if (std::strcmp(name, "vkDeviceWaitIdle") == 0) {
    reg.fallback_procs.device_wait_idle =
        reinterpret_cast<PFN_vkDeviceWaitIdle>(fn);
  }
}

std::shared_ptr<DeviceEntry> LookupQueueEntryOrDie(
    VkQueue queue,
    const char* func_name,
    GuardedProcs* out_fallback,
    VulkanQueueGuard::BeforeQueueLockHook* out_hook) {
  auto& reg = GetRegistry();
  std::lock_guard<std::mutex> lock(reg.registry_mutex);
  if (reg.tombstoned_queues.count(queue) > 0) {
    FML_LOG(FATAL) << "VulkanQueueGuard: use-after-free call to " << func_name
                   << " on tombstoned VkQueue " << static_cast<void*>(queue);
  }
  *out_hook = reg.before_queue_lock_hook;
  auto it = reg.queue_entries.find(queue);
  if (it != reg.queue_entries.end()) {
    return it->second;
  }
  *out_fallback = reg.fallback_procs;
  return nullptr;
}

std::shared_ptr<DeviceEntry> LookupDeviceEntryOrDie(
    VkDevice device,
    const char* func_name,
    GuardedProcs* out_fallback,
    VulkanQueueGuard::BeforeQueueLockHook* out_hook) {
  auto& reg = GetRegistry();
  std::lock_guard<std::mutex> lock(reg.registry_mutex);
  if (reg.tombstoned_devices.count(device) > 0) {
    FML_LOG(FATAL) << "VulkanQueueGuard: use-after-free call to " << func_name
                   << " on tombstoned VkDevice " << static_cast<void*>(device);
  }
  *out_hook = reg.before_queue_lock_hook;
  auto it = reg.device_entries.find(device);
  if (it != reg.device_entries.end()) {
    return it->second;
  }
  *out_fallback = reg.fallback_procs;
  return nullptr;
}

void ReportUnregisteredHandle(const char* func_name, const void* handle) {
  FML_DCHECK(false) << "VulkanQueueGuard: call to " << func_name
                    << " on unregistered handle " << handle;
  FML_LOG(ERROR) << "VulkanQueueGuard: call to " << func_name
                 << " on unregistered handle " << handle
                 << "; forwarding unguarded.";
}

VKAPI_ATTR VkResult VKAPI_CALL GuardedQueueSubmit(VkQueue queue,
                                                  uint32_t submitCount,
                                                  const VkSubmitInfo* pSubmits,
                                                  VkFence fence) {
  GuardedProcs fallback;
  VulkanQueueGuard::BeforeQueueLockHook hook;
  auto entry = LookupQueueEntryOrDie(queue, "vkQueueSubmit", &fallback, &hook);
  if (!entry) {
    ReportUnregisteredHandle("vkQueueSubmit", static_cast<const void*>(queue));
    return fallback.queue_submit
               ? fallback.queue_submit(queue, submitCount, pSubmits, fence)
               : VK_ERROR_INITIALIZATION_FAILED;
  }
  if (hook) {
    hook();
  }
  std::lock_guard<GuardMutex> queue_lock(entry->queue_mutex);
  if (entry->destroyed) {
    FML_LOG(FATAL) << "VulkanQueueGuard: use-after-free call to vkQueueSubmit "
                      "on destroyed VkQueue "
                   << static_cast<void*>(queue);
  }
  GetRegistry().queue_submit_count.fetch_add(1, std::memory_order_relaxed);
  return entry->procs.queue_submit(queue, submitCount, pSubmits, fence);
}

VKAPI_ATTR VkResult VKAPI_CALL
GuardedQueueSubmit2(VkQueue queue,
                    uint32_t submitCount,
                    const VkSubmitInfo2* pSubmits,
                    VkFence fence) {
  GuardedProcs fallback;
  VulkanQueueGuard::BeforeQueueLockHook hook;
  auto entry = LookupQueueEntryOrDie(queue, "vkQueueSubmit2", &fallback, &hook);
  if (!entry) {
    ReportUnregisteredHandle("vkQueueSubmit2", static_cast<const void*>(queue));
    return fallback.queue_submit_2
               ? fallback.queue_submit_2(queue, submitCount, pSubmits, fence)
               : VK_ERROR_INITIALIZATION_FAILED;
  }
  if (hook) {
    hook();
  }
  std::lock_guard<GuardMutex> queue_lock(entry->queue_mutex);
  if (entry->destroyed) {
    FML_LOG(FATAL) << "VulkanQueueGuard: use-after-free call to vkQueueSubmit2 "
                      "on destroyed VkQueue "
                   << static_cast<void*>(queue);
  }
  GetRegistry().queue_submit_count.fetch_add(1, std::memory_order_relaxed);
  return entry->procs.queue_submit_2(queue, submitCount, pSubmits, fence);
}

VKAPI_ATTR VkResult VKAPI_CALL
GuardedQueueSubmit2KHR(VkQueue queue,
                       uint32_t submitCount,
                       const VkSubmitInfo2KHR* pSubmits,
                       VkFence fence) {
  GuardedProcs fallback;
  VulkanQueueGuard::BeforeQueueLockHook hook;
  auto entry =
      LookupQueueEntryOrDie(queue, "vkQueueSubmit2KHR", &fallback, &hook);
  if (!entry) {
    ReportUnregisteredHandle("vkQueueSubmit2KHR",
                             static_cast<const void*>(queue));
    return fallback.queue_submit_2_khr
               ? fallback.queue_submit_2_khr(queue, submitCount, pSubmits,
                                             fence)
               : VK_ERROR_INITIALIZATION_FAILED;
  }
  if (hook) {
    hook();
  }
  std::lock_guard<GuardMutex> queue_lock(entry->queue_mutex);
  if (entry->destroyed) {
    FML_LOG(FATAL)
        << "VulkanQueueGuard: use-after-free call to vkQueueSubmit2KHR "
           "on destroyed VkQueue "
        << static_cast<void*>(queue);
  }
  GetRegistry().queue_submit_count.fetch_add(1, std::memory_order_relaxed);
  return entry->procs.queue_submit_2_khr(queue, submitCount, pSubmits, fence);
}

VKAPI_ATTR VkResult VKAPI_CALL GuardedQueueWaitIdle(VkQueue queue) {
  GuardedProcs fallback;
  VulkanQueueGuard::BeforeQueueLockHook hook;
  auto entry =
      LookupQueueEntryOrDie(queue, "vkQueueWaitIdle", &fallback, &hook);
  if (!entry) {
    ReportUnregisteredHandle("vkQueueWaitIdle",
                             static_cast<const void*>(queue));
    return fallback.queue_wait_idle ? fallback.queue_wait_idle(queue)
                                    : VK_ERROR_INITIALIZATION_FAILED;
  }
  if (hook) {
    hook();
  }
  std::lock_guard<GuardMutex> queue_lock(entry->queue_mutex);
  if (entry->destroyed) {
    FML_LOG(FATAL)
        << "VulkanQueueGuard: use-after-free call to vkQueueWaitIdle "
           "on destroyed VkQueue "
        << static_cast<void*>(queue);
  }
  return entry->procs.queue_wait_idle(queue);
}

VKAPI_ATTR VkResult VKAPI_CALL
GuardedQueuePresentKHR(VkQueue queue, const VkPresentInfoKHR* pPresentInfo) {
  GuardedProcs fallback;
  VulkanQueueGuard::BeforeQueueLockHook hook;
  auto entry =
      LookupQueueEntryOrDie(queue, "vkQueuePresentKHR", &fallback, &hook);
  if (!entry) {
    ReportUnregisteredHandle("vkQueuePresentKHR",
                             static_cast<const void*>(queue));
    return fallback.queue_present_khr
               ? fallback.queue_present_khr(queue, pPresentInfo)
               : VK_ERROR_INITIALIZATION_FAILED;
  }
  if (hook) {
    hook();
  }
  std::lock_guard<GuardMutex> queue_lock(entry->queue_mutex);
  if (entry->destroyed) {
    FML_LOG(FATAL)
        << "VulkanQueueGuard: use-after-free call to vkQueuePresentKHR "
           "on destroyed VkQueue "
        << static_cast<void*>(queue);
  }
  return entry->procs.queue_present_khr(queue, pPresentInfo);
}

VKAPI_ATTR VkResult VKAPI_CALL
GuardedQueueBindSparse(VkQueue queue,
                       uint32_t bindInfoCount,
                       const VkBindSparseInfo* pBindInfo,
                       VkFence fence) {
  GuardedProcs fallback;
  VulkanQueueGuard::BeforeQueueLockHook hook;
  auto entry =
      LookupQueueEntryOrDie(queue, "vkQueueBindSparse", &fallback, &hook);
  if (!entry) {
    ReportUnregisteredHandle("vkQueueBindSparse",
                             static_cast<const void*>(queue));
    return fallback.queue_bind_sparse
               ? fallback.queue_bind_sparse(queue, bindInfoCount, pBindInfo,
                                            fence)
               : VK_ERROR_INITIALIZATION_FAILED;
  }
  if (hook) {
    hook();
  }
  std::lock_guard<GuardMutex> queue_lock(entry->queue_mutex);
  if (entry->destroyed) {
    FML_LOG(FATAL)
        << "VulkanQueueGuard: use-after-free call to vkQueueBindSparse "
           "on destroyed VkQueue "
        << static_cast<void*>(queue);
  }
  return entry->procs.queue_bind_sparse(queue, bindInfoCount, pBindInfo, fence);
}

VKAPI_ATTR void VKAPI_CALL
GuardedQueueInsertDebugUtilsLabelEXT(VkQueue queue,
                                     const VkDebugUtilsLabelEXT* pLabelInfo) {
  GuardedProcs fallback;
  VulkanQueueGuard::BeforeQueueLockHook hook;
  auto entry = LookupQueueEntryOrDie(queue, "vkQueueInsertDebugUtilsLabelEXT",
                                     &fallback, &hook);
  if (!entry) {
    ReportUnregisteredHandle("vkQueueInsertDebugUtilsLabelEXT",
                             static_cast<const void*>(queue));
    if (fallback.queue_insert_debug_utils_label_ext) {
      fallback.queue_insert_debug_utils_label_ext(queue, pLabelInfo);
    }
    return;
  }
  if (hook) {
    hook();
  }
  std::lock_guard<GuardMutex> queue_lock(entry->queue_mutex);
  if (entry->destroyed) {
    FML_LOG(FATAL) << "VulkanQueueGuard: use-after-free call to "
                      "vkQueueInsertDebugUtilsLabelEXT on destroyed VkQueue "
                   << static_cast<void*>(queue);
  }
  entry->procs.queue_insert_debug_utils_label_ext(queue, pLabelInfo);
}

VKAPI_ATTR void VKAPI_CALL
GuardedQueueBeginDebugUtilsLabelEXT(VkQueue queue,
                                    const VkDebugUtilsLabelEXT* pLabelInfo) {
  GuardedProcs fallback;
  VulkanQueueGuard::BeforeQueueLockHook hook;
  auto entry = LookupQueueEntryOrDie(queue, "vkQueueBeginDebugUtilsLabelEXT",
                                     &fallback, &hook);
  if (!entry) {
    ReportUnregisteredHandle("vkQueueBeginDebugUtilsLabelEXT",
                             static_cast<const void*>(queue));
    if (fallback.queue_begin_debug_utils_label_ext) {
      fallback.queue_begin_debug_utils_label_ext(queue, pLabelInfo);
    }
    return;
  }
  if (hook) {
    hook();
  }
  std::lock_guard<GuardMutex> queue_lock(entry->queue_mutex);
  if (entry->destroyed) {
    FML_LOG(FATAL) << "VulkanQueueGuard: use-after-free call to "
                      "vkQueueBeginDebugUtilsLabelEXT on destroyed VkQueue "
                   << static_cast<void*>(queue);
  }
  entry->procs.queue_begin_debug_utils_label_ext(queue, pLabelInfo);
}

VKAPI_ATTR void VKAPI_CALL GuardedQueueEndDebugUtilsLabelEXT(VkQueue queue) {
  GuardedProcs fallback;
  VulkanQueueGuard::BeforeQueueLockHook hook;
  auto entry = LookupQueueEntryOrDie(queue, "vkQueueEndDebugUtilsLabelEXT",
                                     &fallback, &hook);
  if (!entry) {
    ReportUnregisteredHandle("vkQueueEndDebugUtilsLabelEXT",
                             static_cast<const void*>(queue));
    if (fallback.queue_end_debug_utils_label_ext) {
      fallback.queue_end_debug_utils_label_ext(queue);
    }
    return;
  }
  if (hook) {
    hook();
  }
  std::lock_guard<GuardMutex> queue_lock(entry->queue_mutex);
  if (entry->destroyed) {
    FML_LOG(FATAL) << "VulkanQueueGuard: use-after-free call to "
                      "vkQueueEndDebugUtilsLabelEXT on destroyed VkQueue "
                   << static_cast<void*>(queue);
  }
  entry->procs.queue_end_debug_utils_label_ext(queue);
}

VKAPI_ATTR VkResult VKAPI_CALL GuardedDeviceWaitIdle(VkDevice device) {
  GuardedProcs fallback;
  VulkanQueueGuard::BeforeQueueLockHook hook;
  auto entry =
      LookupDeviceEntryOrDie(device, "vkDeviceWaitIdle", &fallback, &hook);
  if (!entry) {
    ReportUnregisteredHandle("vkDeviceWaitIdle",
                             static_cast<const void*>(device));
    return fallback.device_wait_idle ? fallback.device_wait_idle(device)
                                     : VK_ERROR_INITIALIZATION_FAILED;
  }
  if (hook) {
    hook();
  }
  std::lock_guard<GuardMutex> queue_lock(entry->queue_mutex);
  if (entry->destroyed) {
    FML_LOG(FATAL)
        << "VulkanQueueGuard: use-after-free call to vkDeviceWaitIdle "
           "on destroyed VkDevice "
        << static_cast<void*>(device);
  }
  return entry->procs.device_wait_idle(device);
}

PFN_vkVoidFunction LookupGuardedTrampoline(const char* name) {
  if (name == nullptr) {
    return nullptr;
  }
  if (std::strcmp(name, "vkQueueSubmit") == 0) {
    return reinterpret_cast<PFN_vkVoidFunction>(&GuardedQueueSubmit);
  }
  if (std::strcmp(name, "vkQueueSubmit2") == 0) {
    return reinterpret_cast<PFN_vkVoidFunction>(&GuardedQueueSubmit2);
  }
  if (std::strcmp(name, "vkQueueSubmit2KHR") == 0) {
    return reinterpret_cast<PFN_vkVoidFunction>(&GuardedQueueSubmit2KHR);
  }
  if (std::strcmp(name, "vkQueueWaitIdle") == 0) {
    return reinterpret_cast<PFN_vkVoidFunction>(&GuardedQueueWaitIdle);
  }
  if (std::strcmp(name, "vkQueuePresentKHR") == 0) {
    return reinterpret_cast<PFN_vkVoidFunction>(&GuardedQueuePresentKHR);
  }
  if (std::strcmp(name, "vkQueueBindSparse") == 0) {
    return reinterpret_cast<PFN_vkVoidFunction>(&GuardedQueueBindSparse);
  }
  if (std::strcmp(name, "vkQueueInsertDebugUtilsLabelEXT") == 0) {
    return reinterpret_cast<PFN_vkVoidFunction>(
        &GuardedQueueInsertDebugUtilsLabelEXT);
  }
  if (std::strcmp(name, "vkQueueBeginDebugUtilsLabelEXT") == 0) {
    return reinterpret_cast<PFN_vkVoidFunction>(
        &GuardedQueueBeginDebugUtilsLabelEXT);
  }
  if (std::strcmp(name, "vkQueueEndDebugUtilsLabelEXT") == 0) {
    return reinterpret_cast<PFN_vkVoidFunction>(
        &GuardedQueueEndDebugUtilsLabelEXT);
  }
  if (std::strcmp(name, "vkDeviceWaitIdle") == 0) {
    return reinterpret_cast<PFN_vkVoidFunction>(&GuardedDeviceWaitIdle);
  }
  return nullptr;
}

}  // namespace

GuardMutex::GuardMutex() : impl_(VulkanQueueGuard::CreateMutexImpl()) {}

std::unique_ptr<GuardMutexImpl> VulkanQueueGuard::CreateMutexImpl() {
  auto& reg = GetRegistry();
  MutexFactory factory = reg.mutex_factory;
  if (factory) {
    return factory();
  }
  return std::make_unique<DefaultGuardMutexImpl>();
}

PFN_vkGetInstanceProcAddr VulkanQueueGuard::GetInstanceProcAddrTrampoline() {
  return &VulkanQueueGuard::TrampolineGetInstanceProcAddr;
}

PFN_vkGetDeviceProcAddr VulkanQueueGuard::GetDeviceProcAddrTrampoline() {
  return &VulkanQueueGuard::TrampolineGetDeviceProcAddr;
}

bool VulkanQueueGuard::IsGuardedFunctionName(const char* name) {
  return LookupGuardedTrampoline(name) != nullptr;
}

void VulkanQueueGuard::RegisterInstance(
    VkInstance instance,
    PFN_vkGetInstanceProcAddr real_get_instance_proc_addr) {
  if (real_get_instance_proc_addr == nullptr) {
    return;
  }
  auto& reg = GetRegistry();
  std::lock_guard<std::mutex> lock(reg.registry_mutex);
  if (reg.null_instance_proc_addr == nullptr) {
    reg.null_instance_proc_addr = real_get_instance_proc_addr;
  } else if (reg.null_instance_proc_addr != real_get_instance_proc_addr) {
    FML_LOG(FATAL)
        << "VulkanQueueGuard: conflicting PFN_vkGetInstanceProcAddr for "
           "VK_NULL_HANDLE slot: existing="
        << reinterpret_cast<void*>(reg.null_instance_proc_addr)
        << ", new=" << reinterpret_cast<void*>(real_get_instance_proc_addr);
  }
  if (instance != VK_NULL_HANDLE) {
    reg.tombstoned_instances.erase(instance);
    reg.instance_proc_addrs[instance] = real_get_instance_proc_addr;
  }
}

void VulkanQueueGuard::RegisterDevice(
    VkInstance instance,
    VkDevice device,
    const std::vector<VkQueue>& queues,
    PFN_vkGetDeviceProcAddr real_get_device_proc_addr) {
  if (device == VK_NULL_HANDLE) {
    return;
  }

  PFN_vkGetInstanceProcAddr real_gipa = nullptr;
  {
    auto& reg = GetRegistry();
    std::lock_guard<std::mutex> lock(reg.registry_mutex);
    auto it = reg.instance_proc_addrs.find(instance);
    if (it != reg.instance_proc_addrs.end()) {
      real_gipa = it->second;
    } else {
      real_gipa = reg.null_instance_proc_addr;
    }
  }

  PFN_vkGetDeviceProcAddr resolved_gdpa = real_get_device_proc_addr;
  if (resolved_gdpa == nullptr && real_gipa != nullptr &&
      instance != VK_NULL_HANDLE) {
    resolved_gdpa = reinterpret_cast<PFN_vkGetDeviceProcAddr>(
        real_gipa(instance, "vkGetDeviceProcAddr"));
  }

  auto resolve_fn = [&](const char* name) -> PFN_vkVoidFunction {
    if (resolved_gdpa != nullptr) {
      PFN_vkVoidFunction fn = resolved_gdpa(device, name);
      if (fn != nullptr) {
        return fn;
      }
    }
    if (real_gipa != nullptr && instance != VK_NULL_HANDLE) {
      return real_gipa(instance, name);
    }
    return nullptr;
  };

  auto entry = std::make_shared<DeviceEntry>();
  entry->instance = instance;
  entry->device = device;
  entry->queues = queues;
  entry->real_get_instance_proc_addr = real_gipa;
  entry->real_get_device_proc_addr = resolved_gdpa;
  entry->procs.get_device_proc_addr = resolved_gdpa;
  entry->procs.queue_submit =
      reinterpret_cast<PFN_vkQueueSubmit>(resolve_fn("vkQueueSubmit"));
  entry->procs.queue_submit_2 =
      reinterpret_cast<PFN_vkQueueSubmit2>(resolve_fn("vkQueueSubmit2"));
  entry->procs.queue_submit_2_khr =
      reinterpret_cast<PFN_vkQueueSubmit2KHR>(resolve_fn("vkQueueSubmit2KHR"));
  entry->procs.queue_wait_idle =
      reinterpret_cast<PFN_vkQueueWaitIdle>(resolve_fn("vkQueueWaitIdle"));
  entry->procs.queue_present_khr =
      reinterpret_cast<PFN_vkQueuePresentKHR>(resolve_fn("vkQueuePresentKHR"));
  entry->procs.queue_bind_sparse =
      reinterpret_cast<PFN_vkQueueBindSparse>(resolve_fn("vkQueueBindSparse"));
  entry->procs.queue_insert_debug_utils_label_ext =
      reinterpret_cast<PFN_vkQueueInsertDebugUtilsLabelEXT>(
          resolve_fn("vkQueueInsertDebugUtilsLabelEXT"));
  entry->procs.queue_begin_debug_utils_label_ext =
      reinterpret_cast<PFN_vkQueueBeginDebugUtilsLabelEXT>(
          resolve_fn("vkQueueBeginDebugUtilsLabelEXT"));
  entry->procs.queue_end_debug_utils_label_ext =
      reinterpret_cast<PFN_vkQueueEndDebugUtilsLabelEXT>(
          resolve_fn("vkQueueEndDebugUtilsLabelEXT"));
  entry->procs.device_wait_idle =
      reinterpret_cast<PFN_vkDeviceWaitIdle>(resolve_fn("vkDeviceWaitIdle"));

  auto& reg = GetRegistry();
  std::lock_guard<std::mutex> lock(reg.registry_mutex);
  reg.tombstoned_devices.erase(device);
  reg.device_entries[device] = entry;
  for (VkQueue q : queues) {
    if (q != VK_NULL_HANDLE) {
      reg.tombstoned_queues.erase(q);
      reg.queue_entries[q] = entry;
    }
  }
  reg.fallback_procs = entry->procs;
}

void VulkanQueueGuard::TearDownDeviceAndInstance(
    VkInstance instance,
    VkDevice device,
    PFN_vkDestroyDevice destroy_device_fn,
    PFN_vkDestroyInstance destroy_instance_fn) {
  std::shared_ptr<DeviceEntry> entry;
  {
    auto& reg = GetRegistry();
    std::lock_guard<std::mutex> lock(reg.registry_mutex);
    if (device != VK_NULL_HANDLE) {
      auto it = reg.device_entries.find(device);
      if (it != reg.device_entries.end()) {
        entry = it->second;
        for (VkQueue q : entry->queues) {
          if (q != VK_NULL_HANDLE) {
            reg.queue_entries.erase(q);
            reg.tombstoned_queues.insert(q);
          }
        }
        reg.device_entries.erase(it);
      }
      reg.tombstoned_devices.insert(device);
    }
    if (instance != VK_NULL_HANDLE) {
      reg.instance_proc_addrs.erase(instance);
      reg.tombstoned_instances.insert(instance);
    }
  }

  if (entry) {
    std::unique_lock<GuardMutex> queue_lock(entry->queue_mutex);
    entry->destroyed = true;
    if (device != VK_NULL_HANDLE) {
      if (entry->procs.device_wait_idle != nullptr) {
        entry->procs.device_wait_idle(device);
      }
      if (destroy_device_fn != nullptr) {
        destroy_device_fn(device, nullptr);
      }
    }
    queue_lock.unlock();
  } else if (device != VK_NULL_HANDLE && destroy_device_fn != nullptr) {
    destroy_device_fn(device, nullptr);
  }

  if (instance != VK_NULL_HANDLE && destroy_instance_fn != nullptr) {
    destroy_instance_fn(instance, nullptr);
  }
}

VKAPI_ATTR PFN_vkVoidFunction VKAPI_CALL
VulkanQueueGuard::TrampolineGetInstanceProcAddr(VkInstance instance,
                                                const char* pName) {
  if (pName == nullptr) {
    return nullptr;
  }

  auto& reg = GetRegistry();
  if (instance == VK_NULL_HANDLE) {
    PFN_vkGetInstanceProcAddr null_gipa = nullptr;
    {
      std::lock_guard<std::mutex> lock(reg.registry_mutex);
      null_gipa = reg.null_instance_proc_addr;
    }
    if (null_gipa == nullptr) {
      ReportUnregisteredHandle("vkGetInstanceProcAddr(VK_NULL_HANDLE)",
                               nullptr);
      return nullptr;
    }
    return null_gipa(VK_NULL_HANDLE, pName);
  }

  PFN_vkGetInstanceProcAddr real_gipa = nullptr;
  PFN_vkGetInstanceProcAddr fallback_gipa = nullptr;
  bool was_registered = false;
  {
    std::lock_guard<std::mutex> lock(reg.registry_mutex);
    if (reg.tombstoned_instances.count(instance) > 0) {
      FML_LOG(FATAL)
          << "VulkanQueueGuard: use-after-free call to vkGetInstanceProcAddr("
          << pName << ") on tombstoned VkInstance "
          << static_cast<void*>(instance);
    }
    auto it = reg.instance_proc_addrs.find(instance);
    if (it != reg.instance_proc_addrs.end()) {
      real_gipa = it->second;
      was_registered = true;
    } else {
      fallback_gipa = reg.null_instance_proc_addr;
    }
  }

  if (!was_registered) {
    ReportUnregisteredHandle("vkGetInstanceProcAddr",
                             static_cast<const void*>(instance));
    return fallback_gipa ? fallback_gipa(instance, pName) : nullptr;
  }

  if (std::strcmp(pName, "vkGetInstanceProcAddr") == 0) {
    return reinterpret_cast<PFN_vkVoidFunction>(
        &VulkanQueueGuard::TrampolineGetInstanceProcAddr);
  }

  PFN_vkVoidFunction real_fn = real_gipa(instance, pName);
  if (real_fn == nullptr) {
    return nullptr;
  }

  {
    std::lock_guard<std::mutex> lock(reg.registry_mutex);
    UpdateFallbackProcLocked(reg, pName, real_fn);
  }

  if (std::strcmp(pName, "vkGetDeviceProcAddr") == 0) {
    return reinterpret_cast<PFN_vkVoidFunction>(
        &VulkanQueueGuard::TrampolineGetDeviceProcAddr);
  }

  PFN_vkVoidFunction trampoline = LookupGuardedTrampoline(pName);
  if (trampoline != nullptr) {
    return trampoline;
  }

  return real_fn;
}

VKAPI_ATTR PFN_vkVoidFunction VKAPI_CALL
VulkanQueueGuard::TrampolineGetDeviceProcAddr(VkDevice device,
                                              const char* pName) {
  if (pName == nullptr || device == VK_NULL_HANDLE) {
    return nullptr;
  }

  auto& reg = GetRegistry();
  std::shared_ptr<DeviceEntry> entry;
  PFN_vkGetDeviceProcAddr fallback_gdpa = nullptr;
  {
    std::lock_guard<std::mutex> lock(reg.registry_mutex);
    if (reg.tombstoned_devices.count(device) > 0) {
      FML_LOG(FATAL)
          << "VulkanQueueGuard: use-after-free call to vkGetDeviceProcAddr("
          << pName << ") on tombstoned VkDevice " << static_cast<void*>(device);
    }
    auto it = reg.device_entries.find(device);
    if (it != reg.device_entries.end()) {
      entry = it->second;
    } else {
      fallback_gdpa = reg.fallback_procs.get_device_proc_addr;
    }
  }

  if (!entry) {
    ReportUnregisteredHandle("vkGetDeviceProcAddr",
                             static_cast<const void*>(device));
    return fallback_gdpa ? fallback_gdpa(device, pName) : nullptr;
  }

  if (std::strcmp(pName, "vkGetDeviceProcAddr") == 0) {
    return reinterpret_cast<PFN_vkVoidFunction>(
        &VulkanQueueGuard::TrampolineGetDeviceProcAddr);
  }

  PFN_vkVoidFunction real_fn = nullptr;
  if (entry->real_get_device_proc_addr != nullptr) {
    real_fn = entry->real_get_device_proc_addr(device, pName);
  }
  if (real_fn == nullptr && entry->real_get_instance_proc_addr != nullptr &&
      entry->instance != VK_NULL_HANDLE) {
    real_fn = entry->real_get_instance_proc_addr(entry->instance, pName);
  }
  if (real_fn == nullptr) {
    return nullptr;
  }

  PFN_vkVoidFunction trampoline = LookupGuardedTrampoline(pName);
  if (trampoline != nullptr) {
    return trampoline;
  }

  return real_fn;
}

uint64_t VulkanQueueGuard::GetQueueSubmitCountForTesting() {
  return GetRegistry().queue_submit_count.load(std::memory_order_relaxed);
}

void VulkanQueueGuard::SetMutexFactoryForTesting(MutexFactory factory) {
  auto& reg = GetRegistry();
  std::lock_guard<std::mutex> lock(reg.registry_mutex);
  reg.mutex_factory = std::move(factory);
}

void VulkanQueueGuard::SetBeforeQueueLockHookForTesting(
    BeforeQueueLockHook hook) {
  auto& reg = GetRegistry();
  std::lock_guard<std::mutex> lock(reg.registry_mutex);
  reg.before_queue_lock_hook = std::move(hook);
}

void VulkanQueueGuard::ResetForTesting() {
  auto& reg = GetRegistry();
  std::lock_guard<std::mutex> lock(reg.registry_mutex);
  reg.null_instance_proc_addr = nullptr;
  reg.instance_proc_addrs.clear();
  reg.device_entries.clear();
  reg.queue_entries.clear();
  reg.tombstoned_instances.clear();
  reg.tombstoned_devices.clear();
  reg.tombstoned_queues.clear();
  reg.fallback_procs = {};
  reg.queue_submit_count.store(0, std::memory_order_relaxed);
  reg.mutex_factory = nullptr;
  reg.before_queue_lock_hook = nullptr;
}

}  // namespace android
}  // namespace flutter
