// Copyright 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/ios/ios_util.h"

#include "base/sys_info.h"

namespace {
// Return a 3 elements array containing the major, minor and bug fix version of
// the OS.
const int32* OSVersionAsArray() {
  int32* digits = new int32[3];
  base::SysInfo::OperatingSystemVersionNumbers(
      &digits[0], &digits[1], &digits[2]);
  return digits;
}
}  // namespace

namespace base {
namespace ios {

bool IsRunningOnIOS8OrLater() {
  return IsRunningOnOrLater(8, 0, 0);
}

bool IsRunningOnOrLater(int32 major, int32 minor, int32 bug_fix) {
  static const int32* current_version = OSVersionAsArray();
  int32 version[] = { major, minor, bug_fix };
  for (size_t i = 0; i < arraysize(version); i++) {
    if (current_version[i] != version[i])
      return current_version[i] > version[i];
  }
  return true;
}

}  // namespace ios
}  // namespace base
