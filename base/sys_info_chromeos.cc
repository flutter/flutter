// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/sys_info.h"

#include "base/basictypes.h"
#include "base/environment.h"
#include "base/files/file.h"
#include "base/files/file_path.h"
#include "base/files/file_util.h"
#include "base/lazy_instance.h"
#include "base/strings/string_number_conversions.h"
#include "base/strings/string_piece.h"
#include "base/strings/string_split.h"
#include "base/strings/string_tokenizer.h"
#include "base/strings/string_util.h"
#include "base/threading/thread_restrictions.h"

namespace base {

namespace {

const char* const kLinuxStandardBaseVersionKeys[] = {
  "CHROMEOS_RELEASE_VERSION",
  "GOOGLE_RELEASE",
  "DISTRIB_RELEASE",
};

const char kChromeOsReleaseNameKey[] = "CHROMEOS_RELEASE_NAME";

const char* const kChromeOsReleaseNames[] = {
  "Chrome OS",
  "Chromium OS",
};

const char kLinuxStandardBaseReleaseFile[] = "/etc/lsb-release";

const char kLsbReleaseKey[] = "LSB_RELEASE";
const char kLsbReleaseTimeKey[] = "LSB_RELEASE_TIME";  // Seconds since epoch

const char kLsbReleaseSourceKey[] = "lsb-release";
const char kLsbReleaseSourceEnv[] = "env";
const char kLsbReleaseSourceFile[] = "file";

class ChromeOSVersionInfo {
 public:
  ChromeOSVersionInfo() {
    Parse();
  }

  void Parse() {
    lsb_release_map_.clear();
    major_version_ = 0;
    minor_version_ = 0;
    bugfix_version_ = 0;
    is_running_on_chromeos_ = false;

    std::string lsb_release, lsb_release_time_str;
    scoped_ptr<Environment> env(Environment::Create());
    bool parsed_from_env =
        env->GetVar(kLsbReleaseKey, &lsb_release) &&
        env->GetVar(kLsbReleaseTimeKey, &lsb_release_time_str);
    if (parsed_from_env) {
      double us = 0;
      if (StringToDouble(lsb_release_time_str, &us))
        lsb_release_time_ = Time::FromDoubleT(us);
    } else {
      // If the LSB_RELEASE and LSB_RELEASE_TIME environment variables are not
      // set, fall back to a blocking read of the lsb_release file. This should
      // only happen in non Chrome OS environments.
      ThreadRestrictions::ScopedAllowIO allow_io;
      FilePath path(kLinuxStandardBaseReleaseFile);
      ReadFileToString(path, &lsb_release);
      File::Info fileinfo;
      if (GetFileInfo(path, &fileinfo))
        lsb_release_time_ = fileinfo.creation_time;
    }
    ParseLsbRelease(lsb_release);
    // For debugging:
    lsb_release_map_[kLsbReleaseSourceKey] =
        parsed_from_env ? kLsbReleaseSourceEnv : kLsbReleaseSourceFile;
  }

  bool GetLsbReleaseValue(const std::string& key, std::string* value) {
    SysInfo::LsbReleaseMap::const_iterator iter = lsb_release_map_.find(key);
    if (iter == lsb_release_map_.end())
      return false;
    *value = iter->second;
    return true;
  }

  void GetVersionNumbers(int32* major_version,
                         int32* minor_version,
                         int32* bugfix_version) {
    *major_version = major_version_;
    *minor_version = minor_version_;
    *bugfix_version = bugfix_version_;
  }

  const Time& lsb_release_time() const { return lsb_release_time_; }
  const SysInfo::LsbReleaseMap& lsb_release_map() const {
    return lsb_release_map_;
  }
  bool is_running_on_chromeos() const { return is_running_on_chromeos_; }

