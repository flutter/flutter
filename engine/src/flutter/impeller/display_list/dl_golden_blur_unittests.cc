// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/display_list/dl_golden_unittests.h"

#include "flutter/display_list/dl_builder.h"
#include "flutter/display_list/effects/dl_mask_filter.h"
#include "flutter/testing/testing.h"
#include "gtest/gtest.h"
#include "impeller/typographer/backends/skia/text_frame_skia.h"
#include "txt/platform.h"

namespace flutter {
namespace testing {

using impeller::Font;

namespace {
struct TextRenderOptions {
  bool stroke = false;
  SkScalar font_size = 50;
  DlColor color = DlColor::kYellow();
  std::shared_ptr<DlMaskFilter> mask_filter;
};

bool RenderTextInCanvasSkia(DlCanvas* canvas,
                            const std::string& text,
                            const std::string_view& font_fixture,
                            SkPoint position,
                            const TextRenderOptions& options = {}) {
  auto c_font_fixture = std::string(font_fixture);
  auto mapping = flutter::testing::OpenFixtureAsSkData(c_font_fixture.c_str());
  if (!mapping) {
    return false;
  }
  sk_sp<SkFontMgr> font_mgr = txt::GetDefaultFontManager();
  SkFont sk_font(font_mgr->makeFromData(mapping), options.font_size);
  auto blob = SkTextBlob::MakeFromString(text.c_str(), sk_font);
  if (!blob) {
    return false;
  }

  auto frame = impeller::MakeTextFrameFromTextBlobSkia(blob);

  DlPaint text_paint;
  text_paint.setColor(options.color);
  text_paint.setMaskFilter(options.mask_filter);
  // text_paint.mask_blur_descriptor = options.mask_blur_descriptor;
  // text_paint.stroke_width = 1;
  // text_paint.style =
  //     options.stroke ? Paint::Style::kStroke : Paint::Style::kFill;
  canvas->DrawTextFrame(frame, position.x(), position.y(), text_paint);
  return true;
}

}  // namespace

TEST_P(DlGoldenTest, TextBlurMaskFilterRespectCTM) {
  impeller::Point content_scale = GetContentScale();
  auto draw = [&](DlCanvas* canvas,
                  const std::vector<std::unique_ptr<DlImage>>& images) {
    canvas->DrawColor(DlColor(0xff111111));
    canvas->Scale(content_scale.x, content_scale.y);
    canvas->Scale(2, 2);
    TextRenderOptions options;
    options.mask_filter =
        DlBlurMaskFilter::Make(DlBlurStyle::kNormal, /*sigma=*/10,
                               /*respect_ctm=*/true);
    ASSERT_TRUE(RenderTextInCanvasSkia(canvas, "hello world",
                                       "Roboto-Regular.ttf",
                                       SkPoint::Make(101, 101), options));
    options.mask_filter = nullptr;
    options.color = DlColor::kRed();
    ASSERT_TRUE(RenderTextInCanvasSkia(canvas, "hello world",
                                       "Roboto-Regular.ttf",
                                       SkPoint::Make(100, 100), options));
  };

  DisplayListBuilder builder;
  draw(&builder, /*images=*/{});

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(DlGoldenTest, TextBlurMaskFilterDisrespectCTM) {
  impeller::Point content_scale = GetContentScale();
  auto draw = [&](DlCanvas* canvas,
                  const std::vector<std::unique_ptr<DlImage>>& images) {
    canvas->DrawColor(DlColor(0xff111111));
    canvas->Scale(content_scale.x, content_scale.y);
    canvas->Scale(2, 2);
    TextRenderOptions options;
    options.mask_filter =
        DlBlurMaskFilter::Make(DlBlurStyle::kNormal, /*sigma=*/10,
                               /*respect_ctm=*/false);
    ASSERT_TRUE(RenderTextInCanvasSkia(canvas, "hello world",
                                       "Roboto-Regular.ttf",
                                       SkPoint::Make(101, 101), options));
    options.mask_filter = nullptr;
    options.color = DlColor::kRed();
    ASSERT_TRUE(RenderTextInCanvasSkia(canvas, "hello world",
                                       "Roboto-Regular.ttf",
                                       SkPoint::Make(100, 100), options));
  };

  DisplayListBuilder builder;
  draw(&builder, /*images=*/{});

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

}  // namespace testing
}  // namespace flutter
