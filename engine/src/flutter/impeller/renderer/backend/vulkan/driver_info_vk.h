// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_DRIVER_INFO_VK_H_
#define FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_DRIVER_INFO_VK_H_

#include <optional>
#include <string>

#include "flutter/common/vulkan_driver_info.h"
#include "impeller/base/version.h"
#include "impeller/renderer/backend/vulkan/vk.h"

namespace impeller {

using AdrenoGPU = flutter::AdrenoGPU;
using MaliGPU = flutter::MaliGPU;
using PowerVRGPU = flutter::PowerVRGPU;
using VendorVK = flutter::VendorVK;
using DeviceTypeVK = flutter::DeviceTypeVK;

using flutter::GetAdrenoVersion;
using flutter::GetMaliVersion;
using flutter::GetPowerVRVersion;
using flutter::kPixel10DeviceID;
using flutter::kPixel10MinDriverVersion;

//------------------------------------------------------------------------------
/// @brief      Gets information about the Vulkan driver. Override some driver
///             predicates for testing.
///
///             All getters on this object will return valid values if a dynamic
///             lookup of driver info could be performed cleanly.
///
class DriverInfoVK {
 public:
  explicit DriverInfoVK(const vk::PhysicalDevice& device);

  ~DriverInfoVK();

  DriverInfoVK(const DriverInfoVK&) = delete;

  DriverInfoVK& operator=(const DriverInfoVK&) = delete;

  //----------------------------------------------------------------------------
  /// @brief      Gets the Vulkan API version. Should be at or above Vulkan 1.1
  ///             which is the Impeller baseline.
  ///
  /// @return     The Vulkan API version.
  ///
  Version GetAPIVersion() const;

  //----------------------------------------------------------------------------
  /// @brief      Gets the vendor of the Vulkan implementation. This is a broad
  ///             check and covers multiple driver versions and platforms.
  ///
  /// @return     The vendor.
  ///
  VendorVK GetVendor() const;

  //----------------------------------------------------------------------------
  /// @brief      Gets the device type. This may be used to determine if the
  ///             implementation is a CPU implementation like SwiftShader.
  ///
  /// @return     The device type.
  ///
  DeviceTypeVK GetDeviceType() const;

  //----------------------------------------------------------------------------
  /// @brief      Get the self-reported name of the graphics driver. For
  ///             example, "SwiftShader Device (Subzero)" for SwiftShader on
  ///             Android.
  ///
  /// @return     The driver name.
  ///
  const std::string& GetDriverName() const;

  //----------------------------------------------------------------------------
  /// @brief      Dumps the current driver information to the log.
  ///
  void DumpToLog() const;

  //----------------------------------------------------------------------------
  /// @brief      Determines if the driver represents an emulator. There isn't a
  ///             definitive way to tell if a driver is an emulator so talk
  ///             results with a grain of salt. Look into the implementation to
  ///             figure out the anthology of checks used to make the
  ///             determination.
  ///
  /// @return     True if emulator, False otherwise.
  ///
  bool IsEmulator() const;

  //----------------------------------------------------------------------------
  /// @brief      Returns true if the driver is known to have critical issues
  ///             and will never be enabled with Impeller/Vulkan.
  ///
  /// @return     True if the driver is on the permanent blocklist.
  ///
  bool IsKnownBadDriver() const;

  //----------------------------------------------------------------------------
  /// @brief      Returns Arm Mali GPU info if this device is a Mali GPU,
  ///             otherwise std::nullopt.
  ///
  const std::optional<MaliGPU>& GetMaliGPUInfo() const;

  //----------------------------------------------------------------------------
  /// @brief      Returns Qualcomm Adreno GPU info if this device is an Adreno
  ///             GPU, otherwise std::nullopt.
  ///
  const std::optional<AdrenoGPU>& GetAdrenoGPUInfo() const;

  //----------------------------------------------------------------------------
  /// @brief      Returns Imagination PowerVR GPU info if this device is a
  ///             PowerVR GPU, otherwise std::nullopt.
  ///
  const std::optional<PowerVRGPU>& GetPowerVRGPUInfo() const;

 private:
  flutter::VulkanDriverInfo driver_info_;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_DRIVER_INFO_VK_H_
