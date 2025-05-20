// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/tools/licenses_cpp/src/catalog.h"

absl::StatusOr<Catalog> Catalog::Open(std::string_view data_dir) {
  return absl::UnimplementedError("");
}

Catalog::Catalog(std::unique_ptr<RE2> selector, Catalog::Entries entries)
    : selector_(std::move(selector)), entries_(std::move(entries)) {}

absl::StatusOr<bool> Catalog::HasMatch(std::string_view query) {
  std::vector<std::string> results;
  std::string result;
  re2::StringPiece selector_query(query);
  while (RE2::FindAndConsume(&selector_query, *selector_, &result)) {
    results.push_back(result);
  }
  if (results.size() > 1) {
    std::stringstream ss;
    ss << "Multiple unique matches found:" << std::endl;
    for (const std::string& entry : results) {
      ss << "  " << entry;
    }
    return absl::InternalError(ss.str());
  }
  if (results.size() <= 0) {
    return false;
  }

  Entries::iterator it = entries_.find(results[0]);
  if (it == entries_.end()) {
    return absl::InternalError("No matching entry for selector result.");
  }
  return RE2::FullMatch(query, *it->second);
}
