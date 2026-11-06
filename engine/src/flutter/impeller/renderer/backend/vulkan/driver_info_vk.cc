// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/driver_info_vk.h"

namespace impeller {

DriverInfoVK::DriverInfoVK(const vk::PhysicalDevice& device)
    : driver_info_(device.getProperties()) {}

DriverInfoVK::~DriverInfoVK() = default;

Version DriverInfoVK::GetAPIVersion() const {
  const auto api = driver_info_.GetAPIVersion();
  return Version{api.major, api.minor, api.patch};
}

VendorVK DriverInfoVK::GetVendor() const {
  return driver_info_.GetVendor();
}

DeviceTypeVK DriverInfoVK::GetDeviceType() const {
  return driver_info_.GetDeviceType();
}

const std::string& DriverInfoVK::GetDriverName() const {
  return driver_info_.GetDriverName();
}

void DriverInfoVK::DumpToLog() const {
  driver_info_.DumpToLog();
}

bool DriverInfoVK::IsEmulator() const {
  return driver_info_.IsEmulator();
}

bool DriverInfoVK::IsKnownBadDriver() const {
  return driver_info_.IsKnownBadDriver();
}

const std::optional<MaliGPU>& DriverInfoVK::GetMaliGPUInfo() const {
  return driver_info_.GetMaliGPUInfo();
}

const std::optional<AdrenoGPU>& DriverInfoVK::GetAdrenoGPUInfo() const {
  return driver_info_.GetAdrenoGPUInfo();
}

const std::optional<PowerVRGPU>& DriverInfoVK::GetPowerVRGPUInfo() const {
  return driver_info_.GetPowerVRGPUInfo();
}

}  // namespace impeller
