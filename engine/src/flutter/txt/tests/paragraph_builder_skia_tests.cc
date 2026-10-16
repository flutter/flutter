// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gtest/gtest.h"

#include <sstream>

#include "flutter/fml/icu_util.h"
#include "skia/paragraph_builder_skia.h"
#include "txt/paragraph_style.h"
#include "txt/placeholder_run.h"

namespace txt {

class SkiaParagraphBuilderTests : public ::testing::Test {
 public:
  SkiaParagraphBuilderTests() {}

  void SetUp() override { fml::icu::InitializeICU("icudtl.dat"); }
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

TEST_F(SkiaParagraphBuilderTests, PlaceholderBoxesPreserveLogicalOrder) {
  // Regression test for https://github.com/flutter/flutter/issues/54400.
  for (auto direction : {TextDirection::ltr, TextDirection::rtl}) {
    ParagraphStyle style;
    style.text_direction = direction;
    auto collection = std::make_shared<FontCollection>();
    ParagraphBuilderSkia builder(style, collection, false);
    for (double width : {30.0, 50.0, 70.0}) {
      PlaceholderRun placeholder(width, 20.0, PlaceholderAlignment::kBottom,
                                 TextBaseline::kAlphabetic, 0.0);
      builder.AddPlaceholder(placeholder);
    }
    auto paragraph = builder.Build();
    paragraph->Layout(500.0);
    auto boxes = paragraph->GetRectsForPlaceholders();
    ASSERT_EQ(boxes.size(), 3u);

    double offset = direction == TextDirection::rtl ? 500.0 : 0.0;
    for (size_t i = 0; i < boxes.size(); ++i) {
      double width = 30.0 + 20.0 * i;
      double left = direction == TextDirection::rtl ? offset - width : offset;
      EXPECT_FLOAT_EQ(boxes[i].rect.left(), left);
      EXPECT_FLOAT_EQ(boxes[i].rect.width(), width);
      EXPECT_EQ(boxes[i].direction, direction);
      auto range_boxes = paragraph->GetRectsForRange(
          i, i + 1, Paragraph::RectHeightStyle::kTight,
          Paragraph::RectWidthStyle::kTight);
      ASSERT_EQ(range_boxes.size(), 1u);
      EXPECT_EQ(boxes[i].rect, range_boxes[0].rect);
      offset += direction == TextDirection::rtl ? -width : width;
    }
  }
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
}  // namespace txt
