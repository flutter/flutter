// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/tools/licenses_cpp/src/catalog.h"

absl::StatusOr<Catalog> Catalog::Open(std::string_view data_dir) {
  return absl::UnimplementedError("");
}

absl::StatusOr<Catalog> Catalog::Make(
    std::vector<std::pair<std::string_view, std::string_view>> entries) {
  RE2::Set selector(RE2::Options(), RE2::Anchor::UNANCHORED);
  std::vector<std::unique_ptr<RE2>> matchers;
  std::vector<std::string> selector_pieces;

  for (const std::pair<std::string_view, std::string_view>& entry : entries) {
    std::string err;
    int idx = selector.Add(entry.first, &err);
    selector_pieces.push_back(std::string(entry.first));
    if (idx < 0) {
      return absl::InvalidArgumentError(
          absl::StrCat("Unable to add set entry: ", entry.first, " ", err));
    }
    matchers.push_back(std::make_unique<RE2>(entry.second));
  }

  bool did_compile = selector.Compile();
  if (!did_compile) {
    return absl::OutOfRangeError("RE2::Set ran out of memory.");
  }
  return Catalog(std::move(selector), std::move(matchers),
                 std::move(selector_pieces));
}

Catalog::Catalog(RE2::Set selector,
                 std::vector<std::unique_ptr<RE2>> matchers,
                 std::vector<std::string> selector_pieces)
    : selector_(std::move(selector)),
      matchers_(std::move(matchers)),
      selector_pieces_(std::move(selector_pieces)) {}

absl::StatusOr<bool> Catalog::HasMatch(std::string_view query) {
  std::vector<int> selector_results;
  if (!selector_.Match(query, &selector_results)) {
    return false;
  }
  if (selector_results.size() > 1) {
    std::stringstream ss;
    ss << "Multiple unique matches found:" << std::endl;
    for (int idx : selector_results) {
      ss << "  " << selector_pieces_[idx] << std::endl;
    }
    return absl::InternalError(ss.str());
  }
  if (selector_results.size() <= 0) {
    return false;
  }

  return RE2::FullMatch(query, *matchers_[selector_results[0]]);
}
