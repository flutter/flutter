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
}

}  // namespace flutter_runner
