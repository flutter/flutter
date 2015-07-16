// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/memory/scoped_ptr.h"
#include "gpu/config/gpu_blacklist.h"
#include "gpu/config/gpu_control_list_jsons.h"
#include "gpu/config/gpu_feature_type.h"
#include "gpu/config/gpu_info.h"
#include "testing/gtest/include/gtest/gtest.h"

const char kOsVersion[] = "10.6.4";

namespace gpu {

class GpuBlacklistTest : public testing::Test {
 public:
  GpuBlacklistTest() { }

  ~GpuBlacklistTest() override {}

  const GPUInfo& gpu_info() const {
    return gpu_info_;
  }

  void RunFeatureTest(
      const std::string feature_name, GpuFeatureType feature_type) {
    const std::string json =
        "{\n"
        "  \"name\": \"gpu blacklist\",\n"
        "  \"version\": \"0.1\",\n"
        "  \"entries\": [\n"
        "    {\n"
        "      \"id\": 1,\n"
        "      \"os\": {\n"
        "        \"type\": \"macosx\"\n"
        "      },\n"
        "      \"vendor_id\": \"0x10de\",\n"
        "      \"device_id\": [\"0x0640\"],\n"
        "      \"features\": [\n"
        "        \"" +
        feature_name +
        "\"\n"
        "      ]\n"
        "    }\n"
        "  ]\n"
        "}";

    scoped_ptr<GpuBlacklist> blacklist(GpuBlacklist::Create());
    EXPECT_TRUE(blacklist->LoadList(json, GpuBlacklist::kAllOs));
    std::set<int> type = blacklist->MakeDecision(
        GpuBlacklist::kOsMacosx, kOsVersion, gpu_info());
    EXPECT_EQ(1u, type.size());
    EXPECT_EQ(1u, type.count(feature_type));
  }

 protected:
  void SetUp() override {
    gpu_info_.gpu.vendor_id = 0x10de;
    gpu_info_.gpu.device_id = 0x0640;
    gpu_info_.driver_vendor = "NVIDIA";
    gpu_info_.driver_version = "1.6.18";
    gpu_info_.driver_date = "7-14-2009";
    gpu_info_.machine_model_name = "MacBookPro";
    gpu_info_.machine_model_version = "7.1";
    gpu_info_.gl_vendor = "NVIDIA Corporation";
    gpu_info_.gl_renderer = "NVIDIA GeForce GT 120 OpenGL Engine";
  }

  void TearDown() override {}

 private:
  GPUInfo gpu_info_;
};

TEST_F(GpuBlacklistTest, CurrentBlacklistValidation) {
  scoped_ptr<GpuBlacklist> blacklist(GpuBlacklist::Create());
  EXPECT_TRUE(blacklist->LoadList(
      kSoftwareRenderingListJson, GpuBlacklist::kAllOs));
}

#define GPU_BLACKLIST_FEATURE_TEST(test_name, feature_name, feature_type) \
TEST_F(GpuBlacklistTest, test_name) {                                     \
  RunFeatureTest(feature_name, feature_type);                             \
}

GPU_BLACKLIST_FEATURE_TEST(Accelerated2DCanvas,
                           "accelerated_2d_canvas",
                           GPU_FEATURE_TYPE_ACCELERATED_2D_CANVAS)

GPU_BLACKLIST_FEATURE_TEST(GpuCompositing,
                           "gpu_compositing",
                           GPU_FEATURE_TYPE_GPU_COMPOSITING)

GPU_BLACKLIST_FEATURE_TEST(WebGL,
                           "webgl",
                           GPU_FEATURE_TYPE_WEBGL)

GPU_BLACKLIST_FEATURE_TEST(Flash3D,
                           "flash_3d",
                           GPU_FEATURE_TYPE_FLASH3D)

GPU_BLACKLIST_FEATURE_TEST(FlashStage3D,
                           "flash_stage3d",
                           GPU_FEATURE_TYPE_FLASH_STAGE3D)

GPU_BLACKLIST_FEATURE_TEST(FlashStage3DBaseline,
                           "flash_stage3d_baseline",
                           GPU_FEATURE_TYPE_FLASH_STAGE3D_BASELINE)

GPU_BLACKLIST_FEATURE_TEST(AcceleratedVideoDecode,
                           "accelerated_video_decode",
                           GPU_FEATURE_TYPE_ACCELERATED_VIDEO_DECODE)

GPU_BLACKLIST_FEATURE_TEST(AcceleratedVideoEncode,
                           "accelerated_video_encode",
                           GPU_FEATURE_TYPE_ACCELERATED_VIDEO_ENCODE)

GPU_BLACKLIST_FEATURE_TEST(PanelFitting,
                           "panel_fitting",
                           GPU_FEATURE_TYPE_PANEL_FITTING)

GPU_BLACKLIST_FEATURE_TEST(GpuRasterization,
                           "gpu_rasterization",
                           GPU_FEATURE_TYPE_GPU_RASTERIZATION)

}  // namespace gpu
