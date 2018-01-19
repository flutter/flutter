// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Cocoa/Cocoa.h>

#include <iostream>

#include "flutter/fml/message_loop.h"
#include "flutter/shell/common/shell.h"
#include "flutter/shell/common/switches.h"
#include "flutter/shell/platform/darwin/common/platform_mac.h"
#include "flutter/shell/platform/darwin/desktop/flutter_application.h"
#include "flutter/shell/testing/testing.h"
#include "lib/fxl/command_line.h"
#include "lib/fxl/logging.h"

static fxl::CommandLine InitializedCommandLine() {
  std::vector<std::string> args_vector;

  for (NSString* arg in [NSProcessInfo processInfo].arguments) {
    args_vector.emplace_back(arg.UTF8String);
  }

  return fxl::CommandLineFromIterators(args_vector.begin(), args_vector.end());
}

int main(int argc, const char* argv[]) {
  [FlutterApplication sharedApplication];

  // Can't use shell::Shell::Shared().GetCommandLine() because it is initialized only
  // in shell::PlatformMacMain call below.
  auto command_line = InitializedCommandLine();

  std::string bundle_path = "";
  command_line.GetOptionValue(FlagForSwitch(shell::Switch::FlutterAssetsDir), &bundle_path);

  shell::PlatformMacMain("", "", bundle_path);

  // Print help.
  if (command_line.HasOption(shell::FlagForSwitch(shell::Switch::Help))) {
    shell::PrintUsage([NSProcessInfo processInfo].processName.UTF8String);
    return EXIT_SUCCESS;
  }

  // Decide between interactive and non-interactive modes.
  if (command_line.HasOption(shell::FlagForSwitch(shell::Switch::NonInteractive))) {
    if (!shell::InitForTesting(std::move(command_line)))
      return 1;
    fml::MessageLoop::GetCurrent().Run();
    return EXIT_SUCCESS;
  } else {
    return NSApplicationMain(argc, argv);
  }
}
