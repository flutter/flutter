// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/mock_canvas.h"

#include "flutter/testing/canvas_test.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

using MockCanvasTest = CanvasTest;

#ifndef NDEBUG
TEST_F(MockCanvasTest, DrawRRectDies) {
  EXPECT_DEATH_IF_SUPPORTED(mock_canvas().drawRRect(SkRRect(), SkPaint()), "");
}
#endif

TEST_F(MockCanvasTest, DrawCalls) {
  const SkRect rect = SkRect::MakeWH(5.0f, 5.0f);
  const SkPaint paint = SkPaint(SkColors::kGreen);
  const auto expected_draw_calls = std::vector{
      MockCanvas::DrawCall{0, MockCanvas::DrawRectData{rect, paint}}};

  mock_canvas().drawRect(rect, paint);
  EXPECT_EQ(mock_canvas().draw_calls(), expected_draw_calls);
}

}  // namespace testing
}  // namespace flutter
