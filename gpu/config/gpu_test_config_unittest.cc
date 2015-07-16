// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/config/gpu_info.h"
#include "gpu/config/gpu_test_config.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace gpu {

class GPUTestConfigTest : public testing::Test {
 public:
  GPUTestConfigTest() { }

  ~GPUTestConfigTest() override {}

 protected:
  void SetUp() override {}

  void TearDown() override {}
};

TEST_F(GPUTestConfigTest, EmptyValues) {
  GPUTestConfig config;
  EXPECT_EQ(GPUTestConfig::kOsUnknown, config.os());
  EXPECT_EQ(0u, config.gpu_vendor().size());
  EXPECT_EQ(0u, config.gpu_device_id());
  EXPECT_EQ(GPUTestConfig::kBuildTypeUnknown, config.build_type());
}

TEST_F(GPUTestConfigTest, SetGPUInfo) {
  GPUInfo gpu_info;
  gpu_info.gpu.vendor_id = 0x10de;
  gpu_info.gpu.device_id = 0x0640;
  GPUTestBotConfig config;
  EXPECT_TRUE(config.SetGPUInfo(gpu_info));
  EXPECT_EQ(1u, config.gpu_vendor().size());
  EXPECT_EQ(gpu_info.gpu.vendor_id, config.gpu_vendor()[0]);
  EXPECT_EQ(gpu_info.gpu.device_id, config.gpu_device_id());

  gpu_info.gpu.vendor_id = 0x8086;
  gpu_info.gpu.device_id = 0x0046;
  EXPECT_TRUE(config.SetGPUInfo(gpu_info));
  EXPECT_EQ(1u, config.gpu_vendor().size());
  EXPECT_EQ(gpu_info.gpu.vendor_id, config.gpu_vendor()[0]);
  EXPECT_EQ(gpu_info.gpu.device_id, config.gpu_device_id());
}

TEST_F(GPUTestConfigTest, IsValid) {
  {
    GPUTestConfig config;
    config.set_gpu_device_id(0x0640);
    EXPECT_FALSE(config.IsValid());
    config.AddGPUVendor(0x10de);
    EXPECT_TRUE(config.IsValid());
  }

  {
    GPUTestBotConfig config;
    config.set_build_type(GPUTestConfig::kBuildTypeRelease);
    config.set_os(GPUTestConfig::kOsWin7);
    config.set_gpu_device_id(0x0640);
    EXPECT_FALSE(config.IsValid());
    config.AddGPUVendor(0x10de);
    EXPECT_TRUE(config.IsValid());

    config.set_gpu_device_id(0);
    EXPECT_FALSE(config.IsValid());
    config.set_gpu_device_id(0x0640);
    EXPECT_TRUE(config.IsValid());

    config.set_os(GPUTestConfig::kOsWin);
    EXPECT_FALSE(config.IsValid());
    config.set_os(GPUTestConfig::kOsWin7 | GPUTestConfig::kOsWinXP);
    EXPECT_FALSE(config.IsValid());
    config.set_os(GPUTestConfig::kOsWin7);
    EXPECT_TRUE(config.IsValid());

    config.set_build_type(GPUTestConfig::kBuildTypeUnknown);
    EXPECT_FALSE(config.IsValid());
    config.set_build_type(GPUTestConfig::kBuildTypeRelease);
    EXPECT_TRUE(config.IsValid());
  }
}

TEST_F(GPUTestConfigTest, Matches) {
  GPUTestBotConfig config;
  config.set_os(GPUTestConfig::kOsWin7);
  config.set_build_type(GPUTestConfig::kBuildTypeRelease);
  config.AddGPUVendor(0x10de);
  config.set_gpu_device_id(0x0640);
  EXPECT_TRUE(config.IsValid());

  {  // os matching
    GPUTestConfig config2;
    EXPECT_TRUE(config.Matches(config2));
    config2.set_os(GPUTestConfig::kOsWin);
    EXPECT_TRUE(config.Matches(config2));
    config2.set_os(GPUTestConfig::kOsWin7);
    EXPECT_TRUE(config.Matches(config2));
    config2.set_os(GPUTestConfig::kOsMac);
    EXPECT_FALSE(config.Matches(config2));
    config2.set_os(GPUTestConfig::kOsWin7 | GPUTestConfig::kOsLinux);
    EXPECT_TRUE(config.Matches(config2));
  }

  {  // gpu vendor matching
    {
      GPUTestConfig config2;
      config2.AddGPUVendor(0x10de);
      EXPECT_TRUE(config.Matches(config2));
      config2.AddGPUVendor(0x1004);
      EXPECT_TRUE(config.Matches(config2));
    }
    {
      GPUTestConfig config2;
      config2.AddGPUVendor(0x8086);
      EXPECT_FALSE(config.Matches(config2));
    }
  }

  {  // build type matching
    GPUTestConfig config2;
    config2.set_build_type(GPUTestConfig::kBuildTypeRelease);
    EXPECT_TRUE(config.Matches(config2));
    config2.set_build_type(GPUTestConfig::kBuildTypeRelease |
                           GPUTestConfig::kBuildTypeDebug);
    EXPECT_TRUE(config.Matches(config2));
    config2.set_build_type(GPUTestConfig::kBuildTypeDebug);
    EXPECT_FALSE(config.Matches(config2));
  }

  {  // exact matching
    GPUTestConfig config2;
    config2.set_os(GPUTestConfig::kOsWin7);
    config2.set_build_type(GPUTestConfig::kBuildTypeRelease);
    config2.AddGPUVendor(0x10de);
    config2.set_gpu_device_id(0x0640);
    EXPECT_TRUE(config.Matches(config2));
    config2.set_gpu_device_id(0x0641);
    EXPECT_FALSE(config.Matches(config2));
  }
}

