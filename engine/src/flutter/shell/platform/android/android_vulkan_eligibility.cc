// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/android_vulkan_eligibility.h"

#include <cstdlib>
#include <cstring>
#include <string_view>

#include "flutter/fml/build_config.h"

#if FML_OS_ANDROID
#include <sys/system_properties.h>
#include <unistd.h>
#endif

namespace flutter::android {

namespace {

constexpr const char* kAndroidHuawei = "android-huawei";

// Minimum vendor Android API level required to allow Impeller Vulkan
// autoselection on MediaTek platforms (Android 12L / API 32). Older MediaTek
// vendor builds crash when importing AHardwareBuffers.
constexpr int kMinimumAndroidApiLevelForMediaTekVulkan = 32;

constexpr const char* kBadSocs[] = {
    // Most Exynos Series SoC. These are SoCs that crash when using AHB imports.
    "exynos7870",  //
    "exynos7880",  //
    "exynos7872",  //
    "exynos7884",  //
    "exynos7885",  //
    "exynos7904",  //
    // Mongoose line.
    "exynos8890",  //
    "exynos8895",  //
    "exynos9609",  //
    "exynos9610",  //
    "exynos9611",  //
    "exynos9810",  //
    // `exynos9820` and `exynos9825` have graphical errors:
    // https://github.com/flutter/flutter/issues/171992.
    "exynos9820",  //
    "exynos9825",  //
    "rk30sdk"      // https://github.com/flutter/flutter/issues/183510
};

bool IsDeviceEmulator(const DeviceProperties& properties) {
  if (properties.hardware == "goldfish" || properties.hardware == "ranchu" ||
      properties.hardware == "qemu") {
    return true;
  }

  if (properties.product_model.find("gphone") != std::string::npos) {
    return true;
  }

  if (properties.has_qemu_pipe) {
    return true;
  }

  return false;
}

bool IsKnownBadSOC(std::string_view product_board) {
  // TODO(jonahwilliams): if the list gets too long (> 16), convert
  // to a hash map first.
  for (const char* board : kBadSocs) {
    if (product_board == board) {
      return true;
    }
  }
  return false;
}

}  // namespace

DeviceProperties ReadDeviceProperties(int api_level) {
  DeviceProperties props;
  props.vendor_api_level = api_level;

#if FML_OS_ANDROID
  char property[PROP_VALUE_MAX] = {};

  if (__system_property_get("ro.hardware", property) > 0) {
    props.hardware = property;
  }

  if (__system_property_get("ro.product.model", property) > 0) {
    props.product_model = property;
  }

  if (__system_property_get("ro.com.google.clientidbase", property) > 0) {
    props.client_id_base = property;
  }

  if (__system_property_get("ro.product.board", property) > 0) {
    props.product_board = property;
  }

  if (__system_property_get("ro.vendor.build.version.sdk", property) > 0) {
    props.vendor_api_level = std::atoi(property);
  }

  props.has_mediatek_platform =
      __system_property_find("ro.vendor.mediatek.platform") != nullptr;

  props.has_qemu_pipe = ::access("/dev/qemu_pipe", F_OK) == 0;
#endif  // FML_OS_ANDROID

  return props;
}

VulkanIneligibleReason CheckVulkanEligibility(
    const DeviceProperties& properties) {
  // Avoid using Vulkan on known emulators.
  if (IsDeviceEmulator(properties)) {
    return VulkanIneligibleReason::kEmulator;
  }

  // Avoid using Vulkan on Huawei as AHB imports do not consistently work.
  if (properties.client_id_base == kAndroidHuawei) {
    return VulkanIneligibleReason::kHuawei;
  }

  // Probably MediaTek. Avoid Vulkan if older than 32 to work around crashes
  // when importing AHB.
  if (properties.vendor_api_level < kMinimumAndroidApiLevelForMediaTekVulkan &&
      properties.has_mediatek_platform) {
    return VulkanIneligibleReason::kOldMediaTek;
  }

  if (IsKnownBadSOC(properties.product_board)) {
    return VulkanIneligibleReason::kBadSoc;
  }

  return VulkanIneligibleReason::kNone;
}

const char* VulkanIneligibleReasonToString(VulkanIneligibleReason reason) {
  switch (reason) {
    case VulkanIneligibleReason::kNone:
      return "eligible";
    case VulkanIneligibleReason::kEmulator:
      return "emulator";
    case VulkanIneligibleReason::kHuawei:
      return "Huawei device";
    case VulkanIneligibleReason::kOldMediaTek:
      return "MediaTek vendor API < 32";
    case VulkanIneligibleReason::kBadSoc:
      return "known bad SoC";
  }
  return "unknown";
}

}  // namespace flutter::android
