// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_VULKAN_QUEUE_GUARD_VULKAN_QUEUE_GUARD_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_VULKAN_QUEUE_GUARD_VULKAN_QUEUE_GUARD_H_

#include <vulkan/vulkan.h>

// The Vulkan headers may bring in X11 headers on Linux which define macros that
// conflict with other headers (e.g. GoogleTest). Undefine them after including
// Vulkan.
#undef Bool
#undef None
#undef Status
#undef Success

#include <cstdint>
#include <functional>
#include <memory>
#include <mutex>
#include <vector>

#include "flutter/fml/macros.h"

namespace flutter {
namespace android {

/// @brief Abstract mutex implementation used by GuardMutex so unit tests can
/// inject a recording or contention-signaling lock implementation.
class GuardMutexImpl {
 public:
  virtual ~GuardMutexImpl() = default;
  virtual void lock() = 0;
  virtual void unlock() = 0;
};

/// @brief Leaf mutex serializing all Vulkan queue and device-idle operations
/// for a registered VkDevice.
class GuardMutex {
 public:
  GuardMutex();
  ~GuardMutex() = default;

  void lock() { impl_->lock(); }
  void unlock() { impl_->unlock(); }

 private:
  std::unique_ptr<GuardMutexImpl> impl_;

  FML_DISALLOW_COPY_AND_ASSIGN(GuardMutex);
};

/// @brief Process-wide Vulkan queue synchronization guard and lifetime
/// registry.
///
/// Enforces the embedder.h Vulkan queue synchronization contract by
/// intercepting vkGetInstanceProcAddr and vkGetDeviceProcAddr and routing all
/// 10 queue/device-idle entry points through a per-device leaf mutex. Also
/// tracks device/queue/instance tombstones to catch use-after-free calls.
class VulkanQueueGuard {
 public:
  using MutexFactory = std::function<std::unique_ptr<GuardMutexImpl>()>;
  using BeforeQueueLockHook = std::function<void()>;

  /// @brief Returns the PFN_vkGetInstanceProcAddr trampoline that intercepts
  /// queue and device-idle lookups.
  static PFN_vkGetInstanceProcAddr GetInstanceProcAddrTrampoline();

  /// @brief Returns the PFN_vkGetDeviceProcAddr trampoline that intercepts
  /// queue and device-idle lookups.
  static PFN_vkGetDeviceProcAddr GetDeviceProcAddrTrampoline();

  /// @brief Returns true if [name] is one of the 10 guarded Vulkan functions.
  static bool IsGuardedFunctionName(const char* name);

  /// @brief Registers a VkInstance with its real loader
  /// PFN_vkGetInstanceProcAddr.
  ///
  /// The first registration also populates the VK_NULL_HANDLE global loader
  /// slot. Registering a different non-null PFN while the global slot is
  /// already set triggers FML_LOG(FATAL) in all build modes.
  static void RegisterInstance(
      VkInstance instance,
      PFN_vkGetInstanceProcAddr real_get_instance_proc_addr);

  /// @brief Registers a VkDevice and its associated VkQueue handles under an
  /// already-registered VkInstance.
  static void RegisterDevice(
      VkInstance instance,
      VkDevice device,
      const std::vector<VkQueue>& queues,
      PFN_vkGetDeviceProcAddr real_get_device_proc_addr = nullptr);

  /// @brief Executes the 4-step device and instance teardown protocol:
  /// 1. Under registry_mutex, removes the device, its queues, and the instance
  ///    from active maps and inserts them into the tombstone sets, then
  ///    releases registry_mutex.
  /// 2. Acquires the device's queue_mutex, waiting for any in-flight guarded
  ///    call to complete.
  /// 3. Marks the device entry as destroyed so any call that copied the entry
  ///    prior to step 1 triggers FML_LOG(FATAL) upon acquiring queue_mutex.
  /// 4. Calls the real vkDeviceWaitIdle and vkDestroyDevice while holding
  ///    queue_mutex, releases queue_mutex, and calls vkDestroyInstance.
  static void TearDownDeviceAndInstance(
      VkInstance instance,
      VkDevice device,
      PFN_vkDestroyDevice destroy_device_fn,
      PFN_vkDestroyInstance destroy_instance_fn);

  /// @brief Returns the number of guarded vkQueueSubmit / vkQueueSubmit2 /
  /// vkQueueSubmit2KHR calls executed since the last ResetForTesting().
  static uint64_t GetQueueSubmitCountForTesting();

  /// @brief Injects a custom GuardMutexImpl factory for testing contention.
  static void SetMutexFactoryForTesting(MutexFactory factory);

  /// @brief Injects a hook invoked inside guarded trampolines after releasing
  /// registry_mutex and before acquiring queue_mutex.
  static void SetBeforeQueueLockHookForTesting(BeforeQueueLockHook hook);

  /// @brief Clears all registered instances, devices, queues, tombstones,
  /// counters, and test hooks.
  static void ResetForTesting();

  /// @brief Creates a GuardMutexImpl using the active factory (or std::mutex by
  /// default).
  static std::unique_ptr<GuardMutexImpl> CreateMutexImpl();

 private:
  static VKAPI_ATTR PFN_vkVoidFunction VKAPI_CALL
  TrampolineGetInstanceProcAddr(VkInstance instance, const char* pName);

  static VKAPI_ATTR PFN_vkVoidFunction VKAPI_CALL
  TrampolineGetDeviceProcAddr(VkDevice device, const char* pName);

  FML_DISALLOW_IMPLICIT_CONSTRUCTORS(VulkanQueueGuard);
};

}  // namespace android

using android::GuardMutex;
using android::GuardMutexImpl;
using android::VulkanQueueGuard;

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_VULKAN_QUEUE_GUARD_VULKAN_QUEUE_GUARD_H_
