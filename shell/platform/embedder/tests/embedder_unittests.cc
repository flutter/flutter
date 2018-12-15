// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <string>
#include "embedder.h"
#include "flutter/testing/testing.h"

TEST(EmbedderTest, MustNotRunWithInvalidArgs) {
  FlutterEngine engine = nullptr;
  FlutterRendererConfig config = {};
  FlutterProjectArgs args = {};
  FlutterResult result = FlutterEngineRun(FLUTTER_ENGINE_VERSION + 1, &config,
                                          &args, NULL, &engine);
  ASSERT_NE(result, FlutterResult::kSuccess);
}

TEST(EmbedderTest, CanLaunchAndShutdownWithValidProjectArgs) {
  FlutterSoftwareRendererConfig renderer;
  renderer.struct_size = sizeof(FlutterSoftwareRendererConfig);
  renderer.surface_present_callback = [](void*, const void*, size_t, size_t) {
    return false;
  };

  FlutterRendererConfig config = {};
  config.type = FlutterRendererType::kSoftware;
  config.software = renderer;

  FlutterProjectArgs args = {};
  args.struct_size = sizeof(FlutterProjectArgs);
  args.assets_path = testing::GetFixturesPath();
  args.main_path = "";
  args.packages_path = "";

  FlutterEngine engine = nullptr;
  FlutterResult result = FlutterEngineRun(FLUTTER_ENGINE_VERSION, &config,
                                          &args, nullptr, &engine);
  ASSERT_EQ(result, FlutterResult::kSuccess);

  result = FlutterEngineShutdown(engine);
  ASSERT_EQ(result, FlutterResult::kSuccess);
}
