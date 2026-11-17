// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_vulkan_snapshot_pool.h"

#include <fcntl.h>
#include <gio/gio.h>
#include <unistd.h>

#include <atomic>
#include <chrono>
#include <condition_variable>
#include <mutex>
#include <thread>

#include "flutter/shell/platform/linux/fl_vulkan_snapshot.h"
#include "gtest/gtest.h"

namespace flutter {
namespace {
// A per-device driver stand-in: exercises pool ownership, command reuse and
// failure recovery without a Vulkan ICD or DMA-BUF-capable machine.
struct Driver {
  std::atomic<size_t> buffers{0};
  std::atomic<size_t> memories{0};
  std::atomic<size_t> pools{0};
  std::atomic<size_t> fences{0};
  std::atomic<size_t> resets{0};
  std::atomic<size_t> waits{0};
  std::atomic<size_t> acquires{0};
  std::atomic<size_t> idle_waits{0};
  std::atomic<size_t> destroyed_buffers{0};
  std::atomic<bool> fail_wait{false};
  bool export_read_only_fd = false;
  bool fail_allocation = false;
  std::mutex mutex;
  std::condition_variable condition;
  std::thread::id destruction_thread;

  static Driver& Get(VkDevice device) {
    return *reinterpret_cast<Driver*>(device);
  }
  bool WaitForDestruction(size_t count) {
    std::unique_lock lock(mutex);
    return condition.wait_for(lock, std::chrono::seconds(5),
                              [&] { return destroyed_buffers >= count; });
  }
  static VKAPI_ATTR VkResult VKAPI_CALL
  CreateBuffer(VkDevice device,
               const VkBufferCreateInfo*,
               const VkAllocationCallbacks*,
               VkBuffer* result) {
    *result = reinterpret_cast<VkBuffer>(++Get(device).buffers);
    return VK_SUCCESS;
  }
  static VKAPI_ATTR void VKAPI_CALL
  GetBufferMemoryRequirements(VkDevice,
                              VkBuffer,
                              VkMemoryRequirements* result) {
    *result = {4096, 256, 1};
  }
  static VKAPI_ATTR VkResult VKAPI_CALL
  AllocateMemory(VkDevice device,
                 const VkMemoryAllocateInfo*,
                 const VkAllocationCallbacks*,
                 VkDeviceMemory* result) {
    if (Get(device).fail_allocation)
      return VK_ERROR_OUT_OF_DEVICE_MEMORY;
    *result = reinterpret_cast<VkDeviceMemory>(++Get(device).memories);
    return VK_SUCCESS;
  }
  static VKAPI_ATTR VkResult VKAPI_CALL BindBufferMemory(VkDevice,
                                                         VkBuffer,
                                                         VkDeviceMemory,
                                                         VkDeviceSize) {
    return VK_SUCCESS;
  }
  static VKAPI_ATTR VkResult VKAPI_CALL
  GetMemoryFdKHR(VkDevice device, const VkMemoryGetFdInfoKHR*, int* result) {
    if (Get(device).export_read_only_fd) {
      int descriptors[2];
      if (pipe(descriptors) != 0)
        return VK_ERROR_OUT_OF_HOST_MEMORY;
      close(descriptors[1]);
      *result = descriptors[0];
      return VK_SUCCESS;
    }
    *result = open("/dev/null", O_RDWR | O_CLOEXEC);
    return *result >= 0 ? VK_SUCCESS : VK_ERROR_OUT_OF_HOST_MEMORY;
  }
  static VKAPI_ATTR VkResult VKAPI_CALL
  CreateCommandPool(VkDevice device,
                    const VkCommandPoolCreateInfo*,
                    const VkAllocationCallbacks*,
                    VkCommandPool* result) {
    *result = reinterpret_cast<VkCommandPool>(++Get(device).pools);
    return VK_SUCCESS;
  }
  static VKAPI_ATTR VkResult VKAPI_CALL
  AllocateCommandBuffers(VkDevice device,
                         const VkCommandBufferAllocateInfo*,
                         VkCommandBuffer* result) {
    *result = reinterpret_cast<VkCommandBuffer>(device);
    return VK_SUCCESS;
  }
  static VKAPI_ATTR VkResult VKAPI_CALL
  CreateFence(VkDevice device,
              const VkFenceCreateInfo*,
              const VkAllocationCallbacks*,
              VkFence* result) {
    *result = reinterpret_cast<VkFence>(++Get(device).fences);
    return VK_SUCCESS;
  }
  static VKAPI_ATTR VkResult VKAPI_CALL
  ResetCommandPool(VkDevice device, VkCommandPool, VkCommandPoolResetFlags) {
    Get(device).resets++;
    return VK_SUCCESS;
  }
  static VKAPI_ATTR VkResult VKAPI_CALL ResetFences(VkDevice,
                                                    uint32_t,
                                                    const VkFence*) {
    return VK_SUCCESS;
  }
  static VKAPI_ATTR VkResult VKAPI_CALL
  BeginCommandBuffer(VkCommandBuffer, const VkCommandBufferBeginInfo*) {
    return VK_SUCCESS;
  }
  static VKAPI_ATTR void VKAPI_CALL
  CmdPipelineBarrier(VkCommandBuffer command,
                     VkPipelineStageFlags,
                     VkPipelineStageFlags,
                     VkDependencyFlags,
                     uint32_t,
                     const VkMemoryBarrier*,
                     uint32_t count,
                     const VkBufferMemoryBarrier* buffers,
                     uint32_t,
                     const VkImageMemoryBarrier*) {
    for (uint32_t i = 0; i < count; i++) {
      if (buffers[i].srcQueueFamilyIndex == VK_QUEUE_FAMILY_FOREIGN_EXT &&
          buffers[i].dstQueueFamilyIndex == 0) {
        Get(reinterpret_cast<VkDevice>(command)).acquires++;
      }
    }
  }
  static VKAPI_ATTR void VKAPI_CALL
  CmdCopyImageToBuffer(VkCommandBuffer,
                       VkImage,
                       VkImageLayout,
                       VkBuffer,
                       uint32_t,
                       const VkBufferImageCopy*) {}
  static VKAPI_ATTR VkResult VKAPI_CALL EndCommandBuffer(VkCommandBuffer) {
    return VK_SUCCESS;
  }
  static VKAPI_ATTR VkResult VKAPI_CALL QueueSubmit(VkQueue,
                                                    uint32_t,
                                                    const VkSubmitInfo*,
                                                    VkFence) {
    return VK_SUCCESS;
  }
  static VKAPI_ATTR VkResult VKAPI_CALL
  WaitForFences(VkDevice device, uint32_t, const VkFence*, VkBool32, uint64_t) {
    auto& driver = Get(device);
    driver.waits++;
    return driver.fail_wait ? VK_ERROR_DEVICE_LOST : VK_SUCCESS;
  }
  static VKAPI_ATTR VkResult VKAPI_CALL QueueWaitIdle(VkQueue queue) {
    Get(reinterpret_cast<VkDevice>(queue)).idle_waits++;
    return VK_SUCCESS;
  }
  static VKAPI_ATTR void VKAPI_CALL DestroyFence(VkDevice,
                                                 VkFence,
                                                 const VkAllocationCallbacks*) {
  }
  static VKAPI_ATTR void VKAPI_CALL
  DestroyCommandPool(VkDevice, VkCommandPool, const VkAllocationCallbacks*) {}
  static VKAPI_ATTR void VKAPI_CALL
  DestroyBuffer(VkDevice device, VkBuffer, const VkAllocationCallbacks*) {
    auto& driver = Get(device);
    std::scoped_lock lock(driver.mutex);
    driver.destruction_thread = std::this_thread::get_id();
    driver.destroyed_buffers++;
    driver.condition.notify_all();
  }
  static VKAPI_ATTR void VKAPI_CALL FreeMemory(VkDevice,
                                               VkDeviceMemory,
                                               const VkAllocationCallbacks*) {}

