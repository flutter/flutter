// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/display_list.h"
#include "flutter/display_list/dl_builder.h"
#include "flutter/shell/common/dl_op_spy.h"
#include "flutter/testing/testing.h"
#include "third_party/skia/include/core/SkBitmap.h"

namespace flutter {
namespace testing {

TEST(DlOpSpy, DidDrawIsFalseByDefault) {
  DlOpSpy dl_op_spy;
  ASSERT_FALSE(dl_op_spy.did_draw());
}

TEST(DlOpSpy, SetColor) {
  {  // No Color set.
    DisplayListBuilder builder;
    DlPaint paint;
    builder.DrawRect(SkRect::MakeWH(5, 5), paint);
    sk_sp<DisplayList> dl = builder.Build();
    DlOpSpy dl_op_spy;
    dl->Dispatch(dl_op_spy);
    ASSERT_TRUE(dl_op_spy.did_draw());
  }
  {  // Set transparent color.
    DisplayListBuilder builder;
    DlPaint paint(DlColor::kTransparent());
    builder.DrawRect(SkRect::MakeWH(5, 5), paint);
    sk_sp<DisplayList> dl = builder.Build();
    DlOpSpy dl_op_spy;
    dl->Dispatch(dl_op_spy);
    ASSERT_FALSE(dl_op_spy.did_draw());
  }
  {  // Set black color.
    DisplayListBuilder builder;
    DlPaint paint(DlColor::kBlack());
    builder.DrawRect(SkRect::MakeWH(5, 5), paint);
    sk_sp<DisplayList> dl = builder.Build();
    DlOpSpy dl_op_spy;
    dl->Dispatch(dl_op_spy);
    ASSERT_TRUE(dl_op_spy.did_draw());
  }
}

TEST(DlOpSpy, SetColorSource) {
  {  // Set null source
    DisplayListBuilder builder;
    DlPaint paint;
    paint.setColorSource(nullptr);
    builder.DrawRect(SkRect::MakeWH(5, 5), paint);
    sk_sp<DisplayList> dl = builder.Build();
    DlOpSpy dl_op_spy;
    dl->Dispatch(dl_op_spy);
    ASSERT_TRUE(dl_op_spy.did_draw());
  }
  {  // Set transparent color.
    DisplayListBuilder builder;
    DlPaint paint;
    auto color = DlColor::kTransparent();
    DlColorColorSource color_source_transparent(color);
    paint.setColorSource(color_source_transparent.shared());
    builder.DrawRect(SkRect::MakeWH(5, 5), paint);
    sk_sp<DisplayList> dl = builder.Build();
    DlOpSpy dl_op_spy;
    dl->Dispatch(dl_op_spy);
    ASSERT_FALSE(dl_op_spy.did_draw());
  }
  {  // Set black color.
    DisplayListBuilder builder;
    DlPaint paint;
    auto color = DlColor::kBlack();
    DlColorColorSource color_source_transparent(color);
    paint.setColorSource(color_source_transparent.shared());
    builder.DrawRect(SkRect::MakeWH(5, 5), paint);
    sk_sp<DisplayList> dl = builder.Build();
    DlOpSpy dl_op_spy;
    dl->Dispatch(dl_op_spy);
    ASSERT_TRUE(dl_op_spy.did_draw());
  }
}

TEST(DlOpSpy, DrawColor) {
  {  // Black color source.
    DisplayListBuilder builder;
    auto color = DlColor::kBlack();
    builder.DrawColor(color, DlBlendMode::kSrc);
    sk_sp<DisplayList> dl = builder.Build();
    DlOpSpy dl_op_spy;
    dl->Dispatch(dl_op_spy);
    ASSERT_TRUE(dl_op_spy.did_draw());
  }
  {  // Transparent color source.
    DisplayListBuilder builder;
    auto color = DlColor::kTransparent();
    builder.DrawColor(color, DlBlendMode::kSrc);
    sk_sp<DisplayList> dl = builder.Build();
    DlOpSpy dl_op_spy;
    dl->Dispatch(dl_op_spy);
    ASSERT_FALSE(dl_op_spy.did_draw());
  }
}

TEST(DlOpSpy, DrawPaint) {
  {  // Transparent color in paint.
    DisplayListBuilder builder;
    DlPaint paint(DlColor::kTransparent());
    builder.DrawPaint(paint);
    sk_sp<DisplayList> dl = builder.Build();
    DlOpSpy dl_op_spy;
    dl->Dispatch(dl_op_spy);
    ASSERT_FALSE(dl_op_spy.did_draw());
  }
  {  // black color in paint.
    DisplayListBuilder builder;
    DlPaint paint(DlColor::kBlack());
    builder.DrawPaint(paint);
    sk_sp<DisplayList> dl = builder.Build();
    DlOpSpy dl_op_spy;
    dl->Dispatch(dl_op_spy);
    ASSERT_TRUE(dl_op_spy.did_draw());
  }
}

TEST(DlOpSpy, DrawLine) {
  {  // black
    DisplayListBuilder builder;
    DlPaint paint(DlColor::kBlack());
    builder.DrawLine(SkPoint::Make(0, 1), SkPoint::Make(1, 2), paint);
    sk_sp<DisplayList> dl = builder.Build();
    DlOpSpy dl_op_spy;
    dl->Dispatch(dl_op_spy);
    ASSERT_TRUE(dl_op_spy.did_draw());
  }
  {  // transparent
    DisplayListBuilder builder;
    DlPaint paint(DlColor::kTransparent());
    builder.DrawLine(SkPoint::Make(0, 1), SkPoint::Make(1, 2), paint);
    sk_sp<DisplayList> dl = builder.Build();
    DlOpSpy dl_op_spy;
    dl->Dispatch(dl_op_spy);
    ASSERT_FALSE(dl_op_spy.did_draw());
  }
}

TEST(DlOpSpy, DrawRect) {
  {  // black
    DisplayListBuilder builder;
    DlPaint paint(DlColor::kBlack());
    builder.DrawRect(SkRect::MakeWH(5, 5), paint);
    sk_sp<DisplayList> dl = builder.Build();
    DlOpSpy dl_op_spy;
    dl->Dispatch(dl_op_spy);
    ASSERT_TRUE(dl_op_spy.did_draw());
  }
  {  // transparent
    DisplayListBuilder builder;
    DlPaint paint(DlColor::kTransparent());
    builder.DrawRect(SkRect::MakeWH(5, 5), paint);
    sk_sp<DisplayList> dl = builder.Build();
    DlOpSpy dl_op_spy;
    dl->Dispatch(dl_op_spy);
    ASSERT_FALSE(dl_op_spy.did_draw());
  }
}

TEST(DlOpSpy, drawOval) {
  {  // black
    DisplayListBuilder builder;
    DlPaint paint(DlColor::kBlack());
    builder.DrawOval(SkRect::MakeWH(5, 5), paint);
    sk_sp<DisplayList> dl = builder.Build();
    DlOpSpy dl_op_spy;
    dl->Dispatch(dl_op_spy);
    ASSERT_TRUE(dl_op_spy.did_draw());
  }
  {  // transparent
    DisplayListBuilder builder;
    DlPaint paint(DlColor::kTransparent());
    builder.DrawOval(SkRect::MakeWH(5, 5), paint);
    sk_sp<DisplayList> dl = builder.Build();
    DlOpSpy dl_op_spy;
    dl->Dispatch(dl_op_spy);
    ASSERT_FALSE(dl_op_spy.did_draw());
  }
}

TEST(DlOpSpy, drawCircle) {
  {  // black
    DisplayListBuilder builder;
    DlPaint paint(DlColor::kBlack());
    builder.DrawCircle(SkPoint::Make(5, 5), 1.0, paint);
    sk_sp<DisplayList> dl = builder.Build();
    DlOpSpy dl_op_spy;
    dl->Dispatch(dl_op_spy);
    ASSERT_TRUE(dl_op_spy.did_draw());
  }
  {  // transparent
    DisplayListBuilder builder;
    DlPaint paint(DlColor::kTransparent());
    builder.DrawCircle(SkPoint::Make(5, 5), 1.0, paint);
    sk_sp<DisplayList> dl = builder.Build();
    DlOpSpy dl_op_spy;
    dl->Dispatch(dl_op_spy);
    ASSERT_FALSE(dl_op_spy.did_draw());
  }
}

TEST(DlOpSpy, drawRRect) {
  {  // black
    DisplayListBuilder builder;
    DlPaint paint(DlColor::kBlack());
    builder.DrawRRect(SkRRect::MakeRect(SkRect::MakeWH(5, 5)), paint);
    sk_sp<DisplayList> dl = builder.Build();
    DlOpSpy dl_op_spy;
    dl->Dispatch(dl_op_spy);
    ASSERT_TRUE(dl_op_spy.did_draw());
  }
  {  // transparent
    DisplayListBuilder builder;
    DlPaint paint(DlColor::kTransparent());
    builder.DrawRRect(SkRRect::MakeRect(SkRect::MakeWH(5, 5)), paint);
    sk_sp<DisplayList> dl = builder.Build();
    DlOpSpy dl_op_spy;
    dl->Dispatch(dl_op_spy);
    ASSERT_FALSE(dl_op_spy.did_draw());
  }
}

TEST(DlOpSpy, drawPath) {
  {  // black
    DisplayListBuilder builder;
    DlPaint paint(DlColor::kBlack());
    builder.DrawPath(SkPath::Line(SkPoint::Make(0, 1), SkPoint::Make(1, 1)),
                     paint);
    sk_sp<DisplayList> dl = builder.Build();
    DlOpSpy dl_op_spy;
    dl->Dispatch(dl_op_spy);
    ASSERT_TRUE(dl_op_spy.did_draw());
  }
  {  // transparent
    DisplayListBuilder builder;
    DlPaint paint(DlColor::kTransparent());
    builder.DrawPath(SkPath::Line(SkPoint::Make(0, 1), SkPoint::Make(1, 1)),
                     paint);
    sk_sp<DisplayList> dl = builder.Build();
    DlOpSpy dl_op_spy;
    dl->Dispatch(dl_op_spy);
    ASSERT_FALSE(dl_op_spy.did_draw());
  }
}

TEST(DlOpSpy, drawArc) {
  {  // black
    DisplayListBuilder builder;
    DlPaint paint(DlColor::kBlack());
    builder.DrawArc(SkRect::MakeWH(5, 5), 0, 1, true, paint);
    sk_sp<DisplayList> dl = builder.Build();
    DlOpSpy dl_op_spy;
    dl->Dispatch(dl_op_spy);
    ASSERT_TRUE(dl_op_spy.did_draw());
  }
  {  // transparent
    DisplayListBuilder builder;
    DlPaint paint(DlColor::kTransparent());
    builder.DrawArc(SkRect::MakeWH(5, 5), 0, 1, true, paint);
    sk_sp<DisplayList> dl = builder.Build();
    DlOpSpy dl_op_spy;
    dl->Dispatch(dl_op_spy);
    ASSERT_FALSE(dl_op_spy.did_draw());
  }
}

TEST(DlOpSpy, drawPoints) {
  {  // black
    DisplayListBuilder builder;
    DlPaint paint(DlColor::kBlack());
    const SkPoint points[] = {SkPoint::Make(5, 4)};
    builder.DrawPoints(DlCanvas::PointMode::kPoints, 1, points, paint);
    sk_sp<DisplayList> dl = builder.Build();
    DlOpSpy dl_op_spy;
    dl->Dispatch(dl_op_spy);
    ASSERT_TRUE(dl_op_spy.did_draw());
  }
  {  // transparent
    DisplayListBuilder builder;
    DlPaint paint(DlColor::kTransparent());
    const SkPoint points[] = {SkPoint::Make(5, 4)};
    builder.DrawPoints(DlCanvas::PointMode::kPoints, 1, points, paint);
    sk_sp<DisplayList> dl = builder.Build();
    DlOpSpy dl_op_spy;
    dl->Dispatch(dl_op_spy);
    ASSERT_FALSE(dl_op_spy.did_draw());
  }
}

TEST(DlOpSpy, drawVertices) {
  {  // black
    DisplayListBuilder builder;
    DlPaint paint(DlColor::kBlack());
    const SkPoint vertices[] = {SkPoint::Make(5, 5)};
    const SkPoint texture_coordinates[] = {SkPoint::Make(5, 5)};
    const DlColor colors[] = {DlColor::kBlack()};
    auto dl_vertices = DlVertices::Make(DlVertexMode::kTriangles, 1, vertices,
                                        texture_coordinates, colors, 0);
    builder.DrawVertices(dl_vertices.get(), DlBlendMode::kSrc, paint);
    sk_sp<DisplayList> dl = builder.Build();
    DlOpSpy dl_op_spy;
    dl->Dispatch(dl_op_spy);
    ASSERT_TRUE(dl_op_spy.did_draw());
  }
  {  // transparent
    DisplayListBuilder builder;
    DlPaint paint(DlColor::kTransparent());
    const SkPoint vertices[] = {SkPoint::Make(5, 5)};
    const SkPoint texture_coordinates[] = {SkPoint::Make(5, 5)};
    const DlColor colors[] = {DlColor::kBlack()};
    auto dl_vertices = DlVertices::Make(DlVertexMode::kTriangles, 1, vertices,
                                        texture_coordinates, colors, 0);
    builder.DrawVertices(dl_vertices.get(), DlBlendMode::kSrc, paint);
    sk_sp<DisplayList> dl = builder.Build();
    DlOpSpy dl_op_spy;
    dl->Dispatch(dl_op_spy);
    ASSERT_FALSE(dl_op_spy.did_draw());
  }
}

TEST(DlOpSpy, Images) {
  {  // DrawImage
    DisplayListBuilder builder;
    DlPaint paint(DlColor::kBlack());
    SkImageInfo info =
        SkImageInfo::Make(50, 50, SkColorType::kRGBA_8888_SkColorType,
                          SkAlphaType::kPremul_SkAlphaType);
    SkBitmap bitmap;
    bitmap.allocPixels(info, 0);
    auto sk_image = SkImages::RasterFromBitmap(bitmap);
    builder.DrawImage(DlImage::Make(sk_image), SkPoint::Make(5, 5),
                      DlImageSampling::kLinear);
    sk_sp<DisplayList> dl = builder.Build();
    DlOpSpy dl_op_spy;
    dl->Dispatch(dl_op_spy);
    ASSERT_TRUE(dl_op_spy.did_draw());
  }
  {  // DrawImageRect
    DisplayListBuilder builder;
    DlPaint paint(DlColor::kBlack());
    SkImageInfo info =
        SkImageInfo::Make(50, 50, SkColorType::kRGBA_8888_SkColorType,
                          SkAlphaType::kPremul_SkAlphaType);
    SkBitmap bitmap;
    bitmap.allocPixels(info, 0);
    auto sk_image = SkImages::RasterFromBitmap(bitmap);
    builder.DrawImageRect(DlImage::Make(sk_image), SkRect::MakeWH(5, 5),
                          SkRect::MakeWH(5, 5), DlImageSampling::kLinear);
    sk_sp<DisplayList> dl = builder.Build();
    DlOpSpy dl_op_spy;
    dl->Dispatch(dl_op_spy);
    ASSERT_TRUE(dl_op_spy.did_draw());
  }
  {  // DrawImageNine
    DisplayListBuilder builder;
    DlPaint paint(DlColor::kBlack());
    SkImageInfo info =
        SkImageInfo::Make(50, 50, SkColorType::kRGBA_8888_SkColorType,
                          SkAlphaType::kPremul_SkAlphaType);
    SkBitmap bitmap;
    bitmap.allocPixels(info, 0);
    auto sk_image = SkImages::RasterFromBitmap(bitmap);
    builder.DrawImageNine(DlImage::Make(sk_image), SkIRect::MakeWH(5, 5),
                          SkRect::MakeWH(5, 5), DlFilterMode::kLinear);
    sk_sp<DisplayList> dl = builder.Build();
    DlOpSpy dl_op_spy;
    dl->Dispatch(dl_op_spy);
    ASSERT_TRUE(dl_op_spy.did_draw());
  }
  {  // DrawAtlas
    DisplayListBuilder builder;
    DlPaint paint(DlColor::kBlack());
    SkImageInfo info =
        SkImageInfo::Make(50, 50, SkColorType::kRGBA_8888_SkColorType,
                          SkAlphaType::kPremul_SkAlphaType);
    SkBitmap bitmap;
    bitmap.allocPixels(info, 0);
    auto sk_image = SkImages::RasterFromBitmap(bitmap);
    const SkRSXform xform[] = {};
    const SkRect tex[] = {};
    const DlColor colors[] = {};
    SkRect cull_rect = SkRect::MakeWH(5, 5);
    builder.DrawAtlas(DlImage::Make(sk_image), xform, tex, colors, 0,
                      DlBlendMode::kSrc, DlImageSampling::kLinear, &cull_rect);
    sk_sp<DisplayList> dl = builder.Build();
    DlOpSpy dl_op_spy;
    dl->Dispatch(dl_op_spy);
    ASSERT_TRUE(dl_op_spy.did_draw());
  }
}

TEST(DlOpSpy, drawDisplayList) {
  {  // Recursive Transparent DisplayList
    DisplayListBuilder builder;
    DlPaint paint(DlColor::kTransparent());
    builder.DrawPaint(paint);
    sk_sp<DisplayList> dl = builder.Build();

    DisplayListBuilder builder_parent;
    DlPaint paint_parent(DlColor::kTransparent());
    builder_parent.DrawPaint(paint_parent);
    builder_parent.DrawDisplayList(dl, 1);
    sk_sp<DisplayList> dl2 = builder_parent.Build();

    DlOpSpy dl_op_spy;
    dl2->Dispatch(dl_op_spy);
    ASSERT_FALSE(dl_op_spy.did_draw());
  }
  {  // Sub non-transparent DisplayList,
    DisplayListBuilder builder;
    DlPaint paint(DlColor::kBlack());
    builder.DrawPaint(paint);
    sk_sp<DisplayList> dl = builder.Build();

    DisplayListBuilder builder_parent;
    DlPaint paint_parent(DlColor::kTransparent());
    builder_parent.DrawPaint(paint_parent);
    builder_parent.DrawDisplayList(dl, 1);
    sk_sp<DisplayList> dl2 = builder_parent.Build();

    DlOpSpy dl_op_spy;
    dl2->Dispatch(dl_op_spy);
    ASSERT_TRUE(dl_op_spy.did_draw());
  }

  {  // Sub non-transparent DisplayList, 0 opacity
    DisplayListBuilder builder;
    DlPaint paint(DlColor::kBlack());
    builder.DrawPaint(paint);
    sk_sp<DisplayList> dl = builder.Build();

    DisplayListBuilder builder_parent;
    DlPaint paint_parent(DlColor::kTransparent());
    builder_parent.DrawPaint(paint_parent);
    builder_parent.DrawDisplayList(dl, 0);
    sk_sp<DisplayList> dl2 = builder_parent.Build();

    DlOpSpy dl_op_spy;
    dl2->Dispatch(dl_op_spy);
    ASSERT_FALSE(dl_op_spy.did_draw());
  }

  {  // Parent non-transparent DisplayList
    DisplayListBuilder builder;
    DlPaint paint(DlColor::kTransparent());
    builder.DrawPaint(paint);
    sk_sp<DisplayList> dl = builder.Build();

    DisplayListBuilder builder_parent;
    DlPaint paint_parent(DlColor::kBlack());
    builder_parent.DrawPaint(paint_parent);
    builder_parent.DrawDisplayList(dl, 0);
    sk_sp<DisplayList> dl2 = builder_parent.Build();

    DlOpSpy dl_op_spy;
    dl2->Dispatch(dl_op_spy);
    ASSERT_TRUE(dl_op_spy.did_draw());
  }
}

TEST(DlOpSpy, drawTextBlob) {
  {  // Non-transparent color.
    DisplayListBuilder builder;
    DlPaint paint(DlColor::kBlack());
    std::string string = "xx";
    SkFont font;
    auto text_blob = SkTextBlob::MakeFromString(string.c_str(), font);
    builder.DrawTextBlob(text_blob, 1, 1, paint);
    sk_sp<DisplayList> dl = builder.Build();
    DlOpSpy dl_op_spy;
    dl->Dispatch(dl_op_spy);
    ASSERT_TRUE(dl_op_spy.did_draw());
  }
  {  // transparent color.
    DisplayListBuilder builder;
    DlPaint paint(DlColor::kTransparent());
    std::string string = "xx";
    SkFont font;
    auto text_blob = SkTextBlob::MakeFromString(string.c_str(), font);
    builder.DrawTextBlob(text_blob, 1, 1, paint);
    sk_sp<DisplayList> dl = builder.Build();
    DlOpSpy dl_op_spy;
    dl->Dispatch(dl_op_spy);
    ASSERT_FALSE(dl_op_spy.did_draw());
  }
}

TEST(DlOpSpy, drawShadow) {
  {  // valid shadow
    DisplayListBuilder builder;
    DlPaint paint;
    DlColor color = DlColor::kBlack();
    SkPath path = SkPath::Line(SkPoint::Make(0, 1), SkPoint::Make(1, 1));
    builder.DrawShadow(path, color, 1, false, 1);
    sk_sp<DisplayList> dl = builder.Build();
    DlOpSpy dl_op_spy;
    dl->Dispatch(dl_op_spy);
    ASSERT_TRUE(dl_op_spy.did_draw());
  }
  {  // transparent color
    DisplayListBuilder builder;
    DlPaint paint;
    DlColor color = DlColor::kTransparent();
    SkPath path = SkPath::Line(SkPoint::Make(0, 1), SkPoint::Make(1, 1));
    builder.DrawShadow(path, color, 1, false, 1);
    sk_sp<DisplayList> dl = builder.Build();
    DlOpSpy dl_op_spy;
    dl->Dispatch(dl_op_spy);
    ASSERT_FALSE(dl_op_spy.did_draw());
  }
}

}  // namespace testing
}  // namespace flutter
