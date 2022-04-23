// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/display_list_paint.h"

#include "flutter/display_list/display_list_comparable.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

TEST(DisplayListPaint, ConstructorDefaults) {
  DlPaint paint;
  EXPECT_FALSE(paint.isAntiAlias());
  EXPECT_FALSE(paint.isDither());
  EXPECT_FALSE(paint.isInvertColors());
  EXPECT_EQ(paint.getColor(), DlColor{0xFF000000});
  EXPECT_EQ(paint.getAlpha(), 0xFF);
  EXPECT_EQ(paint.getBlendMode(), DlBlendMode::kDefaultMode);
  EXPECT_EQ(paint.getDrawStyle(), DlDrawStyle::kDefaultStyle);
  EXPECT_EQ(paint.getStrokeCap(), DlStrokeCap::kDefaultCap);
  EXPECT_EQ(paint.getStrokeJoin(), DlStrokeJoin::kDefaultJoin);
  EXPECT_EQ(paint.getStrokeWidth(), 0.0);
  EXPECT_EQ(paint.getStrokeMiter(), 4.0);
  EXPECT_EQ(paint.getColorSource(), nullptr);
  EXPECT_EQ(paint.getColorFilter(), nullptr);
  EXPECT_EQ(paint.getImageFilter(), nullptr);
  EXPECT_EQ(paint.getMaskFilter(), nullptr);

  EXPECT_EQ(DlBlendMode::kDefaultMode, DlBlendMode::kSrcOver);
  EXPECT_EQ(DlDrawStyle::kDefaultStyle, DlDrawStyle::kFill);
  EXPECT_EQ(DlStrokeCap::kDefaultCap, DlStrokeCap::kButt);
  EXPECT_EQ(DlStrokeJoin::kDefaultJoin, DlStrokeJoin::kMiter);

  EXPECT_EQ(paint, DlPaint());

  EXPECT_NE(paint, DlPaint().setAntiAlias(true));
  EXPECT_NE(paint, DlPaint().setDither(true));
  EXPECT_NE(paint, DlPaint().setInvertColors(true));
  EXPECT_NE(paint, DlPaint().setColor(DlColor(0xFF00FF00)));
  EXPECT_NE(paint, DlPaint().setAlpha(0x7f));
  EXPECT_NE(paint, DlPaint().setBlendMode(DlBlendMode::kDstIn));
  EXPECT_NE(paint, DlPaint().setDrawStyle(DlDrawStyle::kStrokeAndFill));
  EXPECT_NE(paint, DlPaint().setStrokeCap(DlStrokeCap::kRound));
  EXPECT_NE(paint, DlPaint().setStrokeJoin(DlStrokeJoin::kRound));
  EXPECT_NE(paint, DlPaint().setStrokeWidth(6));
  EXPECT_NE(paint, DlPaint().setStrokeMiter(7));

  DlColorColorSource colorSource(0xFFFF00FF);
  EXPECT_NE(paint, DlPaint().setColorSource(colorSource.shared()));

  DlBlendColorFilter colorFilter(0xFFFFFF00, SkBlendMode::kDstIn);
  EXPECT_NE(paint, DlPaint().setColorFilter(colorFilter.shared()));

  DlBlurImageFilter imageFilter(1.3, 4.7, DlTileMode::kClamp);
  EXPECT_NE(paint, DlPaint().setImageFilter(imageFilter.shared()));

  DlBlurMaskFilter maskFilter(SkBlurStyle::kInner_SkBlurStyle, 3.14);
  EXPECT_NE(paint, DlPaint().setMaskFilter(maskFilter.shared()));
}

TEST(DisplayListPaint, ChainingConstructor) {
  DlPaint paint =
      DlPaint()                                                     //
          .setAntiAlias(true)                                       //
          .setDither(true)                                          //
          .setInvertColors(true)                                    //
          .setColor({0xFF00FF00})                                   //
          .setAlpha(0x7F)                                           //
          .setBlendMode(DlBlendMode::kLuminosity)                   //
          .setDrawStyle(DlDrawStyle::kStrokeAndFill)                //
          .setStrokeCap(DlStrokeCap::kSquare)                       //
          .setStrokeJoin(DlStrokeJoin::kBevel)                      //
          .setStrokeWidth(42)                                       //
          .setStrokeMiter(1.5)                                      //
          .setColorSource(DlColorColorSource(0xFFFF00FF).shared())  //
          .setColorFilter(
              DlBlendColorFilter(0xFFFFFF00, SkBlendMode::kDstIn).shared())
          .setImageFilter(
              DlBlurImageFilter(1.3, 4.7, DlTileMode::kClamp).shared())
          .setMaskFilter(
              DlBlurMaskFilter(SkBlurStyle::kInner_SkBlurStyle, 3.14).shared());
  EXPECT_TRUE(paint.isAntiAlias());
  EXPECT_TRUE(paint.isDither());
  EXPECT_TRUE(paint.isInvertColors());
  EXPECT_EQ(paint.getColor(), DlColor{0x7F00FF00});
  EXPECT_EQ(paint.getAlpha(), 0x7F);
  EXPECT_EQ(paint.getBlendMode(), DlBlendMode::kLuminosity);
  EXPECT_EQ(paint.getDrawStyle(), DlDrawStyle::kStrokeAndFill);
  EXPECT_EQ(paint.getStrokeCap(), DlStrokeCap::kSquare);
  EXPECT_EQ(paint.getStrokeJoin(), DlStrokeJoin::kBevel);
  EXPECT_EQ(paint.getStrokeWidth(), 42);
  EXPECT_EQ(paint.getStrokeMiter(), 1.5);
  EXPECT_TRUE(
      Equals(paint.getColorSource(), DlColorColorSource(0xFFFF00FF).shared()));
  EXPECT_TRUE(
      Equals(paint.getColorFilter(),
             DlBlendColorFilter(0xFFFFFF00, SkBlendMode::kDstIn).shared()));
  EXPECT_TRUE(Equals(paint.getImageFilter(),
                     DlBlurImageFilter(1.3, 4.7, DlTileMode::kClamp).shared()));
  EXPECT_TRUE(
      Equals(paint.getMaskFilter(),
             DlBlurMaskFilter(SkBlurStyle::kInner_SkBlurStyle, 3.14).shared()));

  EXPECT_NE(paint, DlPaint());
}

}  // namespace testing
}  // namespace flutter
