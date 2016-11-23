// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/testing/testing.h"

#include "base/command_line.h"
#include "flutter/shell/common/switches.h"
#include "flutter/shell/testing/test_runner.h"

namespace shell {

bool InitForTesting() {
  base::CommandLine& command_line = *base::CommandLine::ForCurrentProcess();

  TestRunner::TestDescriptor test;
  test.packages =
      command_line.GetSwitchValueASCII(FlagForSwitch(Switch::Packages));
  auto args = command_line.GetArgs();
  if (args.empty())
    return false;
  test.path = args[0];

  TestRunner::Shared().Run(test);
  return true;
}

}  // namespace shell
