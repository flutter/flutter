// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_TESTING_GOLDEN_DIGEST_MANAGER_H_
#define FLUTTER_IMPELLER_TESTING_GOLDEN_DIGEST_MANAGER_H_

#include <map>
#include <string>
#include <vector>

namespace impeller {
namespace testing {

/// Manages a global variable for tracking a directory containing
/// instances of golden images.
class GoldenDigestManager {
 public:
  /// Constructs a GoldenDigest that will accumulate golden image filenames
  /// and Dimension key/value pairs for the specified working directory and
  /// write them to a file named "digest.json" in that directory when
  /// |Write| is called.
  explicit GoldenDigestManager(const std::string& working_directory);

  ~GoldenDigestManager();

  const std::string& GetWorkingDirectory() const;

  std::string GetFullPath(const std::string& filename) const;

  void AddDimension(const std::string& name, const std::string& value);

  void AddImage(const std::string& test_name,
                const std::string& golden_filename,
                int32_t width,
                int32_t height);

  /// Writes a "digest.json" file to the working directory.
  ///
  /// (Failing to call either this method or the |ClearDigestData| method
  /// causes a warning to be written to the console about unwritten data
  /// left in the digest manater.)
  ///
  /// Returns `true` on success.
  bool Write();

  /// Clears all accumulated dimension and golden image data if the digest
  /// should not be written.
  ///
  /// (Failing to call either this method or the |Write| method causes
  /// a warning to be written to the console about unwritten data left
  /// in the digest manater.)
  void ClearDigestData();

 private:
  GoldenDigestManager(const GoldenDigestManager&) = delete;

  GoldenDigestManager& operator=(const GoldenDigestManager&) = delete;

  struct Entry {
    std::string test_name;
    std::string filename;
    int32_t width;
    int32_t height;
    double max_diff_pixels_percent;
    int32_t max_color_delta;
  };

  std::string working_directory_;
  std::vector<Entry> entries_;
  std::map<std::string, std::string> dimensions_;
  size_t entries_written_ = 0u;
  size_t dimensions_written_ = 0u;
};

}  // namespace testing
}  // namespace impeller

#endif  // FLUTTER_IMPELLER_TESTING_GOLDEN_DIGEST_MANAGER_H_
