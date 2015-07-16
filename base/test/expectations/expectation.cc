// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/test/expectations/expectation.h"

#include "base/logging.h"

#if defined(OS_WIN)
#include "base/win/windows_version.h"
#elif defined(OS_MACOSX) && !defined(OS_IOS)
#include "base/mac/mac_util.h"
#elif defined(OS_LINUX)
#include "base/sys_info.h"
#endif

namespace test_expectations {

bool ResultFromString(const base::StringPiece& result, Result* out_result) {
  if (result == "Failure")
    *out_result = RESULT_FAILURE;
  else if (result == "Timeout")
    *out_result = RESULT_TIMEOUT;
  else if (result == "Crash")
    *out_result = RESULT_CRASH;
  else if (result == "Skip")
    *out_result = RESULT_SKIP;
  else if (result == "Pass")
    *out_result = RESULT_PASS;
  else
    return false;

  return true;
}

static bool IsValidPlatform(const Platform* platform) {
  const std::string& name = platform->name;
  const std::string& variant = platform->variant;

  if (name == "Win") {
    if (!variant.empty() &&
        variant != "XP" &&
        variant != "Vista" &&
        variant != "7" &&
        variant != "8") {
      return false;
    }
  } else if (name == "Mac") {
    if (!variant.empty() &&
        variant != "10.6" &&
        variant != "10.7" &&
        variant != "10.8" &&
        variant != "10.9" &&
        variant != "10.10") {
      return false;
    }
  } else if (name == "Linux") {
    if (!variant.empty() &&
        variant != "32" &&
        variant != "64") {
      return false;
    }
  } else if (name == "ChromeOS") {
    // TODO(rsesek): Figure out what ChromeOS needs.
  } else if (name == "iOS") {
    // TODO(rsesek): Figure out what iOS needs. Probably Device and Simulator.
  } else if (name == "Android") {
    // TODO(rsesek): Figure out what Android needs.
  } else {
    return false;
  }

  return true;
}

bool PlatformFromString(const base::StringPiece& modifier,
                        Platform* out_platform) {
  size_t sep = modifier.find('-');
  if (sep == std::string::npos) {
    out_platform->name = modifier.as_string();
    out_platform->variant.clear();
  } else {
    out_platform->name = modifier.substr(0, sep).as_string();
    out_platform->variant = modifier.substr(sep + 1).as_string();
  }

  return IsValidPlatform(out_platform);
}

Platform GetCurrentPlatform() {
  Platform platform;
#if defined(OS_WIN)
  platform.name = "Win";
  base::win::Version version = base::win::GetVersion();
  if (version == base::win::VERSION_XP)
    platform.variant = "XP";
  else if (version == base::win::VERSION_VISTA)
    platform.variant = "Vista";
  else if (version == base::win::VERSION_WIN7)
    platform.variant = "7";
  else if (version == base::win::VERSION_WIN8)
    platform.variant = "8";
#elif defined(OS_IOS)
  platform.name = "iOS";
#elif defined(OS_MACOSX)
  platform.name = "Mac";
  if (base::mac::IsOSSnowLeopard())
    platform.variant = "10.6";
  else if (base::mac::IsOSLion())
    platform.variant = "10.7";
  else if (base::mac::IsOSMountainLion())
    platform.variant = "10.8";
  else if (base::mac::IsOSMavericks())
    platform.variant = "10.9";
  else if (base::mac::IsOSYosemite())
    platform.variant = "10.10";
#elif defined(OS_CHROMEOS)
  platform.name = "ChromeOS";
#elif defined(OS_ANDROID)
  platform.name = "Android";
#elif defined(OS_LINUX)
  platform.name = "Linux";
  std::string arch = base::SysInfo::OperatingSystemArchitecture();
  if (arch == "x86")
    platform.variant = "32";
  else if (arch == "x86_64")
    platform.variant = "64";
#else
  NOTREACHED();
#endif
  return platform;
}

bool ConfigurationFromString(const base::StringPiece& modifier,
                             Configuration* out_configuration) {
  if (modifier == "Debug")
    *out_configuration = CONFIGURATION_DEBUG;
  else if (modifier == "Release")
    *out_configuration = CONFIGURATION_RELEASE;
  else
    return false;

  return true;
}

Configuration GetCurrentConfiguration() {
#if NDEBUG
  return CONFIGURATION_RELEASE;
#else
  return CONFIGURATION_DEBUG;
#endif
}

Expectation::Expectation()
    : configuration(CONFIGURATION_UNSPECIFIED),
      result(RESULT_PASS) {
}

Expectation::~Expectation() {}

}  // namespace test_expectations
