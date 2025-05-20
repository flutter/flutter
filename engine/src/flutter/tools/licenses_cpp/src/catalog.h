// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TOOLS_LICENSES_CPP_SRC_CATALOG_H_
#define FLUTTER_TOOLS_LICENSES_CPP_SRC_CATALOG_H_

#include "flutter/third_party/abseil-cpp/absl/container/flat_hash_map.h"
#include "flutter/third_party/abseil-cpp/absl/status/statusor.h"
#include "flutter/third_party/re2/re2/re2.h"

class Catalog {
 public:
  using Entries = absl::flat_hash_map<std::string, std::unique_ptr<RE2>>;

  static absl::StatusOr<Catalog> Open(std::string_view data_dir);
  Catalog(std::unique_ptr<RE2> selector, Entries entries);
  absl::StatusOr<bool> HasMatch(std::string_view query);

 private:
  std::unique_ptr<RE2> selector_;
  Entries entries_;
};

#endif  // FLUTTER_TOOLS_LICENSES_CPP_SRC_CATALOG_H_
