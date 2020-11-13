// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/shader_mask_layer.h"

#include "flutter/flow/testing/layer_test.h"
#include "flutter/flow/testing/mock_layer.h"
#include "flutter/fml/macros.h"
#include "flutter/testing/mock_canvas.h"
#include "third_party/skia/include/core/SkShader.h"
#include "third_party/skia/include/effects/SkPerlinNoiseShader.h"

namespace flutter {
namespace testing {

using ShaderMaskLayerTest = LayerTest;

#ifndef NDEBUG
TEST_F(ShaderMaskLayerTest, PaintingEmptyLayerDies) {
  auto layer =
      std::make_shared<ShaderMaskLayer>(nullptr, kEmptyRect, SkBlendMode::kSrc);

  layer->Preroll(preroll_context(), SkMatrix());
  EXPECT_EQ(layer->paint_bounds(), kEmptyRect);
  EXPECT_FALSE(layer->needs_painting(paint_context()));

  EXPECT_DEATH_IF_SUPPORTED(layer->Paint(paint_context()),
                            "needs_painting\\(context\\)");
}

TEST_F(ShaderMaskLayerTest, PaintBeforePreollDies) {
  const SkRect child_bounds = SkRect::MakeLTRB(5.0f, 6.0f, 20.5f, 21.5f);
  const SkPath child_path = SkPath().addRect(child_bounds);
  auto mock_layer = std::make_shared<MockLayer>(child_path);
  auto layer =
      std::make_shared<ShaderMaskLayer>(nullptr, kEmptyRect, SkBlendMode::kSrc);
  layer->Add(mock_layer);

  EXPECT_EQ(layer->paint_bounds(), kEmptyRect);
  EXPECT_DEATH_IF_SUPPORTED(layer->Paint(paint_context()),
                            "needs_painting\\(context\\)");
}
#endif

TEST_F(ShaderMaskLayerTest, EmptyFilter) {
  const SkMatrix initial_transform = SkMatrix::Translate(0.5f, 1.0f);
  const SkRect child_bounds = SkRect::MakeLTRB(5.0f, 6.0f, 20.5f, 21.5f);
  const SkRect layer_bounds = SkRect::MakeLTRB(2.0f, 4.0f, 6.5f, 6.5f);
  const SkPath child_path = SkPath().addRect(child_bounds);
  const SkPaint child_paint = SkPaint(SkColors::kYellow);
  auto mock_layer = std::make_shared<MockLayer>(child_path, child_paint);
  auto layer = std::make_shared<ShaderMaskLayer>(nullptr, layer_bounds,
                                                 SkBlendMode::kSrc);
  layer->Add(mock_layer);

  layer->Preroll(preroll_context(), initial_transform);
  EXPECT_EQ(mock_layer->paint_bounds(), child_bounds);
  EXPECT_EQ(layer->paint_bounds(), child_bounds);
  EXPECT_TRUE(mock_layer->needs_painting(paint_context()));
  EXPECT_TRUE(layer->needs_painting(paint_context()));
  EXPECT_EQ(mock_layer->parent_matrix(), initial_transform);

  SkPaint filter_paint;
  filter_paint.setBlendMode(SkBlendMode::kSrc);
  filter_paint.setShader(nullptr);
  layer->Paint(paint_context());
  EXPECT_EQ(
      mock_canvas().draw_calls(),
      std::vector({MockCanvas::DrawCall{
                       0, MockCanvas::SaveLayerData{child_bounds, SkPaint(),
                                                    nullptr, 1}},
                   MockCanvas::DrawCall{
                       1, MockCanvas::DrawPathData{child_path, child_paint}},
                   MockCanvas::DrawCall{
                       1, MockCanvas::ConcatMatrixData{SkMatrix::Translate(
                              layer_bounds.fLeft, layer_bounds.fTop)}},
                   MockCanvas::DrawCall{
                       1, MockCanvas::DrawRectData{SkRect::MakeWH(
                                                       layer_bounds.width(),
                                                       layer_bounds.height()),
                                                   filter_paint}},
                   MockCanvas::DrawCall{1, MockCanvas::RestoreData{0}}}));
}

TEST_F(ShaderMaskLayerTest, SimpleFilter) {
  const SkMatrix initial_transform = SkMatrix::Translate(0.5f, 1.0f);
  const SkRect child_bounds = SkRect::MakeLTRB(5.0f, 6.0f, 20.5f, 21.5f);
  const SkRect layer_bounds = SkRect::MakeLTRB(2.0f, 4.0f, 6.5f, 6.5f);
  const SkPath child_path = SkPath().addRect(child_bounds);
  const SkPaint child_paint = SkPaint(SkColors::kYellow);
  auto layer_filter =
      SkPerlinNoiseShader::MakeImprovedNoise(1.0f, 1.0f, 1, 1.0f);
  auto mock_layer = std::make_shared<MockLayer>(child_path, child_paint);
  auto layer = std::make_shared<ShaderMaskLayer>(layer_filter, layer_bounds,
                                                 SkBlendMode::kSrc);
  layer->Add(mock_layer);

  layer->Preroll(preroll_context(), initial_transform);
  EXPECT_EQ(layer->paint_bounds(), child_bounds);
  EXPECT_TRUE(layer->needs_painting(paint_context()));
  EXPECT_EQ(mock_layer->parent_matrix(), initial_transform);

  SkPaint filter_paint;
  filter_paint.setBlendMode(SkBlendMode::kSrc);
  filter_paint.setShader(layer_filter);
  layer->Paint(paint_context());
  EXPECT_EQ(
      mock_canvas().draw_calls(),
      std::vector({MockCanvas::DrawCall{
                       0, MockCanvas::SaveLayerData{child_bounds, SkPaint(),
                                                    nullptr, 1}},
                   MockCanvas::DrawCall{
                       1, MockCanvas::DrawPathData{child_path, child_paint}},
                   MockCanvas::DrawCall{
                       1, MockCanvas::ConcatMatrixData{SkMatrix::Translate(
                              layer_bounds.fLeft, layer_bounds.fTop)}},
                   MockCanvas::DrawCall{
                       1, MockCanvas::DrawRectData{SkRect::MakeWH(
                                                       layer_bounds.width(),
                                                       layer_bounds.height()),
                                                   filter_paint}},
                   MockCanvas::DrawCall{1, MockCanvas::RestoreData{0}}}));
}

TEST_F(ShaderMaskLayerTest, MultipleChildren) {
  const SkMatrix initial_transform = SkMatrix::Translate(0.5f, 1.0f);
  const SkRect child_bounds = SkRect::MakeLTRB(5.0f, 6.0f, 20.5f, 21.5f);
  const SkRect layer_bounds = SkRect::MakeLTRB(2.0f, 4.0f, 6.5f, 6.5f);
  const SkPath child_path1 = SkPath().addRect(child_bounds);
  const SkPath child_path2 =
      SkPath().addRect(child_bounds.makeOffset(3.0f, 0.0f));
  const SkPaint child_paint1 = SkPaint(SkColors::kYellow);
  const SkPaint child_paint2 = SkPaint(SkColors::kCyan);
  auto layer_filter =
      SkPerlinNoiseShader::MakeImprovedNoise(1.0f, 1.0f, 1, 1.0f);
  auto mock_layer1 = std::make_shared<MockLayer>(child_path1, child_paint1);
  auto mock_layer2 = std::make_shared<MockLayer>(child_path2, child_paint2);
  auto layer = std::make_shared<ShaderMaskLayer>(layer_filter, layer_bounds,
                                                 SkBlendMode::kSrc);
  layer->Add(mock_layer1);
  layer->Add(mock_layer2);

  SkRect children_bounds = child_path1.getBounds();
  children_bounds.join(child_path2.getBounds());
  layer->Preroll(preroll_context(), initial_transform);
  EXPECT_EQ(mock_layer1->paint_bounds(), child_path1.getBounds());
  EXPECT_EQ(mock_layer2->paint_bounds(), child_path2.getBounds());
  EXPECT_EQ(layer->paint_bounds(), children_bounds);
  EXPECT_TRUE(mock_layer1->needs_painting(paint_context()));
  EXPECT_TRUE(mock_layer2->needs_painting(paint_context()));
  EXPECT_TRUE(layer->needs_painting(paint_context()));
  EXPECT_EQ(mock_layer1->parent_matrix(), initial_transform);
  EXPECT_EQ(mock_layer2->parent_matrix(), initial_transform);

  SkPaint filter_paint;
  filter_paint.setBlendMode(SkBlendMode::kSrc);
  filter_paint.setShader(layer_filter);
  layer->Paint(paint_context());
  EXPECT_EQ(
      mock_canvas().draw_calls(),
      std::vector({MockCanvas::DrawCall{
                       0, MockCanvas::SaveLayerData{children_bounds, SkPaint(),
                                                    nullptr, 1}},
                   MockCanvas::DrawCall{
                       1, MockCanvas::DrawPathData{child_path1, child_paint1}},
                   MockCanvas::DrawCall{
                       1, MockCanvas::DrawPathData{child_path2, child_paint2}},
                   MockCanvas::DrawCall{
                       1, MockCanvas::ConcatMatrixData{SkMatrix::Translate(
                              layer_bounds.fLeft, layer_bounds.fTop)}},
                   MockCanvas::DrawCall{
                       1, MockCanvas::DrawRectData{SkRect::MakeWH(
                                                       layer_bounds.width(),
                                                       layer_bounds.height()),
                                                   filter_paint}},
                   MockCanvas::DrawCall{1, MockCanvas::RestoreData{0}}}));
}

TEST_F(ShaderMaskLayerTest, Nested) {
  const SkMatrix initial_transform = SkMatrix::Translate(0.5f, 1.0f);
  const SkRect child_bounds = SkRect::MakeLTRB(5.0f, 6.0f, 7.5f, 8.5f);
  const SkRect layer_bounds = SkRect::MakeLTRB(2.0f, 4.0f, 20.5f, 20.5f);
  const SkPath child_path1 = SkPath().addRect(child_bounds);
  const SkPath child_path2 =
      SkPath().addRect(child_bounds.makeOffset(3.0f, 0.0f));
  const SkPaint child_paint1 = SkPaint(SkColors::kYellow);
  const SkPaint child_paint2 = SkPaint(SkColors::kCyan);
  auto layer_filter1 =
      SkPerlinNoiseShader::MakeImprovedNoise(1.0f, 1.0f, 1, 1.0f);
  auto layer_filter2 =
      SkPerlinNoiseShader::MakeImprovedNoise(2.0f, 2.0f, 2, 2.0f);
  auto mock_layer1 = std::make_shared<MockLayer>(child_path1, child_paint1);
  auto mock_layer2 = std::make_shared<MockLayer>(child_path2, child_paint2);
  auto layer1 = std::make_shared<ShaderMaskLayer>(layer_filter1, layer_bounds,
                                                  SkBlendMode::kSrc);
  auto layer2 = std::make_shared<ShaderMaskLayer>(layer_filter2, layer_bounds,
                                                  SkBlendMode::kSrc);
  layer2->Add(mock_layer2);
  layer1->Add(mock_layer1);
  layer1->Add(layer2);

  SkRect children_bounds = child_path1.getBounds();
  children_bounds.join(child_path2.getBounds());
  layer1->Preroll(preroll_context(), initial_transform);
  EXPECT_EQ(mock_layer1->paint_bounds(), child_path1.getBounds());
  EXPECT_EQ(mock_layer2->paint_bounds(), child_path2.getBounds());
  EXPECT_EQ(layer1->paint_bounds(), children_bounds);
  EXPECT_EQ(layer2->paint_bounds(), mock_layer2->paint_bounds());
  EXPECT_TRUE(mock_layer1->needs_painting(paint_context()));
  EXPECT_TRUE(mock_layer2->needs_painting(paint_context()));
  EXPECT_TRUE(layer1->needs_painting(paint_context()));
  EXPECT_TRUE(layer2->needs_painting(paint_context()));
  EXPECT_EQ(mock_layer1->parent_matrix(), initial_transform);
  EXPECT_EQ(mock_layer2->parent_matrix(), initial_transform);

  SkPaint filter_paint1, filter_paint2;
  filter_paint1.setBlendMode(SkBlendMode::kSrc);
  filter_paint2.setBlendMode(SkBlendMode::kSrc);
  filter_paint1.setShader(layer_filter1);
  filter_paint2.setShader(layer_filter2);
  layer1->Paint(paint_context());
  EXPECT_EQ(
      mock_canvas().draw_calls(),
      std::vector(
          {MockCanvas::DrawCall{
               0, MockCanvas::SaveLayerData{children_bounds, SkPaint(), nullptr,
                                            1}},
           MockCanvas::DrawCall{
               1, MockCanvas::DrawPathData{child_path1, child_paint1}},
           MockCanvas::DrawCall{
               1, MockCanvas::SaveLayerData{child_path2.getBounds(), SkPaint(),
                                            nullptr, 2}},
           MockCanvas::DrawCall{
               2, MockCanvas::DrawPathData{child_path2, child_paint2}},
           MockCanvas::DrawCall{
               2, MockCanvas::ConcatMatrixData{SkMatrix::Translate(
                      layer_bounds.fLeft, layer_bounds.fTop)}},
           MockCanvas::DrawCall{
               2,
               MockCanvas::DrawRectData{
                   SkRect::MakeWH(layer_bounds.width(), layer_bounds.height()),
                   filter_paint2}},
           MockCanvas::DrawCall{2, MockCanvas::RestoreData{1}},
           MockCanvas::DrawCall{
               1, MockCanvas::ConcatMatrixData{SkMatrix::Translate(
                      layer_bounds.fLeft, layer_bounds.fTop)}},
           MockCanvas::DrawCall{
               1,
               MockCanvas::DrawRectData{
                   SkRect::MakeWH(layer_bounds.width(), layer_bounds.height()),
                   filter_paint1}},
           MockCanvas::DrawCall{1, MockCanvas::RestoreData{0}}}));
}

TEST_F(ShaderMaskLayerTest, Readback) {
  auto initial_transform = SkMatrix();
  const SkRect layer_bounds = SkRect::MakeLTRB(2.0f, 4.0f, 20.5f, 20.5f);
  auto layer_filter =
      SkPerlinNoiseShader::MakeImprovedNoise(1.0f, 1.0f, 1, 1.0f);
  auto layer = std::make_shared<ShaderMaskLayer>(layer_filter, layer_bounds,
                                                 SkBlendMode::kSrc);

  // ShaderMaskLayer does not read from surface
  preroll_context()->surface_needs_readback = false;
  layer->Preroll(preroll_context(), initial_transform);
  EXPECT_FALSE(preroll_context()->surface_needs_readback);

  // ShaderMaskLayer blocks child with readback
  auto mock_layer =
      std::make_shared<MockLayer>(SkPath(), SkPaint(), false, false, true);
  layer->Add(mock_layer);
  preroll_context()->surface_needs_readback = false;
  layer->Preroll(preroll_context(), initial_transform);
  EXPECT_FALSE(preroll_context()->surface_needs_readback);
}

}  // namespace testing
}  // namespace flutter
