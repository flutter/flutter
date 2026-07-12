// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gtest/gtest.h"

#include "flutter/vulkan/vulkan_native_surface_linux.h"
#include "third_party/skia/include/core/SkSize.h"

namespace vulkan {
namespace testing {

// Test X11 constructor with null display marks surface as invalid.
TEST(VulkanNativeSurfaceLinuxTest, X11NullDisplayIsInvalid) {
  VulkanNativeSurfaceLinux surface(static_cast<Display*>(nullptr), 0, 800, 600);
  EXPECT_FALSE(surface.IsValid());
  EXPECT_EQ(surface.GetSize(), SkISize::Make(0, 0));
  EXPECT_EQ(surface.GetWindowingSystem(), LinuxWindowingSystem::kX11);
}

// Test X11 constructor with null display but valid window is still invalid.
TEST(VulkanNativeSurfaceLinuxTest, X11NullDisplayValidWindowIsInvalid) {
  VulkanNativeSurfaceLinux surface(static_cast<Display*>(nullptr), 12345, 800,
                                   600);
  EXPECT_FALSE(surface.IsValid());
  EXPECT_EQ(surface.GetSize(), SkISize::Make(0, 0));
}

// Test Wayland constructor with null display marks surface as invalid.
TEST(VulkanNativeSurfaceLinuxTest, WaylandNullDisplayIsInvalid) {
  VulkanNativeSurfaceLinux surface(static_cast<wl_display*>(nullptr),
                                   static_cast<wl_surface*>(nullptr), 800, 600);
  EXPECT_FALSE(surface.IsValid());
  EXPECT_EQ(surface.GetSize(), SkISize::Make(0, 0));
  EXPECT_EQ(surface.GetWindowingSystem(), LinuxWindowingSystem::kWayland);
}

// Test that GetExtensionName returns the correct extension for X11.
TEST(VulkanNativeSurfaceLinuxTest, X11ExtensionName) {
  VulkanNativeSurfaceLinux surface(static_cast<Display*>(nullptr), 0, 100, 100);
  EXPECT_STREQ(surface.GetExtensionName(), VK_KHR_XLIB_SURFACE_EXTENSION_NAME);
}

// Test that GetExtensionName returns the correct extension for Wayland.
TEST(VulkanNativeSurfaceLinuxTest, WaylandExtensionName) {
  VulkanNativeSurfaceLinux surface(static_cast<wl_display*>(nullptr),
                                   static_cast<wl_surface*>(nullptr), 100, 100);
  EXPECT_STREQ(surface.GetExtensionName(),
               VK_KHR_WAYLAND_SURFACE_EXTENSION_NAME);
}

// Test that zero dimensions mark the surface as invalid.
TEST(VulkanNativeSurfaceLinuxTest, ZeroDimensionsInvalid) {
  VulkanNativeSurfaceLinux surface(static_cast<Display*>(nullptr), 0, 0, 0);
  EXPECT_FALSE(surface.IsValid());
  EXPECT_EQ(surface.GetSize(), SkISize::Make(0, 0));
}

// Test that negative dimensions mark the surface as invalid.
TEST(VulkanNativeSurfaceLinuxTest, NegativeDimensionsInvalid) {
  VulkanNativeSurfaceLinux surface(static_cast<Display*>(nullptr), 0, -100,
                                   600);
  EXPECT_FALSE(surface.IsValid());
  EXPECT_EQ(surface.GetSize(), SkISize::Make(0, 0));
}

}  // namespace testing
}  // namespace vulkan
