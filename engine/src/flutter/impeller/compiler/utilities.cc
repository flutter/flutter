// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/compiler/utilities.h"

#include <cctype>
#include <filesystem>
#include <sstream>

namespace impeller {
namespace compiler {

std::string InferShaderNameFromPath(std::string_view path) {
  return std::filesystem::path{path}.stem().u8string();
}

std::string ConvertToCamelCase(std::string_view string) {
  if (string.empty()) {
    return "";
  }

  std::stringstream stream;
  bool next_upper = true;
  for (size_t i = 0, count = string.length(); i < count; i++) {
    auto ch = string.data()[i];
    if (next_upper) {
      next_upper = false;
      stream << static_cast<char>(std::toupper(ch));
      continue;
    }
    if (ch == '_') {
      next_upper = true;
      continue;
    }
    stream << ch;
  }
  return stream.str();
}

}  // namespace compiler
}  // namespace impeller
