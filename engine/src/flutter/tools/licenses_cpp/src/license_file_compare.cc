// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <iostream>

#include "flutter/third_party/re2/re2/re2.h"
#include "flutter/tools/licenses_cpp/src/mmap_file.h"
#include "third_party/abseil-cpp/absl/container/flat_hash_set.h"
#include "third_party/abseil-cpp/absl/log/check.h"
#include "third_party/abseil-cpp/absl/log/globals.h"
#include "third_party/abseil-cpp/absl/log/initialize.h"
#include "third_party/abseil-cpp/absl/log/log.h"

namespace {
re2::RE2 copyright_regex = R"regex((?i)copyright(.*\d\d\d\d.*))regex";

absl::flat_hash_set<std::string_view> GetCopyrights(const MMapFile& filemap) {
  std::string_view string_view(filemap.GetData(), filemap.GetSize());
  absl::flat_hash_set<std::string_view> copyrights;
  std::string_view clause;
  while (RE2::FindAndConsume(&string_view, copyright_regex, &clause)) {
    while (!clause.empty() && (clause.back() == '*' || clause.back() == ' ')) {
      clause = std::string_view(clause.data(), clause.size() - 1);
    }
    copyrights.insert(clause);
  }
  return copyrights;
}
}  // namespace

int main(int argc, const char* argv[]) {
  if (argc != 3) {
    std::cerr << "usage: " << argv[0] << " <path> <path>" << std::endl;
    return 1;
  }

  absl::InitializeLog();
  absl::SetStderrThreshold(absl::LogSeverity::kInfo);

  absl::StatusOr<MMapFile> first = MMapFile::Make(argv[1]);
  CHECK(first.ok());
  absl::StatusOr<MMapFile> second = MMapFile::Make(argv[2]);
  CHECK(second.ok());

  absl::flat_hash_set<std::string_view> first_copyrights =
      GetCopyrights(*first);
  absl::flat_hash_set<std::string_view> second_copyrights =
      GetCopyrights(*second);

  LOG(INFO) << "first size: " << first_copyrights.size();
  LOG(INFO) << "second size: " << second_copyrights.size();

  for (std::string_view entry : first_copyrights) {
    if (second_copyrights.find(entry) == second_copyrights.end()) {
      LOG(INFO) << "second missing: " << entry;
    }
  }
  for (std::string_view entry : second_copyrights) {
    if (first_copyrights.find(entry) == first_copyrights.end()) {
      LOG(INFO) << "first missing: " << entry;
    }
  }

  return 0;
}
