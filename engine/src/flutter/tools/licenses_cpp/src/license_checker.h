// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <string_view>

class LicenseChecker {
 public:
  static int Run(std::string_view working_dir, std::string_view data_dir);
};
