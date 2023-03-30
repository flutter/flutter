// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/golden_tests/golden_digest.h"

#include <fstream>

namespace impeller {
namespace testing {

GoldenDigest* GoldenDigest::instance_ = nullptr;

GoldenDigest* GoldenDigest::Instance() {
  if (!instance_) {
    instance_ = new GoldenDigest();
  }
  return instance_;
}

GoldenDigest::GoldenDigest() {}

void GoldenDigest::AddImage(const std::string& test_name,
                            const std::string& filename,
                            int32_t width,
                            int32_t height) {
  entries_.push_back({test_name, filename, width, height});
}

bool GoldenDigest::Write(WorkingDirectory* working_directory) {
  std::ofstream fout;
  fout.open(working_directory->GetFilenamePath("digest.json"));
  if (!fout.good()) {
    return false;
  }

  fout << "[" << std::endl;
  bool is_first = true;
  for (const auto& entry : entries_) {
    if (!is_first) {
      fout << "," << std::endl;
    }
    is_first = false;

    fout << "  { "
         << "\"testName\" : \"" << entry.test_name << "\", "
         << "\"filename\" : \"" << entry.filename << "\", "
         << "\"width\" : " << entry.width << ", "
         << "\"height\" : " << entry.height << " "
         << "}";
  }
  fout << std::endl << "]" << std::endl;

  fout.close();
  return true;
}

}  // namespace testing
}  // namespace impeller
