// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <cstddef>
#include <optional>
#include <string>
#include <tuple>
#include <vector>

namespace impeller {

struct Version {
 public:
  size_t major;
  size_t minor;
  size_t patch;

  constexpr Version(size_t p_major = 0, size_t p_minor = 0, size_t p_patch = 0)
      : major(p_major), minor(p_minor), patch(p_patch) {}

  static std::optional<Version> FromVector(const std::vector<size_t>& version);

  constexpr bool IsAtLeast(const Version& other) {
    return std::tie(major, minor, patch) >=
           std::tie(other.major, other.minor, other.patch);
  }

  std::string ToString() const;
};

}  // namespace impeller
