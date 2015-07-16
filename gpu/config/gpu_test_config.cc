// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/config/gpu_test_config.h"

#include "base/logging.h"
#include "base/sys_info.h"
#include "gpu/config/gpu_info.h"
#include "gpu/config/gpu_info_collector.h"
#include "gpu/config/gpu_test_expectations_parser.h"

#if defined(OS_MACOSX) && !defined(OS_IOS)
#include "base/mac/mac_util.h"
#elif defined(OS_WIN)
#include "base/win/windows_version.h"
#endif

namespace gpu {

namespace {

GPUTestConfig::OS GetCurrentOS() {
#if defined(OS_CHROMEOS)
  return GPUTestConfig::kOsChromeOS;
#elif defined(OS_LINUX) || defined(OS_OPENBSD)
  return GPUTestConfig::kOsLinux;
#elif defined(OS_WIN)
  int32 major_version = 0;
  int32 minor_version = 0;
  int32 bugfix_version = 0;
  base::SysInfo::OperatingSystemVersionNumbers(
      &major_version, &minor_version, &bugfix_version);
  if (major_version == 5)
    return GPUTestConfig::kOsWinXP;
  if (major_version == 6 && minor_version == 0)
    return GPUTestConfig::kOsWinVista;
  if (major_version == 6 && minor_version == 1)
    return GPUTestConfig::kOsWin7;
  if (major_version == 6 && (minor_version == 2 || minor_version == 3))
    return GPUTestConfig::kOsWin8;
#elif defined(OS_MACOSX)

#if defined(OS_IOS)
  return GPUTestConfig::kOsiOS;
#else
  int32 major_version = 0;
  int32 minor_version = 0;
  int32 bugfix_version = 0;
  base::SysInfo::OperatingSystemVersionNumbers(
      &major_version, &minor_version, &bugfix_version);
  if (major_version == 10) {
    switch (minor_version) {
      case 5:
        return GPUTestConfig::kOsMacLeopard;
      case 6:
        return GPUTestConfig::kOsMacSnowLeopard;
      case 7:
        return GPUTestConfig::kOsMacLion;
      case 8:
        return GPUTestConfig::kOsMacMountainLion;
      case 9:
        return GPUTestConfig::kOsMacMavericks;
    }
  }
#endif /* OS_IOS */
#elif defined(OS_ANDROID)
  return GPUTestConfig::kOsAndroid;
#endif
  return GPUTestConfig::kOsUnknown;
}

}  // namespace anonymous

GPUTestConfig::GPUTestConfig()
    : validate_gpu_info_(true),
      os_(kOsUnknown),
      gpu_device_id_(0),
      build_type_(kBuildTypeUnknown) {
}

GPUTestConfig::~GPUTestConfig() {
}

void GPUTestConfig::set_os(int32 os) {
  DCHECK_EQ(0, os & ~(kOsAndroid | kOsWin | kOsMac | kOsLinux | kOsChromeOS));
  os_ = os;
}

void GPUTestConfig::AddGPUVendor(uint32 gpu_vendor) {
  DCHECK_NE(0u, gpu_vendor);
  for (size_t i = 0; i < gpu_vendor_.size(); ++i)
    DCHECK_NE(gpu_vendor_[i], gpu_vendor);
  gpu_vendor_.push_back(gpu_vendor);
}

void GPUTestConfig::set_gpu_device_id(uint32 id) {
  gpu_device_id_ = id;
}

void GPUTestConfig::set_build_type(int32 build_type) {
  DCHECK_EQ(0, build_type & ~(kBuildTypeRelease | kBuildTypeDebug));
  build_type_ = build_type;
}

bool GPUTestConfig::IsValid() const {
  if (!validate_gpu_info_)
    return true;
  if (gpu_device_id_ != 0 && (gpu_vendor_.size() != 1 || gpu_vendor_[0] == 0))
    return false;
  return true;
}

bool GPUTestConfig::OverlapsWith(const GPUTestConfig& config) const {
  DCHECK(IsValid());
  DCHECK(config.IsValid());
  if (config.os_ != kOsUnknown && os_ != kOsUnknown &&
      (os_ & config.os_) == 0)
    return false;
  if (config.gpu_vendor_.size() > 0 && gpu_vendor_.size() > 0) {
    bool shared = false;
    for (size_t i = 0; i < config.gpu_vendor_.size() && !shared; ++i) {
      for (size_t j = 0; j < gpu_vendor_.size(); ++j) {
        if (config.gpu_vendor_[i] == gpu_vendor_[j]) {
          shared = true;
          break;
        }
      }
    }
    if (!shared)
      return false;
  }
  if (config.gpu_device_id_ != 0 && gpu_device_id_ != 0 &&
      gpu_device_id_ != config.gpu_device_id_)
    return false;
  if (config.build_type_ != kBuildTypeUnknown &&
      build_type_ != kBuildTypeUnknown &&
      (build_type_ & config.build_type_) == 0)
    return false;
  return true;
}

void GPUTestConfig::DisableGPUInfoValidation() {
  validate_gpu_info_ = false;
}

void GPUTestConfig::ClearGPUVendor() {
  gpu_vendor_.clear();
}

GPUTestBotConfig::~GPUTestBotConfig() {
}

void GPUTestBotConfig::AddGPUVendor(uint32 gpu_vendor) {
  DCHECK_EQ(0u, GPUTestConfig::gpu_vendor().size());
  GPUTestConfig::AddGPUVendor(gpu_vendor);
}

bool GPUTestBotConfig::SetGPUInfo(const GPUInfo& gpu_info) {
  DCHECK(validate_gpu_info_);
  if (gpu_info.gpu.device_id == 0 || gpu_info.gpu.vendor_id == 0)
    return false;
  ClearGPUVendor();
  AddGPUVendor(gpu_info.gpu.vendor_id);
  set_gpu_device_id(gpu_info.gpu.device_id);
  return true;
}

bool GPUTestBotConfig::IsValid() const {
  switch (os()) {
    case kOsWinXP:
    case kOsWinVista:
    case kOsWin7:
    case kOsWin8:
    case kOsMacLeopard:
    case kOsMacSnowLeopard:
    case kOsMacLion:
    case kOsMacMountainLion:
    case kOsMacMavericks:
    case kOsLinux:
    case kOsChromeOS:
    case kOsAndroid:
      break;
    default:
      return false;
  }
  if (validate_gpu_info_) {
    if (gpu_vendor().size() != 1 || gpu_vendor()[0] == 0)
      return false;
    if (gpu_device_id() == 0)
      return false;
  }
  switch (build_type()) {
    case kBuildTypeRelease:
    case kBuildTypeDebug:
      break;
    default:
      return false;
  }
  return true;
}

bool GPUTestBotConfig::Matches(const GPUTestConfig& config) const {
  DCHECK(IsValid());
  DCHECK(config.IsValid());
  if (config.os() != kOsUnknown && (os() & config.os()) == 0)
    return false;
  if (config.gpu_vendor().size() > 0) {
    bool contained = false;
    for (size_t i = 0; i < config.gpu_vendor().size(); ++i) {
      if (config.gpu_vendor()[i] == gpu_vendor()[0]) {
        contained = true;
        break;
      }
    }
    if (!contained)
      return false;
  }
  if (config.gpu_device_id() != 0 &&
      gpu_device_id() != config.gpu_device_id())
    return false;
  if (config.build_type() != kBuildTypeUnknown &&
      (build_type() & config.build_type()) == 0)
    return false;
  return true;
}

bool GPUTestBotConfig::Matches(const std::string& config_data) const {
  GPUTestExpectationsParser parser;
  GPUTestConfig config;

  if (!parser.ParseConfig(config_data, &config))
    return false;
  return Matches(config);
}

bool GPUTestBotConfig::LoadCurrentConfig(const GPUInfo* gpu_info) {
  bool rt;
  if (gpu_info == NULL) {
    GPUInfo my_gpu_info;
    CollectInfoResult result = CollectGpuID(
        &my_gpu_info.gpu.vendor_id, &my_gpu_info.gpu.device_id);
    if (result != kCollectInfoSuccess) {
      LOG(ERROR) << "Fail to identify GPU";
      DisableGPUInfoValidation();
      rt = true;
    } else {
      rt = SetGPUInfo(my_gpu_info);
    }
  } else {
    rt = SetGPUInfo(*gpu_info);
  }
  set_os(GetCurrentOS());
  if (os() == kOsUnknown) {
    LOG(ERROR) << "Unknown OS";
    rt = false;
  }
#if defined(NDEBUG)
  set_build_type(kBuildTypeRelease);
#else
  set_build_type(kBuildTypeDebug);
#endif
  return rt;
}

// static
bool GPUTestBotConfig::CurrentConfigMatches(const std::string& config_data) {
  GPUTestBotConfig my_config;
  if (!my_config.LoadCurrentConfig(NULL))
    return false;
  return my_config.Matches(config_data);
}

// static
bool GPUTestBotConfig::CurrentConfigMatches(
    const std::vector<std::string>& configs) {
  GPUTestBotConfig my_config;
  if (!my_config.LoadCurrentConfig(NULL))
    return false;
  for (size_t i = 0 ; i < configs.size(); ++i) {
    if (my_config.Matches(configs[i]))
      return true;
  }
  return false;
}

// static
bool GPUTestBotConfig::GpuBlacklistedOnBot() {
#if defined(OS_MACOSX) && !defined(OS_IOS)
  // Blacklist rule #81 disables all Gpu acceleration on Mac < 10.8 bots.
  if (CurrentConfigMatches("MAC VMWARE") && base::mac::IsOSLionOrEarlier()) {
    return true;
  }
#elif defined(OS_WIN)
  // Blacklist rule #79 disables all Gpu acceleration before Windows 7.
  if (base::win::GetVersion() <= base::win::VERSION_VISTA) {
    return true;
  }
#endif
  return false;
}

}  // namespace gpu

