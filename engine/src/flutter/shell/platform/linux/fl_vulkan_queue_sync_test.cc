// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_vulkan_queue_sync.h"

#include <chrono>
#include <future>
#include <thread>

#include "gtest/gtest.h"

namespace {
using namespace std::chrono_literals;

// Driver stand-in: idle waits remain inside the driver until explicitly
// released. No Vulkan loader, GPU or window system is needed to reproduce
// contention.
struct Device {
  std::promise<void> entered;
  std::promise<void> release;
  std::shared_future<void> released = release.get_future().share();
  VkDevice device() { return reinterpret_cast<VkDevice>(this); }
  VkQueue queue() { return reinterpret_cast<VkQueue>(this); }

  Device() {
    fl_vulkan_queue_sync_register(device(), queue(), Submit, QueueWait,
                                  DeviceWait);
  }
  ~Device() { fl_vulkan_queue_sync_unregister(device(), queue()); }

  static VKAPI_ATTR VkResult VKAPI_CALL Submit(VkQueue,
                                               uint32_t,
                                               const VkSubmitInfo*,
                                               VkFence) {
    return VK_SUCCESS;
  }
  static VkResult Wait(Device* self) {
    self->entered.set_value();
    self->released.wait();
    return VK_SUCCESS;
  }
  static VKAPI_ATTR VkResult VKAPI_CALL QueueWait(VkQueue queue) {
    return Wait(reinterpret_cast<Device*>(queue));
  }
  static VKAPI_ATTR VkResult VKAPI_CALL DeviceWait(VkDevice device) {
    return Wait(reinterpret_cast<Device*>(device));
  }
};

class FlVulkanQueueSyncTest : public ::testing::TestWithParam<bool> {
 protected:
  VkResult Wait(Device& device) {
    return GetParam() ? fl_vulkan_device_wait_idle(device.device())
                      : fl_vulkan_queue_wait_idle(device.queue());
  }
};

TEST_P(FlVulkanQueueSyncTest, IdleWaitDoesNotBlockAnotherDevice) {
  Device slow;
  Device fast;
  auto entered = slow.entered.get_future();
  auto wait = std::async(std::launch::async, [&] { return Wait(slow); });
  // Always release the fake driver, including on failure, so regressions fail
  // with an assertion instead of hanging the test process.
  EXPECT_EQ(entered.wait_for(5s), std::future_status::ready);
  auto submit = std::async(std::launch::async, [&] {
    return fl_vulkan_queue_submit(fast.queue(), 0, nullptr, VK_NULL_HANDLE);
  });
  EXPECT_EQ(submit.wait_for(5s), std::future_status::ready);
  slow.release.set_value();
  EXPECT_EQ(wait.get(), VK_SUCCESS);
  EXPECT_EQ(submit.get(), VK_SUCCESS);
}

TEST_P(FlVulkanQueueSyncTest, IdleWaitSerializesSubmissionOnSameDevice) {
  Device device;
  auto entered = device.entered.get_future();
  auto wait = std::async(std::launch::async, [&] { return Wait(device); });
  EXPECT_EQ(entered.wait_for(5s), std::future_status::ready);
  std::promise<void> submitting;
  auto started = submitting.get_future();
  auto submit = std::async(std::launch::async, [&] {
    submitting.set_value();
    return fl_vulkan_queue_submit(device.queue(), 0, nullptr, VK_NULL_HANDLE);
  });
  EXPECT_EQ(started.wait_for(5s), std::future_status::ready);
  EXPECT_EQ(submit.wait_for(100ms), std::future_status::timeout);
  device.release.set_value();
  EXPECT_EQ(wait.get(), VK_SUCCESS);
  EXPECT_EQ(submit.get(), VK_SUCCESS);
}

INSTANTIATE_TEST_SUITE_P(QueueAndDeviceWaits,
                         FlVulkanQueueSyncTest,
                         ::testing::Bool());

TEST(FlVulkanQueueSyncRegistryTest, UnregisteredHandlesFail) {
  Device device;
  fl_vulkan_queue_sync_unregister(device.device(), device.queue());
  EXPECT_EQ(fl_vulkan_queue_submit(device.queue(), 0, nullptr, VK_NULL_HANDLE),
            VK_ERROR_INITIALIZATION_FAILED);
  EXPECT_EQ(fl_vulkan_queue_wait_idle(device.queue()),
            VK_ERROR_INITIALIZATION_FAILED);
  EXPECT_EQ(fl_vulkan_device_wait_idle(device.device()),
            VK_ERROR_INITIALIZATION_FAILED);
  fl_vulkan_queue_sync_register(device.device(), device.queue(), Device::Submit,
                                Device::QueueWait, Device::DeviceWait);
  EXPECT_EQ(fl_vulkan_queue_submit(device.queue(), 0, nullptr, VK_NULL_HANDLE),
            VK_SUCCESS);
}
}  // namespace
