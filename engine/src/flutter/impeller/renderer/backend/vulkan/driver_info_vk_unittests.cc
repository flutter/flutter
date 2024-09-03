// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/playground/playground_test.h"
#include "impeller/renderer/backend/vulkan/context_vk.h"
#include "impeller/renderer/backend/vulkan/driver_info_vk.h"
#include "impeller/renderer/backend/vulkan/surface_context_vk.h"
#include "impeller/renderer/backend/vulkan/test/mock_vulkan.h"

namespace impeller::testing {

using DriverInfoVKTest = PlaygroundTest;
INSTANTIATE_VULKAN_PLAYGROUND_SUITE(DriverInfoVKTest);

TEST_P(DriverInfoVKTest, CanQueryDriverInfo) {
  ASSERT_TRUE(GetContext());
  const auto& driver_info =
      SurfaceContextVK::Cast(*GetContext()).GetParent()->GetDriverInfo();
  ASSERT_NE(driver_info, nullptr);
  // 1.1 is the base Impeller version. The driver can't be lower than that.
  ASSERT_TRUE(driver_info->GetAPIVersion().IsAtLeast(Version{1, 1, 0}));
  ASSERT_NE(driver_info->GetVendor(), VendorVK::kUnknown);
  ASSERT_NE(driver_info->GetDeviceType(), DeviceTypeVK::kUnknown);
  ASSERT_NE(driver_info->GetDriverName(), "");
  EXPECT_FALSE(driver_info->IsKnownBadDriver());
}

TEST_P(DriverInfoVKTest, CanDumpToLog) {
  ASSERT_TRUE(GetContext());
  const auto& driver_info =
      SurfaceContextVK::Cast(*GetContext()).GetParent()->GetDriverInfo();
  ASSERT_NE(driver_info, nullptr);
  fml::testing::LogCapture log;
  driver_info->DumpToLog();
  EXPECT_TRUE(log.str().find("Driver Information") != std::string::npos);
}

TEST(DriverInfoVKTest, DisabledDevices) {
  std::string name = "Adreno (TM) 630";
  auto const context = MockVulkanContextBuilder()
                           .SetPhysicalPropertiesCallback(
                               [&name](VkPhysicalDevice device,
                                       VkPhysicalDeviceProperties* prop) {
                                 prop->vendorID = 0x168C;  // Qualcomm
                                 name.copy(prop->deviceName, name.size());
                                 prop->deviceType =
                                     VK_PHYSICAL_DEVICE_TYPE_INTEGRATED_GPU;
                               })
                           .Build();

  EXPECT_TRUE(context->GetDriverInfo()->IsKnownBadDriver());
}

}  // namespace impeller::testing
