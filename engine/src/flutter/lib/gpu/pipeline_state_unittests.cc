// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/gpu/pipeline_state.h"

#include "gtest/gtest.h"
#include "impeller/core/formats.h"
#include "impeller/renderer/pipeline_descriptor.h"
#include "third_party/abseil-cpp/absl/hash/hash.h"

namespace flutter::gpu {
namespace {

TEST(FlutterGpuPipelineStateTest, ComparesOnlyUsedAttachments) {
  PipelineState a;
  a.color_attachment_count = 1;
  PipelineState b = a;
  EXPECT_EQ(a, b);
  EXPECT_EQ(absl::HashOf(a), absl::HashOf(b));

  // Beyond the used attachments.
  b.colors[1].blending_enabled = true;
  EXPECT_EQ(a, b);
  EXPECT_EQ(absl::HashOf(a), absl::HashOf(b));

  b.colors[0].blending_enabled = true;
  EXPECT_FALSE(a == b);
  EXPECT_NE(absl::HashOf(a), absl::HashOf(b));
}

TEST(FlutterGpuPipelineStateTest, ToDescriptorKeepsTheState) {
  PipelineState state;
  state.cull_mode = impeller::CullMode::kBackFace;
  state.sample_count = impeller::SampleCount::kCount4;
  state.depth_format = impeller::PixelFormat::kD32FloatS8UInt;
  state.depth.depth_write_enabled = true;
  state.color_attachment_count = 2;
  state.colors[0].format = impeller::PixelFormat::kR8G8B8A8UNormInt;
  state.colors[1].format = impeller::PixelFormat::kUnknown;

  const impeller::PipelineDescriptor descriptor = state.ToDescriptor();
  EXPECT_EQ(descriptor.GetCullMode(), impeller::CullMode::kBackFace);
  EXPECT_EQ(descriptor.GetSampleCount(), impeller::SampleCount::kCount4);
  EXPECT_EQ(descriptor.GetDepthPixelFormat(),
            impeller::PixelFormat::kD32FloatS8UInt);
  ASSERT_TRUE(descriptor.GetDepthStencilAttachmentDescriptor().has_value());
  EXPECT_TRUE(
      descriptor.GetDepthStencilAttachmentDescriptor()->depth_write_enabled);
  EXPECT_EQ(descriptor.GetColorAttachmentDescriptors().size(), 1u);
  EXPECT_EQ(descriptor.GetStencilPixelFormat(),
            impeller::PixelFormat::kUnknown);
}

}  // namespace
}  // namespace flutter::gpu
