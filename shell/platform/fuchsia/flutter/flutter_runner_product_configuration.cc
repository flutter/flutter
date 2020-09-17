// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter_runner_product_configuration.h"

#include "rapidjson/document.h"

namespace flutter_runner {

FlutterRunnerProductConfiguration::FlutterRunnerProductConfiguration(
    std::string json_string) {
  rapidjson::Document document;
  document.Parse(json_string);

  if (!document.IsObject())
    return;

  // Parse out all values we're expecting.
  if (auto& val = document["vsync_offset_in_us"]; val.IsInt()) {
    vsync_offset_ = fml::TimeDelta::FromMicroseconds(val.GetInt());
  }
  if (auto& val = document["max_frames_in_flight"]; val.IsInt()) {
    max_frames_in_flight_ = val.GetInt();
  }
#if defined(LEGACY_FUCHSIA_EMBEDDER)
  if (auto& val = document["use_legacy_renderer"]; val.IsBool()) {
    use_legacy_renderer_ = val.GetBool();
  }
#endif
}

}  // namespace flutter_runner
