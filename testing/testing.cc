// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "testing.h"

#include "flutter/fml/file.h"

namespace flutter {
namespace testing {

std::string GetCurrentTestName() {
  return ::testing::UnitTest::GetInstance()->current_test_info()->name();
}

fml::UniqueFD OpenFixturesDirectory() {
  auto fixtures_directory =
      OpenDirectory(GetFixturesPath(),          // path
                    false,                      // create
                    fml::FilePermission::kRead  // permission
      );

  if (!fixtures_directory.is_valid()) {
    FML_LOG(ERROR) << "Could not open fixtures directory.";
    return {};
  }
  return fixtures_directory;
}

fml::UniqueFD OpenFixture(std::string fixture_name) {
  if (fixture_name.size() == 0) {
    FML_LOG(ERROR) << "Invalid fixture name.";
    return {};
  }

  auto fixtures_directory = OpenFixturesDirectory();

  auto fixture_fd = fml::OpenFile(fixtures_directory,         // base directory
                                  fixture_name.c_str(),       // path
                                  false,                      // create
                                  fml::FilePermission::kRead  // permission
  );
  if (!fixture_fd.is_valid()) {
    FML_LOG(ERROR) << "Could not open fixture for path: " << GetFixturesPath()
                   << "/" << fixture_name << ".";
    return {};
  }

  return fixture_fd;
}

}  // namespace testing
}  // namespace flutter
