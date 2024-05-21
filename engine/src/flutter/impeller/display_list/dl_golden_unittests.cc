// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/display_list/dl_golden_unittests.h"

#include "flutter/display_list/dl_builder.h"
#include "flutter/testing/testing.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

using impeller::PlaygroundBackend;
using impeller::PlaygroundTest;
using impeller::Point;

INSTANTIATE_PLAYGROUND_SUITE(DlGoldenTest);

TEST_P(DlGoldenTest, CanDrawPaint) {
  auto draw = [](DlCanvas* canvas,
                 const std::vector<std::unique_ptr<DlImage>>& images) {
    canvas->Scale(0.2, 0.2);
    DlPaint paint;
    paint.setColor(DlColor::kCyan());
    canvas->DrawPaint(paint);
  };

  DisplayListBuilder builder;
  draw(&builder, /*images=*/{});

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(DlGoldenTest, CanRenderImage) {
  auto draw = [](DlCanvas* canvas, const std::vector<sk_sp<DlImage>>& images) {
    FML_CHECK(images.size() >= 1);
    DlPaint paint;
    paint.setColor(DlColor::kRed());
    canvas->DrawImage(images[0], SkPoint::Make(100.0, 100.0),
                      DlImageSampling::kLinear, &paint);
  };

  DisplayListBuilder builder;
  std::vector<sk_sp<DlImage>> images;
  images.emplace_back(CreateDlImageForFixture("kalimba.jpg"));
  draw(&builder, images);

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

// Asserts that subpass rendering of MatrixImageFilters works.
// https://github.com/flutter/flutter/issues/147807
TEST_P(DlGoldenTest, Bug147807) {
  Point content_scale = GetContentScale();
  auto draw = [content_scale](DlCanvas* canvas,
                              const std::vector<sk_sp<DlImage>>& images) {
    canvas->Transform2DAffine(content_scale.x, 0, 0, 0, content_scale.y, 0);
    DlPaint paint;
    paint.setColor(DlColor(0xfffef7ff));
    canvas->DrawRect(SkRect::MakeLTRB(0, 0, 375, 667), paint);
    paint.setColor(DlColor(0xffff9800));
    canvas->DrawRect(SkRect::MakeLTRB(0, 0, 187.5, 333.5), paint);
    paint.setColor(DlColor(0xff9c27b0));
    canvas->DrawRect(SkRect::MakeLTRB(187.5, 0, 375, 333.5), paint);
    paint.setColor(DlColor(0xff4caf50));
    canvas->DrawRect(SkRect::MakeLTRB(0, 333.5, 187.5, 667), paint);
    paint.setColor(DlColor(0xfff44336));
    canvas->DrawRect(SkRect::MakeLTRB(187.5, 333.5, 375, 667), paint);

    canvas->Save();
    {
      canvas->ClipRRect(
          SkRRect::MakeOval(SkRect::MakeLTRB(201.25, 10, 361.25, 170)),
          DlCanvas::ClipOp::kIntersect, true);
      SkRect save_layer_bounds = SkRect::MakeLTRB(201.25, 10, 361.25, 170);
      DlMatrixImageFilter backdrop(SkMatrix::MakeAll(3, 0, -280,  //
                                                     0, 3, -920,  //
                                                     0, 0, 1),
                                   DlImageSampling::kLinear);
      canvas->SaveLayer(&save_layer_bounds, /*paint=*/nullptr, &backdrop);
      {
        canvas->Translate(201.25, 10);
        auto paint = DlPaint()
                         .setAntiAlias(true)
                         .setColor(DlColor(0xff2196f3))
                         .setStrokeWidth(5)
                         .setDrawStyle(DlDrawStyle::kStroke);
        canvas->DrawCircle(SkPoint::Make(80, 80), 80, paint);
      }
      canvas->Restore();
    }
    canvas->Restore();
  };

  DisplayListBuilder builder;
  std::vector<sk_sp<DlImage>> images;
  draw(&builder, images);

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

}  // namespace testing
}  // namespace flutter
