// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_VULKAN_ELIGIBILITY_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_VULKAN_ELIGIBILITY_H_

#include <string>

namespace flutter::android {

/// @brief Reason why an Android device is ineligible for Impeller Vulkan
/// autoselection.
enum class VulkanIneligibleReason {
  kNone,
  kEmulator,
  kHuawei,
  kOldMediaTek,
  kBadSoc,
};

/// @brief System properties read from the Android device to evaluate Impeller
/// Vulkan autoselection eligibility. Injectable for unit tests.
struct DeviceProperties {
  std::string hardware;
  std::string product_model;
  std::string client_id_base;
  std::string product_board;
  /// Value of `ro.vendor.build.version.sdk`, or `api_level` when unset.
  int vendor_api_level = 0;
  bool has_mediatek_platform = false;
  bool has_qemu_pipe = false;
};

/// @brief Reads the system properties used for Impeller Vulkan eligibility
/// evaluation from the running Android device.
DeviceProperties ReadDeviceProperties(int api_level);

/// @brief Evaluates whether the given device properties are eligible for
/// Impeller Vulkan autoselection according to upstream rules.
VulkanIneligibleReason CheckVulkanEligibility(
    const DeviceProperties& properties);

/// @brief Returns a human-readable string describing the ineligibility reason.
const char* VulkanIneligibleReasonToString(VulkanIneligibleReason reason);

}  // namespace flutter::android

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_VULKAN_ELIGIBILITY_H_
