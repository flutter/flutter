// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/testing/mock_texture.h"

#include "gtest/gtest.h"

namespace flutter {
namespace testing {

TEST(MockTextureTest, Callbacks) {
  auto texture = std::make_shared<MockTexture>(0);

  ASSERT_FALSE(texture->gr_context_created());
  texture->OnGrContextCreated();
  ASSERT_TRUE(texture->gr_context_created());

  ASSERT_FALSE(texture->gr_context_destroyed());
  texture->OnGrContextDestroyed();
  ASSERT_TRUE(texture->gr_context_destroyed());

  ASSERT_FALSE(texture->unregistered());
  texture->OnTextureUnregistered();
  ASSERT_TRUE(texture->unregistered());
}

TEST(MockTextureTest, PaintCalls) {
  SkCanvas canvas;
  const SkRect paint_bounds1 = SkRect::MakeWH(1.0f, 1.0f);
  const SkRect paint_bounds2 = SkRect::MakeWH(2.0f, 2.0f);
  const auto expected_paint_calls =
      std::vector{MockTexture::PaintCall{canvas, paint_bounds1, false, nullptr},
                  MockTexture::PaintCall{canvas, paint_bounds2, true, nullptr}};
  auto texture = std::make_shared<MockTexture>(0);

  texture->Paint(canvas, paint_bounds1, false, nullptr);
  texture->Paint(canvas, paint_bounds2, true, nullptr);
  EXPECT_EQ(texture->paint_calls(), expected_paint_calls);
}

}  // namespace testing
}  // namespace flutter
