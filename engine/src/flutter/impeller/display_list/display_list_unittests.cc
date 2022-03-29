// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/display_list_builder.h"
#include "flutter/testing/testing.h"
#include "impeller/display_list/display_list_image_impeller.h"
#include "impeller/display_list/display_list_playground.h"
#include "third_party/skia/include/core/SkPathBuilder.h"

namespace impeller {
namespace testing {

using DisplayListTest = DisplayListPlayground;

TEST_F(DisplayListTest, CanDrawRect) {
  flutter::DisplayListBuilder builder;
  builder.setColor(SK_ColorBLUE);
  builder.drawRect(SkRect::MakeXYWH(10, 10, 100, 100));
  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_F(DisplayListTest, CanDrawTextBlob) {
  flutter::DisplayListBuilder builder;
  builder.setColor(SK_ColorBLUE);
  builder.drawTextBlob(SkTextBlob::MakeFromString("Hello", CreateTestFont()),
                       100, 100);
  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_F(DisplayListTest, CanDrawImage) {
  auto texture = CreateTextureForFixture("embarcadero.jpg");
  flutter::DisplayListBuilder builder;
  builder.drawImage(DlImageImpeller::Make(texture), SkPoint::Make(100, 100),
                    SkSamplingOptions{}, true);
  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_F(DisplayListTest, CapsAndJoins) {
  flutter::DisplayListBuilder builder;

  builder.setStyle(SkPaint::Style::kStroke_Style);
  builder.setStrokeWidth(30);
  builder.setColor(SK_ColorRED);

  auto path =
      SkPathBuilder{}.moveTo(-50, 0).lineTo(0, -50).lineTo(50, 0).snapshot();

  builder.translate(100, 100);
  {
    builder.setStrokeCap(SkPaint::Cap::kButt_Cap);
    builder.setStrokeJoin(SkPaint::Join::kMiter_Join);
    builder.setStrokeMiter(4);
    builder.drawPath(path);
  }

  {
    builder.save();
    builder.translate(0, 100);
    // The joint in the path is 45 degrees. A miter length of 1 convert to a
    // bevel in this case.
    builder.setStrokeMiter(1);
    builder.drawPath(path);
    builder.restore();
  }

  builder.translate(150, 0);
  {
    builder.setStrokeCap(SkPaint::Cap::kSquare_Cap);
    builder.setStrokeJoin(SkPaint::Join::kBevel_Join);
    builder.drawPath(path);
  }

  builder.translate(150, 0);
  {
    builder.setStrokeCap(SkPaint::Cap::kRound_Cap);
    builder.setStrokeJoin(SkPaint::Join::kRound_Join);
    builder.drawPath(path);
  }

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

}  // namespace testing
}  // namespace impeller
