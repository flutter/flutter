// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <memory>
#include <string>

#include "flutter/shell/platform/windows/client_wrapper/include/flutter/flutter_window_controller.h"
#include "flutter/shell/platform/windows/client_wrapper/testing/stub_flutter_windows_api.h"
#include "gtest/gtest.h"

namespace flutter {

namespace {

// Stub implementation to validate calls to the API.
class TestWindowsApi : public testing::StubFlutterWindowsApi {
 public:
  // |flutter::testing::StubFlutterWindowsApi|
  bool Init() override {
    init_called_ = true;
    return true;
  }

  // |flutter::testing::StubFlutterWindowsApi|
  void Terminate() override { terminate_called_ = true; }

  bool init_called() { return init_called_; }

  bool terminate_called() { return terminate_called_; }

 private:
  bool init_called_ = false;
  bool terminate_called_ = false;
};

}  // namespace

TEST(FlutterViewControllerTest, CreateDestroy) {
  const std::string icu_data_path = "fake/path/to/icu";
  testing::ScopedStubFlutterWindowsApi scoped_api_stub(
      std::make_unique<TestWindowsApi>());
  auto test_api = static_cast<TestWindowsApi*>(scoped_api_stub.stub());
  {
    FlutterWindowController controller(icu_data_path);
    EXPECT_EQ(test_api->init_called(), true);
    EXPECT_EQ(test_api->terminate_called(), false);
  }
  EXPECT_EQ(test_api->init_called(), true);
  EXPECT_EQ(test_api->terminate_called(), true);
}

}  // namespace flutter
