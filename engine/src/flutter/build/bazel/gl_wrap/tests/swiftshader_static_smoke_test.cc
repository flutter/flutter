// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Smoke test for SwiftShader's static library from the wrapped GN build: the
// driver linked into the binary, entered through vkGetInstanceProcAddr as
// //flutter/shell/gpu's Vulkan surface suite does.

#include <string>

#include "gtest/gtest.h"

// After gtest (see gl_backends_smoke_test.cc).
#include <vulkan/vulkan.h>

namespace {

TEST(SwiftShaderStaticSmokeTest, EnumeratesItsDevice) {
  auto create_instance = reinterpret_cast<PFN_vkCreateInstance>(
      vkGetInstanceProcAddr(nullptr, "vkCreateInstance"));
  ASSERT_NE(create_instance, nullptr);
  VkApplicationInfo application_info = {};
  application_info.sType = VK_STRUCTURE_TYPE_APPLICATION_INFO;
  application_info.pApplicationName = "swiftshader_static_smoke_test";
  application_info.apiVersion = VK_API_VERSION_1_1;
  VkInstanceCreateInfo create_info = {};
  create_info.sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
  create_info.pApplicationInfo = &application_info;
  VkInstance instance = VK_NULL_HANDLE;
  ASSERT_EQ(create_instance(&create_info, nullptr, &instance), VK_SUCCESS);

  auto enumerate_physical_devices =
      reinterpret_cast<PFN_vkEnumeratePhysicalDevices>(
          vkGetInstanceProcAddr(instance, "vkEnumeratePhysicalDevices"));
  auto get_physical_device_properties =
      reinterpret_cast<PFN_vkGetPhysicalDeviceProperties>(
          vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceProperties"));
  auto destroy_instance = reinterpret_cast<PFN_vkDestroyInstance>(
      vkGetInstanceProcAddr(instance, "vkDestroyInstance"));
  ASSERT_NE(enumerate_physical_devices, nullptr);
  ASSERT_NE(get_physical_device_properties, nullptr);
  ASSERT_NE(destroy_instance, nullptr);

  uint32_t device_count = 0;
  ASSERT_EQ(enumerate_physical_devices(instance, &device_count, nullptr),
            VK_SUCCESS);
  ASSERT_EQ(device_count, 1u);
  VkPhysicalDevice device = VK_NULL_HANDLE;
  ASSERT_EQ(enumerate_physical_devices(instance, &device_count, &device),
            VK_SUCCESS);
  VkPhysicalDeviceProperties properties = {};
  get_physical_device_properties(device, &properties);
  EXPECT_NE(std::string(properties.deviceName).find("SwiftShader"),
            std::string::npos)
      << properties.deviceName;
  destroy_instance(instance, nullptr);
}

}  // namespace
