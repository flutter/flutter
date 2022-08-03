// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/public/flutter_windows.h"

#include <cstring>

#include "gtest/gtest.h"

namespace flutter {

TEST(FlutterWindowsTest, GetTextureRegistrar) {
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

}  // namespace flutter
