// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/testing/mock_texture.h"

#include "flutter/display_list/dl_builder.h"
#include "flutter/testing/display_list_testing.h"
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
  DisplayListBuilder builder;
  const DlRect paint_bounds1 = DlRect::MakeWH(1.0f, 1.0f);
  const DlRect paint_bounds2 = DlRect::MakeWH(2.0f, 2.0f);
  const DlImageSampling sampling = DlImageSampling::kNearestNeighbor;
  const auto texture_image = MockTexture::MakeTestTexture(20, 20, 5);
  auto texture = std::make_shared<MockTexture>(0, texture_image);

  Texture::PaintContext context{
      .canvas = &builder,
  };
  texture->Paint(context, paint_bounds1, false, sampling);
  texture->Paint(context, paint_bounds2, true, sampling);

  DlRect src1 = DlRect::Make(texture_image->GetBounds());
  DlRect src2 = src1.Expand(-1.0f, -1.0f);

  DisplayListBuilder expected_builder;
  expected_builder.DrawImageRect(texture_image, src1, paint_bounds1, sampling);
  expected_builder.DrawImageRect(texture_image, src2, paint_bounds2, sampling);
  EXPECT_TRUE(
      DisplayListsEQ_Verbose(builder.Build(), expected_builder.Build()));
}

TEST(MockTextureTest, PaintCallsWithLinearSampling) {
  DisplayListBuilder builder;
  const DlRect paint_bounds1 = DlRect::MakeWH(1.0f, 1.0f);
  const DlRect paint_bounds2 = DlRect::MakeWH(2.0f, 2.0f);
  const auto sampling = DlImageSampling::kLinear;
  const auto texture_image = MockTexture::MakeTestTexture(20, 20, 5);
  auto texture = std::make_shared<MockTexture>(0, texture_image);

  Texture::PaintContext context{
      .canvas = &builder,
  };
  texture->Paint(context, paint_bounds1, false, sampling);
  texture->Paint(context, paint_bounds2, true, sampling);

  DlRect src1 = DlRect::Make(texture_image->GetBounds());
  DlRect src2 = src1.Expand(-1.0f, -1.0f);

  DisplayListBuilder expected_builder;
  expected_builder.DrawImageRect(texture_image, src1, paint_bounds1, sampling);
  expected_builder.DrawImageRect(texture_image, src2, paint_bounds2, sampling);
  EXPECT_TRUE(
      DisplayListsEQ_Verbose(builder.Build(), expected_builder.Build()));
}

}  // namespace testing
}  // namespace flutter
