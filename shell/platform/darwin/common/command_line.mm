// Copyright 2017 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/common/command_line.h"

#import <Foundation/Foundation.h>

namespace shell {

fxl::CommandLine CommandLineFromNSProcessInfo() {
  std::vector<std::string> args_vector;

  for (NSString* arg in [NSProcessInfo processInfo].arguments) {
    args_vector.emplace_back(arg.UTF8String);
  }

  return fxl::CommandLineFromIterators(args_vector.begin(), args_vector.end());
}

}  // namespace shell
