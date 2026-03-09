// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gtest/gtest.h"

#include "flutter/fml/logging.h"
#include "flutter/shell/platform/linux/fl_vulkan_manager.h"

// Verify that the Vulkan availability check completes without crashing.
// Thread-safe: uses g_once_init_enter internally, so this test also
// implicitly validates that is_available is safe to call multiple times.
TEST(FlVulkanManagerTest, CheckAvailability) {
  gboolean available = fl_vulkan_manager_is_available();
  FML_LOG(INFO) << "Vulkan availability: " << (available ? "YES" : "NO");

  // Calling a second time should return the cached result.
  gboolean available2 = fl_vulkan_manager_is_available();
  EXPECT_EQ(available, available2);
}

// Test Vulkan manager creation without a window.
// This exercises headless Vulkan initialization (instance, device, queue)
// without creating a VkSurfaceKHR.
TEST(FlVulkanManagerTest, CreateWithoutWindow) {
  if (!fl_vulkan_manager_is_available()) {
    GTEST_SKIP() << "Vulkan is not available on this system.";
  }

  g_autoptr(FlVulkanManager) manager = fl_vulkan_manager_new(nullptr);

  // On systems without proper drivers, creation may fail.
  // The test passes as long as no crash occurs.
  if (manager != nullptr) {
    EXPECT_NE(fl_vulkan_manager_get_instance(manager), VK_NULL_HANDLE);
    EXPECT_NE(fl_vulkan_manager_get_physical_device(manager), VK_NULL_HANDLE);
    EXPECT_NE(fl_vulkan_manager_get_device(manager), VK_NULL_HANDLE);
    EXPECT_NE(fl_vulkan_manager_get_queue(manager), VK_NULL_HANDLE);
    EXPECT_NE(fl_vulkan_manager_get_queue_family_index(manager), UINT32_MAX);
    EXPECT_NE(fl_vulkan_manager_get_vulkan_version(manager), 0u);
    EXPECT_NE(fl_vulkan_manager_get_proc_table(manager), nullptr);

    // Without a window, there should be no surface.
    EXPECT_EQ(fl_vulkan_manager_get_surface(manager), VK_NULL_HANDLE);

    // Test extension getters.
    size_t instance_ext_count = 0;
    const char** instance_exts =
        fl_vulkan_manager_get_enabled_instance_extensions(manager,
                                                          &instance_ext_count);
    EXPECT_NE(instance_exts, nullptr);
    EXPECT_GT(instance_ext_count, 0u);

    size_t device_ext_count = 0;
    const char** device_exts = fl_vulkan_manager_get_enabled_device_extensions(
        manager, &device_ext_count);
    EXPECT_NE(device_exts, nullptr);
    EXPECT_GT(device_ext_count, 0u);

    // Test proc address lookup.
    void* proc = fl_vulkan_manager_get_instance_proc_address(
        manager, fl_vulkan_manager_get_instance(manager), "vkCreateInstance");
    EXPECT_NE(proc, nullptr);

    // Test mutex operations (should not hang or crash).
    fl_vulkan_manager_acquire_queue_mutex(manager);
    fl_vulkan_manager_release_queue_mutex(manager);
  } else {
    FML_LOG(WARNING) << "Vulkan manager creation failed (expected on systems "
                        "without Vulkan support).";
  }
}

// Test that shutdown and wait_idle are safe on a headless manager
// and that double-shutdown does not crash (since the raster thread may
// call shutdown while dispose is also shutting down).
TEST(FlVulkanManagerTest, ShutdownAndWaitIdle) {
  if (!fl_vulkan_manager_is_available()) {
    GTEST_SKIP() << "Vulkan is not available on this system.";
  }

  g_autoptr(FlVulkanManager) manager = fl_vulkan_manager_new(nullptr);
  if (manager == nullptr) {
    GTEST_SKIP() << "Vulkan manager creation failed.";
  }

  // wait_idle should complete without error.
  fl_vulkan_manager_wait_idle(manager);

  // shutdown should complete without error.
  fl_vulkan_manager_shutdown(manager);

  // Double shutdown must not crash - dispose also calls shutdown logic.
  fl_vulkan_manager_shutdown(manager);

  // After shutdown, acquire_image should return an empty image.
  FlutterVulkanImage image = fl_vulkan_manager_acquire_image(manager, 100, 100);
  EXPECT_EQ(image.image, 0u);
}

// Test deferred image destruction API with VK_NULL_HANDLE values.
// This validates that the deferred deletion queue handles null inputs
// gracefully and that process_deferred_deletions does not crash on
// empty or null-filled queues.
TEST(FlVulkanManagerTest, DeferredDeletionNullSafe) {
  if (!fl_vulkan_manager_is_available()) {
    GTEST_SKIP() << "Vulkan is not available on this system.";
  }

  g_autoptr(FlVulkanManager) manager = fl_vulkan_manager_new(nullptr);
  if (manager == nullptr) {
    GTEST_SKIP() << "Vulkan manager creation failed.";
  }

  // Processing an empty queue should be a no-op.
  fl_vulkan_manager_process_deferred_deletions(manager);

  // Deferring null handles should not crash.
  fl_vulkan_manager_defer_image_destruction(manager, VK_NULL_HANDLE,
                                            VK_NULL_HANDLE);

  // Processing should handle null handles gracefully (vkDestroyImage and
  // vkFreeMemory with VK_NULL_HANDLE are valid per Vulkan spec).
  fl_vulkan_manager_process_deferred_deletions(manager);
}

// Test memory properties getter returns valid data.
TEST(FlVulkanManagerTest, MemoryProperties) {
  if (!fl_vulkan_manager_is_available()) {
    GTEST_SKIP() << "Vulkan is not available on this system.";
  }

  g_autoptr(FlVulkanManager) manager = fl_vulkan_manager_new(nullptr);
  if (manager == nullptr) {
    GTEST_SKIP() << "Vulkan manager creation failed.";
  }

  const VkPhysicalDeviceMemoryProperties* props =
      fl_vulkan_manager_get_memory_properties(manager);
  EXPECT_NE(props, nullptr);
  // Every Vulkan device must have at least one memory type and heap.
  EXPECT_GT(props->memoryTypeCount, 0u);
  EXPECT_GT(props->memoryHeapCount, 0u);
}

// Test that release_surface returns VK_NULL_HANDLE for headless manager
// and that subsequent calls also return VK_NULL_HANDLE.
TEST(FlVulkanManagerTest, ReleaseSurface) {
  if (!fl_vulkan_manager_is_available()) {
    GTEST_SKIP() << "Vulkan is not available on this system.";
  }

  g_autoptr(FlVulkanManager) manager = fl_vulkan_manager_new(nullptr);
  if (manager == nullptr) {
    GTEST_SKIP() << "Vulkan manager creation failed.";
  }

  // No surface in headless mode.
  VkSurfaceKHR surface = fl_vulkan_manager_release_surface(manager);
  EXPECT_EQ(surface, VK_NULL_HANDLE);

  // After release, get_surface should also return VK_NULL_HANDLE.
  EXPECT_EQ(fl_vulkan_manager_get_surface(manager), VK_NULL_HANDLE);
}
