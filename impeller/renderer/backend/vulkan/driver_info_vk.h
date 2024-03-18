// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_DRIVER_INFO_VK_H_
#define FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_DRIVER_INFO_VK_H_

#include "impeller/base/version.h"
#include "impeller/renderer/backend/vulkan/vk.h"

namespace impeller {

enum class VendorVK {
  kUnknown,
  //----------------------------------------------------------------------------
  /// Includes the SwiftShader CPU implementation.
  ///
  kGoogle,
  kQualcomm,
  kARM,
  kImgTec,
  kPowerVR = kImgTec,
  kAMD,
  kNvidia,
  kIntel,
  //----------------------------------------------------------------------------
  /// Includes the LLVM Pipe CPU implementation.
  ///
  kMesa,
  //----------------------------------------------------------------------------
  /// Includes Vulkan on Metal via MoltenVK.
  ///
  kApple,
};

enum class DeviceTypeVK {
  kUnknown,
  //----------------------------------------------------------------------------
  /// The device is an integrated GPU. Typically mobile GPUs.
  ///
  kIntegratedGPU,
  //----------------------------------------------------------------------------
  /// The device is a discrete GPU. Typically desktop GPUs.
  ///
  kDiscreteGPU,
  //----------------------------------------------------------------------------
  /// The device is a GPU in a virtualized environment.
  ///
  kVirtualGPU,
  //----------------------------------------------------------------------------
  /// There is no GPU. Vulkan is implemented on the CPU. This is typically
  /// emulators like SwiftShader and LLVMPipe.
  ///
  kCPU,
};

//------------------------------------------------------------------------------
/// @brief      Get information about the Vulkan driver.
///
/// @warning    Be extremely cautious about the information reported here. This
///             is self-reported information (by the driver) and may be
///             inaccurate and or inconsistent.
///
///             Before gating features behind any of the information reported by
///             the driver, consider alternatives (extensions checks perhaps)
///             and try to get a reviewer buddy to convince you to avoid using
///             this.
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
  const Version& GetAPIVersion() const;

  //----------------------------------------------------------------------------
  /// @brief      Get the vendor of the Vulkan implementation. This is a broad
  ///             check and includes multiple drivers and platforms.
  ///
  /// @return     The vendor.
  ///
  const VendorVK& GetVendor() const;

  //----------------------------------------------------------------------------
  /// @brief      Get the device type. Typical use might be to check if the
  ///             device is a CPU implementation.
  ///
  /// @return     The device type.
  ///
  const DeviceTypeVK& GetDeviceType() const;

  //----------------------------------------------------------------------------
  /// @brief      Get the self-reported name of the graphics driver.
  ///
  /// @return     The driver name.
  ///
  const std::string& GetDriverName() const;

 private:
  bool is_valid_ = false;
  Version api_version_;
  VendorVK vendor_ = VendorVK::kUnknown;
  DeviceTypeVK type_ = DeviceTypeVK::kUnknown;
  std::string driver_name_;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_DRIVER_INFO_VK_H_
