// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Cocoa/Cocoa.h>
#include <iostream>
#include "base/bind.h"
#include "base/message_loop/message_loop.h"
#include "sky/engine/public/web/WebRuntimeFeatures.h"
#include "sky/shell/mac/platform_mac.h"
#include "base/command_line.h"
#include "sky/shell/switches.h"
#include "sky/shell/testing/test_runner.h"

namespace sky {
namespace shell {
namespace {

bool FlagsValid() {
  base::CommandLine& command_line = *base::CommandLine::ForCurrentProcess();

  if (command_line.HasSwitch(sky::shell::switches::kHelp) ||
      (!command_line.HasSwitch(sky::shell::switches::kPackageRoot) &&
       !command_line.HasSwitch(sky::shell::switches::kSnapshot))) {
    return false;
  }

  return true;
}

void Usage() {
  std::cerr << "(For Test Shell) Usage: sky_shell"
            << " --" << switches::kNonInteractive
            << " --" << switches::kPackageRoot << "=PACKAGE_ROOT"
            << " --" << switches::kSnapshot << "=SNAPSHOT"
            << " [ MAIN_DART ]" << std::endl;
}

void Init() {
  base::CommandLine& command_line = *base::CommandLine::ForCurrentProcess();
  blink::WebRuntimeFeatures::enableObservatory(
      !command_line.HasSwitch(switches::kNonInteractive));

  // Explicitly boot the shared test runner.
  TestRunner& runner = TestRunner::Shared();

  std::string package_root =
      command_line.GetSwitchValueASCII(switches::kPackageRoot);
  runner.set_package_root(package_root);

  scoped_ptr<TestRunner::SingleTest> single_test;
  if (command_line.HasSwitch(switches::kSnapshot)) {
    single_test.reset(new TestRunner::SingleTest);
    single_test->path = command_line.GetSwitchValueASCII(switches::kSnapshot);
    single_test->is_snapshot = true;
  } else {
    auto args = command_line.GetArgs();
    if (!args.empty()) {
      single_test.reset(new TestRunner::SingleTest);
      single_test->path = args[0];
    }
  }

  runner.Start(single_test.Pass());
}

}  // namespace
}  // namespace shell
}  // namespace sky

int main(int argc, const char * argv[]) {
  return PlatformMacMain(argc, argv, ^(){
    if (!sky::shell::FlagsValid()) {
      sky::shell::Usage();
      return NSApplicationMain(argc, argv);
    } else {
      auto loop = base::MessageLoop::current();
      loop->PostTask(FROM_HERE, base::Bind(&sky::shell::Init));
      loop->Run();
      return EXIT_SUCCESS;
    }
  });
}
