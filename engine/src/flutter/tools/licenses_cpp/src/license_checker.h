// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TOOLS_LICENSES_CPP_SRC_LICENSE_CHECKER_H_
#define FLUTTER_TOOLS_LICENSES_CPP_SRC_LICENSE_CHECKER_H_

#include <iosfwd>
#include <string_view>
#include <vector>
#include "flutter/third_party/abseil-cpp/absl/status/status.h"
#include "flutter/tools/licenses_cpp/src/data.h"

class LicenseChecker {
 public:
  static const char* kHeaderLicenseRegex;
  static std::vector<absl::Status> Run(std::string_view working_dir,
                                       std::ostream& licenses,
                                       const Data& data);
  static int Run(std::string_view working_dir,
                 std::ostream& licenses,
                 std::string_view data_dir);
};

#endif  // FLUTTER_TOOLS_LICENSES_CPP_SRC_LICENSE_CHECKER_H_
