// Copyright 2017 The Flutter Authors. All rights reserved.
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
  FlutterOpenGLRendererConfig renderer = {
      .struct_size = sizeof(FlutterOpenGLRendererConfig),
      .make_current = [](void*) { return false; },
      .clear_current = [](void*) { return false; },
      .present = [](void*) { return false; },
      .fbo_callback = [](void*) -> uint32_t { return 0; },
  };

  std::string main =
      std::string(testing::GetFixturesPath()) + "/simple_main.dart";

  FlutterRendererConfig config = {.type = FlutterRendererType::kOpenGL,
                                  .open_gl = renderer};
  FlutterProjectArgs args = {.struct_size = sizeof(FlutterProjectArgs),
                             .assets_path = "",
                             .main_path = main.c_str(),
                             .packages_path = ""};
  FlutterEngine engine = nullptr;
  FlutterResult result = FlutterEngineRun(FLUTTER_ENGINE_VERSION, &config,
                                          &args, nullptr, &engine);
  ASSERT_EQ(result, FlutterResult::kSuccess);

  result = FlutterEngineShutdown(engine);
  ASSERT_EQ(result, FlutterResult::kSuccess);
}
