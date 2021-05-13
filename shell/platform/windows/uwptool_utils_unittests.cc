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
TEST(ApplicationStore, GetInstalledApplications) {
  ApplicationStore app_store;
  std::vector<Application> apps = app_store.GetInstalledApplications();
  EXPECT_FALSE(apps.empty());

  auto ms_pos = std::find_if(apps.begin(), apps.end(), [](const auto& app) {
    return app.GetPackageFamily().rfind(L"Microsoft.", 0);
  });
  EXPECT_TRUE(ms_pos != apps.end());
}

// Verify that we can look up an app by family name.
TEST(ApplicationStore, GetInstalledApplication) {
  ApplicationStore app_store;
  std::vector<Application> apps = app_store.GetInstalledApplications();
  EXPECT_FALSE(apps.empty());

  std::optional<Application> found_app =
      app_store.GetInstalledApplication(apps[0].GetPackageFamily());
  ASSERT_TRUE(found_app != std::nullopt);
  EXPECT_EQ(found_app->GetPackageFamily(), apps[0].GetPackageFamily());
  EXPECT_EQ(found_app->GetPackageFullName(), apps[0].GetPackageFullName());
}

}  // namespace testing
}  // namespace flutter
