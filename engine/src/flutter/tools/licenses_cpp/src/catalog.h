// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TOOLS_LICENSES_CPP_SRC_CATALOG_H_
#define FLUTTER_TOOLS_LICENSES_CPP_SRC_CATALOG_H_

#include "flutter/third_party/abseil-cpp/absl/container/flat_hash_map.h"
#include "flutter/third_party/abseil-cpp/absl/status/statusor.h"
#include "flutter/third_party/re2/re2/re2.h"
#include "flutter/third_party/re2/re2/set.h"

#include <iosfwd>
#include <optional>

/// A storage of licenses that can be matched against.
/// The in memory representation of the `data/headers` and `data/licenses`
/// directories.  This represents a 2 tiered search, first the sector is used
/// to determine what matcher should be used, then a match is performend on
/// that. This approach was chosen to minimize the size of the RE2::Set.
class Catalog {
 public:
  /// VisibleForTesting
  struct Entry {
    std::string name;
    std::string unique;
    std::string matcher;
  };

  struct Match {
    std::string_view matcher;
    std::string_view matched_text;
  };

  static absl::StatusOr<Catalog> Open(std::string_view data_dir);

  /// Make a Catalog for testing.
  static absl::StatusOr<Catalog> Make(const std::vector<Entry>& entries);

  /// @brief Tries to identify a match for the `query` across the `Catalog`.
  /// @param query The text that will be matched against.
  /// @return absl::StatusCode::kNotFound when a match can't be found.
  /// absl::StatusCode::kInvalidArgument if more than one match comes up from
  /// the selector.
  absl::StatusOr<std::vector<Match>> FindMatch(std::string_view query) const;

  /// VisibleForTesting
  static absl::StatusOr<Entry> ParseEntry(std::istream& is);

 private:
  explicit Catalog(RE2::Set selector,
                   std::vector<std::unique_ptr<RE2>> matchers,
                   std::vector<std::string> names);
  RE2::Set selector_;
  std::vector<std::unique_ptr<RE2>> matchers_;
  std::vector<std::string> names_;
};

#endif  // FLUTTER_TOOLS_LICENSES_CPP_SRC_CATALOG_H_
