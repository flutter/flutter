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

TEST_F(SkiaParagraphBuilderTests, RenderSoftHyphensEnabled) {
  ParagraphStyle style = ParagraphStyle();
  auto collection = std::make_shared<FontCollection>();
  auto builder = ParagraphBuilderSkia(style, collection, false);

  // Defaults to rendering the soft hyphen glyph (Hyphens.manual).
  ASSERT_TRUE(builder.TxtToSkia(style).getRenderSoftHyphens());

  // Hyphens.hidden suppresses the soft hyphen glyph.
  style.render_soft_hyphens = false;
  ASSERT_FALSE(builder.TxtToSkia(style).getRenderSoftHyphens());
}

TEST_F(SkiaParagraphBuilderTests, SoftHyphenString) {
  ParagraphStyle style = ParagraphStyle();
  auto collection = std::make_shared<FontCollection>();
  auto builder = ParagraphBuilderSkia(style, collection, false);

  // Unset keeps Skia's default hyphen.
  ASSERT_EQ(builder.TxtToSkia(style).getSoftHyphenString(), SkString("-"));

  style.soft_hyphen_string = u"\u2010";
  ASSERT_EQ(builder.TxtToSkia(style).getSoftHyphenString(), SkString("\u2010"));

  // The empty string is passed through and draws nothing.
  style.soft_hyphen_string = u"";
  ASSERT_EQ(builder.TxtToSkia(style).getSoftHyphenString(), SkString(""));
}
}  // namespace txt
