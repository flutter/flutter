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
#if defined(LEGACY_FUCHSIA_EMBEDDER)
  bool use_legacy_renderer() { return use_legacy_renderer_; }
#endif

 private:
  fml::TimeDelta vsync_offset_ = fml::TimeDelta::Zero();
#if defined(LEGACY_FUCHSIA_EMBEDDER)
  bool use_legacy_renderer_ = true;
#endif
};

}  // namespace flutter_runner
#endif  // FLUTTER_SHELL_PLATFORM_FUCHSIA_FLUTTER_RUNNER_PRODUCT_CONFIGURATION_H_
