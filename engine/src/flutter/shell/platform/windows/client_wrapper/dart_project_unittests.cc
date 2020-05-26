// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <memory>
#include <string>

#include "flutter/shell/platform/windows/client_wrapper/include/flutter/dart_project.h"
#include "gtest/gtest.h"

namespace flutter {

class DartProjectTest : public ::testing::Test {
 protected:
  // Wrapper for accessing private icu_data_path.
  std::wstring GetProjectIcuDataPath(const DartProject& project) {
    return project.icu_data_path();
  }

  // Wrapper for accessing private assets_path.
  std::wstring GetProjectAssetsPath(const DartProject& project) {
    return project.assets_path();
  }

  // Wrapper for accessing private aot_library_path_.
  std::wstring GetProjectAotLibraryPath(const DartProject& project) {
    return project.aot_library_path();
  }

  // Wrapper for accessing private engine_switches.
  std::vector<std::string> GetProjectEngineSwitches(
      const DartProject& project) {
    return project.engine_switches();
  }
};

TEST_F(DartProjectTest, StandardProjectFormat) {
  DartProject project(L"test");
  EXPECT_EQ(GetProjectIcuDataPath(project), L"test\\icudtl.dat");
  EXPECT_EQ(GetProjectAssetsPath(project), L"test\\flutter_assets");
  EXPECT_EQ(GetProjectAotLibraryPath(project), L"test\\app.so");
}

TEST_F(DartProjectTest, Switches) {
  DartProject project(L"test");
  std::vector<std::string> switches = {"--foo", "--bar"};
  project.SetEngineSwitches(switches);
  EXPECT_EQ(GetProjectEngineSwitches(project).size(), 2);
  EXPECT_EQ(GetProjectEngineSwitches(project)[0], "--foo");
}

}  // namespace flutter
