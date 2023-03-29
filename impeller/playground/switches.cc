// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/playground/switches.h"

#include <cstdlib>

namespace impeller {

PlaygroundSwitches::PlaygroundSwitches() = default;

PlaygroundSwitches::PlaygroundSwitches(const fml::CommandLine& args) {
  std::string timeout_str;
  if (args.GetOptionValue("playground_timeout_ms", &timeout_str)) {
    timeout = std::chrono::milliseconds(atoi(timeout_str.c_str()));
  }
  enable_vulkan_validation = args.HasOption("enable_vulkan_validation");
}

}  // namespace impeller
