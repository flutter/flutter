// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "font_features.h"

#include <sstream>

namespace txt {

void FontFeatures::SetFeature(const std::string& tag, int value) {
  feature_map_[tag] = value;
}

std::string FontFeatures::GetFeatureSettings() const {
  if (feature_map_.empty()) {
    return "";
  }

  std::ostringstream stream;

  for (const auto& kv : feature_map_) {
    if (stream.tellp()) {
      stream << ',';
    }
    stream << kv.first << '=' << kv.second;
  }

  return stream.str();
}

const std::map<std::string, int>& FontFeatures::GetFontFeatures() const {
  return feature_map_;
}

void FontVariations::SetAxisValue(const std::string& tag, float value) {
  axis_map_[tag] = value;
}

const std::map<std::string, float>& FontVariations::GetAxisValues() const {
  return axis_map_;
}

}  // namespace txt
