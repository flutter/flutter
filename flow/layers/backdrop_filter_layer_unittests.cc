// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/backdrop_filter_layer.h"
#include "flutter/flow/layers/clip_rect_layer.h"

#include "flutter/flow/layers/clip_rect_layer.h"
#include "flutter/flow/layers/transform_layer.h"
#include "flutter/flow/testing/diff_context_test.h"
#include "flutter/flow/testing/layer_test.h"
#include "flutter/flow/testing/mock_layer.h"
#include "flutter/fml/macros.h"
#include "flutter/testing/mock_canvas.h"
#include "third_party/skia/include/core/SkImageFilter.h"
#include "third_party/skia/include/effects/SkImageFilters.h"

namespace flutter {
namespace testing {

using BackdropFilterLayerTest = LayerTest;

#ifndef NDEBUG
TEST_F(BackdropFilterLayerTest, PaintingEmptyLayerDies) {
  auto layer = std::make_shared<BackdropFilterLayer>(sk_sp<SkImageFilter>(),
                                                     SkBlendMode::kSrcOver);
  auto parent = std::make_shared<ClipRectLayer>(kEmptyRect, Clip::hardEdge);
  parent->Add(layer);

  parent->Preroll(preroll_context(), SkMatrix());
  EXPECT_EQ(layer->paint_bounds(), kEmptyRect);
  EXPECT_FALSE(layer->needs_painting(paint_context()));

  EXPECT_DEATH_IF_SUPPORTED(layer->Paint(paint_context()),
                            "needs_painting\\(context\\)");
}

TEST_F(BackdropFilterLayerTest, PaintBeforePrerollDies) {
  const SkRect child_bounds = SkRect::MakeLTRB(5.0f, 6.0f, 20.5f, 21.5f);
  const SkPath child_path = SkPath().addRect(child_bounds);
  auto mock_layer = std::make_shared<MockLayer>(child_path);
  auto layer = std::make_shared<BackdropFilterLayer>(sk_sp<SkImageFilter>(),
                                                     SkBlendMode::kSrcOver);
  layer->Add(mock_layer);

  EXPECT_EQ(layer->paint_bounds(), kEmptyRect);
  EXPECT_DEATH_IF_SUPPORTED(layer->Paint(paint_context()),
                            "needs_painting\\(context\\)");
}
#endif

TEST_F(BackdropFilterLayerTest, EmptyFilter) {
  const SkMatrix initial_transform = SkMatrix::Translate(0.5f, 1.0f);
  const SkRect child_bounds = SkRect::MakeLTRB(5.0f, 6.0f, 20.5f, 21.5f);
  const SkPath child_path = SkPath().addRect(child_bounds);
  const SkPaint child_paint = SkPaint(SkColors::kYellow);
  auto mock_layer = std::make_shared<MockLayer>(child_path, child_paint);
  auto layer =
      std::make_shared<BackdropFilterLayer>(nullptr, SkBlendMode::kSrcOver);
  layer->Add(mock_layer);
  auto parent = std::make_shared<ClipRectLayer>(child_bounds, Clip::hardEdge);
  parent->Add(layer);

  parent->Preroll(preroll_context(), initial_transform);
  EXPECT_EQ(layer->paint_bounds(), child_bounds);
  EXPECT_TRUE(layer->needs_painting(paint_context()));
  EXPECT_EQ(mock_layer->parent_matrix(), initial_transform);

  layer->Paint(paint_context());
  EXPECT_EQ(
      mock_canvas().draw_calls(),
      std::vector({MockCanvas::DrawCall{
                       0, MockCanvas::SaveLayerData{child_bounds, SkPaint(),
                                                    nullptr, 1}},
                   MockCanvas::DrawCall{
                       1, MockCanvas::DrawPathData{child_path, child_paint}},
                   MockCanvas::DrawCall{1, MockCanvas::RestoreData{0}}}));
}

TEST_F(BackdropFilterLayerTest, SimpleFilter) {
  const SkMatrix initial_transform = SkMatrix::Translate(0.5f, 1.0f);
  const SkRect child_bounds = SkRect::MakeLTRB(5.0f, 6.0f, 20.5f, 21.5f);
  const SkPath child_path = SkPath().addRect(child_bounds);
  const SkPaint child_paint = SkPaint(SkColors::kYellow);
  auto layer_filter = SkImageFilters::Paint(SkPaint(SkColors::kMagenta));
  auto mock_layer = std::make_shared<MockLayer>(child_path, child_paint);
  auto layer = std::make_shared<BackdropFilterLayer>(layer_filter,
                                                     SkBlendMode::kSrcOver);
  layer->Add(mock_layer);
  auto parent = std::make_shared<ClipRectLayer>(child_bounds, Clip::hardEdge);
  parent->Add(layer);

  parent->Preroll(preroll_context(), initial_transform);
  EXPECT_EQ(layer->paint_bounds(), child_bounds);
  EXPECT_TRUE(layer->needs_painting(paint_context()));
  EXPECT_EQ(mock_layer->parent_matrix(), initial_transform);

  layer->Paint(paint_context());
  EXPECT_EQ(
      mock_canvas().draw_calls(),
      std::vector({MockCanvas::DrawCall{
                       0, MockCanvas::SaveLayerData{child_bounds, SkPaint(),
                                                    layer_filter, 1}},
                   MockCanvas::DrawCall{
                       1, MockCanvas::DrawPathData{child_path, child_paint}},
                   MockCanvas::DrawCall{1, MockCanvas::RestoreData{0}}}));
}

TEST_F(BackdropFilterLayerTest, NonSrcOverBlend) {
  const SkMatrix initial_transform = SkMatrix::Translate(0.5f, 1.0f);
  const SkRect child_bounds = SkRect::MakeLTRB(5.0f, 6.0f, 20.5f, 21.5f);
  const SkPath child_path = SkPath().addRect(child_bounds);
  const SkPaint child_paint = SkPaint(SkColors::kYellow);
  auto layer_filter = SkImageFilters::Paint(SkPaint(SkColors::kMagenta));
  auto mock_layer = std::make_shared<MockLayer>(child_path, child_paint);
  auto layer =
      std::make_shared<BackdropFilterLayer>(layer_filter, SkBlendMode::kSrc);
  layer->Add(mock_layer);
  auto parent = std::make_shared<ClipRectLayer>(child_bounds, Clip::hardEdge);
  parent->Add(layer);

  parent->Preroll(preroll_context(), initial_transform);
  EXPECT_EQ(layer->paint_bounds(), child_bounds);
  EXPECT_TRUE(layer->needs_painting(paint_context()));
  EXPECT_EQ(mock_layer->parent_matrix(), initial_transform);

  SkPaint filter_paint = SkPaint();
  filter_paint.setBlendMode(SkBlendMode::kSrc);

  layer->Paint(paint_context());
  EXPECT_EQ(
      mock_canvas().draw_calls(),
      std::vector({MockCanvas::DrawCall{
                       0, MockCanvas::SaveLayerData{child_bounds, filter_paint,
                                                    layer_filter, 1}},
                   MockCanvas::DrawCall{
                       1, MockCanvas::DrawPathData{child_path, child_paint}},
                   MockCanvas::DrawCall{1, MockCanvas::RestoreData{0}}}));
}

TEST_F(BackdropFilterLayerTest, MultipleChildren) {
  const SkMatrix initial_transform = SkMatrix::Translate(0.5f, 1.0f);
  const SkRect child_bounds = SkRect::MakeLTRB(5.0f, 6.0f, 2.5f, 3.5f);
  const SkPath child_path1 = SkPath().addRect(child_bounds);
  const SkPath child_path2 =
      SkPath().addRect(child_bounds.makeOffset(3.0f, 0.0f));
  const SkPaint child_paint1 = SkPaint(SkColors::kYellow);
  const SkPaint child_paint2 = SkPaint(SkColors::kCyan);
  SkRect children_bounds = child_path1.getBounds();
  children_bounds.join(child_path2.getBounds());
  auto layer_filter = SkImageFilters::Paint(SkPaint(SkColors::kMagenta));
  auto mock_layer1 = std::make_shared<MockLayer>(child_path1, child_paint1);
  auto mock_layer2 = std::make_shared<MockLayer>(child_path2, child_paint2);
  auto layer = std::make_shared<BackdropFilterLayer>(layer_filter,
                                                     SkBlendMode::kSrcOver);
  layer->Add(mock_layer1);
  layer->Add(mock_layer2);
  auto parent =
      std::make_shared<ClipRectLayer>(children_bounds, Clip::hardEdge);
  parent->Add(layer);

  parent->Preroll(preroll_context(), initial_transform);
  EXPECT_EQ(mock_layer1->paint_bounds(), child_path1.getBounds());
  EXPECT_EQ(mock_layer2->paint_bounds(), child_path2.getBounds());
  EXPECT_EQ(layer->paint_bounds(), children_bounds);
  EXPECT_TRUE(mock_layer1->needs_painting(paint_context()));
  EXPECT_TRUE(mock_layer2->needs_painting(paint_context()));
  EXPECT_TRUE(layer->needs_painting(paint_context()));
  EXPECT_EQ(mock_layer1->parent_matrix(), initial_transform);
  EXPECT_EQ(mock_layer2->parent_matrix(), initial_transform);

  layer->Paint(paint_context());
  EXPECT_EQ(
      mock_canvas().draw_calls(),
      std::vector({MockCanvas::DrawCall{
                       0, MockCanvas::SaveLayerData{children_bounds, SkPaint(),
                                                    layer_filter, 1}},
                   MockCanvas::DrawCall{
                       1, MockCanvas::DrawPathData{child_path1, child_paint1}},
                   MockCanvas::DrawCall{
                       1, MockCanvas::DrawPathData{child_path2, child_paint2}},
                   MockCanvas::DrawCall{1, MockCanvas::RestoreData{0}}}));
}

TEST_F(BackdropFilterLayerTest, Nested) {
  const SkMatrix initial_transform = SkMatrix::Translate(0.5f, 1.0f);
  const SkRect child_bounds = SkRect::MakeLTRB(5.0f, 6.0f, 2.5f, 3.5f);
  const SkPath child_path1 = SkPath().addRect(child_bounds);
  const SkPath child_path2 =
      SkPath().addRect(child_bounds.makeOffset(3.0f, 0.0f));
  const SkPaint child_paint1 = SkPaint(SkColors::kYellow);
  const SkPaint child_paint2 = SkPaint(SkColors::kCyan);
  SkRect children_bounds = child_path1.getBounds();
  children_bounds.join(child_path2.getBounds());
  auto layer_filter1 = SkImageFilters::Paint(SkPaint(SkColors::kMagenta));
  auto layer_filter2 = SkImageFilters::Paint(SkPaint(SkColors::kDkGray));
  auto mock_layer1 = std::make_shared<MockLayer>(child_path1, child_paint1);
  auto mock_layer2 = std::make_shared<MockLayer>(child_path2, child_paint2);
  auto layer1 = std::make_shared<BackdropFilterLayer>(layer_filter1,
                                                      SkBlendMode::kSrcOver);
  auto layer2 = std::make_shared<BackdropFilterLayer>(layer_filter2,
                                                      SkBlendMode::kSrcOver);
  layer2->Add(mock_layer2);
  layer1->Add(mock_layer1);
  layer1->Add(layer2);
  auto parent =
      std::make_shared<ClipRectLayer>(children_bounds, Clip::hardEdge);
  parent->Add(layer1);

  parent->Preroll(preroll_context(), initial_transform);
  EXPECT_EQ(mock_layer1->paint_bounds(), child_path1.getBounds());
  EXPECT_EQ(mock_layer2->paint_bounds(), child_path2.getBounds());
  EXPECT_EQ(layer1->paint_bounds(), children_bounds);
  EXPECT_EQ(layer2->paint_bounds(), children_bounds);
  EXPECT_TRUE(mock_layer1->needs_painting(paint_context()));
  EXPECT_TRUE(mock_layer2->needs_painting(paint_context()));
  EXPECT_TRUE(layer1->needs_painting(paint_context()));
  EXPECT_TRUE(layer2->needs_painting(paint_context()));
  EXPECT_EQ(mock_layer1->parent_matrix(), initial_transform);
  EXPECT_EQ(mock_layer2->parent_matrix(), initial_transform);

  layer1->Paint(paint_context());
  EXPECT_EQ(
      mock_canvas().draw_calls(),
      std::vector({MockCanvas::DrawCall{
                       0, MockCanvas::SaveLayerData{children_bounds, SkPaint(),
                                                    layer_filter1, 1}},
                   MockCanvas::DrawCall{
                       1, MockCanvas::DrawPathData{child_path1, child_paint1}},
                   MockCanvas::DrawCall{
                       1, MockCanvas::SaveLayerData{children_bounds, SkPaint(),
                                                    layer_filter2, 2}},
                   MockCanvas::DrawCall{
                       2, MockCanvas::DrawPathData{child_path2, child_paint2}},
                   MockCanvas::DrawCall{2, MockCanvas::RestoreData{1}},
                   MockCanvas::DrawCall{1, MockCanvas::RestoreData{0}}}));
}

TEST_F(BackdropFilterLayerTest, Readback) {
  sk_sp<SkImageFilter> no_filter;
  auto layer_filter = SkImageFilters::Paint(SkPaint(SkColors::kMagenta));
  auto initial_transform = SkMatrix();

  // BDF with filter always reads from surface
  auto layer1 = std::make_shared<BackdropFilterLayer>(layer_filter,
                                                      SkBlendMode::kSrcOver);
  preroll_context()->surface_needs_readback = false;
  layer1->Preroll(preroll_context(), initial_transform);
  EXPECT_TRUE(preroll_context()->surface_needs_readback);

  // BDF with no filter does not read from surface itself
  auto layer2 =
      std::make_shared<BackdropFilterLayer>(no_filter, SkBlendMode::kSrcOver);
  preroll_context()->surface_needs_readback = false;
  layer2->Preroll(preroll_context(), initial_transform);
  EXPECT_FALSE(preroll_context()->surface_needs_readback);

  // BDF with no filter does not block prior readback value
  preroll_context()->surface_needs_readback = true;
  layer2->Preroll(preroll_context(), initial_transform);
  EXPECT_TRUE(preroll_context()->surface_needs_readback);

  // BDF with no filter blocks child with readback
  auto mock_layer =
      std::make_shared<MockLayer>(SkPath(), SkPaint(), false, true);
  layer2->Add(mock_layer);
  preroll_context()->surface_needs_readback = false;
  layer2->Preroll(preroll_context(), initial_transform);
  EXPECT_FALSE(preroll_context()->surface_needs_readback);
}

#ifdef FLUTTER_ENABLE_DIFF_CONTEXT

using BackdropLayerDiffTest = DiffContextTest;

TEST_F(BackdropLayerDiffTest, BackdropLayer) {
  auto filter = SkImageFilters::Blur(10, 10, SkTileMode::kClamp, nullptr);

  {
    // tests later assume 30px readback area, fail early if that's not the case
    auto readback = filter->filterBounds(SkIRect::MakeWH(10, 10), SkMatrix::I(),
                                         SkImageFilter::kReverse_MapDirection);
    EXPECT_EQ(readback, SkIRect::MakeLTRB(-30, -30, 40, 40));
  }

  MockLayerTree l1(SkISize::Make(100, 100));
  l1.root()->Add(
      std::make_shared<BackdropFilterLayer>(filter, SkBlendMode::kSrcOver));

  // no clip, effect over entire surface
  auto damage = DiffLayerTree(l1, MockLayerTree(SkISize::Make(100, 100)));
  EXPECT_EQ(damage.frame_damage, SkIRect::MakeWH(100, 100));

  MockLayerTree l2(SkISize::Make(100, 100));

  auto clip = std::make_shared<ClipRectLayer>(SkRect::MakeLTRB(20, 20, 60, 60),
                                              Clip::hardEdge);
  clip->Add(
      std::make_shared<BackdropFilterLayer>(filter, SkBlendMode::kSrcOver));
  l2.root()->Add(clip);
  damage = DiffLayerTree(l2, MockLayerTree(SkISize::Make(100, 100)));

  EXPECT_EQ(damage.frame_damage, SkIRect::MakeLTRB(0, 0, 90, 90));

  MockLayerTree l3;
  auto scale = std::make_shared<TransformLayer>(SkMatrix::Scale(2.0, 2.0));
  scale->Add(clip);
  l3.root()->Add(scale);

  damage = DiffLayerTree(l3, MockLayerTree());
  EXPECT_EQ(damage.frame_damage, SkIRect::MakeLTRB(0, 0, 180, 180));

  MockLayerTree l4;
  l4.root()->Add(scale);

  // path just outside of readback region, doesn't affect blur
  auto path1 = SkPath().addRect(SkRect::MakeLTRB(180, 180, 190, 190));
  l4.root()->Add(std::make_shared<MockLayer>(path1));
  damage = DiffLayerTree(l4, l3);
  EXPECT_EQ(damage.frame_damage, SkIRect::MakeLTRB(180, 180, 190, 190));

  MockLayerTree l5;
  l5.root()->Add(scale);

  // path just inside of readback region, must trigger backdrop repaint
  auto path2 = SkPath().addRect(SkRect::MakeLTRB(179, 179, 189, 189));
  l5.root()->Add(std::make_shared<MockLayer>(path2));
  damage = DiffLayerTree(l5, l4);
  EXPECT_EQ(damage.frame_damage, SkIRect::MakeLTRB(0, 0, 190, 190));
}

#endif

}  // namespace testing
}  // namespace flutter
