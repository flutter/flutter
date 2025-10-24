// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/tools/licenses_cpp/src/filter.h"
#include <fstream>
#include "third_party/abseil-cpp/absl/strings/str_cat.h"

absl::StatusOr<Filter> Filter::Open(std::string_view path) {
  std::ifstream input;
  input.open(path);
  absl::StatusOr<Filter> result = Open(input);
  input.close();
  return result;
}

absl::StatusOr<Filter> Filter::Open(std::istream& input) {
  if (!input.good()) {
    return absl::InvalidArgumentError("stream not good");
  }
  std::string regex;
  bool first = true;
  std::string line;
  while (input.good()) {
    std::getline(input, line);
    if (line.length() <= 0) {
      continue;
    }
    if (line[0] == '#') {
      // Comments.
      continue;
    }
    if (!first) {
      absl::StrAppend(&regex, "|");
    } else {
      first = false;
    }
    absl::StrAppend(&regex, line);
  }

  return Filter(regex);
}

Filter::Filter(std::string_view regex) : re_(std::make_unique<RE2>(regex)) {}

bool Filter::Matches(std::string_view input) const {
  return RE2::FullMatch(input, *re_);
}
