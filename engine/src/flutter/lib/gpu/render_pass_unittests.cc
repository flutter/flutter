// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/gpu/render_pass.h"

#include "gtest/gtest.h"

#include "fml/memory/ref_ptr.h"

namespace flutter::gpu {
namespace {

// Regression test for https://github.com/flutter/flutter/issues/188712:
// SetDepthWriteEnable must honor its argument. It previously ignored the
// argument and always enabled depth writes, so disabling depth writes (for
// example to keep overlapping translucent draws from self-occluding) had no
// effect.
TEST(FlutterGpuRenderPassTest, SetDepthWriteEnableHonorsArgument) {
  auto render_pass = fml::MakeRefCounted<RenderPass>();

  InternalFlutterGpu_RenderPass_SetDepthWriteEnable(render_pass.get(), true);
  EXPECT_TRUE(render_pass->GetDepthAttachmentDescriptor().depth_write_enabled);

  InternalFlutterGpu_RenderPass_SetDepthWriteEnable(render_pass.get(), false);
  EXPECT_FALSE(render_pass->GetDepthAttachmentDescriptor().depth_write_enabled);
}

}  // namespace
}  // namespace flutter::gpu
