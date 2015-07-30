// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/switches.h"

#include <iostream>

namespace sky {
namespace shell {
namespace switches {

const char kEnableCheckedMode[] = "enable-checked-mode";
const char kHelp[] = "help";
const char kNonInteractive[] = "non-interactive";
const char kPackageRoot[] = "package-root";
const char kSnapshot[] = "snapshot";

void PrintUsage(const std::string& executable_name) {
  std::cerr << "Usage: " << executable_name
            << " --" << kEnableCheckedMode
            << " --" << kNonInteractive
            << " --" << kPackageRoot << "=PACKAGE_ROOT"
            << " --" << kSnapshot << "=SNAPSHOT"
            << " [ MAIN_DART ]" << std::endl;
}

}  // namespace switches
}  // namespace shell
}  // namespace sky
