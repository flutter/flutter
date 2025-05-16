// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TOOLS_LICENSES_CPP_SRC_LICENSE_CHECKER_H_
#define FLUTTER_TOOLS_LICENSES_CPP_SRC_LICENSE_CHECKER_H_

#include <string_view>

class LicenseChecker {
 public:
  static const char* kHeaderLicenseRegex;
  static int Run(std::string_view working_dir, std::string_view data_dir);
};

#endif  // FLUTTER_TOOLS_LICENSES_CPP_SRC_LICENSE_CHECKER_H_
