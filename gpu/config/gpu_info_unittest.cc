// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/config/gpu_info.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace gpu {

// Test that an empty GPUInfo has valid members
TEST(GPUInfoBasicTest, EmptyGPUInfo) {
  GPUInfo gpu_info;
  EXPECT_EQ(gpu_info.initialization_time.ToInternalValue(), 0);
  EXPECT_EQ(gpu_info.gpu.vendor_id, 0u);
  EXPECT_EQ(gpu_info.gpu.device_id, 0u);
  EXPECT_EQ(gpu_info.secondary_gpus.size(), 0u);
  EXPECT_EQ(gpu_info.driver_vendor, "");
  EXPECT_EQ(gpu_info.driver_version, "");
  EXPECT_EQ(gpu_info.driver_date, "");
  EXPECT_EQ(gpu_info.pixel_shader_version, "");
  EXPECT_EQ(gpu_info.vertex_shader_version, "");
  EXPECT_EQ(gpu_info.gl_version, "");
  EXPECT_EQ(gpu_info.gl_vendor, "");
  EXPECT_EQ(gpu_info.gl_renderer, "");
  EXPECT_EQ(gpu_info.gl_extensions, "");
  EXPECT_EQ(gpu_info.gl_ws_vendor, "");
  EXPECT_EQ(gpu_info.gl_ws_version, "");
  EXPECT_EQ(gpu_info.gl_ws_extensions, "");
  EXPECT_EQ(gpu_info.can_lose_context, false);
  EXPECT_EQ(gpu_info.basic_info_state, kCollectInfoNone);
  EXPECT_EQ(gpu_info.context_info_state, kCollectInfoNone);
#if defined(OS_WIN)
  EXPECT_EQ(gpu_info.dx_diagnostics_info_state, kCollectInfoNone);
#endif
  EXPECT_EQ(gpu_info.video_encode_accelerator_supported_profiles.size(), 0u);
}

}  // namespace gpu

