// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/tools/licenses_cpp/src/data.h"
#include <filesystem>
namespace {
const char* kIncludeFilename = "include.txt";
const char* kExcludeFilename = "exclude.txt";
}  // namespace

namespace fs = std::filesystem;

absl::StatusOr<Data> Data::Open(std::string_view data_dir) {
  fs::path data_path = fs::path(data_dir);
  fs::path include_path = data_path / kIncludeFilename;
  absl::StatusOr<Filter> include_filter = Filter::Open(include_path.string());
  if (!include_filter.ok()) {
    return absl::InvalidArgumentError("Can't open include.txt at " +
                                      include_path.string() + ": " +
                                      include_filter.status().ToString());
  }
  fs::path exclude_path = fs::path(data_dir) / kExcludeFilename;
  absl::StatusOr<Filter> exclude_filter = Filter::Open(exclude_path.string());
  if (!exclude_filter.ok()) {
    return absl::InvalidArgumentError("Can't open exclude.txt at " +
                                      exclude_path.string() + ": " +
                                      include_filter.status().ToString());
  }
  absl::StatusOr<Catalog> catalog = Catalog::Open(data_dir);
  if (!catalog.ok()) {
    return absl::InvalidArgumentError("Can't open catalog at " +
                                      exclude_path.string() + ": " +
                                      catalog.status().ToString());
  }

  fs::path secondary_dir = data_path / "secondary";

  return Data{
      .include_filter = std::move(*include_filter),
      .exclude_filter = std::move(*exclude_filter),
      .catalog = std::move(*catalog),
      .secondary_dir = fs::exists(secondary_dir) ? secondary_dir : fs::path()};
}
