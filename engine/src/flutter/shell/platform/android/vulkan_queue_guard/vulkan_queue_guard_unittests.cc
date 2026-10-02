// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/vulkan_queue_guard/vulkan_queue_guard.h"

#include <atomic>
#include <cstring>
#include <memory>
#include <mutex>
#include <thread>
#include <vector>

#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/fml/time/time_delta.h"
#include "gtest/gtest.h"

namespace flutter {
namespace android {
namespace testing {

namespace {

// Synthetic non-null handles used by host unit tests.
const VkInstance kFakeInstance = reinterpret_cast<VkInstance>(0x1001);
const VkDevice kFakeDevice = reinterpret_cast<VkDevice>(0x2002);
const VkQueue kFakeQueue = reinterpret_cast<VkQueue>(0x3003);

struct FakeDriverState {
  std::function<VkResult(VkQueue, uint32_t, const VkSubmitInfo*, VkFence)>
      on_queue_submit;
  std::function<VkResult(VkDevice)> on_device_wait_idle;
  std::function<void(VkDevice)> on_destroy_device;
  std::function<void(VkInstance)> on_destroy_instance;
  std::atomic<int> global_query_count{0};
  std::atomic<int> current_in_flight{0};
  std::atomic<int> max_in_flight{0};
  std::atomic<int> destroy_device_count{0};
  std::atomic<int> destroy_instance_count{0};
};

FakeDriverState* g_driver = nullptr;

void EnterInFlight() {
  if (!g_driver) {
    return;
  }
  int current =
      g_driver->current_in_flight.fetch_add(1, std::memory_order_seq_cst) + 1;
  int prev_max = g_driver->max_in_flight.load(std::memory_order_seq_cst);
  while (current > prev_max &&
         !g_driver->max_in_flight.compare_exchange_weak(
             prev_max, current, std::memory_order_seq_cst)) {
  }
}

void ExitInFlight() {
  if (!g_driver) {
    return;
  }
  g_driver->current_in_flight.fetch_sub(1, std::memory_order_seq_cst);
}

VKAPI_ATTR VkResult VKAPI_CALL
FakeQueueSubmit(VkQueue queue,
                uint32_t submitCount,
                const VkSubmitInfo* pSubmits,
                VkFence fence) {
  EnterInFlight();
  VkResult res = VK_SUCCESS;
  if (g_driver && g_driver->on_queue_submit) {
    res = g_driver->on_queue_submit(queue, submitCount, pSubmits, fence);
  }
  ExitInFlight();
  return res;
}

VKAPI_ATTR VkResult VKAPI_CALL
FakeQueueSubmit2(VkQueue, uint32_t, const VkSubmitInfo2*, VkFence) {
  EnterInFlight();
  ExitInFlight();
  return VK_SUCCESS;
}

VKAPI_ATTR VkResult VKAPI_CALL
FakeQueueSubmit2KHR(VkQueue, uint32_t, const VkSubmitInfo2KHR*, VkFence) {
  EnterInFlight();
  ExitInFlight();
  return VK_SUCCESS;
}

VKAPI_ATTR VkResult VKAPI_CALL FakeQueueWaitIdle(VkQueue) {
  EnterInFlight();
  ExitInFlight();
  return VK_SUCCESS;
}

VKAPI_ATTR VkResult VKAPI_CALL
FakeQueuePresentKHR(VkQueue, const VkPresentInfoKHR*) {
  EnterInFlight();
  ExitInFlight();
  return VK_SUCCESS;
}

VKAPI_ATTR VkResult VKAPI_CALL
FakeQueueBindSparse(VkQueue, uint32_t, const VkBindSparseInfo*, VkFence) {
  EnterInFlight();
  ExitInFlight();
  return VK_SUCCESS;
}

VKAPI_ATTR void VKAPI_CALL
FakeQueueInsertDebugUtilsLabelEXT(VkQueue, const VkDebugUtilsLabelEXT*) {
  EnterInFlight();
  ExitInFlight();
}

VKAPI_ATTR void VKAPI_CALL
FakeQueueBeginDebugUtilsLabelEXT(VkQueue, const VkDebugUtilsLabelEXT*) {
  EnterInFlight();
  ExitInFlight();
}

VKAPI_ATTR void VKAPI_CALL FakeQueueEndDebugUtilsLabelEXT(VkQueue) {
  EnterInFlight();
  ExitInFlight();
}

VKAPI_ATTR VkResult VKAPI_CALL FakeDeviceWaitIdle(VkDevice device) {
  EnterInFlight();
  VkResult res = VK_SUCCESS;
  if (g_driver && g_driver->on_device_wait_idle) {
    res = g_driver->on_device_wait_idle(device);
  }
  ExitInFlight();
  return res;
}

VKAPI_ATTR void VKAPI_CALL
FakeDestroyDevice(VkDevice device, const VkAllocationCallbacks*) {
  if (g_driver) {
    g_driver->destroy_device_count.fetch_add(1, std::memory_order_seq_cst);
    if (g_driver->on_destroy_device) {
      g_driver->on_destroy_device(device);
    }
  }
}

VKAPI_ATTR void VKAPI_CALL
FakeDestroyInstance(VkInstance instance, const VkAllocationCallbacks*) {
  if (g_driver) {
    g_driver->destroy_instance_count.fetch_add(1, std::memory_order_seq_cst);
    if (g_driver->on_destroy_instance) {
      g_driver->on_destroy_instance(instance);
    }
  }
}

VKAPI_ATTR VkResult VKAPI_CALL
FakeEnumerateInstanceExtensionProperties(const char*,
                                         uint32_t* pPropertyCount,
                                         VkExtensionProperties*) {
  if (pPropertyCount) {
    *pPropertyCount = 0;
  }
  return VK_SUCCESS;
}

VKAPI_ATTR PFN_vkVoidFunction VKAPI_CALL
FakeGetDeviceProcAddr(VkDevice, const char* pName) {
  if (pName == nullptr) {
    return nullptr;
  }
  if (std::strcmp(pName, "vkQueueSubmit") == 0) {
    return reinterpret_cast<PFN_vkVoidFunction>(&FakeQueueSubmit);
  }
  if (std::strcmp(pName, "vkQueueSubmit2") == 0) {
    return reinterpret_cast<PFN_vkVoidFunction>(&FakeQueueSubmit2);
  }
  if (std::strcmp(pName, "vkQueueSubmit2KHR") == 0) {
    return reinterpret_cast<PFN_vkVoidFunction>(&FakeQueueSubmit2KHR);
  }
  if (std::strcmp(pName, "vkQueueWaitIdle") == 0) {
    return reinterpret_cast<PFN_vkVoidFunction>(&FakeQueueWaitIdle);
  }
  if (std::strcmp(pName, "vkQueuePresentKHR") == 0) {
    return reinterpret_cast<PFN_vkVoidFunction>(&FakeQueuePresentKHR);
  }
  if (std::strcmp(pName, "vkQueueBindSparse") == 0) {
    return reinterpret_cast<PFN_vkVoidFunction>(&FakeQueueBindSparse);
  }
  if (std::strcmp(pName, "vkQueueInsertDebugUtilsLabelEXT") == 0) {
    return reinterpret_cast<PFN_vkVoidFunction>(
        &FakeQueueInsertDebugUtilsLabelEXT);
  }
  if (std::strcmp(pName, "vkQueueBeginDebugUtilsLabelEXT") == 0) {
    return reinterpret_cast<PFN_vkVoidFunction>(
        &FakeQueueBeginDebugUtilsLabelEXT);
  }
  if (std::strcmp(pName, "vkQueueEndDebugUtilsLabelEXT") == 0) {
    return reinterpret_cast<PFN_vkVoidFunction>(
        &FakeQueueEndDebugUtilsLabelEXT);
  }
  if (std::strcmp(pName, "vkDeviceWaitIdle") == 0) {
    return reinterpret_cast<PFN_vkVoidFunction>(&FakeDeviceWaitIdle);
  }
  if (std::strcmp(pName, "vkDestroyDevice") == 0) {
    return reinterpret_cast<PFN_vkVoidFunction>(&FakeDestroyDevice);
  }
  return nullptr;
}

VKAPI_ATTR PFN_vkVoidFunction VKAPI_CALL
FakeGetInstanceProcAddr(VkInstance instance, const char* pName) {
  if (pName == nullptr) {
    return nullptr;
  }
  if (instance == VK_NULL_HANDLE) {
    if (g_driver) {
      g_driver->global_query_count.fetch_add(1, std::memory_order_seq_cst);
    }
    if (std::strcmp(pName, "vkEnumerateInstanceExtensionProperties") == 0) {
      return reinterpret_cast<PFN_vkVoidFunction>(
          &FakeEnumerateInstanceExtensionProperties);
    }
    return nullptr;
  }
  if (std::strcmp(pName, "vkGetDeviceProcAddr") == 0) {
    return reinterpret_cast<PFN_vkVoidFunction>(&FakeGetDeviceProcAddr);
  }
  if (std::strcmp(pName, "vkDestroyInstance") == 0) {
    return reinterpret_cast<PFN_vkVoidFunction>(&FakeDestroyInstance);
  }
  return FakeGetDeviceProcAddr(kFakeDevice, pName);
}

VKAPI_ATTR PFN_vkVoidFunction VKAPI_CALL
AlternateGetInstanceProcAddr(VkInstance instance, const char* pName) {
  return FakeGetInstanceProcAddr(instance, pName);
}

class RecordingGuardMutex final : public GuardMutexImpl {
 public:
  explicit RecordingGuardMutex(fml::AutoResetWaitableEvent* contended_event)
      : contended_event_(contended_event) {}