TEST_F(GPUTestConfigTest, StringMatches) {
  GPUTestBotConfig config;
  config.set_os(GPUTestConfig::kOsWin7);
  config.set_build_type(GPUTestConfig::kBuildTypeRelease);
  config.AddGPUVendor(0x10de);
  config.set_gpu_device_id(0x0640);
  EXPECT_TRUE(config.IsValid());

  EXPECT_TRUE(config.Matches(std::string()));

  // os matching
  EXPECT_TRUE(config.Matches("WIN"));
  EXPECT_TRUE(config.Matches("WIN7"));
  EXPECT_FALSE(config.Matches("MAC"));
  EXPECT_TRUE(config.Matches("WIN7 LINUX"));

  // gpu vendor matching
  EXPECT_TRUE(config.Matches("NVIDIA"));
  EXPECT_TRUE(config.Matches("NVIDIA AMD"));
  EXPECT_FALSE(config.Matches("INTEL"));

  // build type matching
  EXPECT_TRUE(config.Matches("RELEASE"));
  EXPECT_TRUE(config.Matches("RELEASE DEBUG"));
  EXPECT_FALSE(config.Matches("DEBUG"));

  // exact matching
  EXPECT_TRUE(config.Matches("WIN7 RELEASE NVIDIA 0X0640"));
  EXPECT_FALSE(config.Matches("WIN7 RELEASE NVIDIA 0X0641"));
}

TEST_F(GPUTestConfigTest, OverlapsWith) {
  {  // os
    // win vs win7
    GPUTestConfig config;
    config.set_os(GPUTestConfig::kOsWin);
    GPUTestConfig config2;
    config2.set_os(GPUTestConfig::kOsWin7);
    EXPECT_TRUE(config.OverlapsWith(config2));
    EXPECT_TRUE(config2.OverlapsWith(config));
    // win vs win7+linux
    config2.set_os(GPUTestConfig::kOsWin7 | GPUTestConfig::kOsLinux);
    EXPECT_TRUE(config.OverlapsWith(config2));
    EXPECT_TRUE(config2.OverlapsWith(config));
    // win vs mac
    config2.set_os(GPUTestConfig::kOsMac);
    EXPECT_FALSE(config.OverlapsWith(config2));
    EXPECT_FALSE(config2.OverlapsWith(config));
    // win vs unknown
    config2.set_os(GPUTestConfig::kOsUnknown);
    EXPECT_TRUE(config.OverlapsWith(config2));
    EXPECT_TRUE(config2.OverlapsWith(config));
  }

  {  // gpu vendor
    GPUTestConfig config;
    config.AddGPUVendor(0x10de);
    // nvidia vs unknown
    GPUTestConfig config2;
    EXPECT_TRUE(config.OverlapsWith(config2));
    EXPECT_TRUE(config2.OverlapsWith(config));
    // nvidia vs intel
    config2.AddGPUVendor(0x1086);
    EXPECT_FALSE(config.OverlapsWith(config2));
    EXPECT_FALSE(config2.OverlapsWith(config));
    // nvidia vs nvidia+intel
    config2.AddGPUVendor(0x10de);
    EXPECT_TRUE(config.OverlapsWith(config2));
    EXPECT_TRUE(config2.OverlapsWith(config));
  }

  {  // build type
    // release vs debug
    GPUTestConfig config;
    config.set_build_type(GPUTestConfig::kBuildTypeRelease);
    GPUTestConfig config2;
    config2.set_build_type(GPUTestConfig::kBuildTypeDebug);
    EXPECT_FALSE(config.OverlapsWith(config2));
    EXPECT_FALSE(config2.OverlapsWith(config));
    // release vs release+debug
    config2.set_build_type(GPUTestConfig::kBuildTypeRelease |
                           GPUTestConfig::kBuildTypeDebug);
    EXPECT_TRUE(config.OverlapsWith(config2));
    EXPECT_TRUE(config2.OverlapsWith(config));
    // release vs unknown
    config2.set_build_type(GPUTestConfig::kBuildTypeUnknown);
    EXPECT_TRUE(config.OverlapsWith(config2));
    EXPECT_TRUE(config2.OverlapsWith(config));
  }

  {  // win7 vs nvidia
    GPUTestConfig config;
    config.set_os(GPUTestConfig::kOsWin7);
    GPUTestConfig config2;
    config2.AddGPUVendor(0x10de);
    EXPECT_TRUE(config.OverlapsWith(config2));
    EXPECT_TRUE(config2.OverlapsWith(config));
  }
}

TEST_F(GPUTestConfigTest, LoadCurrentConfig) {
  GPUTestBotConfig config;
  GPUInfo gpu_info;
  gpu_info.gpu.vendor_id = 0x10de;
  gpu_info.gpu.device_id = 0x0640;
  EXPECT_TRUE(config.LoadCurrentConfig(&gpu_info));
  EXPECT_TRUE(config.IsValid());
}

}  // namespace gpu

