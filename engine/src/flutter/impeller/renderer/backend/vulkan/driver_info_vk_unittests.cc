// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/playground/playground_test.h"
#include "impeller/renderer/backend/vulkan/context_vk.h"
#include "impeller/renderer/backend/vulkan/surface_context_vk.h"

namespace impeller::testing {

using DriverInfoVKTest = PlaygroundTest;
INSTANTIATE_VULKAN_PLAYGROUND_SUITE(DriverInfoVKTest);

TEST_P(DriverInfoVKTest, CanQueryDriverInfo) {
  ASSERT_TRUE(GetContext());
  const auto& driver_info =
      SurfaceContextVK::Cast(*GetContext()).GetParent().GetDriverInfo();
  ASSERT_NE(driver_info, nullptr);
  // 1.1 is the base Impeller version. The driver can't be lower than that.
  ASSERT_TRUE(driver_info->GetAPIVersion().IsAtLeast(Version{1, 1, 0}));
  ASSERT_NE(driver_info->GetVendor(), VendorVK::kUnknown);
  ASSERT_NE(driver_info->GetDeviceType(), DeviceTypeVK::kUnknown);
  ASSERT_NE(driver_info->GetDriverName(), "");
}

}  // namespace impeller::testing
