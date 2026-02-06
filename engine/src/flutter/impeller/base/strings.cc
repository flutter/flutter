// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/base/strings.h"

namespace impeller {

bool HasPrefix(const std::string& string, const std::string& prefix) {
  return string.find(prefix) == 0u;
}

bool HasSuffix(const std::string& string, const std::string& suffix) {
  auto position = string.rfind(suffix);
  if (position == std::string::npos) {
    return false;
  }
  return position == string.size() - suffix.size();
}

std::string StripPrefix(const std::string& string,
                        const std::string& to_strip) {
  if (!HasPrefix(string, to_strip)) {
    return string;
  }
  return string.substr(to_strip.length());
}

}  // namespace impeller
