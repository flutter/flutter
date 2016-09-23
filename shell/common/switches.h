// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SHELL_COMMON_SWITCHES_H_
#define SHELL_COMMON_SWITCHES_H_

#include <string>

namespace shell {
namespace switches {

extern const char kAotInstructionsBlob[];
extern const char kAotIsolateSnapshot[];
extern const char kAotRodataBlob[];
extern const char kAotSnapshotPath[];
extern const char kAotVmIsolateSnapshot[];
extern const char kCacheDirPath[];
extern const char kDartFlags[];
extern const char kDeviceObservatoryPort[];
extern const char kDisableObservatory[];
extern const char kEndlessTraceBuffer[];
extern const char kFLX[];
extern const char kHelp[];
extern const char kMainDartFile[];
extern const char kNonInteractive[];
extern const char kNoRedirectToSyslog[];
extern const char kPackages[];
extern const char kStartPaused[];
extern const char kTraceStartup[];

void PrintUsage(const std::string& executable_name);

}  // namespace switches
}  // namespace shell

#endif  // SHELL_COMMON_SWITCHES_H_
