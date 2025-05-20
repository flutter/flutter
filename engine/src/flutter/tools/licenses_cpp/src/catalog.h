// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TOOLS_LICENSES_CPP_SRC_CATALOG_H_
#define FLUTTER_TOOLS_LICENSES_CPP_SRC_CATALOG_H_

#include "flutter/third_party/abseil-cpp/absl/container/flat_hash_map.h"
#include "flutter/third_party/abseil-cpp/absl/status/statusor.h"
#include "flutter/third_party/re2/re2/re2.h"
#include "flutter/third_party/re2/re2/set.h"

class Catalog {
 public:
  static absl::StatusOr<Catalog> Open(std::string_view data_dir);
  static absl::StatusOr<Catalog> Make(
      std::vector<std::pair<std::string_view, std::string_view>> entries);
  absl::StatusOr<bool> HasMatch(std::string_view query);

 private:
  explicit Catalog(RE2::Set selector,
                   std::vector<std::unique_ptr<RE2>> matchers,
                   std::vector<std::string> selector_pieces);
  RE2::Set selector_;
  std::vector<std::unique_ptr<RE2>> matchers_;
  /// Storage of the parts of `selector_` for debugging purposes.
  std::vector<std::string> selector_pieces_;
};

#endif  // FLUTTER_TOOLS_LICENSES_CPP_SRC_CATALOG_H_
