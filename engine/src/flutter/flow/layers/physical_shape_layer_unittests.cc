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
  // The Fuchsia system compositor handles all elevated PhysicalShapeLayers and
  // their shadows , so we do not do any painting there.
  EXPECT_EQ(layer->paint_bounds(),
            PhysicalShapeLayer::ComputeShadowBounds(layer_path.getBounds(),
                                                    initial_elevation, 1.0f));
  EXPECT_TRUE(layer->needs_painting());
  EXPECT_FALSE(layer->needs_system_composite());
  EXPECT_EQ(layer->total_elevation(), initial_elevation);

  // The Fuchsia system compositor handles all elevated PhysicalShapeLayers and
  // their shadows , so we do not use the direct |Paint()| path there.
#if !defined(OS_FUCHSIA)
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
#endif
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
    // On Fuchsia, the system compositor handles all elevated
    // PhysicalShapeLayers and their shadows , so we do not do any painting
    // there.
    EXPECT_EQ(layers[i]->paint_bounds(),
              (PhysicalShapeLayer::ComputeShadowBounds(
                  layer_path.getBounds(), initial_elevations[i],
                  1.0f /* pixel_ratio */)));
    EXPECT_TRUE(layers[i]->needs_painting());
    EXPECT_FALSE(layers[i]->needs_system_composite());
    EXPECT_EQ(layers[i]->total_elevation(), total_elevations[i]);
  }

  // The Fuchsia system compositor handles all elevated PhysicalShapeLayers and
  // their shadows , so we do not use the direct |Paint()| path there.
#if !defined(OS_FUCHSIA)
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
#endif
}

static bool ReadbackResult(PrerollContext* context,
                           Clip clip_behavior,
                           std::shared_ptr<Layer> child,
                           bool before) {
  const SkMatrix initial_matrix = SkMatrix();
  const SkRect layer_bounds = SkRect::MakeXYWH(0.5, 1.0, 5.0, 6.0);
  const SkPath layer_path = SkPath().addRect(layer_bounds);
  auto layer =
      std::make_shared<PhysicalShapeLayer>(SK_ColorGREEN, SK_ColorBLACK,
                                           0.0f,  // elevation
                                           layer_path, clip_behavior);
  if (child != nullptr) {
    layer->Add(child);
  }
  context->surface_needs_readback = before;
  layer->Preroll(context, initial_matrix);
  return context->surface_needs_readback;
}

TEST_F(PhysicalShapeLayerTest, Readback) {
  PrerollContext* context = preroll_context();
  SkPath path;
  SkPaint paint;

  const Clip hard = Clip::hardEdge;
  const Clip soft = Clip::antiAlias;
  const Clip save_layer = Clip::antiAliasWithSaveLayer;

  std::shared_ptr<MockLayer> nochild;
  auto reader = std::make_shared<MockLayer>(path, paint, false, false, true);
  auto nonreader = std::make_shared<MockLayer>(path, paint);

  // No children, no prior readback -> no readback after
  EXPECT_FALSE(ReadbackResult(context, hard, nochild, false));
  EXPECT_FALSE(ReadbackResult(context, soft, nochild, false));
  EXPECT_FALSE(ReadbackResult(context, save_layer, nochild, false));

  // No children, prior readback -> readback after
  EXPECT_TRUE(ReadbackResult(context, hard, nochild, true));
  EXPECT_TRUE(ReadbackResult(context, soft, nochild, true));
  EXPECT_TRUE(ReadbackResult(context, save_layer, nochild, true));

  // Non readback child, no prior readback -> no readback after
  EXPECT_FALSE(ReadbackResult(context, hard, nonreader, false));
  EXPECT_FALSE(ReadbackResult(context, soft, nonreader, false));
  EXPECT_FALSE(ReadbackResult(context, save_layer, nonreader, false));

  // Non readback child, prior readback -> readback after
  EXPECT_TRUE(ReadbackResult(context, hard, nonreader, true));
  EXPECT_TRUE(ReadbackResult(context, soft, nonreader, true));
  EXPECT_TRUE(ReadbackResult(context, save_layer, nonreader, true));

  // Readback child, no prior readback -> readback after unless SaveLayer
  EXPECT_TRUE(ReadbackResult(context, hard, reader, false));
  EXPECT_TRUE(ReadbackResult(context, soft, reader, false));
  EXPECT_FALSE(ReadbackResult(context, save_layer, reader, false));

  // Readback child, prior readback -> readback after
  EXPECT_TRUE(ReadbackResult(context, hard, reader, true));
  EXPECT_TRUE(ReadbackResult(context, soft, reader, true));
  EXPECT_TRUE(ReadbackResult(context, save_layer, reader, true));
}

}  // namespace testing
}  // namespace flutter
