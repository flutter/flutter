// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/public/flutter_windows.h"

#include <cstring>
#include <thread>

#include "flutter/shell/platform/windows/testing/windows_test.h"
#include "flutter/shell/platform/windows/testing/windows_test_config_builder.h"
#include "flutter/shell/platform/windows/testing/windows_test_context.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

TEST(WindowsNoFixtureTest, GetTextureRegistrar) {
  FlutterDesktopEngineProperties properties;
  memset(&properties, 0, sizeof(FlutterDesktopEngineProperties));
  properties.assets_path = L"";
  properties.icu_data_path = L"icudtl.dat";
  auto engine = FlutterDesktopEngineCreate(&properties);
  ASSERT_NE(engine, nullptr);
  auto texture_registrar = FlutterDesktopEngineGetTextureRegistrar(engine);
  EXPECT_NE(texture_registrar, nullptr);
  FlutterDesktopEngineDestroy(engine);
}

TEST_F(WindowsTest, LaunchMain) {
  auto& context = GetContext();
  WindowsConfigBuilder builder(context);
  ViewControllerPtr controller{builder.LaunchEngine()};
  ASSERT_NE(controller, nullptr);

  // Run for 1 second, then shut down.
  //
  // TODO(cbracken): Support registring a native function we can use to
  // determine that execution has made it to a specific point in the Dart
  // code. https://github.com/flutter/flutter/issues/109242
  std::this_thread::sleep_for(std::chrono::seconds(1));
}

}  // namespace testing
}  // namespace flutter
