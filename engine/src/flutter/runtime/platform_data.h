// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_RUNTIME_PLATFORM_DATA_H_
#define FLUTTER_RUNTIME_PLATFORM_DATA_H_

#include "flutter/lib/ui/window/viewport_metrics.h"

#include <memory>
#include <string>
#include <vector>

namespace flutter {

//------------------------------------------------------------------------------
/// The struct of platform-specific data used for initializing ui.Window.
///
/// framework may request data from ui.Window before platform is properly
/// configured. Engine this struct to set the desired default value for
/// ui.Window when creating Shell before platform is ready to send the real
/// data.
///
/// See also:
///
///  * flutter::Shell::Create, which takes a platform_data to initialize the
///    ui.Window attached to it.
struct PlatformData {
  PlatformData();

  ~PlatformData();

  ViewportMetrics viewport_metrics;
  std::string language_code;
  std::string country_code;
  std::string script_code;
  std::string variant_code;
  std::vector<std::string> locale_data;
  std::string user_settings_data = "{}";
  std::string lifecycle_state;
  bool semantics_enabled = false;
  bool assistive_technology_enabled = false;
  int32_t accessibility_feature_flags_ = 0;
};

}  // namespace flutter

#endif  // FLUTTER_RUNTIME_PLATFORM_DATA_H_
