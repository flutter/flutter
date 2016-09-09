// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/sky/shell/switches.h"

#include <iostream>

namespace sky {
namespace shell {
namespace switches {

const char kAotInstructionsBlob[] = "instructions-blob";
const char kAotIsolateSnapshot[] = "isolate-snapshot";
const char kAotRodataBlob[] = "rodata-blob";
const char kAotSnapshotPath[] = "aot-snapshot-path";
const char kAotVmIsolateSnapshot[] = "vm-isolate-snapshot";
const char kCacheDirPath[] = "cache-dir-path";
const char kDartFlags[] = "dart-flags";
const char kDeviceObservatoryPort[] = "observatory-port";
const char kDisableObservatory[] = "disable-observatory";
const char kEndlessTraceBuffer[] = "endless-trace-buffer";
const char kFLX[] = "flx";
const char kHelp[] = "help";
const char kMainDartFile[] = "dart-main";
const char kNonInteractive[] = "non-interactive";
const char kNoRedirectToSyslog[] = "no-redirect-to-syslog";
const char kPackages[] = "packages";
const char kStartPaused[] = "start-paused";
const char kTraceStartup[] = "trace-startup";

void PrintUsage(const std::string& executable_name) {
  // clang-format off
  std::cerr << "Usage: " << executable_name
            << " --" << kNonInteractive
            << " --" << kStartPaused
            << " --" << kTraceStartup
            << " --" << kFLX << "=FLX"
            << " --" << kPackages << "=PACKAGES"
            << " --" << kDeviceObservatoryPort << "=8181"
            << " [ MAIN_DART ]" << std::endl;
  // clang-format on
}

}  // namespace switches
}  // namespace shell
}  // namespace sky
