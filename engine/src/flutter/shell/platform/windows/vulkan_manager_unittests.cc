// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/vulkan_manager.h"

#include <algorithm>
#include <cstring>

#include "gtest/gtest.h"

namespace flutter {
namespace testing {

// IsAvailable must not crash regardless of whether a Vulkan runtime is
// installed.
TEST(VulkanManagerTest, IsAvailable) {
  bool available = VulkanManager::IsAvailable();
  (void)available;
}

// Create() returns a fully initialized manager when Vulkan with Direct3D 11
// interop is available, or nullptr otherwise. It must never crash.
TEST(VulkanManagerTest, CreateReturnsManagerOrNull) {
  auto manager = VulkanManager::Create();
  if (!manager) {
    GTEST_SKIP() << "Vulkan with D3D11 interop is not available.";
  }

  EXPECT_NE(manager->GetInstance(), VK_NULL_HANDLE);
  EXPECT_NE(manager->GetPhysicalDevice(), VK_NULL_HANDLE);
  EXPECT_NE(manager->GetDevice(), VK_NULL_HANDLE);
  EXPECT_NE(manager->GetQueue(), VK_NULL_HANDLE);
  EXPECT_NE(manager->GetProcTable(), nullptr);
  EXPECT_GE(manager->GetVulkanVersion(), VK_API_VERSION_1_1);
}

// A successfully created manager must report a valid adapter LUID: it is
// what ties the Vulkan device to the same DXGI adapter on the Direct3D
// side. An all-zero LUID never identifies a hardware adapter.
TEST(VulkanManagerTest, DeviceLUIDIsValid) {
  auto manager = VulkanManager::Create();
  if (!manager) {
    GTEST_SKIP() << "Vulkan with D3D11 interop is not available.";
  }

  const auto& luid = manager->GetDeviceLUID();
  bool all_zero =
      std::all_of(luid.begin(), luid.end(), [](uint8_t b) { return b == 0; });
  EXPECT_FALSE(all_zero);
}

// The device must be created with the extensions the DXGI interop relies
// on; anything less and image export or the keyed mutex handoff would fail
// at runtime instead of falling back cleanly at startup.
TEST(VulkanManagerTest, EnabledExtensionsIncludeExternalMemory) {
  auto manager = VulkanManager::Create();
  if (!manager) {
    GTEST_SKIP() << "Vulkan with D3D11 interop is not available.";
  }

  size_t device_ext_count = 0;
  const char* const* device_exts =
      manager->GetEnabledDeviceExtensions(&device_ext_count);
  ASSERT_NE(device_exts, nullptr);

  auto has_extension = [&](const char* name) {
    for (size_t i = 0; i < device_ext_count; i++) {
      if (std::strcmp(device_exts[i], name) == 0) {
        return true;
      }
    }
    return false;
  };

  EXPECT_TRUE(has_extension(VK_KHR_EXTERNAL_MEMORY_WIN32_EXTENSION_NAME));
  EXPECT_TRUE(has_extension(VK_KHR_WIN32_KEYED_MUTEX_EXTENSION_NAME));
}

// No windowing system extensions may be enabled: presentation happens on
// the DXGI side and a VK_KHR_win32_surface dependency would be a
// regression toward the swapchain design.
TEST(VulkanManagerTest, NoSurfaceExtensionsEnabled) {
  auto manager = VulkanManager::Create();
  if (!manager) {
    GTEST_SKIP() << "Vulkan with D3D11 interop is not available.";
  }

  size_t instance_ext_count = 0;
  const char* const* instance_exts =
      manager->GetEnabledInstanceExtensions(&instance_ext_count);
  for (size_t i = 0; i < instance_ext_count; i++) {
    EXPECT_STRNE(instance_exts[i], "VK_KHR_surface");
    EXPECT_STRNE(instance_exts[i], "VK_KHR_win32_surface");
  }

  size_t device_ext_count = 0;
  const char* const* device_exts =
      manager->GetEnabledDeviceExtensions(&device_ext_count);
  for (size_t i = 0; i < device_ext_count; i++) {
    EXPECT_STRNE(device_exts[i], "VK_KHR_swapchain");
  }
}

// Instance proc address resolution works for real functions and returns
// null for unknown names.
TEST(VulkanManagerTest, GetInstanceProcAddress) {
  auto manager = VulkanManager::Create();
  if (!manager) {
    GTEST_SKIP() << "Vulkan with D3D11 interop is not available.";
  }

  void* proc = manager->GetInstanceProcAddress(manager->GetInstance(),
                                               "vkEnumeratePhysicalDevices");
  EXPECT_NE(proc, nullptr);

  void* bad_proc = manager->GetInstanceProcAddress(manager->GetInstance(),
                                                   "vkNonExistentFunction");
  EXPECT_EQ(bad_proc, nullptr);
}

// Destroying the manager must clean up the device and instance without
// crashing.
TEST(VulkanManagerTest, DestructionOrder) {
  auto manager = VulkanManager::Create();
  if (!manager) {
    GTEST_SKIP() << "Vulkan with D3D11 interop is not available.";
  }

  manager.reset();
}

}  // namespace testing
}  // namespace flutter
