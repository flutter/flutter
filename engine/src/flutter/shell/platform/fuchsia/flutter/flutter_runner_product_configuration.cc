// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter_runner_product_configuration.h"
#include <zircon/assert.h>

#include "rapidjson/document.h"

namespace flutter_runner {

FlutterRunnerProductConfiguration::FlutterRunnerProductConfiguration(
    std::string json_string) {
  rapidjson::Document document;
  document.Parse(json_string);

  if (!document.IsObject())
    return;

  // Parse out all values we're expecting.
  if (document.HasMember("vsync_offset_in_us")) {
    auto& val = document["vsync_offset_in_us"];
    if (val.IsInt())
      vsync_offset_ = fml::TimeDelta::FromMicroseconds(val.GetInt());
  }
  if (document.HasMember("max_frames_in_flight")) {
    auto& val = document["max_frames_in_flight"];
    if (val.IsInt())
      max_frames_in_flight_ = val.GetInt();
  }
  if (document.HasMember("intercept_all_input")) {
    auto& val = document["intercept_all_input"];
    if (val.IsBool())
      intercept_all_input_ = val.GetBool();
  }
  if (document.HasMember("enable_shader_warmup")) {
    auto& val = document["enable_shader_warmup"];
    if (val.IsBool())
      enable_shader_warmup_ = val.GetBool();
  }
#if defined(LEGACY_FUCHSIA_EMBEDDER)
  if (document.HasMember("use_legacy_renderer")) {
    auto& val = document["use_legacy_renderer"];
    if (val.IsBool())
      use_legacy_renderer_ = val.GetBool();
  }
#endif
}

}  // namespace flutter_runner
