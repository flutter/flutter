// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/impeller/aiks/aiks_unittests.h"

#include "flutter/display_list/dl_blend_mode.h"
#include "flutter/display_list/dl_builder.h"
#include "flutter/display_list/dl_color.h"
#include "flutter/display_list/dl_paint.h"
#include "flutter/display_list/effects/dl_color_filter.h"
#include "flutter/testing/testing.h"

namespace impeller {
namespace testing {

using namespace flutter;

TEST_P(AiksTest, RotateColorFilteredPath) {
  DisplayListBuilder builder;
  builder.Transform(SkMatrix::Translate(300, 300) * SkMatrix::RotateDeg(90));

  SkPath arrow_stem;
  SkPath arrow_head;

  arrow_stem.moveTo({120, 190}).lineTo({120, 50});
  arrow_head.moveTo({50, 120}).lineTo({120, 190}).lineTo({190, 120});

  auto filter =
      DlBlendColorFilter::Make(DlColor::kAliceBlue(), DlBlendMode::kSrcIn);

  DlPaint paint;
  paint.setStrokeWidth(15.0);
  paint.setStrokeCap(DlStrokeCap::kRound);
  paint.setStrokeJoin(DlStrokeJoin::kRound);
  paint.setDrawStyle(DlDrawStyle::kStroke);
  paint.setColorFilter(filter);
  paint.setColor(DlColor::kBlack());

  builder.DrawPath(arrow_stem, paint);
  builder.DrawPath(arrow_head, paint);

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}
}  // namespace testing
}  // namespace impeller
