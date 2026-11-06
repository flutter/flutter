// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_COMMON_VULKAN_DRIVER_INFO_H_
#define FLUTTER_COMMON_VULKAN_DRIVER_INFO_H_

#include <array>
#include <cstdint>
#include <optional>
#include <sstream>
#include <string>
#include <string_view>
#include <unordered_map>
#include <utility>

#include "flutter/fml/logging.h"

namespace flutter {

// https://en.wikipedia.org/wiki/Adreno
// Ordered from oldest to newest matching driver_info_vk.h.
enum class AdrenoGPU {
  // 500s
  kAdreno504,
  kAdreno505,
  kAdreno506,
  kAdreno508,
  kAdreno509,
  kAdreno510,
  kAdreno512,
  kAdreno530,
  kAdreno540,

  // 600s
  kAdreno605,
  kAdreno608,
  kAdreno610,
  kAdreno612,
  kAdreno613,
  kAdreno615,
  kAdreno616,
  kAdreno618,
  kAdreno619L,
  kAdreno619,
  kAdreno620,
  kAdreno630,
  kAdreno640,
  kAdreno642L,
  kAdreno642,
  kAdreno643L,
  kAdreno644,
  kAdreno650,
  kAdreno660,
  kAdreno663,
  kAdreno675,
  kAdreno680,
  kAdreno685,
  kAdreno690,
  kAdreno695,

  // 700s
  kAdreno702,
  kAdreno710,
  kAdreno720,
  kAdreno725,
  kAdreno730,
  kAdreno732,
  kAdreno735,
  kAdreno740,
  kAdreno750,
  // X Series
  kAdrenoX145,
  kAdrenoX185,

  // 800s
  kAdreno830,

  // Unknown GPU, likely newer model.
  kUnknown,
};

// https://en.wikipedia.org/wiki/Mali_(GPU)
// Ordered from oldest to newest.
enum class MaliGPU {
  // Utgard
  kT400,
  kT450,
  kT470,

  // Midgard
  kT604,
  kT622,
  kT624,
  kT628,
  kT658,
  kT678,
  kT720,
  kT760,
  kT820,
  kT830,
  kT860,
  kT880,

  // Bifrost
  // 1st Gen
  kG31,
  kG51,
  kG71,
  // 2nd Gen
  kG52,
  kG72,
  // 3rd Gen
  kG76,

  // Valhall
  // 1st Gen
  kG57,
  kG77,
  // 2nd Gen
  kG68,
  kG78,
  // 3rd Gen
  kG310,
  kG510,
  kG610,
  kG710,
  // 4th Gen
  kG615,
  kG715,

  // 5th Gen
  kG620,
  kG720,
  kG625,
  kG725,
  kG925,

