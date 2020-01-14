// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <memory>
#include <string>

#include "flutter/shell/platform/windows/client_wrapper/include/flutter/flutter_view_controller.h"
#include "flutter/shell/platform/windows/client_wrapper/testing/stub_flutter_windows_api.h"
#include "gtest/gtest.h"

namespace flutter {

namespace {

// Stub implementation to validate calls to the API.
class TestWindowsApi : public testing::StubFlutterWindowsApi {
  FlutterDesktopViewControllerRef CreateViewController(
      int initial_width,
      int initial_height,
      const char* assets_path,
      const char* icu_data_path,
      const char** arguments,
      size_t argument_count) override {
    return reinterpret_cast<FlutterDesktopViewControllerRef>(1);
  }
};

}  // namespace

TEST(FlutterViewControllerTest, CreateDestroy) {
  testing::ScopedStubFlutterWindowsApi scoped_api_stub(
      std::make_unique<TestWindowsApi>());
  auto test_api = static_cast<TestWindowsApi*>(scoped_api_stub.stub());
  {
    FlutterViewController controller("", 100, 100, "",
                                     std::vector<std::string>{});
  }
}

TEST(FlutterViewControllerTest, GetView) {
  std::string icu_data_path = "fake_path_to_icu";
  testing::ScopedStubFlutterWindowsApi scoped_api_stub(
      std::make_unique<TestWindowsApi>());
  auto test_api = static_cast<TestWindowsApi*>(scoped_api_stub.stub());
  FlutterViewController controller("", 100, 100, "",
                                   std::vector<std::string>{});
  EXPECT_NE(controller.view(), nullptr);
}

}  // namespace flutter
