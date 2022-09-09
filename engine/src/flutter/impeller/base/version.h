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
  size_t major_version;
  size_t minor_version;
  size_t patch_version;

  constexpr Version(size_t p_major = 0, size_t p_minor = 0, size_t p_patch = 0)
      : major_version(p_major),
        minor_version(p_minor),
        patch_version(p_patch) {}

  static std::optional<Version> FromVector(const std::vector<size_t>& version);

  constexpr bool IsAtLeast(const Version& other) {
    return std::tie(major_version, minor_version, patch_version) >=
           std::tie(other.major_version, other.minor_version,
                    other.patch_version);
  }

  std::string ToString() const;
};

}  // namespace impeller