  static VKAPI_ATTR PFN_vkVoidFunction VKAPI_CALL GetProc(VkDevice,
                                                          const char* name) {
#define PROC(name_)                   \
  if (strcmp(name, "vk" #name_) == 0) \
    return reinterpret_cast<PFN_vkVoidFunction>(name_);
    PROC(CreateBuffer)
    PROC(GetBufferMemoryRequirements)
    PROC(AllocateMemory)
    PROC(BindBufferMemory)
    PROC(GetMemoryFdKHR)
    PROC(CreateCommandPool)
    PROC(AllocateCommandBuffers)
    PROC(CreateFence)
    PROC(ResetCommandPool)
    PROC(ResetFences)
    PROC(BeginCommandBuffer)
    PROC(CmdPipelineBarrier)
    PROC(CmdCopyImageToBuffer)
    PROC(EndCommandBuffer)
    PROC(WaitForFences)
    PROC(QueueWaitIdle)
    PROC(DestroyFence)
    PROC(DestroyCommandPool)
    PROC(DestroyBuffer)
    PROC(FreeMemory)
#undef PROC
    return nullptr;
  }
};

class FlVulkanSnapshotPoolTest : public ::testing::Test {
 protected:
  FlVulkanSnapshotPoolTest() {
    FlVulkanDeviceContext context = {};
    context.lifetime = driver;
    context.device = reinterpret_cast<VkDevice>(driver.get());
    context.queue = reinterpret_cast<VkQueue>(driver.get());
    context.max_image_dimension = 4096;
    context.memory.memoryTypeCount = 1;
    context.memory.memoryTypes[0].propertyFlags =
        VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT |
        VK_MEMORY_PROPERTY_HOST_COHERENT_BIT;
    context.get_proc = Driver::GetProc;
    context.submit = Driver::QueueSubmit;
    pool = FlVulkanSnapshotPool::Create(context, 2);
  }
  std::shared_ptr<FlVulkanSnapshot> Copy(uint32_t width = 17,
                                         uint32_t height = 13,
                                         GError** error = nullptr) {
    return FlVulkanSnapshot::Create(pool, reinterpret_cast<VkImage>(1), width,
                                    height, error);
  }
  std::shared_ptr<Driver> driver = std::make_shared<Driver>();
  std::shared_ptr<FlVulkanSnapshotPool> pool;
};

TEST_F(FlVulkanSnapshotPoolTest, ReusesAllocationCommandsAndFenceAfterWarmup) {
  for (size_t i = 0; i < 100; i++) {
    auto frame = Copy();
    ASSERT_NE(frame, nullptr);
  }
  EXPECT_EQ(driver->buffers, 1u);
  EXPECT_EQ(driver->memories, 1u);
  EXPECT_EQ(driver->pools, 1u);
  EXPECT_EQ(driver->fences, 1u);
  EXPECT_EQ(driver->waits, 100u);
  EXPECT_EQ(driver->resets, 100u);
  EXPECT_EQ(driver->acquires, 99u);
  EXPECT_EQ(pool->stats().allocations, 1u);
  EXPECT_EQ(pool->stats().reuses, 99u);
  EXPECT_EQ(pool->stats().memory_bytes, 4096u);
}

TEST_F(FlVulkanSnapshotPoolTest, RetainedFramesExhaustPoolThenRecover) {
  auto first = Copy();
  auto second = Copy();
  ASSERT_NE(first, nullptr);
  ASSERT_NE(second, nullptr);
  const int first_fd = first->descriptor().planes[0].fd;
  EXPECT_NE(first_fd, second->descriptor().planes[0].fd);
  g_autoptr(GError) error = nullptr;
  EXPECT_EQ(Copy(17, 13, &error), nullptr);
  EXPECT_TRUE(g_error_matches(error, G_IO_ERROR, G_IO_ERROR_WOULD_BLOCK));
  EXPECT_EQ(driver->buffers, 2u);
  std::thread release([frame = std::move(first)]() mutable { frame.reset(); });
  release.join();
  EXPECT_EQ(driver->destroyed_buffers, 0u);
  auto reused = Copy();
  ASSERT_NE(reused, nullptr);
  EXPECT_EQ(reused->descriptor().planes[0].fd, first_fd);
  EXPECT_EQ(pool->stats().reuses, 1u);
  EXPECT_EQ(pool->stats().exhaustions, 1u);
}

TEST_F(FlVulkanSnapshotPoolTest, ResizeRetiresIdleSizesButPreservesHeldFrames) {
  auto held = Copy();
  auto resized = Copy(101, 29);
  ASSERT_NE(held, nullptr);
  ASSERT_NE(resized, nullptr);
  const int held_fd = held->descriptor().planes[0].fd;
  EXPECT_NE(fcntl(held_fd, F_GETFD), -1);
  EXPECT_EQ(driver->destroyed_buffers, 0u);
  resized.reset();
  auto reused = Copy(101, 29);
  ASSERT_NE(reused, nullptr);
  EXPECT_EQ(pool->stats().allocations, 2u);
  held.reset();
  reused.reset();
  auto replacement = Copy(61, 41);
  ASSERT_NE(replacement, nullptr);
  EXPECT_EQ(driver->destroyed_buffers, 2u);
  EXPECT_EQ(pool->stats().slots, 1u);
  EXPECT_EQ(replacement->descriptor().width, 61u);
  EXPECT_EQ(replacement->descriptor().height, 41u);
}

TEST_F(FlVulkanSnapshotPoolTest, DoesNotReuseBufferWithUnreadyImplicitFences) {
  // A non-writable FD stands in for a DMA-BUF whose readers have not finished.
  driver->export_read_only_fd = true;
  {
    ASSERT_NE(Copy(), nullptr);
  }
  {
    ASSERT_NE(Copy(), nullptr);
  }
  g_autoptr(GError) error = nullptr;
  EXPECT_EQ(Copy(17, 13, &error), nullptr);
  EXPECT_TRUE(g_error_matches(error, G_IO_ERROR, G_IO_ERROR_WOULD_BLOCK));
  EXPECT_EQ(driver->buffers, 2u);
  EXPECT_EQ(pool->stats().reuses, 0u);
}

TEST_F(FlVulkanSnapshotPoolTest, FailedWaitRetiresSlotAfterQuiescingQueue) {
  driver->fail_wait = true;
  g_autoptr(GError) error = nullptr;
  EXPECT_EQ(Copy(17, 13, &error), nullptr);
  ASSERT_NE(error, nullptr);
  EXPECT_EQ(driver->idle_waits, 1u);
  driver->fail_wait = false;
  auto frame = Copy();
  ASSERT_NE(frame, nullptr);
  EXPECT_EQ(driver->destroyed_buffers, 1u);
  EXPECT_EQ(driver->buffers, 2u);
  EXPECT_EQ(pool->stats().reuses, 0u);
}

TEST_F(FlVulkanSnapshotPoolTest, LastLeaseDefersCleanupBeyondReleaseCallback) {
  auto frame = Copy();
  ASSERT_NE(frame, nullptr);
  pool.reset();
  EXPECT_EQ(driver->destroyed_buffers, 0u);
  auto release_thread = std::this_thread::get_id();
  frame.reset();
  ASSERT_TRUE(driver->WaitForDestruction(1));
  EXPECT_NE(driver->destruction_thread, release_thread);
}

TEST_F(FlVulkanSnapshotPoolTest, PartialAllocationFailureIsCleanedAndCanRetry) {
  driver->fail_allocation = true;
  g_autoptr(GError) error = nullptr;
  EXPECT_EQ(Copy(17, 13, &error), nullptr);
  ASSERT_NE(error, nullptr);
  EXPECT_EQ(driver->destroyed_buffers, 1u);
  EXPECT_EQ(pool->stats().slots, 0u);
  driver->fail_allocation = false;
  ASSERT_NE(Copy(), nullptr);
  EXPECT_EQ(pool->stats().allocations, 1u);
}

TEST_F(FlVulkanSnapshotPoolTest, RejectsInvalidDimensionsWithoutAllocating) {
  for (auto dimensions :
       {std::pair{0u, 13u}, std::pair{17u, 0u}, std::pair{4097u, 13u}}) {
    g_autoptr(GError) error = nullptr;
    EXPECT_EQ(Copy(dimensions.first, dimensions.second, &error), nullptr);
    EXPECT_TRUE(
        g_error_matches(error, G_IO_ERROR, G_IO_ERROR_INVALID_ARGUMENT));
  }
  EXPECT_EQ(driver->buffers, 0u);
}
}  // namespace
}  // namespace flutter
