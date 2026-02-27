// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TOOLS_LICENSES_CPP_SRC_DEPS_PARSER_H_
#define FLUTTER_TOOLS_LICENSES_CPP_SRC_DEPS_PARSER_H_

#include <string>
#include <string_view>
#include <vector>

class DepsParser {
 public:
  DepsParser();
  ~DepsParser();

  std::vector<std::string> Parse(std::string_view input);
};

#endif  // FLUTTER_TOOLS_LICENSES_CPP_SRC_DEPS_PARSER_H_
