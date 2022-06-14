// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/base/strings.h"

#include <cstdarg>

namespace impeller {

IMPELLER_PRINTF_FORMAT(1, 2)
std::string SPrintF(const char* format, ...) {
  va_list list;
  va_start(list, format);
  char buffer[64] = {0};
  ::vsnprintf(buffer, sizeof(buffer), format, list);
  va_end(list);
  return buffer;
}

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
