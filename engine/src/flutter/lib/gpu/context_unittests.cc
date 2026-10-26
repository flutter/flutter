// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/gpu/context.h"

#include <memory>

#include "flutter/lib/gpu/formats.h"
#include "fml/memory/ref_ptr.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"
#include "impeller/renderer/testing/mocks.h"

namespace flutter::gpu {
namespace {

using ::testing::Return;
using ::testing::ReturnRef;

// The default color format reported to Dart for a context whose capabilities
// report `impeller_format`.
FlutterGPUPixelFormat DefaultColorFormatFor(
    impeller::PixelFormat impeller_format) {
  auto capabilities = std::make_shared<impeller::testing::MockCapabilities>();
  EXPECT_CALL(*capabilities, GetDefaultColorFormat())
      .WillRepeatedly(Return(impeller_format));
  const std::shared_ptr<const impeller::Capabilities> const_capabilities =
      capabilities;

  auto impeller_context =
      std::make_shared<impeller::testing::MockImpellerContext>();
  EXPECT_CALL(*impeller_context, GetCapabilities())
      .WillRepeatedly(ReturnRef(const_capabilities));

  auto context = fml::MakeRefCounted<Context>(impeller_context);
  return static_cast<FlutterGPUPixelFormat>(
      InternalFlutterGpu_Context_GetDefaultColorFormat(context.get()));
}

// With wide gamut enabled, Metal reports an extended-range default color
// format that Flutter GPU does not expose. defaultColorFormat must still be a
// format Dart can create textures with.
TEST(FlutterGpuContextTest, DefaultColorFormatFallsBackFromExtendedRange) {
  EXPECT_EQ(DefaultColorFormatFor(impeller::PixelFormat::kB10G10R10A10XR),
            FlutterGPUPixelFormat::kB8G8R8A8UNormInt);
  EXPECT_EQ(DefaultColorFormatFor(impeller::PixelFormat::kB10G10R10XR),
            FlutterGPUPixelFormat::kB8G8R8A8UNormInt);
  EXPECT_EQ(DefaultColorFormatFor(impeller::PixelFormat::kB10G10R10XRSRGB),
            FlutterGPUPixelFormat::kB8G8R8A8UNormIntSRGB);
}

TEST(FlutterGpuContextTest, DefaultColorFormatPassesThroughExposedFormats) {
  EXPECT_EQ(DefaultColorFormatFor(impeller::PixelFormat::kB8G8R8A8UNormInt),
            FlutterGPUPixelFormat::kB8G8R8A8UNormInt);
  EXPECT_EQ(DefaultColorFormatFor(impeller::PixelFormat::kR8G8B8A8UNormInt),
            FlutterGPUPixelFormat::kR8G8B8A8UNormInt);
}

}  // namespace
}  // namespace flutter::gpu
