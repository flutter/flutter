// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/tools/licenses_cpp/src/catalog.h"

#include <fstream>

namespace fs = std::filesystem;

namespace {
bool Overlaps(std::string_view a, std::string_view b) {
  const char* const start1 = a.data();
  const char* const end1 = start1 + a.size();
  const char* const start2 = b.data();
  const char* const end2 = start2 + b.size();

  return start1 < end2 && start2 < end1;
}
}  // namespace

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

absl::StatusOr<std::vector<Catalog::Match>> Catalog::FindMatch(
    std::string_view query) const {
  std::vector<int> selector_results;
  if (!selector_.Match(query, &selector_results)) {
    return absl::NotFoundError("Selector didn't match.");
  }

  std::vector<Catalog::Match> results;
  std::vector<int> missed_results;
  missed_results.reserve(selector_results.size());
  std::vector<int> hit_results;
  hit_results.reserve(selector_results.size());
  for (int selector_result : selector_results) {
    RE2* matcher = matchers_[selector_result].get();
    std::string_view match_text;
    if (matcher->Match(query, 0, query.length(), RE2::Anchor::UNANCHORED,
                       &match_text,
                       /*nsubmatch=*/1)) {
      results.emplace_back(Match{.matcher = names_[selector_result],
                                 .matched_text = match_text});
      hit_results.push_back(selector_result);
    } else {
      missed_results.push_back(selector_result);
    }
  }
  if (selector_results.size() != results.size()) {
    std::stringstream missed;
    for (size_t i = 0; i < missed_results.size(); ++i) {
      if (i != 0) {
        missed << ", ";
      }
      missed << names_[missed_results[i]];
    }
    std::stringstream hit;
    hit << " Hit matcher(s): (";
    for (size_t i = 0; i < hit_results.size(); ++i) {
      if (i != 0) {
        hit << ", ";
      }
      hit << names_[hit_results[i]];
    }
    hit << ")";
    return absl::NotFoundError(
        absl::StrCat("Selected matcher(s) (", missed.str(), ") didn't match.",
                     hit_results.empty() ? "" : hit.str()));
  } else {
    for (size_t i = 0; i < results.size(); ++i) {
      for (size_t j = i + 1; j < results.size(); ++j) {
        if (Overlaps(results[i].matched_text, results[j].matched_text)) {
          return absl::InvalidArgumentError(
              absl::StrCat("Selected matchers overlap (", results[i].matcher,
                           ", ", results[j].matcher, ")."));
        }
      }
    }

    return results;
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