 private:
  void ParseLsbRelease(const std::string& lsb_release) {
    // Parse and cache lsb_release key pairs. There should only be a handful
    // of entries so the overhead for this will be small, and it can be
    // useful for debugging.
    base::StringPairs pairs;
    SplitStringIntoKeyValuePairs(lsb_release, '=', '\n', &pairs);
    for (size_t i = 0; i < pairs.size(); ++i) {
      std::string key, value;
      TrimWhitespaceASCII(pairs[i].first, TRIM_ALL, &key);
      TrimWhitespaceASCII(pairs[i].second, TRIM_ALL, &value);
      if (key.empty())
        continue;
      lsb_release_map_[key] = value;
    }
    // Parse the version from the first matching recognized version key.
    std::string version;
    for (size_t i = 0; i < arraysize(kLinuxStandardBaseVersionKeys); ++i) {
      std::string key = kLinuxStandardBaseVersionKeys[i];
      if (GetLsbReleaseValue(key, &version) && !version.empty())
        break;
    }
    StringTokenizer tokenizer(version, ".");
    if (tokenizer.GetNext()) {
      StringToInt(StringPiece(tokenizer.token_begin(), tokenizer.token_end()),
                  &major_version_);
    }
    if (tokenizer.GetNext()) {
      StringToInt(StringPiece(tokenizer.token_begin(), tokenizer.token_end()),
                  &minor_version_);
    }
    if (tokenizer.GetNext()) {
      StringToInt(StringPiece(tokenizer.token_begin(), tokenizer.token_end()),
                  &bugfix_version_);
    }

    // Check release name for Chrome OS.
    std::string release_name;
    if (GetLsbReleaseValue(kChromeOsReleaseNameKey, &release_name)) {
      for (size_t i = 0; i < arraysize(kChromeOsReleaseNames); ++i) {
        if (release_name == kChromeOsReleaseNames[i]) {
          is_running_on_chromeos_ = true;
          break;
        }
      }
    }
  }

  Time lsb_release_time_;
  SysInfo::LsbReleaseMap lsb_release_map_;
  int32 major_version_;
  int32 minor_version_;
  int32 bugfix_version_;
  bool is_running_on_chromeos_;
};

static LazyInstance<ChromeOSVersionInfo>
    g_chrome_os_version_info = LAZY_INSTANCE_INITIALIZER;

ChromeOSVersionInfo& GetChromeOSVersionInfo() {
  return g_chrome_os_version_info.Get();
}

}  // namespace

// static
void SysInfo::OperatingSystemVersionNumbers(int32* major_version,
                                            int32* minor_version,
                                            int32* bugfix_version) {
  return GetChromeOSVersionInfo().GetVersionNumbers(
      major_version, minor_version, bugfix_version);
}

// static
const SysInfo::LsbReleaseMap& SysInfo::GetLsbReleaseMap() {
  return GetChromeOSVersionInfo().lsb_release_map();
}

// static
bool SysInfo::GetLsbReleaseValue(const std::string& key, std::string* value) {
  return GetChromeOSVersionInfo().GetLsbReleaseValue(key, value);
}

// static
std::string SysInfo::GetLsbReleaseBoard() {
  const char kMachineInfoBoard[] = "CHROMEOS_RELEASE_BOARD";
  std::string board;
  if (!GetLsbReleaseValue(kMachineInfoBoard, &board))
    board = "unknown";
  return board;
}

// static
Time SysInfo::GetLsbReleaseTime() {
  return GetChromeOSVersionInfo().lsb_release_time();
}

// static
bool SysInfo::IsRunningOnChromeOS() {
  return GetChromeOSVersionInfo().is_running_on_chromeos();
}

// static
void SysInfo::SetChromeOSVersionInfoForTest(const std::string& lsb_release,
                                            const Time& lsb_release_time) {
  scoped_ptr<Environment> env(Environment::Create());
  env->SetVar(kLsbReleaseKey, lsb_release);
  env->SetVar(kLsbReleaseTimeKey,
              DoubleToString(lsb_release_time.ToDoubleT()));
  g_chrome_os_version_info.Get().Parse();
}

}  // namespace base
