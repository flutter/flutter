// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/impeller/testing/golden_digest_manager.h"

#include <fstream>
#include <sstream>

#include "flutter/fml/logging.h"
#include "flutter/fml/paths.h"

static const double kMaxDiffPixelsPercent = 0.01;
static const int32_t kMaxColorDelta = 8;

namespace impeller {
namespace testing {

GoldenDigestManager::GoldenDigestManager(
    const std::string& working_directory_path)
    : working_directory_(working_directory_path) {}

GoldenDigestManager::~GoldenDigestManager() {
  if (entries_written_ < entries_.size() ||
      dimensions_written_ < dimensions_.size()) {
    FML_LOG(WARNING)                                  //
        << "golden digest at " << working_directory_  //
        << " incomplete, with only "                  //
        << dimensions_written_ << " out of "          //
        << dimensions_.size() << " dimensions "       //
        << "and "                                     //
        << entries_written_ << " out of "             //
        << entries_.size() << " image entries"        //
        << " written";
  }
}

const std::string& GoldenDigestManager::GetWorkingDirectory() const {
  return working_directory_;
}

std::string GoldenDigestManager::GetFullPath(
    const std::string& filename) const {
  return fml::paths::JoinPaths({working_directory_, filename});
}

void GoldenDigestManager::AddDimension(const std::string& name,
                                       const std::string& value) {
  std::stringstream ss;
  ss << "\"" << value << "\"";
  dimensions_[name] = ss.str();
}

void GoldenDigestManager::AddImage(const std::string& test_name,
                                   const std::string& filename,
                                   int32_t width,
                                   int32_t height) {
  entries_.push_back({test_name, filename, width, height, kMaxDiffPixelsPercent,
                      kMaxColorDelta});
}

bool GoldenDigestManager::Write() {
  std::ofstream fout;
  fout.open(GetFullPath("digest.json"));
  if (!fout.good()) {
    return false;
  }

  // If we wrote some stuff before, this will be an update on top of that
  // work, rewriting the file again from the beginning. This allows test
  // suites to defensively write the digest after every group of tests.
  dimensions_written_ = 0u;
  entries_written_ = 0u;

  fout << "{" << std::endl;
  fout << "  \"dimensions\": {" << std::endl;
  bool is_first = true;
  for (const auto& dimension : dimensions_) {
    if (!is_first) {
      fout << "," << std::endl;
    }
    is_first = false;
    fout << "    \"" << dimension.first << "\": " << dimension.second;
    dimensions_written_++;
  }
  fout << std::endl << "  }," << std::endl;
  fout << "  \"entries\":" << std::endl;

  fout << "  [" << std::endl;
  is_first = true;
  for (const auto& entry : entries_) {
    if (!is_first) {
      fout << "," << std::endl;
    }
    is_first = false;

    fout << "    { " << "\"testName\" : \"" << entry.test_name << "\", "
         << "\"filename\" : \"" << entry.filename << "\", "
         << "\"width\" : " << entry.width << ", "
         << "\"height\" : " << entry.height << ", ";

    if (entry.max_diff_pixels_percent ==
        static_cast<int64_t>(entry.max_diff_pixels_percent)) {
      fout << "\"maxDiffPixelsPercent\" : " << entry.max_diff_pixels_percent
           << ".0, ";
    } else {
      fout << "\"maxDiffPixelsPercent\" : " << entry.max_diff_pixels_percent
           << ", ";
    }

    fout << "\"maxColorDelta\":" << entry.max_color_delta << " ";
    fout << "}";
    entries_written_++;
  }
  fout << std::endl << "  ]" << std::endl;

  fout << "}" << std::endl;

  fout.close();
  return true;
}

void GoldenDigestManager::ClearDigestData() {
  dimensions_.clear();
  entries_.clear();

  dimensions_written_ = 0u;
  entries_written_ = 0u;
}

}  // namespace testing
}  // namespace impeller
