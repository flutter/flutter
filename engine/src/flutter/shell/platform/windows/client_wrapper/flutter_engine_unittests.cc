// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <memory>
#include <string>

#include "flutter/shell/platform/windows/client_wrapper/include/flutter/flutter_engine.h"
#include "flutter/shell/platform/windows/client_wrapper/testing/stub_flutter_windows_api.h"
#include "gtest/gtest.h"

namespace flutter {

namespace {

// Stub implementation to validate calls to the API.
class TestFlutterWindowsApi : public testing::StubFlutterWindowsApi {
 public:
  // |flutter::testing::StubFlutterWindowsApi|
  FlutterDesktopEngineRef RunEngine(
      const FlutterDesktopEngineProperties& properties) override {
    run_called_ = true;
    return reinterpret_cast<FlutterDesktopEngineRef>(1);
  }

  // |flutter::testing::StubFlutterWindowsApi|
  uint64_t ProcessMessages() override { return 99; }

  // |flutter::testing::StubFlutterWindowsApi|
  bool ShutDownEngine() override {
    shut_down_called_ = true;
    return true;
  }

  bool run_called() { return run_called_; }

  bool shut_down_called() { return shut_down_called_; }

 private:
  bool run_called_ = false;
  bool shut_down_called_ = false;
};

}  // namespace

TEST(FlutterEngineTest, CreateDestroy) {
  testing::ScopedStubFlutterWindowsApi scoped_api_stub(
      std::make_unique<TestFlutterWindowsApi>());
  auto test_api = static_cast<TestFlutterWindowsApi*>(scoped_api_stub.stub());
  {
    FlutterEngine engine(DartProject(L"fake/project/path"));
    engine.Run();
    EXPECT_EQ(test_api->run_called(), true);
    EXPECT_EQ(test_api->shut_down_called(), false);
  }
  // Destroying should implicitly shut down if it hasn't been done manually.
  EXPECT_EQ(test_api->shut_down_called(), true);
}

TEST(FlutterEngineTest, ExplicitShutDown) {
  testing::ScopedStubFlutterWindowsApi scoped_api_stub(
      std::make_unique<TestFlutterWindowsApi>());
  auto test_api = static_cast<TestFlutterWindowsApi*>(scoped_api_stub.stub());

  FlutterEngine engine(DartProject(L"fake/project/path"));
  engine.Run();
  EXPECT_EQ(test_api->run_called(), true);
  EXPECT_EQ(test_api->shut_down_called(), false);
  engine.ShutDown();
  EXPECT_EQ(test_api->shut_down_called(), true);
}

TEST(FlutterEngineTest, ProcessMessages) {
  testing::ScopedStubFlutterWindowsApi scoped_api_stub(
      std::make_unique<TestFlutterWindowsApi>());
  auto test_api = static_cast<TestFlutterWindowsApi*>(scoped_api_stub.stub());

  FlutterEngine engine(DartProject(L"fake/project/path"));
  engine.Run();

  std::chrono::nanoseconds next_event_time = engine.ProcessMessages();
  EXPECT_EQ(next_event_time.count(), 99);
}

}  // namespace flutter
