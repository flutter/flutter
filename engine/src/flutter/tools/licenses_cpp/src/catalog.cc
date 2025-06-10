// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/tools/licenses_cpp/src/catalog.h"

absl::StatusOr<Catalog> Catalog::Open(std::string_view data_dir) {
  return absl::UnimplementedError("");
}

absl::StatusOr<Catalog> Catalog::Make(
    const std::vector<std::vector<std::string_view>>& entries) {
  RE2::Set selector(RE2::Options(), RE2::Anchor::UNANCHORED);
  std::vector<std::unique_ptr<RE2>> matchers;
  std::vector<std::string> names;

  for (const std::vector<std::string_view>& entry : entries) {
    if (entry.size() != 3) {
      return absl::InvalidArgumentError("Entry doesn't have 3 items");
    }
    std::string err;
    names.push_back(std::string(entry[0]));
    int idx = selector.Add(entry[1], &err);
    if (idx < 0) {
      return absl::InvalidArgumentError(
          absl::StrCat("Unable to add set entry: ", entry[1], " ", err));
    }
    matchers.push_back(std::make_unique<RE2>(entry[2]));
  }

  bool did_compile = selector.Compile();
  if (!did_compile) {
    return absl::OutOfRangeError("RE2::Set ran out of memory.");
  }
  return Catalog(std::move(selector), std::move(matchers), std::move(names));
}

Catalog::Catalog(RE2::Set selector,
                 std::vector<std::unique_ptr<RE2>> matchers,
                 std::vector<std::string> names)
    : selector_(std::move(selector)),
      matchers_(std::move(matchers)),
      names_(std::move(names)) {}

absl::StatusOr<std::string> Catalog::FindMatch(std::string_view query) {
  std::vector<int> selector_results;
  if (!selector_.Match(query, &selector_results)) {
    return absl::NotFoundError("Selector didn't match.");
  }
  if (selector_results.size() > 1) {
    std::stringstream ss;
    ss << "Multiple unique matches found:" << std::endl;
    for (int idx : selector_results) {
      ss << "  " << names_[idx] << std::endl;
    }
    return absl::InvalidArgumentError(ss.str());
  }

  if (selector_results.size() == 1 &&
      RE2::FullMatch(query, *matchers_[selector_results[0]])) {
    return names_[selector_results[0]];
  } else {
    return absl::NotFoundError("Selection didn't match.");
  }
}
