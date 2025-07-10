// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/tools/licenses_cpp/src/catalog.h"

#include <fstream>

namespace fs = std::filesystem;

absl::StatusOr<Catalog> Catalog::Open(std::string_view data_dir) {
  fs::path data_dir_path(data_dir);
  if (!fs::exists(data_dir_path)) {
    return absl::InvalidArgumentError(
        absl::StrCat("Data directory doesn't exist ", data_dir));
  }
  fs::path licenses_path = data_dir_path / "licenses";
  if (!fs::exists(licenses_path)) {
    return absl::InvalidArgumentError(absl::StrCat(
        "Licenses directory doesn't exist ", licenses_path.string()));
  }

  RE2::Set selector(RE2::Options(), RE2::Anchor::UNANCHORED);
  std::vector<std::unique_ptr<RE2>> matchers;
  std::vector<std::string> names;

  for (const fs::path& file : fs::directory_iterator(licenses_path)) {
    std::ifstream infile(file.string());
    if (!infile.good()) {
      return absl::InvalidArgumentError("Unable to open file " + file.string());
    }

    absl::StatusOr<Entry> entry = ParseEntry(infile);
    if (!entry.ok()) {
      return absl::InvalidArgumentError(
          absl::StrCat("Unable to parse data entry at ", file.string(), " : ",
                       entry.status()));
    }

    std::string err;
    selector.Add(entry->unique, &err);
    if (!err.empty()) {
      return absl::InvalidArgumentError(absl::StrCat(
          "Unable to add unique key from ", file.string(), " : ", err));
    }
    names.emplace_back(std::move(entry->name));

    auto matcher_re2 = std::make_unique<RE2>(entry->matcher);
    if (!matcher_re2) {
      return absl::InvalidArgumentError("Unable to make matcher.");
    }

    matchers.emplace_back(std::move(matcher_re2));
  }

  bool did_compile = selector.Compile();
  if (!did_compile) {
    return absl::UnknownError("Unable to compile selector.");
  }

  return Catalog(std::move(selector), std::move(matchers), std::move(names));
}

absl::StatusOr<Catalog> Catalog::Make(const std::vector<Entry>& entries) {
  RE2::Set selector(RE2::Options(), RE2::Anchor::UNANCHORED);
  std::vector<std::unique_ptr<RE2>> matchers;
  std::vector<std::string> names;

  for (const Entry& entry : entries) {
    std::string err;
    names.push_back(std::string(entry.name));
    int idx = selector.Add(entry.unique, &err);
    if (idx < 0) {
      return absl::InvalidArgumentError(
          absl::StrCat("Unable to add set entry: ", entry.unique, " ", err));
    }
    matchers.push_back(std::make_unique<RE2>(entry.matcher));
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

absl::StatusOr<Catalog::Match> Catalog::FindMatch(
    std::string_view query) const {
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

  std::string_view match_text;
  RE2* matcher = matchers_[selector_results[0]].get();
  if (selector_results.size() == 1 &&
      matcher->Match(query, 0, query.length(), RE2::Anchor::UNANCHORED,
                     &match_text,
                     /*nsubmatch=*/1)) {
    return Match{.matcher = names_[selector_results[0]],
                 .matched_text = match_text};
  } else {
    return absl::NotFoundError(absl::StrCat(
        "Selected matcher (", names_[selector_results[0]], ") didn't match."));
  }
}

absl::StatusOr<Catalog::Entry> Catalog::ParseEntry(std::istream& is) {
  if (!is.good()) {
    return absl::InvalidArgumentError("Bad stream.");
  }
  std::string name;
  std::getline(is, name);
  if (is.eof()) {
    return absl::InvalidArgumentError("Bad stream.");
  }
  std::string unique;
  std::getline(is, unique);
  if (is.eof()) {
    return absl::InvalidArgumentError("Bad stream.");
  }

  std::string matcher_text((std::istreambuf_iterator<char>(is)),
                           std::istreambuf_iterator<char>());

  return Catalog::Entry{.name = std::move(name),
                        .unique = std::move(unique),
                        .matcher = std::move(matcher_text)};
}
