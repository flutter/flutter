// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Cocoa/Cocoa.h>
#include <iostream>
#include "base/bind.h"
#include "base/command_line.h"
#include "base/message_loop/message_loop.h"
#include "flutter/sky/shell/platform/mac/platform_mac.h"
#include "flutter/sky/shell/platform/mac/sky_application.h"
#include "flutter/sky/shell/switches.h"
#include "flutter/sky/shell/testing/testing.h"

namespace sky {
namespace shell {
namespace {

void AttachMessageLoopToMainRunLoop(void) {
  // We want to call Run() on the MessageLoopForUI but after NSApplicationMain.
  // If called before this point, the call is blocking and will prevent the
  // NSApplicationMain invocation.
  dispatch_async(dispatch_get_main_queue(), ^() {
    base::MessageLoopForUI::current()->Run();
  });
}

}  // namespace
}  // namespace shell
}  // namespace sky

int main(int argc, const char* argv[]) {
  [SkyApplication sharedApplication];

  sky::shell::PlatformMacMain(argc, argv, "");

  base::CommandLine& command_line = *base::CommandLine::ForCurrentProcess();
  if (command_line.HasSwitch(sky::shell::switches::kHelp)) {
    sky::shell::switches::PrintUsage("SkyShell");
    return EXIT_SUCCESS;
  }

  if (command_line.HasSwitch(sky::shell::switches::kNonInteractive)) {
    if (!sky::shell::InitForTesting())
      return 1;
    base::MessageLoop::current()->Run();
    return EXIT_SUCCESS;
  }

  sky::shell::AttachMessageLoopToMainRunLoop();
  return NSApplicationMain(argc, argv);
}
