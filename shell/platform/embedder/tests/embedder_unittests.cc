// Copyright 2017 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "embedder.h"
#include "gtest/gtest.h"

TEST(EmbedderTest, MustNotRunWithInvalidArgs) {
  FlutterEngine engine = nullptr;
  FlutterRendererConfig config = {};
  FlutterProjectArgs args = {};
  auto result = FlutterEngineRun(FLUTTER_ENGINE_VERSION + 1, &config, &args,
                                 NULL, &engine);
  ASSERT_NE(result, kSuccess);
}
