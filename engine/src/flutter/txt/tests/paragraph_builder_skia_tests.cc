// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gtest/gtest.h"

#include <sstream>

#include "skia/paragraph_builder_skia.h"
#include "txt/paragraph_style.h"

namespace txt {

class SkiaParagraphBuilderTests : public ::testing::Test {
 public:
  SkiaParagraphBuilderTests() {}

  void SetUp() override {}
};

TEST_F(SkiaParagraphBuilderTests, ParagraphStrutStyle) {
  ParagraphStyle style = ParagraphStyle();
  auto collection = std::make_shared<FontCollection>();
  auto builder = ParagraphBuilderSkia(style, collection, false);

  auto strut_style = builder.TxtToSkia(style).getStrutStyle();
  ASSERT_FALSE(strut_style.getHalfLeading());

  style.strut_half_leading = true;
  strut_style = builder.TxtToSkia(style).getStrutStyle();
  ASSERT_TRUE(strut_style.getHalfLeading());
}

TEST_F(SkiaParagraphBuilderTests, FakeMissingFontStyles) {
  ParagraphStyle style;
  auto collection = std::make_shared<FontCollection>();
  ParagraphBuilderSkia builder(style, collection, false);

  EXPECT_TRUE(builder.TxtToSkia(style).fakeMissingFontStyles());

  style.fake_missing_font_styles = false;
  EXPECT_FALSE(builder.TxtToSkia(style).fakeMissingFontStyles());
}
}  // namespace txt
