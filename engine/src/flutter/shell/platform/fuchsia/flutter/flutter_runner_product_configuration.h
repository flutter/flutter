// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_FUCHSIA_FLUTTER_RUNNER_PRODUCT_CONFIGURATION_H_
#define FLUTTER_SHELL_PLATFORM_FUCHSIA_FLUTTER_RUNNER_PRODUCT_CONFIGURATION_H_
#include "flutter/fml/time/time_delta.h"

namespace flutter_runner {

class FlutterRunnerProductConfiguration {
 public:
  FlutterRunnerProductConfiguration() {}
  FlutterRunnerProductConfiguration(std::string path);

  fml::TimeDelta get_vsync_offset() { return vsync_offset_; }

 private:
  fml::TimeDelta vsync_offset_ = fml::TimeDelta::Zero();
};

}  // namespace flutter_runner
#endif  // FLUTTER_SHELL_PLATFORM_FUCHSIA_FLUTTER_RUNNER_PRODUCT_CONFIGURATION_H_
