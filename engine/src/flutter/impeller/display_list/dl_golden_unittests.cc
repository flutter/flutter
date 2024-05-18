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

}  // namespace testing
}  // namespace flutter