  // Unknown GPU, possibly hinged on vendor string.
  kUnknown,
};

// https://en.wikipedia.org/wiki/PowerVR
enum class PowerVRGPU {
  kUnknown,
  kRogue,
  kAXE,
  kAXM,
  kAXT,
  kBXE,
  kBXM,
  kBXS,
  kBXT,
  kCXM,
  kCXT,
  kDXT,
};

enum class VendorVK {
  kUnknown,
  kAMD,
  kImgTec,
  kPowerVR = kImgTec,
  kNvidia,
  kArm,
  kARM = kArm,
  kQualcomm,
  kIntel,
  // Includes SwiftShader CPU rendering.
  kGoogle,
  // Runs over Metal via MoltenVK.
  kApple,
  // Maleoon GPUs.
  kHuawei,
  // Xclipse GPUs.
  kSamsung,
  // Includes the LLVM Pipe CPU implementation.
  kMesa,
};

enum class DeviceTypeVK {
  kOther,
  kUnknown = kOther,
  kIntegratedGPU,
  kDiscreteGPU,
  kVirtualGPU,
  kCPU,
};

// PCI / Khronos Vulkan Vendor IDs:
// https://www.pcilookup.com/ and VkVendorId
constexpr uint32_t kVulkanVendorIDAMD = 0x1002;
constexpr uint32_t kVulkanVendorIDAMD2 = 0x1022;
constexpr uint32_t kVulkanVendorIDImgTec = 0x1010;
constexpr uint32_t kVulkanVendorIDApple = 0x106B;
constexpr uint32_t kVulkanVendorIDNvidia = 0x10DE;
constexpr uint32_t kVulkanVendorIDArm = 0x13B5;
constexpr uint32_t kVulkanVendorIDSamsung = 0x144D;
constexpr uint32_t kVulkanVendorIDQualcommPCI1 = 0x168C;
constexpr uint32_t kVulkanVendorIDQualcommPCI2 = 0x17CB;
constexpr uint32_t kVulkanVendorIDQualcommPCI3 = 0x1969;
constexpr uint32_t kVulkanVendorIDHuawei = 0x19E5;
constexpr uint32_t kVulkanVendorIDGoogle = 0x1AE0;
constexpr uint32_t kVulkanVendorIDQualcomm = 0x5143;
constexpr uint32_t kVulkanVendorIDIntel = 0x8086;
constexpr uint32_t kVulkanVendorIDMesa = 0x10005;

// VkPhysicalDeviceType numeric values from <vulkan/vulkan_core.h>:
constexpr uint32_t kVkPhysicalDeviceTypeOther = 0;
constexpr uint32_t kVkPhysicalDeviceTypeIntegratedGpu = 1;
constexpr uint32_t kVkPhysicalDeviceTypeDiscreteGpu = 2;
constexpr uint32_t kVkPhysicalDeviceTypeVirtualGpu = 3;
constexpr uint32_t kVkPhysicalDeviceTypeCpu = 4;

// Vulkan API version bit shifts and masks per VK_API_VERSION_MAJOR / MINOR /
// PATCH:
constexpr uint32_t kVkApiVersionMajorShift = 22;
constexpr uint32_t kVkApiVersionMajorMask = 0x7FU;
constexpr uint32_t kVkApiVersionMinorShift = 12;
constexpr uint32_t kVkApiVersionMinorMask = 0x3FFU;
constexpr uint32_t kVkApiVersionPatchMask = 0xFFFU;

// Minimum Vulkan 1.3 minor version required on Samsung Xclipse GPUs:
constexpr uint32_t kSamsungMinVulkanMajorVersion = 1;
constexpr uint32_t kSamsungMinVulkanMinorVersion = 3;

// Pixel 10 device ID and minimum non-blocklisted PowerVR driver version:
// https://github.com/flutter/flutter/issues/177378
constexpr uint32_t kPixel10DeviceID = 0x71061212;
constexpr uint32_t kPixel10MinDriverVersion = 6794074;

// Prefix lengths used when parsing GPU device names:
constexpr size_t kMaliPrefixLength = 5;     // strlen("Mali-")
constexpr size_t kAdrenoPrefixLength = 12;  // strlen("Adreno (TM) ")

struct VulkanDriverVersion {
  uint32_t major = 0;
  uint32_t minor = 0;
  uint32_t patch = 0;

  constexpr VulkanDriverVersion() = default;
  constexpr VulkanDriverVersion(uint32_t maj, uint32_t min, uint32_t pat)
      : major(maj), minor(min), patch(pat) {}

  static constexpr VulkanDriverVersion FromVkVersion(uint32_t raw_version) {
    return VulkanDriverVersion(
        (raw_version >> kVkApiVersionMajorShift) & kVkApiVersionMajorMask,
        (raw_version >> kVkApiVersionMinorShift) & kVkApiVersionMinorMask,
        raw_version & kVkApiVersionPatchMask);
  }

