// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef TESTING_TESTING_H_
#define TESTING_TESTING_H_

#include <string>

#include "flutter/fml/file.h"
#include "flutter/testing/assertions.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

// Returns the directory containing the test fixture for the target if this
// target has fixtures configured. If there are no fixtures, this is a link
// error.
const char* GetFixturesPath();

fml::UniqueFD OpenFixturesDirectory();

fml::UniqueFD OpenFixture(std::string fixture_name);

std::string GetCurrentTestName();

}  // namespace testing
}  // namespace flutter

#endif  // TESTING_TESTING_H_
