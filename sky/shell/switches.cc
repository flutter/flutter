// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/switches.h"

#include <iostream>

namespace sky {
namespace shell {
namespace switches {

const char kEnableCheckedMode[] = "enable-checked-mode";
const char kFLX[] = "flx";
const char kHelp[] = "help";
const char kNonInteractive[] = "non-interactive";
const char kMainDartFile[] = "dart-main";
const char kPackages[] = "packages";
const char kStartPaused[] = "start-paused";
const char kTraceStartup[] = "trace-startup";
const char kDeviceObservatoryPort[] = "observatory-port";
const char kAotSnapshotPath[] = "aot-snapshot-path";

void PrintUsage(const std::string& executable_name) {
  std::cerr << "Usage: " << executable_name
            << " --" << kEnableCheckedMode
            << " --" << kNonInteractive
            << " --" << kStartPaused
            << " --" << kTraceStartup
            << " --" << kFLX << "=FLX"
            << " --" << kPackages << "=PACKAGES"
            << " --" << kDeviceObservatoryPort << "=8181"
            << " [ MAIN_DART ]" << std::endl;
}

}  // namespace switches
}  // namespace shell
}  // namespace sky
