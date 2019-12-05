// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/physical_shape_layer.h"

#include "flutter/flow/testing/layer_test.h"
#include "flutter/flow/testing/mock_layer.h"
#include "flutter/fml/macros.h"
#include "flutter/testing/mock_canvas.h"

namespace flutter {
namespace testing {

using PhysicalShapeLayerTest = LayerTest;

#ifndef NDEBUG
TEST_F(PhysicalShapeLayerTest, PaintingEmptyLayerDies) {
  auto layer =
      std::make_shared<PhysicalShapeLayer>(SK_ColorBLACK, SK_ColorBLACK,
                                           0.0f,  // elevation
                                           SkPath(), Clip::none);

  layer->Preroll(preroll_context(), SkMatrix());
  EXPECT_EQ(layer->paint_bounds(), SkRect::MakeEmpty());
  EXPECT_FALSE(layer->needs_painting());
  EXPECT_FALSE(layer->needs_system_composite());

  EXPECT_DEATH_IF_SUPPORTED(layer->Paint(paint_context()),
                            "needs_painting\\(\\)");
}

TEST_F(PhysicalShapeLayerTest, PaintBeforePreollDies) {
  SkPath child_path;
  child_path.addRect(5.0f, 6.0f, 20.5f, 21.5f);
  auto mock_layer = std::make_shared<MockLayer>(child_path, SkPaint());
  auto layer =
      std::make_shared<PhysicalShapeLayer>(SK_ColorBLACK, SK_ColorBLACK,
                                           0.0f,  // elevation
                                           SkPath(), Clip::none);
  layer->Add(mock_layer);

  EXPECT_DEATH_IF_SUPPORTED(layer->Paint(paint_context()),
                            "needs_painting\\(\\)");
}
#endif

TEST_F(PhysicalShapeLayerTest, NonEmptyLayer) {
  SkPath layer_path;
  layer_path.addRect(5.0f, 6.0f, 20.5f, 21.5f);
  auto layer =
      std::make_shared<PhysicalShapeLayer>(SK_ColorGREEN, SK_ColorBLACK,
                                           0.0f,  // elevation
                                           layer_path, Clip::none);
  layer->Preroll(preroll_context(), SkMatrix());
  EXPECT_EQ(layer->paint_bounds(), layer_path.getBounds());
  EXPECT_TRUE(layer->needs_painting());
  EXPECT_FALSE(layer->needs_system_composite());

  SkPaint layer_paint;
  layer_paint.setColor(SK_ColorGREEN);
  layer_paint.setAntiAlias(true);
  layer->Paint(paint_context());
  EXPECT_EQ(mock_canvas().draw_calls(),
            std::vector({MockCanvas::DrawCall{
                0, MockCanvas::DrawPathData{layer_path, layer_paint}}}));
}

TEST_F(PhysicalShapeLayerTest, ChildrenLargerThanPath) {
  SkPath layer_path;
  layer_path.addRect(5.0f, 6.0f, 20.5f, 21.5f);
  SkPath child1_path;
  child1_path.addRect(4, 0, 12, 12).close();
  SkPath child2_path;
  child2_path.addRect(3, 2, 5, 15).close();
  auto child1 = std::make_shared<PhysicalShapeLayer>(SK_ColorRED, SK_ColorBLACK,
                                                     0.0f,  // elevation
                                                     child1_path, Clip::none);
  auto child2 =
      std::make_shared<PhysicalShapeLayer>(SK_ColorBLUE, SK_ColorBLACK,
                                           0.0f,  // elevation
                                           child2_path, Clip::none);
  auto layer =
      std::make_shared<PhysicalShapeLayer>(SK_ColorGREEN, SK_ColorBLACK,
                                           0.0f,  // elevation
                                           layer_path, Clip::none);
  layer->Add(child1);
  layer->Add(child2);

  SkRect child_paint_bounds;
  layer->Preroll(preroll_context(), SkMatrix());
  child_paint_bounds.join(child1->paint_bounds());
  child_paint_bounds.join(child2->paint_bounds());
  EXPECT_EQ(layer->paint_bounds(), layer_path.getBounds());
  EXPECT_NE(layer->paint_bounds(), child_paint_bounds);
  EXPECT_TRUE(layer->needs_painting());
  EXPECT_FALSE(layer->needs_system_composite());

  SkPaint layer_paint;
  layer_paint.setColor(SK_ColorGREEN);
  layer_paint.setAntiAlias(true);
  SkPaint child1_paint;
  child1_paint.setColor(SK_ColorRED);
  child1_paint.setAntiAlias(true);
  SkPaint child2_paint;
  child2_paint.setColor(SK_ColorBLUE);
  child2_paint.setAntiAlias(true);
  layer->Paint(paint_context());
  EXPECT_EQ(
      mock_canvas().draw_calls(),
      std::vector({MockCanvas::DrawCall{
                       0, MockCanvas::DrawPathData{layer_path, layer_paint}},
                   MockCanvas::DrawCall{
                       0, MockCanvas::DrawPathData{child1_path, child1_paint}},
                   MockCanvas::DrawCall{0, MockCanvas::DrawPathData{
                                               child2_path, child2_paint}}}));
}

TEST_F(PhysicalShapeLayerTest, ElevationSimple) {
  constexpr float initial_elevation = 20.0f;
  SkPath layer_path;
  layer_path.addRect(0, 0, 8, 8).close();
  auto layer = std::make_shared<PhysicalShapeLayer>(
      SK_ColorGREEN, SK_ColorBLACK, initial_elevation, layer_path, Clip::none);

  layer->Preroll(preroll_context(), SkMatrix());
  EXPECT_EQ(layer->paint_bounds(),
            PhysicalShapeLayer::ComputeShadowBounds(layer_path.getBounds(),
                                                    initial_elevation, 1.0f));
  EXPECT_TRUE(layer->needs_painting());
  EXPECT_FALSE(layer->needs_system_composite());
  EXPECT_EQ(layer->total_elevation(), initial_elevation);

  SkPaint layer_paint;
  layer_paint.setColor(SK_ColorGREEN);
  layer_paint.setAntiAlias(true);
  layer->Paint(paint_context());
  EXPECT_EQ(
      mock_canvas().draw_calls(),
      std::vector(
          {MockCanvas::DrawCall{0, MockCanvas::DrawShadowData{layer_path}},
           MockCanvas::DrawCall{
               0, MockCanvas::DrawPathData{layer_path, layer_paint}}}));
}

TEST_F(PhysicalShapeLayerTest, ElevationComplex) {
  // The layer tree should look like this:
  // layers[0] +1.0f = 1.0f
  // |       \
  // |        \
  // |         \
  // |       layers[2] +3.0f = 4.0f
  // |          |
  // |       layers[3] +4.0f = 8.0f
  // |
  // |
  // layers[1] + 2.0f = 3.0f
  constexpr float initial_elevations[4] = {1.0f, 2.0f, 3.0f, 4.0f};
  constexpr float total_elevations[4] = {1.0f, 3.0f, 4.0f, 8.0f};
  SkPath layer_path;
  layer_path.addRect(0, 0, 80, 80).close();

  std::shared_ptr<PhysicalShapeLayer> layers[4];
  for (int i = 0; i < 4; i += 1) {
    layers[i] = std::make_shared<PhysicalShapeLayer>(
        SK_ColorBLACK, SK_ColorBLACK, initial_elevations[i], layer_path,
        Clip::none);
  }
  layers[0]->Add(layers[1]);
  layers[0]->Add(layers[2]);
  layers[2]->Add(layers[3]);

  layers[0]->Preroll(preroll_context(), SkMatrix());
  for (int i = 0; i < 4; i += 1) {
    EXPECT_EQ(layers[i]->paint_bounds(),
              (PhysicalShapeLayer::ComputeShadowBounds(
                  layer_path.getBounds(), initial_elevations[i],
                  1.0f /* pixel_ratio */)));
    EXPECT_TRUE(layers[i]->needs_painting());
    EXPECT_FALSE(layers[i]->needs_system_composite());
    EXPECT_EQ(layers[i]->total_elevation(), total_elevations[i]);
  }

  SkPaint layer_paint;
  layer_paint.setColor(SK_ColorBLACK);
  layer_paint.setAntiAlias(true);
  layers[0]->Paint(paint_context());
  EXPECT_EQ(
      mock_canvas().draw_calls(),
      std::vector(
          {MockCanvas::DrawCall{0, MockCanvas::DrawShadowData{layer_path}},
           MockCanvas::DrawCall{
               0, MockCanvas::DrawPathData{layer_path, layer_paint}},
           MockCanvas::DrawCall{0, MockCanvas::DrawShadowData{layer_path}},
           MockCanvas::DrawCall{
               0, MockCanvas::DrawPathData{layer_path, layer_paint}},
           MockCanvas::DrawCall{0, MockCanvas::DrawShadowData{layer_path}},
           MockCanvas::DrawCall{
               0, MockCanvas::DrawPathData{layer_path, layer_paint}},
           MockCanvas::DrawCall{0, MockCanvas::DrawShadowData{layer_path}},
           MockCanvas::DrawCall{
               0, MockCanvas::DrawPathData{layer_path, layer_paint}}}));
}

}  // namespace testing
}  // namespace flutter
