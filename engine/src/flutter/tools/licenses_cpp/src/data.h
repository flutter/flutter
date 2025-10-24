// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TOOLS_LICENSES_CPP_SRC_DATA_H_
#define FLUTTER_TOOLS_LICENSES_CPP_SRC_DATA_H_

#include <filesystem>

#include "flutter/tools/licenses_cpp/src/catalog.h"
#include "flutter/tools/licenses_cpp/src/filter.h"
#include "third_party/abseil-cpp/absl/status/statusor.h"

/// In memory representation of the contents of the data directory
///
/// All the data needed to run the license checker.
struct Data {
  static absl::StatusOr<Data> Open(std::string_view data_dir);
  Filter include_filter;
  Filter exclude_filter;
  Catalog catalog;
  std::filesystem::path secondary_dir;
};

#endif  // FLUTTER_TOOLS_LICENSES_CPP_SRC_DATA_H_
