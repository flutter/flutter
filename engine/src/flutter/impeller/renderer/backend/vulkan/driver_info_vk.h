// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_DRIVER_INFO_VK_H_
#define FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_DRIVER_INFO_VK_H_

#include "impeller/base/version.h"
#include "impeller/renderer/backend/vulkan/vk.h"

namespace impeller {

// https://en.wikipedia.org/wiki/Adreno
enum class AdrenoGPU {
  // Unknown GPU, likely newer model.
  kUnknown,
  // X
  kAdrenoX185,
  kAdrenoX145,
  // 700s
  kAdreno750,
  kAdreno740,
  kAdreno735,
  kAdreno732,
  kAdreno730,
  kAdreno725,
  kAdreno720,
  kAdreno710,
  kAdreno702,
  // 600s
  kAdreno695,
  kAdreno690,
  kAdreno685,
  kAdreno680,
  kAdreno675,
  kAdreno663,
  kAdreno660,
  kAdreno650,
  kAdreno644,
  kAdreno643L,
  kAdreno642,
  kAdreno642L,
  // The 640 is the first GPU inside an Android device with upgradable drivers.
  // Anything before this point exhibiting broken behavior is broken forever.
  kAdreno640,
  kAdreno630,
  kAdreno620,
  kAdreno619,
  kAdreno619L,
  kAdreno618,
  kAdreno616,
  kAdreno615,
  kAdreno613,
  kAdreno612,
  kAdreno610,
  kAdreno608,
  kAdreno605,
  // 500s
  kAdreno540,
  kAdreno530,
  kAdreno512,
  kAdreno510,
  kAdreno509,
  kAdreno508,
  kAdreno506,
  kAdreno505,
  kAdreno504,
  // I don't think the 400 series will ever run Vulkan, but if some show up we
  // can add them here.
};

// https://en.wikipedia.org/wiki/Mali_(processor)
enum class MaliGPU {
  kUnknown,
  // 5th Gen
  kG925,
  kG725,
  kG625,
  kG720,
  kG620,

  // Valhall
  // Note: there is an Immortalis-G715 a Mali-G715
  kG715,
  kG615,
  kG710,
  kG610,
  kG510,
  kG310,
  kG78,
  kG68,
  kG77,
  kG57,

  // Bifrost
  kG76,
  kG72,
  kG52,
  kG71,
  kG51,
  kG31,

  // These might be Vulkan 1.0 Only.
  kT880,
  kT860,
  kT830,
  kT820,
  kT760,
};

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
  kHuawei,
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

// visible for testing.
AdrenoGPU GetAdrenoVersion(std::string_view version);

// visible for testing.
MaliGPU GetMaliVersion(std::string_view version);

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

  //----------------------------------------------------------------------------
  /// @brief      Dumps the current driver info to the log.
  ///
  void DumpToLog() const;

  //----------------------------------------------------------------------------
  /// @brief      Determines if the driver represents an emulator. There is no
  ///             definitive way to tell if a driver is an emulator and drivers
  ///             don't self identify as emulators. So take this information
  ///             with a pinch of salt.
  ///
  /// @return     True if emulator, False otherwise.
  ///
  bool IsEmulator() const;

  //----------------------------------------------------------------------------
  /// @brief      Determines if the driver has been tested and determined to be
  ///             non-functional.
  ///
  ///             If true, context setup should fail such that the device falls
  ///             back to OpenGLES.
  ///
  /// @return     True if non-functional device, False otherwiise.
  ///
  bool IsKnownBadDriver() const;

 private:
  bool is_valid_ = false;
  Version api_version_;
  VendorVK vendor_ = VendorVK::kUnknown;
  DeviceTypeVK type_ = DeviceTypeVK::kUnknown;
  // If the VendorVK is  VendorVK::kQualcomm, this will be populated with the
  // identified Adreno GPU.
  std::optional<AdrenoGPU> adreno_gpu_ = std::nullopt;
  std::optional<MaliGPU> mali_gpu_ = std::nullopt;
  std::string driver_name_;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_DRIVER_INFO_VK_H_
