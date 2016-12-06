// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Cocoa/Cocoa.h>

#include <iostream>

#include "base/bind.h"
#include "base/command_line.h"
#include "base/message_loop/message_loop.h"
#include "flutter/shell/common/switches.h"
#include "flutter/shell/platform/darwin/common/platform_mac.h"
#include "flutter/shell/platform/darwin/desktop/flutter_application.h"
#include "flutter/shell/testing/testing.h"

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

int main(int argc, const char* argv[]) {
  [FlutterApplication sharedApplication];

  shell::PlatformMacMain(argc, argv, "", "");

  base::CommandLine& command_line = *base::CommandLine::ForCurrentProcess();
  if (command_line.HasSwitch(shell::FlagForSwitch(shell::Switch::Help))) {
    shell::PrintUsage([NSProcessInfo processInfo].processName.UTF8String);
    return EXIT_SUCCESS;
  }

  if (command_line.HasSwitch(
          shell::FlagForSwitch(shell::Switch::NonInteractive))) {
    if (!shell::InitForTesting())
      return 1;
    base::MessageLoop::current()->Run();
    return EXIT_SUCCESS;
  }

  shell::AttachMessageLoopToMainRunLoop();
  return NSApplicationMain(argc, argv);
}
