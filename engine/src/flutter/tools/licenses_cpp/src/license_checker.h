// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TOOLS_LICENSES_CPP_SRC_LICENSE_CHECKER_H_
#define FLUTTER_TOOLS_LICENSES_CPP_SRC_LICENSE_CHECKER_H_

#include <iosfwd>
#include <string_view>
#include <vector>
#include "flutter/tools/licenses_cpp/src/data.h"
#include "third_party/abseil-cpp/absl/status/status.h"

class LicenseChecker {
 public:
  struct Flags {
    bool treat_unmatched_comments_as_errors = false;
    std::optional<std::string> root_package_name;
  };

  static const char* kHeaderLicenseRegex;
  static std::vector<absl::Status> Run(std::string_view working_dir,
                                       std::ostream& licenses,
                                       const Data& data);
  static std::vector<absl::Status> Run(std::string_view working_dir,
                                       std::ostream& licenses,
                                       const Data& data,
                                       const Flags& flags);
  static int Run(std::string_view working_dir,
                 std::ostream& licenses,
                 std::string_view data_dir,
                 const Flags& flags);
  /// Run on a single file.
  static int FileRun(std::string_view working_dir,
                     std::string_view full_path,
                     std::ostream& licenses,
                     std::string_view data_dir,
                     const Flags& flags);
};

#endif  // FLUTTER_TOOLS_LICENSES_CPP_SRC_LICENSE_CHECKER_H_
