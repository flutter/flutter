// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/public/cpp/test_support/test_support.h"

#include <stdlib.h>

namespace mojo {
namespace test {

std::vector<std::string> EnumerateSourceRootRelativeDirectory(
    const std::string& relative_path) {
  char** names = MojoTestSupportEnumerateSourceRootRelativeDirectory(
      relative_path.c_str());
  std::vector<std::string> results;
  for (char** ptr = names; *ptr != nullptr; ++ptr) {
    results.push_back(*ptr);
    free(*ptr);
  }
  free(names);
  return results;
}

}  // namespace test
}  // namespace mojo