  void lock() override {
    if (!mutex_.try_lock()) {
      if (contended_event_) {
        contended_event_->Signal();
      }
      mutex_.lock();
    }
  }

  void unlock() override { mutex_.unlock(); }

 private:
  std::mutex mutex_;
  fml::AutoResetWaitableEvent* contended_event_;
};

class QueueGuardTest : public ::testing::Test {
 protected:
  void SetUp() override {
    VulkanQueueGuard::ResetForTesting();
    driver_ = std::make_unique<FakeDriverState>();
    g_driver = driver_.get();
  }

  void TearDown() override {
    VulkanQueueGuard::ResetForTesting();
    g_driver = nullptr;
    driver_.reset();
  }

  std::unique_ptr<FakeDriverState> driver_;
};

}  // namespace

// Test 1: Interception table through vkGetInstanceProcAddr and
// vkGetDeviceProcAddr, plus VK_NULL_HANDLE forwarding.
TEST_F(QueueGuardTest, TrampolineGuardsQueueFunctions) {
  VulkanQueueGuard::RegisterInstance(kFakeInstance, &FakeGetInstanceProcAddr);
  VulkanQueueGuard::RegisterDevice(kFakeInstance, kFakeDevice, {kFakeQueue},
                                   &FakeGetDeviceProcAddr);

  PFN_vkGetInstanceProcAddr gipa =
      VulkanQueueGuard::GetInstanceProcAddrTrampoline();
  ASSERT_NE(gipa, nullptr);

  // VK_NULL_HANDLE queries are forwarded unchanged to the registered loader.
  PFN_vkVoidFunction global_fn =
      gipa(VK_NULL_HANDLE, "vkEnumerateInstanceExtensionProperties");
  EXPECT_EQ(global_fn, reinterpret_cast<PFN_vkVoidFunction>(
                           &FakeEnumerateInstanceExtensionProperties));
  EXPECT_EQ(driver_->global_query_count.load(), 1);

  const std::vector<const char*> kGuardedNames = {
      "vkQueueSubmit",
      "vkQueueSubmit2",
      "vkQueueSubmit2KHR",
      "vkQueueWaitIdle",
      "vkQueuePresentKHR",
      "vkQueueBindSparse",
      "vkQueueInsertDebugUtilsLabelEXT",
      "vkQueueBeginDebugUtilsLabelEXT",
      "vkQueueEndDebugUtilsLabelEXT",
      "vkDeviceWaitIdle",
  };

  for (const char* name : kGuardedNames) {
    PFN_vkVoidFunction guarded_fn = gipa(kFakeInstance, name);
    PFN_vkVoidFunction raw_fn = FakeGetInstanceProcAddr(kFakeInstance, name);
    EXPECT_NE(guarded_fn, nullptr) << "Missing trampoline for " << name;
    EXPECT_NE(guarded_fn, raw_fn)
        << "Expected guard trampoline instead of raw pointer for " << name;
  }

  // Repeat through the returned vkGetDeviceProcAddr.
  auto gdpa = reinterpret_cast<PFN_vkGetDeviceProcAddr>(
      gipa(kFakeInstance, "vkGetDeviceProcAddr"));
  ASSERT_NE(gdpa, nullptr);
  EXPECT_NE(gdpa, &FakeGetDeviceProcAddr);

  for (const char* name : kGuardedNames) {
    PFN_vkVoidFunction guarded_fn = gdpa(kFakeDevice, name);
    PFN_vkVoidFunction raw_fn = FakeGetDeviceProcAddr(kFakeDevice, name);
    EXPECT_NE(guarded_fn, nullptr) << "Missing device trampoline for " << name;
    EXPECT_NE(guarded_fn, raw_fn)
        << "Expected device guard trampoline instead of raw pointer for "
        << name;
  }
}

// Test 2: Deterministic serialization between vkQueueSubmit and
// vkDeviceWaitIdle using an injected recording GuardMutex.
TEST_F(QueueGuardTest, DeviceWaitIdleBlocksWhileSubmitInFlight) {
  fml::AutoResetWaitableEvent contended;
  fml::AutoResetWaitableEvent submit_entered;
  fml::AutoResetWaitableEvent release_submit;
  std::atomic<bool> wait_idle_entered{false};
  std::atomic<bool> wait_idle_completed{false};

  VulkanQueueGuard::SetMutexFactoryForTesting([&contended]() {
    return std::make_unique<RecordingGuardMutex>(&contended);
  });

  driver_->on_queue_submit = [&](VkQueue, uint32_t, const VkSubmitInfo*,
                                 VkFence) -> VkResult {
    submit_entered.Signal();
    release_submit.Wait();
    return VK_SUCCESS;
  };
  driver_->on_device_wait_idle = [&](VkDevice) -> VkResult {
    wait_idle_entered.store(true, std::memory_order_seq_cst);
    return VK_SUCCESS;
  };

  VulkanQueueGuard::RegisterInstance(kFakeInstance, &FakeGetInstanceProcAddr);
  VulkanQueueGuard::RegisterDevice(kFakeInstance, kFakeDevice, {kFakeQueue},
                                   &FakeGetDeviceProcAddr);

  PFN_vkGetInstanceProcAddr gipa =
      VulkanQueueGuard::GetInstanceProcAddrTrampoline();
  auto submit_fn =
      reinterpret_cast<PFN_vkQueueSubmit>(gipa(kFakeInstance, "vkQueueSubmit"));
  auto wait_idle_fn = reinterpret_cast<PFN_vkDeviceWaitIdle>(
      gipa(kFakeInstance, "vkDeviceWaitIdle"));

  std::thread thread_a([&]() {
    EXPECT_EQ(submit_fn(kFakeQueue, 0, nullptr, VK_NULL_HANDLE), VK_SUCCESS);
  });

  // Wait for thread A to enter the fake vkQueueSubmit under queue_mutex.
  submit_entered.Wait();

  std::thread thread_b([&]() {
    EXPECT_EQ(wait_idle_fn(kFakeDevice), VK_SUCCESS);
    wait_idle_completed.store(true, std::memory_order_seq_cst);
  });

  // Bounded 5-second wait that only expires on the failure path (if the guard
  // fails to lock and contend on queue_mutex).
  constexpr int64_t kFailurePathTimeoutSeconds = 5;
  EXPECT_FALSE(contended.WaitWithTimeout(
      fml::TimeDelta::FromSeconds(kFailurePathTimeoutSeconds)));
  EXPECT_FALSE(wait_idle_entered.load(std::memory_order_seq_cst));

  release_submit.Signal();
  thread_a.join();
  thread_b.join();

  EXPECT_TRUE(wait_idle_entered.load(std::memory_order_seq_cst));
  EXPECT_TRUE(wait_idle_completed.load(std::memory_order_seq_cst));
}

// Test 3: Teardown waits for an in-flight guarded call before running
// vkDestroyDevice.
TEST_F(QueueGuardTest, DestroyWaitsForInFlightCall) {
  fml::AutoResetWaitableEvent wait_idle_entered;
  fml::AutoResetWaitableEvent release_wait_idle;
  std::atomic<int> sequence{0};
  std::atomic<int> in_flight_return_order{0};
  std::atomic<int> destroy_device_order{0};

  driver_->on_device_wait_idle = [&](VkDevice) -> VkResult {
    // Only block the first call (the in-flight call from thread A), not the
    // internal vkDeviceWaitIdle call inside TearDownDeviceAndInstance.
    static std::atomic<int> call_num{0};
    if (call_num.fetch_add(1) == 0) {
      wait_idle_entered.Signal();
      release_wait_idle.Wait();
    }
    return VK_SUCCESS;
  };
  driver_->on_destroy_device = [&](VkDevice) {
    destroy_device_order.store(
        sequence.fetch_add(1, std::memory_order_seq_cst) + 1,
        std::memory_order_seq_cst);
  };

  VulkanQueueGuard::RegisterInstance(kFakeInstance, &FakeGetInstanceProcAddr);
  VulkanQueueGuard::RegisterDevice(kFakeInstance, kFakeDevice, {kFakeQueue},
                                   &FakeGetDeviceProcAddr);

  PFN_vkGetInstanceProcAddr gipa =
      VulkanQueueGuard::GetInstanceProcAddrTrampoline();
  auto wait_idle_fn = reinterpret_cast<PFN_vkDeviceWaitIdle>(
      gipa(kFakeInstance, "vkDeviceWaitIdle"));

  std::thread in_flight_thread([&]() {
    EXPECT_EQ(wait_idle_fn(kFakeDevice), VK_SUCCESS);
    in_flight_return_order.store(
        sequence.fetch_add(1, std::memory_order_seq_cst) + 1,
        std::memory_order_seq_cst);
  });

  wait_idle_entered.Wait();

  std::thread teardown_thread([&]() {
    VulkanQueueGuard::TearDownDeviceAndInstance(
        kFakeInstance, kFakeDevice, &FakeDestroyDevice, &FakeDestroyInstance);
  });

  // Verify vkDestroyDevice has not run while the in-flight call is blocked.
  EXPECT_EQ(driver_->destroy_device_count.load(), 0);

  release_wait_idle.Signal();
  in_flight_thread.join();
  teardown_thread.join();

  EXPECT_EQ(driver_->destroy_device_count.load(), 1);
  EXPECT_EQ(driver_->destroy_instance_count.load(), 1);
  EXPECT_LT(in_flight_return_order.load(), destroy_device_order.load());
}

// Test 4: Calling through a tombstoned queue triggers FATAL naming the
// function, and re-registering the handle clears the tombstone.
TEST_F(QueueGuardTest, TombstonedHandleIsFatal) {
  VulkanQueueGuard::RegisterInstance(kFakeInstance, &FakeGetInstanceProcAddr);
  VulkanQueueGuard::RegisterDevice(kFakeInstance, kFakeDevice, {kFakeQueue},
                                   &FakeGetDeviceProcAddr);

  PFN_vkGetInstanceProcAddr gipa =
      VulkanQueueGuard::GetInstanceProcAddrTrampoline();
  auto submit_fn =
      reinterpret_cast<PFN_vkQueueSubmit>(gipa(kFakeInstance, "vkQueueSubmit"));

  VulkanQueueGuard::TearDownDeviceAndInstance(
      kFakeInstance, kFakeDevice, &FakeDestroyDevice, &FakeDestroyInstance);

  EXPECT_DEATH(submit_fn(kFakeQueue, 0, nullptr, VK_NULL_HANDLE),
               "vkQueueSubmit.*tombstoned");

  // Re-registering the same handles clears the tombstones.
  VulkanQueueGuard::RegisterInstance(kFakeInstance, &FakeGetInstanceProcAddr);
  VulkanQueueGuard::RegisterDevice(kFakeInstance, kFakeDevice, {kFakeQueue},
                                   &FakeGetDeviceProcAddr);
  EXPECT_EQ(submit_fn(kFakeQueue, 0, nullptr, VK_NULL_HANDLE), VK_SUCCESS);
}

// Test 4b: A call that copied the DeviceEntry before teardown and acquires
// queue_mutex after teardown triggers FATAL on the entry->destroyed check.
TEST_F(QueueGuardTest, CallRacingDestroyIsFatal) {
  VulkanQueueGuard::RegisterInstance(kFakeInstance, &FakeGetInstanceProcAddr);
  VulkanQueueGuard::RegisterDevice(kFakeInstance, kFakeDevice, {kFakeQueue},
                                   &FakeGetDeviceProcAddr);

  PFN_vkGetInstanceProcAddr gipa =
      VulkanQueueGuard::GetInstanceProcAddrTrampoline();
  auto submit_fn =
      reinterpret_cast<PFN_vkQueueSubmit>(gipa(kFakeInstance, "vkQueueSubmit"));

  EXPECT_DEATH(
      {
        VulkanQueueGuard::SetBeforeQueueLockHookForTesting([]() {
          VulkanQueueGuard::TearDownDeviceAndInstance(
              kFakeInstance, kFakeDevice, &FakeDestroyDevice,
              &FakeDestroyInstance);
        });
        submit_fn(kFakeQueue, 0, nullptr, VK_NULL_HANDLE);
      },
      "vkQueueSubmit.*destroyed");
}

// Test 4c: Registering a conflicting PFN for the VK_NULL_HANDLE slot triggers
// FATAL, and ResetForTesting allows registering a different loader afterwards.
TEST_F(QueueGuardTest, ConflictingNullInstanceLoaderIsFatal) {
  VulkanQueueGuard::RegisterInstance(kFakeInstance, &FakeGetInstanceProcAddr);

  EXPECT_DEATH(VulkanQueueGuard::RegisterInstance(
                   kFakeInstance, &AlternateGetInstanceProcAddr),
               "conflicting PFN_vkGetInstanceProcAddr");

  VulkanQueueGuard::ResetForTesting();
  VulkanQueueGuard::RegisterInstance(kFakeInstance,
                                     &AlternateGetInstanceProcAddr);
}

// Test 5: 100-iteration stress test of concurrent vkQueueSubmit and
// vkDeviceWaitIdle verifying max in-flight calls never exceeds 1.
TEST_F(QueueGuardTest, StressSubmitAndWaitIdle) {
  VulkanQueueGuard::RegisterInstance(kFakeInstance, &FakeGetInstanceProcAddr);
  VulkanQueueGuard::RegisterDevice(kFakeInstance, kFakeDevice, {kFakeQueue},
                                   &FakeGetDeviceProcAddr);

  PFN_vkGetInstanceProcAddr gipa =
      VulkanQueueGuard::GetInstanceProcAddrTrampoline();
  auto submit_fn =
      reinterpret_cast<PFN_vkQueueSubmit>(gipa(kFakeInstance, "vkQueueSubmit"));
  auto wait_idle_fn = reinterpret_cast<PFN_vkDeviceWaitIdle>(
      gipa(kFakeInstance, "vkDeviceWaitIdle"));

  // 100 iterations per §5.3 test 5 specification.
  constexpr int kStressIterations = 100;
  std::thread submit_thread([&]() {
    for (int i = 0; i < kStressIterations; ++i) {
      EXPECT_EQ(submit_fn(kFakeQueue, 0, nullptr, VK_NULL_HANDLE), VK_SUCCESS);
    }
  });
  std::thread wait_idle_thread([&]() {
    for (int i = 0; i < kStressIterations; ++i) {
      EXPECT_EQ(wait_idle_fn(kFakeDevice), VK_SUCCESS);
    }
  });

  submit_thread.join();
  wait_idle_thread.join();

  EXPECT_EQ(driver_->max_in_flight.load(), 1);
  EXPECT_EQ(VulkanQueueGuard::GetQueueSubmitCountForTesting(),
            static_cast<uint64_t>(kStressIterations));
}

}  // namespace testing
}  // namespace android
}  // namespace flutter
