// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/common/vulkan_driver_info.h"

#include "gtest/gtest.h"

namespace flutter::testing {

namespace {

// Minimal VkPhysicalDeviceProperties-compatible struct for unit testing without
// requiring <vulkan/vulkan.h>.
struct FakeVkPhysicalDeviceProperties {
  uint32_t apiVersion = 0;
  uint32_t driverVersion = 0;
  uint32_t vendorID = 0;
  uint32_t deviceID = 0;
  uint32_t deviceType = kVkPhysicalDeviceTypeIntegratedGpu;
  const char* deviceName = "";
};

constexpr uint32_t MakeVkApiVersion(uint32_t major,
                                    uint32_t minor,
                                    uint32_t patch) {
  return (major << kVkApiVersionMajorShift) |
         (minor << kVkApiVersionMinorShift) | patch;
}

}  // namespace

TEST(VulkanDriverInfoTest, CanIdentifyAdrenoGPUs) {
  EXPECT_EQ(GetAdrenoVersion("Adreno (TM) 630"), AdrenoGPU::kAdreno630);
  EXPECT_EQ(GetAdrenoVersion("Adreno (TM) 650"), AdrenoGPU::kAdreno650);
  EXPECT_EQ(GetAdrenoVersion("Adreno (TM) 660"), AdrenoGPU::kAdreno660);
  EXPECT_EQ(GetAdrenoVersion("Adreno (TM) 740"), AdrenoGPU::kAdreno740);
  EXPECT_EQ(GetAdrenoVersion("Adreno (TM) 830"), AdrenoGPU::kAdreno830);
  EXPECT_EQ(GetAdrenoVersion("Mali-G78"), AdrenoGPU::kUnknown);
}

TEST(VulkanDriverInfoTest, CanIdentifyMaliGPUs) {
  EXPECT_EQ(GetMaliVersion("Mali-G78"), MaliGPU::kG78);
  EXPECT_EQ(GetMaliVersion("Mali-G715-Immortalis MC10"), MaliGPU::kG715);
  EXPECT_EQ(GetMaliVersion("Mali-T880"), MaliGPU::kT880);
  EXPECT_EQ(GetMaliVersion("Adreno (TM) 630"), MaliGPU::kUnknown);
}

TEST(VulkanDriverInfoTest, CanIdentifyPowerVRGPUs) {
  EXPECT_EQ(GetPowerVRVersion("PowerVR Rogue GE8320"), PowerVRGPU::kUnknown);
  EXPECT_EQ(GetPowerVRVersion("PowerVR B-Series BXM-8-256"), PowerVRGPU::kBXM);
  EXPECT_EQ(GetPowerVRVersion("PowerVR C-Series CXT-48-1536"),
            PowerVRGPU::kCXT);
  EXPECT_EQ(GetPowerVRVersion("PowerVR D-Series DXT-48-1536"),
            PowerVRGPU::kDXT);
  EXPECT_EQ(GetPowerVRVersion("PowerVR DXT 123"), PowerVRGPU::kDXT);
  EXPECT_EQ(GetPowerVRVersion("Mali-G78"), PowerVRGPU::kUnknown);
}

TEST(VulkanDriverInfoTest, BlocksAdreno650AndOlder) {
  FakeVkPhysicalDeviceProperties adreno_650{
      .apiVersion = MakeVkApiVersion(1, 1, 0),
      .vendorID = kVulkanVendorIDQualcomm,
      .deviceName = "Adreno (TM) 650",
  };
  EXPECT_TRUE(IsKnownBadVulkanDriver(adreno_650));

  FakeVkPhysicalDeviceProperties adreno_660{
      .apiVersion = MakeVkApiVersion(1, 1, 0),
      .vendorID = kVulkanVendorIDQualcomm,
      .deviceName = "Adreno (TM) 660",
  };
  EXPECT_FALSE(IsKnownBadVulkanDriver(adreno_660));
}

TEST(VulkanDriverInfoTest, BlocksHuaweiAndOldSamsungDrivers) {
  FakeVkPhysicalDeviceProperties huawei{
      .apiVersion = MakeVkApiVersion(1, 3, 0),
      .vendorID = kVulkanVendorIDHuawei,
      .deviceName = "Maleoon 910",
  };
  EXPECT_TRUE(IsKnownBadVulkanDriver(huawei));

  FakeVkPhysicalDeviceProperties samsung_vk11{
      .apiVersion = MakeVkApiVersion(1, 1, 0),
      .vendorID = kVulkanVendorIDSamsung,
      .deviceName = "Samsung Xclipse 920",
  };
  EXPECT_TRUE(IsKnownBadVulkanDriver(samsung_vk11));

  FakeVkPhysicalDeviceProperties samsung_vk13{
      .apiVersion = MakeVkApiVersion(1, 3, 0),
      .vendorID = kVulkanVendorIDSamsung,
      .deviceName = "Samsung Xclipse 940",
  };
  EXPECT_FALSE(IsKnownBadVulkanDriver(samsung_vk13));
}

TEST(VulkanDriverInfoTest, BlocksPowerVRAndPixel10OldDrivers) {
  FakeVkPhysicalDeviceProperties powervr_bxm{
      .apiVersion = MakeVkApiVersion(1, 3, 0),
      .vendorID = kVulkanVendorIDImgTec,
      .deviceName = "PowerVR B-Series BXM-8-256",
  };
  EXPECT_TRUE(IsKnownBadVulkanDriver(powervr_bxm));

  FakeVkPhysicalDeviceProperties pixel10_old{
      .apiVersion = MakeVkApiVersion(1, 3, 0),
      .driverVersion = kPixel10MinDriverVersion - 1,
      .vendorID = kVulkanVendorIDImgTec,
      .deviceID = kPixel10DeviceID,
      .deviceName = "PowerVR D-Series DXT-48-1536",
  };
  EXPECT_TRUE(IsKnownBadVulkanDriver(pixel10_old));

  FakeVkPhysicalDeviceProperties pixel10_new{
      .apiVersion = MakeVkApiVersion(1, 3, 0),
      .driverVersion = kPixel10MinDriverVersion,
      .vendorID = kVulkanVendorIDImgTec,
      .deviceID = kPixel10DeviceID,
      .deviceName = "PowerVR D-Series DXT-48-1536",
  };
  EXPECT_FALSE(IsKnownBadVulkanDriver(pixel10_new));
}

TEST(VulkanDriverInfoTest, IdentifiesSwiftShaderEmulator) {
  FakeVkPhysicalDeviceProperties swiftshader{
      .apiVersion = MakeVkApiVersion(1, 1, 0),
      .vendorID = kVulkanVendorIDGoogle,
      .deviceType = kVkPhysicalDeviceTypeCpu,
      .deviceName = "SwiftShader Device (Subzero)",
  };
  VulkanDriverInfo info(swiftshader);
  EXPECT_TRUE(info.IsEmulator());
}

}  // namespace flutter::testing
