// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include "flow/layers/layer.h"
#include "flutter/flow/layers/aiks_layer.h"
#include "flutter/flow/layers/layer_tree.h"
#include "flutter/flow/testing/layer_test.h"
#include "impeller/aiks/canvas.h"

namespace flutter {
namespace testing {

using AiksLayerTest = LayerTest;

TEST_F(AiksLayerTest, InfiniteBounds) {
  impeller::Canvas canvas;
  canvas.DrawPaint(impeller::Paint{.color = impeller::Color::Red()});
  auto picture =
      std::make_shared<const impeller::Picture>(canvas.EndRecordingAsPicture());
  AiksLayer layer(SkPoint::Make(0.0f, 0.0f), picture);

  const FixedRefreshRateStopwatch unused_stopwatch;
  LayerStateStack state_stack;
  state_stack.set_preroll_delegate(kGiantRect, SkMatrix::I());
  PrerollContext preroll_context{
      .state_stack = state_stack,
      .raster_time = unused_stopwatch,
      .ui_time = unused_stopwatch,
      .texture_registry = nullptr,
  };
  PaintContext context{
      // clang-format off
      .state_stack                   = state_stack,
      .raster_time                   = unused_stopwatch,
      .ui_time                       = unused_stopwatch,
      .texture_registry              = nullptr,
      // clang-format on
  };

  EXPECT_FALSE(layer.needs_painting(context));
  layer.Preroll(&preroll_context);
  EXPECT_TRUE(layer.needs_painting(context));
}

}  // namespace testing
}  // namespace flutter
