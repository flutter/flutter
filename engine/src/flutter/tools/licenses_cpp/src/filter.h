// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TOOLS_LICENSES_CPP_SRC_FILTER_H_
#define FLUTTER_TOOLS_LICENSES_CPP_SRC_FILTER_H_

#include <iosfwd>
#include <memory>
#include <string_view>
#include "flutter/third_party/re2/re2/re2.h"
#include "third_party/abseil-cpp/absl/status/statusor.h"

/// A filter is a concatenation of multiple regex.
///
/// This is used for things like the include.txt and exclude.txt.
class Filter {
 public:
  static absl::StatusOr<Filter> Open(std::string_view path);

  static absl::StatusOr<Filter> Open(std::istream& input);

  bool Matches(std::string_view input) const;

  Filter(const Filter&) = delete;
  Filter& operator=(const Filter&) = delete;
  Filter(Filter&&) = default;
  Filter& operator=(Filter&&) = default;

 private:
  explicit Filter(std::string_view regex);
  std::unique_ptr<RE2> re_;
};

#endif  // FLUTTER_TOOLS_LICENSES_CPP_SRC_FILTER_H_
