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
    return app.GetPackageId().rfind(L"Microsoft.", 0);
  });
  EXPECT_TRUE(ms_pos != apps.end());
}

}  // namespace testing
}  // namespace flutter
