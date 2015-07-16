// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/test/launcher/test_result.h"

#include "base/logging.h"

namespace base {

TestResult::TestResult() : status(TEST_UNKNOWN) {
}

TestResult::~TestResult() {
}

std::string TestResult::StatusAsString() const {
  switch (status) {
    case TEST_UNKNOWN:
      return "UNKNOWN";
    case TEST_SUCCESS:
      return "SUCCESS";
    case TEST_FAILURE:
      return "FAILURE";
    case TEST_FAILURE_ON_EXIT:
      return "FAILURE_ON_EXIT";
    case TEST_CRASH:
      return "CRASH";
    case TEST_TIMEOUT:
      return "TIMEOUT";
    case TEST_SKIPPED:
      return "SKIPPED";
     // Rely on compiler warnings to ensure all possible values are handled.
  }

  NOTREACHED();
  return std::string();
}

std::string TestResult::GetTestName() const {
  size_t dot_pos = full_name.find('.');
  CHECK_NE(dot_pos, std::string::npos);
  return full_name.substr(dot_pos + 1);
}

std::string TestResult::GetTestCaseName() const {
  size_t dot_pos = full_name.find('.');
  CHECK_NE(dot_pos, std::string::npos);
  return full_name.substr(0, dot_pos);
}

}  // namespace base
