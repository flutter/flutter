// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/testing.h"
#include "impeller/renderer/capabilities.h"

#include "gtest/gtest.h"

namespace impeller {
namespace testing {

#define CAPABILITY_TEST(name, default_value)                                 \
  TEST(CapabilitiesTest, name) {                                             \
    auto defaults = CapabilitiesBuilder().Build();                           \
    ASSERT_EQ(defaults->name(), default_value);                              \
    auto opposite = CapabilitiesBuilder().Set##name(!default_value).Build(); \
    ASSERT_EQ(opposite->name(), !default_value);                             \
  }

CAPABILITY_TEST(SupportsOffscreenMSAA, false);
CAPABILITY_TEST(SupportsSSBO, false);
CAPABILITY_TEST(SupportsBufferToTextureBlits, false);
CAPABILITY_TEST(SupportsTextureToTextureBlits, false);
CAPABILITY_TEST(SupportsFramebufferFetch, false);
CAPABILITY_TEST(SupportsCompute, false);
CAPABILITY_TEST(SupportsComputeSubgroups, false);
CAPABILITY_TEST(SupportsReadFromResolve, false);
CAPABILITY_TEST(SupportsDecalSamplerAddressMode, false);
CAPABILITY_TEST(SupportsDeviceTransientTextures, false);

TEST(CapabilitiesTest, DefaultColorFormat) {
  auto defaults = CapabilitiesBuilder().Build();
  ASSERT_EQ(defaults->GetDefaultColorFormat(), PixelFormat::kUnknown);
  auto mutated = CapabilitiesBuilder()
                     .SetDefaultColorFormat(PixelFormat::kB10G10R10A10XR)
                     .Build();
  ASSERT_EQ(mutated->GetDefaultColorFormat(), PixelFormat::kB10G10R10A10XR);
}

TEST(CapabilitiesTest, DefaultStencilFormat) {
  auto defaults = CapabilitiesBuilder().Build();
  ASSERT_EQ(defaults->GetDefaultStencilFormat(), PixelFormat::kUnknown);
  auto mutated = CapabilitiesBuilder()
                     .SetDefaultStencilFormat(PixelFormat::kS8UInt)
                     .Build();
  ASSERT_EQ(mutated->GetDefaultStencilFormat(), PixelFormat::kS8UInt);
}

TEST(CapabilitiesTest, DefaultDepthStencilFormat) {
  auto defaults = CapabilitiesBuilder().Build();
  ASSERT_EQ(defaults->GetDefaultDepthStencilFormat(), PixelFormat::kUnknown);
  auto mutated = CapabilitiesBuilder()
                     .SetDefaultDepthStencilFormat(PixelFormat::kD32FloatS8UInt)
                     .Build();
  ASSERT_EQ(mutated->GetDefaultDepthStencilFormat(),
            PixelFormat::kD32FloatS8UInt);
}

}  // namespace testing
}  // namespace impeller
