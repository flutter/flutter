// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include <string>
#include <vector>

#include "embedder.h"
#include "flutter/shell/platform/embedder/tests/embedder_assertions.h"
#include "flutter/shell/platform/embedder/tests/embedder_config_builder.h"
#include "flutter/shell/platform/embedder/tests/embedder_test.h"
#include "flutter/shell/platform/embedder/tests/embedder_test_context_gl.h"
#include "flutter/shell/platform/embedder/tests/embedder_unittests_util.h"
#include "flutter/testing/assertions_skia.h"
#include "flutter/testing/testing.h"

namespace flutter {
namespace testing {

using EmbedderTest = testing::EmbedderTest;

TEST_F(EmbedderTest, CanRenderGradientWithMetal) {
  auto& context = GetEmbedderContext(EmbedderTestContextType::kMetalContext);

  EmbedderConfigBuilder builder(context);

  builder.SetDartEntrypoint("render_gradient");
  builder.SetMetalRendererConfig(SkISize::Make(800, 600));

  auto rendered_scene = context.GetNextSceneImage();

  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());

  // Send a window metrics events so frames may be scheduled.
  FlutterWindowMetricsEvent event = {};
  event.struct_size = sizeof(event);
  event.width = 800;
  event.height = 600;
  event.pixel_ratio = 1.0;
  ASSERT_EQ(FlutterEngineSendWindowMetricsEvent(engine.get(), &event),
            kSuccess);

  // TODO (https://github.com/flutter/flutter/issues/73590): re-enable once
  // we are able to figure out why this fails on the bots.
  // ASSERT_TRUE(ImageMatchesFixture("gradient_metal.png", rendered_scene));
}

}  // namespace testing
}  // namespace flutter
