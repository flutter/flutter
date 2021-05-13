// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/uwptool_utils.h"

#include <algorithm>
#include <iostream>
#include <string>
#include <vector>

#include "gtest/gtest.h"

namespace flutter {
namespace testing {

// TODO(cbracken): write registry values to be tested, then cleanup, refactor
// to support a mock registry.
// https://github.com/flutter/flutter/issues/82095

// Verify that at least one Microsoft app (e.g. Microsoft.WindowsCalculator) is
// installed and can be found.
TEST(ApplicationStore, GetApps) {
  ApplicationStore store;
  std::vector<Application> apps = store.GetApps();
  EXPECT_FALSE(apps.empty());

  auto ms_pos = std::find_if(apps.begin(), apps.end(), [](const auto& app) {
    return app.GetPackageFamily().rfind(L"Microsoft.", 0);
  });
  EXPECT_TRUE(ms_pos != apps.end());
}

// Verify that we can look up an app by family name.
TEST(ApplicationStore, GetAppsByPackageFamily) {
  ApplicationStore store;
  std::vector<Application> all_apps = store.GetApps();
  EXPECT_FALSE(all_apps.empty());

  Application app = all_apps[0];
  std::vector<Application> found_apps = store.GetApps(app.GetPackageFamily());
  ASSERT_FALSE(found_apps.empty());
  for (const Application& found_app : found_apps) {
    EXPECT_EQ(found_app.GetPackageName(), app.GetPackageName());
    EXPECT_EQ(found_app.GetPackageFamily(), app.GetPackageFamily());
  }
}

}  // namespace testing
}  // namespace flutter
