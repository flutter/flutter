// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/display_list.h"
#include "flutter/display_list/display_list_builder.h"
#include "flutter/display_list/display_list_complexity.h"
#include "flutter/display_list/display_list_complexity_gl.h"
#include "flutter/display_list/display_list_complexity_metal.h"
#include "flutter/display_list/display_list_sampling_options.h"
#include "flutter/display_list/testing/dl_test_snippets.h"
#include "flutter/testing/testing.h"
#include "third_party/skia/include/core/SkColor.h"

namespace flutter {
namespace testing {

namespace {

std::vector<DisplayListComplexityCalculator*> Calculators() {
  return {DisplayListMetalComplexityCalculator::GetInstance(),
          DisplayListGLComplexityCalculator::GetInstance(),
          DisplayListNaiveComplexityCalculator::GetInstance()};
}

std::vector<DisplayListComplexityCalculator*> AccumulatorCalculators() {
  return {DisplayListMetalComplexityCalculator::GetInstance(),
          DisplayListGLComplexityCalculator::GetInstance()};
}

std::vector<SkPoint> GetTestPoints() {
  std::vector<SkPoint> points;
  points.push_back(SkPoint::Make(0, 0));
  points.push_back(SkPoint::Make(10, 0));
  points.push_back(SkPoint::Make(10, 10));
  points.push_back(SkPoint::Make(20, 10));
  points.push_back(SkPoint::Make(20, 20));

  return points;
}

}  // namespace

TEST(DisplayListComplexity, EmptyDisplayList) {
  auto display_list = GetSampleDisplayList(0);

  auto calculators = Calculators();
  for (auto calculator : calculators) {
    ASSERT_EQ(calculator->Compute(display_list.get()), 0u);
  }
}

TEST(DisplayListComplexity, DisplayListCeiling) {
  auto display_list = GetSampleDisplayList();

  auto calculators = AccumulatorCalculators();
  for (auto calculator : calculators) {
    calculator->SetComplexityCeiling(10u);
    ASSERT_EQ(calculator->Compute(display_list.get()), 10u);
    calculator->SetComplexityCeiling(std::numeric_limits<unsigned int>::max());
  }
}

TEST(DisplayListComplexity, NestedDisplayList) {
  auto display_list = GetSampleNestedDisplayList();

  auto calculators = Calculators();
  for (auto calculator : calculators) {
    // There's only one draw call in the "outer" DisplayList, which calls
    // drawDisplayList with the "inner" DisplayList. To ensure we are
    // recursing correctly into the inner DisplayList, check that we aren't
    // returning 0 (if the function is a no-op) or 1 (as the op_count is 1)
    ASSERT_GT(calculator->Compute(display_list.get()), 1u);
  }
}

TEST(DisplayListComplexity, AntiAliasing) {
  DisplayListBuilder builder_no_aa;
  builder_no_aa.drawLine(SkPoint::Make(0, 0), SkPoint::Make(100, 100));
  auto display_list_no_aa = builder_no_aa.Build();

  DisplayListBuilder builder_aa;
  builder_aa.setAntiAlias(true);
  builder_aa.drawLine(SkPoint::Make(0, 0), SkPoint::Make(100, 100));
  auto display_list_aa = builder_aa.Build();

  auto calculators = AccumulatorCalculators();
  for (auto calculator : calculators) {
    ASSERT_NE(calculator->Compute(display_list_no_aa.get()),
              calculator->Compute(display_list_aa.get()));
  }
}

TEST(DisplayListComplexity, StrokeWidth) {
  DisplayListBuilder builder_stroke_0;
  builder_stroke_0.setStrokeWidth(0.0f);
  builder_stroke_0.drawLine(SkPoint::Make(0, 0), SkPoint::Make(100, 100));
  auto display_list_stroke_0 = builder_stroke_0.Build();

  DisplayListBuilder builder_stroke_1;
  builder_stroke_1.setStrokeWidth(1.0f);
  builder_stroke_1.drawLine(SkPoint::Make(0, 0), SkPoint::Make(100, 100));
  auto display_list_stroke_1 = builder_stroke_1.Build();

  auto calculators = AccumulatorCalculators();
  for (auto calculator : calculators) {
    ASSERT_NE(calculator->Compute(display_list_stroke_0.get()),
              calculator->Compute(display_list_stroke_1.get()));
  }
}

TEST(DisplayListComplexity, Style) {
  DisplayListBuilder builder_filled;
  builder_filled.setStyle(DlDrawStyle::kFill);
  builder_filled.drawRect(SkRect::MakeXYWH(10, 10, 80, 80));
  auto display_list_filled = builder_filled.Build();

  DisplayListBuilder builder_stroked;
  builder_stroked.setStyle(DlDrawStyle::kStroke);
  builder_stroked.drawRect(SkRect::MakeXYWH(10, 10, 80, 80));
  auto display_list_stroked = builder_stroked.Build();

  auto calculators = AccumulatorCalculators();
  for (auto calculator : calculators) {
    ASSERT_NE(calculator->Compute(display_list_filled.get()),
              calculator->Compute(display_list_stroked.get()));
  }
}

TEST(DisplayListComplexity, SaveLayers) {
  DisplayListBuilder builder;
  builder.saveLayer(nullptr, true);
  auto display_list = builder.Build();

  auto calculators = AccumulatorCalculators();
  for (auto calculator : calculators) {
    ASSERT_NE(calculator->Compute(display_list.get()), 0u);
  }
}

TEST(DisplayListComplexity, DrawPath) {
  DisplayListBuilder builder_line;
  SkPath line_path;
  line_path.moveTo(SkPoint::Make(0, 0));
  line_path.lineTo(SkPoint::Make(10, 10));
  line_path.close();
  builder_line.drawPath(line_path);
  auto display_list_line = builder_line.Build();

  DisplayListBuilder builder_quad;
  SkPath quad_path;
  quad_path.moveTo(SkPoint::Make(0, 0));
  quad_path.quadTo(SkPoint::Make(10, 10), SkPoint::Make(10, 20));
  quad_path.close();
  builder_quad.drawPath(quad_path);
  auto display_list_quad = builder_quad.Build();

  DisplayListBuilder builder_conic;
  SkPath conic_path;
  conic_path.moveTo(SkPoint::Make(0, 0));
  conic_path.conicTo(SkPoint::Make(10, 10), SkPoint::Make(10, 20), 1.5f);
  conic_path.close();
  builder_conic.drawPath(conic_path);
  auto display_list_conic = builder_conic.Build();

  DisplayListBuilder builder_cubic;
  SkPath cubic_path;
  cubic_path.moveTo(SkPoint::Make(0, 0));
  cubic_path.cubicTo(SkPoint::Make(10, 10), SkPoint::Make(10, 20),
                     SkPoint::Make(20, 20));
  builder_cubic.drawPath(cubic_path);
  auto display_list_cubic = builder_cubic.Build();

  auto calculators = AccumulatorCalculators();
  for (auto calculator : calculators) {
    ASSERT_NE(calculator->Compute(display_list_line.get()), 0u);
    ASSERT_NE(calculator->Compute(display_list_quad.get()), 0u);
    ASSERT_NE(calculator->Compute(display_list_conic.get()), 0u);
    ASSERT_NE(calculator->Compute(display_list_cubic.get()), 0u);
  }
}

TEST(DisplayListComplexity, DrawShadow) {
  DisplayListBuilder builder_line;
  SkPath line_path;
  line_path.moveTo(SkPoint::Make(0, 0));
  line_path.lineTo(SkPoint::Make(10, 10));
  line_path.close();
  builder_line.drawShadow(line_path, SK_ColorRED, 10.0f, false, 1.0f);
  auto display_list_line = builder_line.Build();

  DisplayListBuilder builder_quad;
  SkPath quad_path;
  quad_path.moveTo(SkPoint::Make(0, 0));
  quad_path.quadTo(SkPoint::Make(10, 10), SkPoint::Make(10, 20));
  quad_path.close();
  builder_quad.drawShadow(quad_path, SK_ColorRED, 10.0f, false, 1.0f);
  auto display_list_quad = builder_quad.Build();

  DisplayListBuilder builder_conic;
  SkPath conic_path;
  conic_path.moveTo(SkPoint::Make(0, 0));
  conic_path.conicTo(SkPoint::Make(10, 10), SkPoint::Make(10, 20), 1.5f);
  conic_path.close();
  builder_conic.drawShadow(conic_path, SK_ColorRED, 10.0f, false, 1.0f);
  auto display_list_conic = builder_conic.Build();

  DisplayListBuilder builder_cubic;
  SkPath cubic_path;
  cubic_path.moveTo(SkPoint::Make(0, 0));
  cubic_path.cubicTo(SkPoint::Make(10, 10), SkPoint::Make(10, 20),
                     SkPoint::Make(20, 20));
  builder_cubic.drawShadow(cubic_path, SK_ColorRED, 10.0f, false, 1.0f);
  auto display_list_cubic = builder_cubic.Build();

  auto calculators = AccumulatorCalculators();
  for (auto calculator : calculators) {
    ASSERT_NE(calculator->Compute(display_list_line.get()), 0u);
    ASSERT_NE(calculator->Compute(display_list_quad.get()), 0u);
    ASSERT_NE(calculator->Compute(display_list_conic.get()), 0u);
    ASSERT_NE(calculator->Compute(display_list_cubic.get()), 0u);
  }
}

TEST(DisplayListComplexity, DrawOval) {
  DisplayListBuilder builder;
  builder.drawOval(SkRect::MakeXYWH(10, 10, 100, 80));
  auto display_list = builder.Build();

  auto calculators = AccumulatorCalculators();
  for (auto calculator : calculators) {
    ASSERT_NE(calculator->Compute(display_list.get()), 0u);
  }
}

TEST(DisplayListComplexity, DrawCircle) {
  DisplayListBuilder builder;
  builder.drawCircle(SkPoint::Make(50, 50), 10.0f);
  auto display_list = builder.Build();

  auto calculators = AccumulatorCalculators();
  for (auto calculator : calculators) {
    ASSERT_NE(calculator->Compute(display_list.get()), 0u);
  }
}

TEST(DisplayListComplexity, DrawRRect) {
  DisplayListBuilder builder;
  builder.drawRRect(
      SkRRect::MakeRectXY(SkRect::MakeXYWH(10, 10, 80, 80), 2.0f, 3.0f));
  auto display_list = builder.Build();

  auto calculators = AccumulatorCalculators();
  for (auto calculator : calculators) {
    ASSERT_NE(calculator->Compute(display_list.get()), 0u);
  }
}

TEST(DisplayListComplexity, DrawDRRect) {
  DisplayListBuilder builder;
  SkRRect outer =
      SkRRect::MakeRectXY(SkRect::MakeXYWH(10, 10, 80, 80), 2.0f, 3.0f);
  SkRRect inner =
      SkRRect::MakeRectXY(SkRect::MakeXYWH(15, 15, 70, 70), 1.5f, 1.5f);
  builder.drawDRRect(outer, inner);
  auto display_list = builder.Build();

  auto calculators = AccumulatorCalculators();
  for (auto calculator : calculators) {
    ASSERT_NE(calculator->Compute(display_list.get()), 0u);
  }
}

TEST(DisplayListComplexity, DrawArc) {
  DisplayListBuilder builder;
  builder.drawArc(SkRect::MakeXYWH(10, 10, 100, 80), 0.0f, 10.0f, true);
  auto display_list = builder.Build();

  auto calculators = AccumulatorCalculators();
  for (auto calculator : calculators) {
    ASSERT_NE(calculator->Compute(display_list.get()), 0u);
  }
}

TEST(DisplayListComplexity, DrawVertices) {
  auto points = GetTestPoints();
  auto vertices = DlVertices::Make(DlVertexMode::kTriangles, points.size(),
                                   points.data(), nullptr, nullptr);
  DisplayListBuilder builder;
  builder.drawVertices(vertices, DlBlendMode::kSrc);
  auto display_list = builder.Build();

  auto calculators = AccumulatorCalculators();
  for (auto calculator : calculators) {
    ASSERT_NE(calculator->Compute(display_list.get()), 0u);
  }
}

TEST(DisplayListComplexity, DrawTextBlob) {
  auto text_blob = SkTextBlob::MakeFromString(
      "The quick brown fox jumps over the lazy dog.", SkFont());

  DisplayListBuilder builder;
  builder.drawTextBlob(text_blob, 0.0f, 0.0f);
  auto display_list = builder.Build();

  DisplayListBuilder builder_multiple;
  builder_multiple.drawTextBlob(text_blob, 0.0f, 0.0f);
  builder_multiple.drawTextBlob(text_blob, 0.0f, 0.0f);
  auto display_list_multiple = builder_multiple.Build();

  auto calculators = AccumulatorCalculators();
  for (auto calculator : calculators) {
    ASSERT_NE(calculator->Compute(display_list.get()), 0u);
    ASSERT_GT(calculator->Compute(display_list_multiple.get()),
              calculator->Compute(display_list.get()));
  }
}

TEST(DisplayListComplexity, DrawPoints) {
  auto points = GetTestPoints();
  DisplayListBuilder builder_lines;
  builder_lines.drawPoints(SkCanvas::kLines_PointMode, points.size(),
                           points.data());
  auto display_list_lines = builder_lines.Build();

  DisplayListBuilder builder_points;
  builder_points.drawPoints(SkCanvas::kPoints_PointMode, points.size(),
                            points.data());
  auto display_list_points = builder_points.Build();

  DisplayListBuilder builder_polygon;
  builder_polygon.drawPoints(SkCanvas::kPolygon_PointMode, points.size(),
                             points.data());
  auto display_list_polygon = builder_polygon.Build();

  auto calculators = AccumulatorCalculators();
  for (auto calculator : calculators) {
    ASSERT_NE(calculator->Compute(display_list_lines.get()), 0u);
    ASSERT_NE(calculator->Compute(display_list_points.get()), 0u);
    ASSERT_NE(calculator->Compute(display_list_polygon.get()), 0u);
  }
}

TEST(DisplayListComplexity, DrawImage) {
  SkImageInfo info =
      SkImageInfo::Make(50, 50, SkColorType::kRGBA_8888_SkColorType,
                        SkAlphaType::kPremul_SkAlphaType);
  SkBitmap bitmap;
  bitmap.allocPixels(info, 0);
  auto image = SkImage::MakeFromBitmap(bitmap);

  DisplayListBuilder builder;
  builder.drawImage(DlImage::Make(image), SkPoint::Make(0, 0),
                    DlImageSampling::kNearestNeighbor, false);
  auto display_list = builder.Build();

  auto calculators = AccumulatorCalculators();
  for (auto calculator : calculators) {
    ASSERT_NE(calculator->Compute(display_list.get()), 0u);
  }
}

TEST(DisplayListComplexity, DrawImageNine) {
  SkImageInfo info =
      SkImageInfo::Make(50, 50, SkColorType::kRGBA_8888_SkColorType,
                        SkAlphaType::kPremul_SkAlphaType);
  SkBitmap bitmap;
  bitmap.allocPixels(info, 0);
  auto image = SkImage::MakeFromBitmap(bitmap);

  SkIRect center = SkIRect::MakeXYWH(5, 5, 20, 20);
  SkRect dest = SkRect::MakeXYWH(0, 0, 50, 50);

  DisplayListBuilder builder;
  builder.drawImageNine(DlImage::Make(image), center, dest,
                        DlFilterMode::kNearest, true);
  auto display_list = builder.Build();

  auto calculators = AccumulatorCalculators();
  for (auto calculator : calculators) {
    ASSERT_NE(calculator->Compute(display_list.get()), 0u);
  }
}

TEST(DisplayListComplexity, DrawImageRect) {
  SkImageInfo info =
      SkImageInfo::Make(50, 50, SkColorType::kRGBA_8888_SkColorType,
                        SkAlphaType::kPremul_SkAlphaType);
  SkBitmap bitmap;
  bitmap.allocPixels(info, 0);
  auto image = SkImage::MakeFromBitmap(bitmap);

  SkRect src = SkRect::MakeXYWH(0, 0, 50, 50);
  SkRect dest = SkRect::MakeXYWH(0, 0, 50, 50);

  DisplayListBuilder builder;
  builder.drawImageRect(DlImage::Make(image), src, dest,
                        DlImageSampling::kNearestNeighbor, true);
  auto display_list = builder.Build();

  auto calculators = AccumulatorCalculators();
  for (auto calculator : calculators) {
    ASSERT_NE(calculator->Compute(display_list.get()), 0u);
  }
}

TEST(DisplayListComplexity, DrawAtlas) {
  SkImageInfo info =
      SkImageInfo::Make(50, 50, SkColorType::kRGBA_8888_SkColorType,
                        SkAlphaType::kPremul_SkAlphaType);
  SkBitmap bitmap;
  bitmap.allocPixels(info, 0);
  auto image = SkImage::MakeFromBitmap(bitmap);

  std::vector<SkRect> rects;
  std::vector<SkRSXform> xforms;
  for (int i = 0; i < 10; i++) {
    rects.push_back(SkRect::MakeXYWH(0, 0, 10, 10));
    xforms.push_back(SkRSXform::Make(0, 0, 0, 0));
  }

  DisplayListBuilder builder;
  builder.drawAtlas(DlImage::Make(image), xforms.data(), rects.data(), nullptr,
                    10, DlBlendMode::kSrc, DlImageSampling::kNearestNeighbor,
                    nullptr, true);
  auto display_list = builder.Build();

  auto calculators = AccumulatorCalculators();
  for (auto calculator : calculators) {
    ASSERT_NE(calculator->Compute(display_list.get()), 0u);
  }
}

}  // namespace testing
}  // namespace flutter