  constexpr bool IsAtLeast(uint32_t min_major,
                           uint32_t min_minor = 0,
                           uint32_t min_patch = 0) const {
    if (major != min_major) {
      return major > min_major;
    }
    if (minor != min_minor) {
      return minor > min_minor;
    }
    return patch >= min_patch;
  }
};

constexpr VendorVK IdentifyVendor(uint32_t vendor) {
  switch (vendor) {
    case kVulkanVendorIDAMD:
    case kVulkanVendorIDAMD2:
      return VendorVK::kAMD;
    case kVulkanVendorIDImgTec:
      return VendorVK::kImgTec;
    case kVulkanVendorIDApple:
      return VendorVK::kApple;
    case kVulkanVendorIDNvidia:
      return VendorVK::kNvidia;
    case kVulkanVendorIDArm:
      return VendorVK::kArm;
    case kVulkanVendorIDGoogle:
      return VendorVK::kGoogle;
    case kVulkanVendorIDQualcommPCI1:
    case kVulkanVendorIDQualcommPCI2:
    case kVulkanVendorIDQualcommPCI3:
    case kVulkanVendorIDQualcomm:
      return VendorVK::kQualcomm;
    case kVulkanVendorIDIntel:
      return VendorVK::kIntel;
    case kVulkanVendorIDHuawei:
      return VendorVK::kHuawei;
    case kVulkanVendorIDSamsung:
      return VendorVK::kSamsung;
    case kVulkanVendorIDMesa:
      return VendorVK::kMesa;
    default:
      return VendorVK::kUnknown;
  }
}

constexpr const char* VendorToString(VendorVK vendor) {
  switch (vendor) {
    case VendorVK::kUnknown:
      return "Unknown";
    case VendorVK::kAMD:
      return "AMD";
    case VendorVK::kImgTec:
      return "ImgTec";
    case VendorVK::kNvidia:
      return "Nvidia";
    case VendorVK::kArm:
      return "Arm";
    case VendorVK::kQualcomm:
      return "Qualcomm";
    case VendorVK::kIntel:
      return "Intel";
    case VendorVK::kGoogle:
      return "Google (Shader)";
    case VendorVK::kApple:
      return "Apple";
    case VendorVK::kHuawei:
      return "Huawei";
    case VendorVK::kSamsung:
      return "Samsung";
    case VendorVK::kMesa:
      return "Mesa";
  }
  FML_UNREACHABLE();
}

constexpr const char* DeviceTypeToString(DeviceTypeVK type) {
  switch (type) {
    case DeviceTypeVK::kOther:
      return "Other";
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

constexpr DeviceTypeVK ToDeviceTypeVK(uint32_t raw_device_type) {
  switch (raw_device_type) {
    case kVkPhysicalDeviceTypeOther:
      return DeviceTypeVK::kOther;
    case kVkPhysicalDeviceTypeIntegratedGpu:
      return DeviceTypeVK::kIntegratedGPU;
    case kVkPhysicalDeviceTypeDiscreteGpu:
      return DeviceTypeVK::kDiscreteGPU;
    case kVkPhysicalDeviceTypeVirtualGpu:
      return DeviceTypeVK::kVirtualGPU;
    case kVkPhysicalDeviceTypeCpu:
      return DeviceTypeVK::kCPU;
    default:
      return DeviceTypeVK::kOther;
  }
}

inline AdrenoGPU GetAdrenoVersion(std::string_view version) {
  static const std::unordered_map<std::string_view, AdrenoGPU> kAdrenoVersions =
      {
          // 500s
          {"504", AdrenoGPU::kAdreno504},
          {"505", AdrenoGPU::kAdreno505},
          {"506", AdrenoGPU::kAdreno506},
          {"508", AdrenoGPU::kAdreno508},
          {"509", AdrenoGPU::kAdreno509},
          {"510", AdrenoGPU::kAdreno510},
          {"512", AdrenoGPU::kAdreno512},
          {"530", AdrenoGPU::kAdreno530},
          {"540", AdrenoGPU::kAdreno540},

          // 600s
          {"605", AdrenoGPU::kAdreno605},
          {"608", AdrenoGPU::kAdreno608},
          {"610", AdrenoGPU::kAdreno610},
          {"612", AdrenoGPU::kAdreno612},
          {"613", AdrenoGPU::kAdreno613},
          {"615", AdrenoGPU::kAdreno615},
          {"616", AdrenoGPU::kAdreno616},
          {"618", AdrenoGPU::kAdreno618},
          {"619L", AdrenoGPU::kAdreno619L},
          {"619", AdrenoGPU::kAdreno619},
          {"620", AdrenoGPU::kAdreno620},
          {"630", AdrenoGPU::kAdreno630},
          {"640", AdrenoGPU::kAdreno640},
          {"642L", AdrenoGPU::kAdreno642L},
          {"642", AdrenoGPU::kAdreno642},
          {"643L", AdrenoGPU::kAdreno643L},
          {"644", AdrenoGPU::kAdreno644},
          {"650", AdrenoGPU::kAdreno650},
          {"660", AdrenoGPU::kAdreno660},
          {"663", AdrenoGPU::kAdreno663},
          {"675", AdrenoGPU::kAdreno675},
          {"680", AdrenoGPU::kAdreno680},
          {"685", AdrenoGPU::kAdreno685},
          {"690", AdrenoGPU::kAdreno690},
          {"695", AdrenoGPU::kAdreno695},

          // 700s
          {"702", AdrenoGPU::kAdreno702},
          {"710", AdrenoGPU::kAdreno710},
          {"720", AdrenoGPU::kAdreno720},
          {"725", AdrenoGPU::kAdreno725},
          {"730", AdrenoGPU::kAdreno730},
          {"721", AdrenoGPU::kAdreno732},
          {"732", AdrenoGPU::kAdreno732},
          {"735", AdrenoGPU::kAdreno735},
          {"740", AdrenoGPU::kAdreno740},
          {"750", AdrenoGPU::kAdreno750},
          {"X145", AdrenoGPU::kAdrenoX145},
          {"X185", AdrenoGPU::kAdrenoX185},

          // 800s
          {"830", AdrenoGPU::kAdreno830},
  };

  /// The format that Adreno names follow is "Adreno (TM) VERSION".
  auto paren_pos = version.find("Adreno (TM) ");
  if (paren_pos == std::string_view::npos) {
    return AdrenoGPU::kUnknown;
  }
  auto version_str = version.substr(paren_pos + kAdrenoPrefixLength);
  // Look until the end of the string or the next space.
  auto end_pos = version_str.find(' ');
  if (end_pos != std::string_view::npos) {
    version_str = version_str.substr(0, end_pos);
  }

  const auto result = kAdrenoVersions.find(version_str);
  if (result == kAdrenoVersions.end()) {
    return AdrenoGPU::kUnknown;
  }
  return result->second;
}

inline MaliGPU GetMaliVersion(std::string_view version) {
  static const std::unordered_map<std::string_view, MaliGPU> kMaliVersions = {
      // Utgard
      {"T400", MaliGPU::kT400},
      {"T450", MaliGPU::kT450},
      {"T470", MaliGPU::kT470},

      // Midgard
      {"T604", MaliGPU::kT604},
      {"T622", MaliGPU::kT622},
      {"T624", MaliGPU::kT624},
      {"T628", MaliGPU::kT628},
      {"T658", MaliGPU::kT658},
      {"T678", MaliGPU::kT678},
      {"T720", MaliGPU::kT720},
      {"T760", MaliGPU::kT760},
      {"T820", MaliGPU::kT820},
      {"T830", MaliGPU::kT830},
      {"T860", MaliGPU::kT860},
      {"T880", MaliGPU::kT880},

      // Bifrost
      {"G31", MaliGPU::kG31},
      {"G51", MaliGPU::kG51},
      {"G71", MaliGPU::kG71},
      {"G52", MaliGPU::kG52},
      {"G72", MaliGPU::kG72},
      {"G76", MaliGPU::kG76},

      // Valhall
      {"G57", MaliGPU::kG57},
      {"G77", MaliGPU::kG77},
      {"G68", MaliGPU::kG68},
      {"G78", MaliGPU::kG78},
      {"G310", MaliGPU::kG310},
      {"G510", MaliGPU::kG510},
      {"G610", MaliGPU::kG610},
      {"G710", MaliGPU::kG710},
      {"G615", MaliGPU::kG615},
      {"G715", MaliGPU::kG715},

      // 5th Gen
      {"G620", MaliGPU::kG620},
      {"G720", MaliGPU::kG720},
      {"G625", MaliGPU::kG625},
      {"G725", MaliGPU::kG725},
      {"G925", MaliGPU::kG925},
  };

  // Mali drivers usually have names like "Mali-G78" or "Mali-G715-Immortalis
  // MC10".
  auto dash_pos = version.find("Mali-");
  if (dash_pos == std::string_view::npos) {
    return MaliGPU::kUnknown;
  }
  auto version_str_with_suffix = version.substr(dash_pos + kMaliPrefixLength);
  // Remove any trailing parts like "-Immortalis MC10" or " MC4".
  auto space_pos = version_str_with_suffix.find(' ');
  if (space_pos != std::string_view::npos) {
    version_str_with_suffix = version_str_with_suffix.substr(0, space_pos);
  }
  auto hyphen_pos = version_str_with_suffix.find('-');
  if (hyphen_pos != std::string_view::npos) {
    version_str_with_suffix = version_str_with_suffix.substr(0, hyphen_pos);
  }

  const auto result = kMaliVersions.find(version_str_with_suffix);
  if (result == kMaliVersions.end()) {
    return MaliGPU::kUnknown;
  }
  return result->second;
}

inline PowerVRGPU GetPowerVRVersion(std::string_view version) {
  constexpr std::array<std::pair<std::string_view, PowerVRGPU>, 10>
      kGpuSeriesMap = {{
          {"AXE", PowerVRGPU::kAXE},
          {"AXM", PowerVRGPU::kAXM},
          {"AXT", PowerVRGPU::kAXT},
          {"BXE", PowerVRGPU::kBXE},
          {"BXM", PowerVRGPU::kBXM},
          {"BXS", PowerVRGPU::kBXS},
          {"BXT", PowerVRGPU::kBXT},
          {"CXM", PowerVRGPU::kCXM},
          {"CXT", PowerVRGPU::kCXT},
          {"DXT", PowerVRGPU::kDXT},
      }};
  for (const auto& entry : kGpuSeriesMap) {
    if (version.find(entry.first) != std::string_view::npos) {
      return entry.second;
    }
  }
  return PowerVRGPU::kUnknown;
}

class VulkanDriverInfo {
 public:
  VulkanDriverInfo(uint32_t vendor_id,
                   uint32_t device_id,
                   uint32_t api_version,
                   uint32_t driver_version,
                   uint32_t device_type,
                   std::string_view device_name)
      : api_version_(VulkanDriverVersion::FromVkVersion(api_version)),
        vendor_(IdentifyVendor(vendor_id)),
        device_type_(ToDeviceTypeVK(device_type)),
        driver_name_(device_name),
        driver_version_(driver_version),
        device_id_(device_id) {
    switch (vendor_) {
      case VendorVK::kQualcomm:
        adreno_gpu_ = GetAdrenoVersion(driver_name_);
        break;
      case VendorVK::kArm:
        mali_gpu_ = GetMaliVersion(driver_name_);
        break;
      case VendorVK::kImgTec:
        powervr_gpu_ = GetPowerVRVersion(driver_name_);
        break;
      default:
        break;
    }
  }

  template <typename PhysicalDeviceProperties>
  explicit VulkanDriverInfo(const PhysicalDeviceProperties& props)
      : VulkanDriverInfo(props.vendorID,
                         props.deviceID,
                         props.apiVersion,
                         props.driverVersion,
                         static_cast<uint32_t>(props.deviceType),
                         props.deviceName) {}

  VulkanDriverVersion GetAPIVersion() const { return api_version_; }

  VendorVK GetVendor() const { return vendor_; }

  DeviceTypeVK GetDeviceType() const { return device_type_; }

  const std::string& GetDriverName() const { return driver_name_; }

  uint32_t GetDriverVersion() const { return driver_version_; }

  uint32_t GetDeviceID() const { return device_id_; }

  bool IsEmulator() const {
    // Google SwiftShader.
    if (device_type_ == DeviceTypeVK::kCPU && vendor_ == VendorVK::kGoogle &&
        driver_name_.find("SwiftShader") != std::string::npos) {
      return true;
    }
    return false;
  }

  bool IsKnownBadDriver() const {
    if (adreno_gpu_.has_value()) {
      AdrenoGPU adreno = adreno_gpu_.value();
      // Identify Adreno 630/640/650 Stability & Performance Bug, check logic in
      // lines below.
      if (adreno <= AdrenoGPU::kAdreno650) {
        return true;
      }
    }

    // Wait for tests to be added before enabling Huawei Maleoon Impeller
    // Vulkan. See also: https://github.com/flutter/flutter/issues/128121
    if (vendor_ == VendorVK::kHuawei) {
      return true;
    }

    // Samsung Xclipse drivers with Vulkan < 1.3 have driver bugs.
    // https://github.com/flutter/flutter/issues/161122
    if (vendor_ == VendorVK::kSamsung) {
      return !api_version_.IsAtLeast(kSamsungMinVulkanMajorVersion,
                                     kSamsungMinVulkanMinorVersion);
    }

    if (vendor_ == VendorVK::kImgTec) {
      if (powervr_gpu_.has_value()) {
        // Older PowerVR GPUs have critically broken Vulkan drivers.
        // We enable CXT and newer, with an additional check for Pixel 10.
        if (powervr_gpu_.value() < PowerVRGPU::kCXT) {
          return true;
        }
        if (device_id_ == kPixel10DeviceID &&
            driver_version_ < kPixel10MinDriverVersion) {
          return true;
        }
        return false;
      }
      return true;
    }

    // PowerVR rogue platform with Unknown vendor id.
    if (vendor_ == VendorVK::kUnknown &&
        driver_name_.find("PowerVR Rogue") != std::string::npos) {
      return true;
    }

    return false;
  }

  const std::optional<MaliGPU>& GetMaliGPUInfo() const { return mali_gpu_; }

  const std::optional<AdrenoGPU>& GetAdrenoGPUInfo() const {
    return adreno_gpu_;
  }

  const std::optional<PowerVRGPU>& GetPowerVRGPUInfo() const {
    return powervr_gpu_;
  }

  void DumpToLog() const {
    std::stringstream stream;
    stream << "--- Driver Information ---" << std::endl;
    stream << "  Driver Name: " << driver_name_ << std::endl;
    stream << "  API Version: " << api_version_.major << "."
           << api_version_.minor << "." << api_version_.patch << std::endl;
    stream << "  Vendor: " << VendorToString(vendor_) << std::endl;
    stream << "  Device Type: " << DeviceTypeToString(device_type_)
           << std::endl;
    stream << "  Is Emulator: " << (IsEmulator() ? "Yes" : "No");
    FML_LOG(IMPORTANT) << stream.str();
  }

 private:
  VulkanDriverVersion api_version_;
  VendorVK vendor_ = VendorVK::kUnknown;
  DeviceTypeVK device_type_ = DeviceTypeVK::kOther;
  std::optional<MaliGPU> mali_gpu_;
  std::optional<AdrenoGPU> adreno_gpu_;
  std::optional<PowerVRGPU> powervr_gpu_;
  std::string driver_name_;
  uint32_t driver_version_ = 0;
  uint32_t device_id_ = 0;
};

template <typename PhysicalDeviceProperties>
bool IsKnownBadVulkanDriver(const PhysicalDeviceProperties& props) {
  return VulkanDriverInfo(props).IsKnownBadDriver();
}

}  // namespace flutter

#endif  // FLUTTER_COMMON_VULKAN_DRIVER_INFO_H_
