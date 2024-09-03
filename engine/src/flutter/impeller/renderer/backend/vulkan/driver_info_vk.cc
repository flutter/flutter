// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/driver_info_vk.h"

#include <iomanip>
#include <sstream>
#include <string_view>

#include "flutter/fml/build_config.h"

namespace impeller {

/// Non functional Vulkan driver, see:
/// https://github.com/flutter/flutter/issues/154103
///
/// Reports "VK_INCOMPLETE" when compiling certain entity shader with
/// vkCreateGraphicsPipelines, which is not a valid return status.
constexpr std::string_view kAdreno630 = "Adreno (TM) 630";

constexpr VendorVK IdentifyVendor(uint32_t vendor) {
  // Check if the vendor has a PCI ID:
  // https://pcisig.com/membership/member-companies
  switch (vendor) {
    case 0x1AE0:
      return VendorVK::kGoogle;
    case 0x168C:
    case 0x17CB:
    case 0x1969:
    case 0x5143:
      return VendorVK::kQualcomm;
    case 0x13B5:
      return VendorVK::kARM;
    case 0x1010:
      return VendorVK::kImgTec;
    case 0x1002:
    case 0x1022:
      return VendorVK::kAMD;
    case 0x10DE:
      return VendorVK::kNvidia;
    case 0x8086:  // :)
      return VendorVK::kIntel;
    case 0x106B:
      return VendorVK::kApple;
    case 0x19E5:
      return VendorVK::kHuawei;
  }
  // Check if the ID is a known Khronos vendor.
  switch (vendor) {
    case VK_VENDOR_ID_MESA:
      return VendorVK::kMesa;
      // There are others but have never been observed. These can be added as
      // needed.
  }
  return VendorVK::kUnknown;
}

constexpr const char* VendorToString(VendorVK vendor) {
  switch (vendor) {
    case VendorVK::kUnknown:
      return "Unknown";
    case VendorVK::kGoogle:
      return "Google";
    case VendorVK::kQualcomm:
      return "Qualcomm";
    case VendorVK::kARM:
      return "ARM";
    case VendorVK::kImgTec:
      return "ImgTec PowerVR";
    case VendorVK::kAMD:
      return "AMD";
    case VendorVK::kNvidia:
      return "Nvidia";
    case VendorVK::kIntel:
      return "Intel";
    case VendorVK::kMesa:
      return "Mesa";
    case VendorVK::kApple:
      return "Apple";
    case VendorVK::kHuawei:
      return "Huawei";
  }
  FML_UNREACHABLE();
}

constexpr const char* DeviceTypeToString(DeviceTypeVK type) {
  switch (type) {
    case DeviceTypeVK::kUnknown:
      return "Unknown";
    case DeviceTypeVK::kIntegratedGPU:
      return "Integrated GPU";
    case DeviceTypeVK::kDiscreteGPU:
      return "Discrete GPU";
    case DeviceTypeVK::kVirtualGPU:
      return "Virtual GPU";
    case DeviceTypeVK::kCPU:
      return "CPU";
  }
  FML_UNREACHABLE();
}

constexpr DeviceTypeVK ToDeviceType(const vk::PhysicalDeviceType& type) {
  switch (type) {
    case vk::PhysicalDeviceType::eOther:
      return DeviceTypeVK::kUnknown;
    case vk::PhysicalDeviceType::eIntegratedGpu:
      return DeviceTypeVK::kIntegratedGPU;
    case vk::PhysicalDeviceType::eDiscreteGpu:
      return DeviceTypeVK::kDiscreteGPU;
    case vk::PhysicalDeviceType::eVirtualGpu:
      return DeviceTypeVK::kVirtualGPU;
    case vk::PhysicalDeviceType::eCpu:
      return DeviceTypeVK::kCPU;
      break;
  }
  return DeviceTypeVK::kUnknown;
}

DriverInfoVK::DriverInfoVK(const vk::PhysicalDevice& device) {
  auto props = device.getProperties();
  api_version_ = Version{VK_API_VERSION_MAJOR(props.apiVersion),
                         VK_API_VERSION_MINOR(props.apiVersion),
                         VK_API_VERSION_PATCH(props.apiVersion)};
  vendor_ = IdentifyVendor(props.vendorID);
  if (vendor_ == VendorVK::kUnknown) {
    FML_LOG(WARNING) << "Unknown GPU Driver Vendor: " << props.vendorID
                     << ". This is not an error.";
  }
  type_ = ToDeviceType(props.deviceType);
  if (props.deviceName.data() != nullptr) {
    driver_name_ = props.deviceName.data();
  }
}

DriverInfoVK::~DriverInfoVK() = default;

const Version& DriverInfoVK::GetAPIVersion() const {
  return api_version_;
}

const VendorVK& DriverInfoVK::GetVendor() const {
  return vendor_;
}

const DeviceTypeVK& DriverInfoVK::GetDeviceType() const {
  return type_;
}

const std::string& DriverInfoVK::GetDriverName() const {
  return driver_name_;
}

void DriverInfoVK::DumpToLog() const {
  std::vector<std::pair<std::string, std::string>> items;
  items.emplace_back("Name", driver_name_);
  items.emplace_back("API Version", api_version_.ToString());
  items.emplace_back("Vendor", VendorToString(vendor_));
  items.emplace_back("Device Type", DeviceTypeToString(type_));
  items.emplace_back("Is Emulator", std::to_string(IsEmulator()));

  size_t padding = 0;

  for (const auto& item : items) {
    padding = std::max(padding, item.first.size());
  }

  padding += 1;

  std::stringstream stream;

  stream << std::endl;

  stream << "--- Driver Information ------------------------------------------";

  stream << std::endl;

  for (const auto& item : items) {
    stream << "| " << std::setw(static_cast<int>(padding)) << item.first
           << std::setw(0) << ": " << item.second << std::endl;
  }

  stream << "-----------------------------------------------------------------";

  FML_LOG(IMPORTANT) << stream.str();
}

bool DriverInfoVK::IsEmulator() const {
#if FML_OS_ANDROID
  // Google SwiftShader on Android.
  if (type_ == DeviceTypeVK::kCPU && vendor_ == VendorVK::kGoogle &&
      driver_name_.find("SwiftShader") != std::string::npos) {
    return true;
  }
#endif  // FML_OS_ANDROID
  return false;
}

bool DriverInfoVK::IsKnownBadDriver() const {
  if (vendor_ == VendorVK::kQualcomm && driver_name_ == kAdreno630) {
    return true;
  }
  return false;
}

}  // namespace impeller
