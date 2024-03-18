// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/driver_info_vk.h"

namespace impeller {

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

}  // namespace impeller
