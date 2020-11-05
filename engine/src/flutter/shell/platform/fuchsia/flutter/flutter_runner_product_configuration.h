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
  uint64_t get_max_frames_in_flight() { return max_frames_in_flight_; }
  bool get_intercept_all_input() { return intercept_all_input_; }
  bool enable_shader_warmup() { return enable_shader_warmup_; }
#if defined(LEGACY_FUCHSIA_EMBEDDER)
  bool use_legacy_renderer() { return use_legacy_renderer_; }
#endif

 private:
  fml::TimeDelta vsync_offset_ = fml::TimeDelta::Zero();
  uint64_t max_frames_in_flight_ = 3;
  bool intercept_all_input_ = false;
  bool enable_shader_warmup_ = false;
#if defined(LEGACY_FUCHSIA_EMBEDDER)
  bool use_legacy_renderer_ = true;
#endif
};

}  // namespace flutter_runner
#endif  // FLUTTER_SHELL_PLATFORM_FUCHSIA_FLUTTER_RUNNER_PRODUCT_CONFIGURATION_H_
