// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/vulkan_manager.h"

#include "gtest/gtest.h"

namespace flutter {
namespace testing {

// Verify IsAvailable returns a valid result when Vulkan drivers may or may
// not be present.
TEST(VulkanManagerTest, IsAvailable) {
  // IsAvailable should return a boolean regardless of whether Vulkan drivers
  // are installed.
  bool available = VulkanManager::IsAvailable();
  (void)available;
}

// Create() returns a valid manager when Vulkan is available, or nullptr
// otherwise.
TEST(VulkanManagerTest, CreateReturnsManagerOrNull) {
  auto manager = VulkanManager::Create();
  if (!manager) {
    GTEST_SKIP() << "Vulkan is not available on this system.";
  }

  EXPECT_NE(manager->GetInstance(), VK_NULL_HANDLE);
  EXPECT_NE(manager->GetPhysicalDevice(), VK_NULL_HANDLE);
  EXPECT_NE(manager->GetDevice(), VK_NULL_HANDLE);
  EXPECT_NE(manager->GetQueue(), VK_NULL_HANDLE);
  EXPECT_NE(manager->GetProcTable(), nullptr);
  EXPECT_NE(manager->GetVulkanVersion(), 0u);
}

// Test that enabled extension getters return valid data.
TEST(VulkanManagerTest, EnabledExtensions) {
  auto manager = VulkanManager::Create();
  if (!manager) {
    GTEST_SKIP() << "Vulkan is not available on this system.";
  }

  size_t instance_ext_count = 0;
  const char* const* instance_exts =
      manager->GetEnabledInstanceExtensions(&instance_ext_count);
  EXPECT_NE(instance_exts, nullptr);
  EXPECT_GE(instance_ext_count, 2u);  // VK_KHR_surface + VK_KHR_win32_surface

  size_t device_ext_count = 0;
  const char* const* device_exts =
      manager->GetEnabledDeviceExtensions(&device_ext_count);
  EXPECT_NE(device_exts, nullptr);
  EXPECT_GE(device_ext_count, 1u);  // VK_KHR_swapchain
}

// Test instance proc address resolution.
TEST(VulkanManagerTest, GetInstanceProcAddress) {
  auto manager = VulkanManager::Create();
  if (!manager) {
    GTEST_SKIP() << "Vulkan is not available on this system.";
  }

  void* proc = manager->GetInstanceProcAddress(manager->GetInstance(),
                                               "vkEnumeratePhysicalDevices");
  EXPECT_NE(proc, nullptr);

  // Non-existent function should return nullptr.
  void* bad_proc = manager->GetInstanceProcAddress(manager->GetInstance(),
                                                   "vkNonExistentFunction");
  EXPECT_EQ(bad_proc, nullptr);
}

// Test GetInstanceProcAddress with null VulkanManager state.
TEST(VulkanManagerTest, GetInstanceProcAddressNullInstance) {
  auto manager = VulkanManager::Create();
  if (!manager) {
    GTEST_SKIP() << "Vulkan is not available on this system.";
  }

  // Calling with VK_NULL_HANDLE should return gracefully.
  void* proc =
      manager->GetInstanceProcAddress(VK_NULL_HANDLE, "vkCreateInstance");
  // Result is implementation-defined.
  (void)proc;
}

// Test surface lifecycle without a real window.
TEST(VulkanManagerTest, InitializeSurfaceNullHwnd) {
  auto manager = VulkanManager::Create();
  if (!manager) {
    GTEST_SKIP() << "Vulkan is not available on this system.";
  }

  // Initializing with nullptr HWND should fail gracefully.
  EXPECT_FALSE(manager->InitializeSurface(nullptr));
  EXPECT_EQ(manager->GetSurface(), VK_NULL_HANDLE);
}

// Test ReleaseSurface returns VK_NULL_HANDLE when no surface is created.
TEST(VulkanManagerTest, ReleaseSurfaceWithoutInit) {
  auto manager = VulkanManager::Create();
  if (!manager) {
    GTEST_SKIP() << "Vulkan is not available on this system.";
  }

  VkSurfaceKHR surface = manager->ReleaseSurface();
  EXPECT_EQ(surface, VK_NULL_HANDLE);
  EXPECT_EQ(manager->GetSurface(), VK_NULL_HANDLE);
}

// Verify clean resource teardown when manager is destroyed.
TEST(VulkanManagerTest, DestructionOrder) {
  auto manager = VulkanManager::Create();
  if (!manager) {
    GTEST_SKIP() << "Vulkan is not available on this system.";
  }

  // Destroying the manager should properly clean up instance, device, etc.
  manager.reset();
}

}  // namespace testing
}  // namespace flutter
