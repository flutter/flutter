// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/physical_shape_layer.h"

#include "flutter/display_list/display_list_canvas_dispatcher.h"
#include "flutter/flow/testing/diff_context_test.h"
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
  EXPECT_EQ(layer->child_paint_bounds(), SkRect::MakeEmpty());
  EXPECT_FALSE(layer->needs_painting(paint_context()));

  EXPECT_DEATH_IF_SUPPORTED(layer->Paint(paint_context()),
                            "needs_painting\\(context\\)");
}

TEST_F(PhysicalShapeLayerTest, PaintBeforePrerollDies) {
  SkPath child_path;
  child_path.addRect(5.0f, 6.0f, 20.5f, 21.5f);
  auto mock_layer = std::make_shared<MockLayer>(child_path, SkPaint());
  auto layer =
      std::make_shared<PhysicalShapeLayer>(SK_ColorBLACK, SK_ColorBLACK,
                                           0.0f,  // elevation
                                           SkPath(), Clip::none);
  layer->Add(mock_layer);

  EXPECT_DEATH_IF_SUPPORTED(layer->Paint(paint_context()),
                            "needs_painting\\(context\\)");
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
  EXPECT_EQ(layer->child_paint_bounds(), SkRect::MakeEmpty());
  EXPECT_TRUE(layer->needs_painting(paint_context()));

  SkPaint layer_paint;
  layer_paint.setColor(SK_ColorGREEN);
  layer_paint.setAntiAlias(true);
  layer->Paint(paint_context());
  EXPECT_EQ(mock_canvas().draw_calls(),
            std::vector({MockCanvas::DrawCall{
                0, MockCanvas::DrawPathData{layer_path, layer_paint}}}));
}

TEST_F(PhysicalShapeLayerTest, ChildrenLargerThanPathClip) {
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
                                           layer_path, Clip::hardEdge);
  layer->Add(child1);
  layer->Add(child2);

  SkRect child_paint_bounds = SkRect::MakeEmpty();
  layer->Preroll(preroll_context(), SkMatrix());
  child_paint_bounds.join(child1->paint_bounds());
  child_paint_bounds.join(child2->paint_bounds());
  EXPECT_EQ(layer->paint_bounds(), layer_path.getBounds());
  EXPECT_NE(layer->paint_bounds(), child_paint_bounds);
  EXPECT_EQ(layer->child_paint_bounds(), child_paint_bounds);
  EXPECT_TRUE(layer->needs_painting(paint_context()));

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
  EXPECT_EQ(mock_canvas().draw_calls(),
            std::vector({
                MockCanvas::DrawCall{
                    0, MockCanvas::DrawPathData{layer_path, layer_paint}},
                MockCanvas::DrawCall{0, MockCanvas::SaveData{1}},
                MockCanvas::DrawCall{
                    1, MockCanvas::ClipRectData{layer_path.getBounds(),
                                                SkClipOp::kIntersect}},
                MockCanvas::DrawCall{
                    1, MockCanvas::DrawPathData{child1_path, child1_paint}},
                MockCanvas::DrawCall{
                    1, MockCanvas::DrawPathData{child2_path, child2_paint}},
                MockCanvas::DrawCall{1, MockCanvas::RestoreData{0}},
            }));
}

TEST_F(PhysicalShapeLayerTest, ChildrenLargerThanPathNoClip) {
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

  layer->Preroll(preroll_context(), SkMatrix());
  SkRect child_bounds = child1->paint_bounds();
  child_bounds.join(child2->paint_bounds());
  SkRect total_bounds = child_bounds;
  total_bounds.join(layer_path.getBounds());
  EXPECT_NE(layer->paint_bounds(), layer_path.getBounds());
  EXPECT_EQ(layer->paint_bounds(), total_bounds);
  EXPECT_EQ(layer->child_paint_bounds(), child_bounds);
  EXPECT_TRUE(layer->needs_painting(paint_context()));

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
            DisplayListCanvasDispatcher::ComputeShadowBounds(
                layer_path, initial_elevation, 1.0f, SkMatrix()));
  EXPECT_TRUE(layer->needs_painting(paint_context()));
  EXPECT_EQ(layer->elevation(), initial_elevation);

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
    SkRect paint_bounds = DisplayListCanvasDispatcher::ComputeShadowBounds(
        layer_path, initial_elevations[i], 1.0f /* pixel_ratio */, SkMatrix());

    // Without clipping the children will be painted as well
    for (auto layer : layers[i]->layers()) {
      paint_bounds.join(layer->paint_bounds());
    }
    EXPECT_EQ(layers[i]->paint_bounds(), paint_bounds);
    EXPECT_TRUE(layers[i]->needs_painting(paint_context()));
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

TEST_F(PhysicalShapeLayerTest, ShadowNotDependsCtm) {
  constexpr SkScalar elevations[] = {1, 2, 3, 4, 5, 10};
  constexpr SkScalar scales[] = {0.5, 1, 1.5, 2, 3, 5};
  constexpr SkScalar translates[] = {0, 1, -1, 0.5, 2, 10};

  SkPath path;
  path.addRect(0, 0, 8, 8).close();

  for (SkScalar elevation : elevations) {
    SkRect baseline_bounds = DisplayListCanvasDispatcher::ComputeShadowBounds(
        path, elevation, 1.0f, SkMatrix());
    for (SkScalar scale : scales) {
      for (SkScalar translateX : translates) {
        for (SkScalar translateY : translates) {
          SkMatrix ctm;
          ctm.setScaleTranslate(scale, scale, translateX, translateY);
          SkRect bounds = DisplayListCanvasDispatcher::ComputeShadowBounds(
              path, elevation, scale, ctm);
          EXPECT_FLOAT_EQ(bounds.fLeft, baseline_bounds.fLeft);
          EXPECT_FLOAT_EQ(bounds.fTop, baseline_bounds.fTop);
          EXPECT_FLOAT_EQ(bounds.fRight, baseline_bounds.fRight);
          EXPECT_FLOAT_EQ(bounds.fBottom, baseline_bounds.fBottom);
        }
      }
    }
  }
}

static int RasterizedDifferenceInPixels(
    const std::function<void(SkCanvas*)>& actual_draw_function,
    const std::function<void(SkCanvas*)>& expected_draw_function,
    const SkSize& canvas_size) {
  sk_sp<SkSurface> actual_surface =
      SkSurface::MakeRasterN32Premul(canvas_size.width(), canvas_size.height());
  sk_sp<SkSurface> expected_surface =
      SkSurface::MakeRasterN32Premul(canvas_size.width(), canvas_size.height());

  actual_surface->getCanvas()->drawColor(SK_ColorWHITE);
  expected_surface->getCanvas()->drawColor(SK_ColorWHITE);

  actual_draw_function(actual_surface->getCanvas());
  expected_draw_function(expected_surface->getCanvas());

  SkPixmap actual_pixels;
  EXPECT_TRUE(actual_surface->peekPixels(&actual_pixels));

  SkPixmap expected_pixels;
  EXPECT_TRUE(expected_surface->peekPixels(&expected_pixels));

  int different_pixels = 0;
  for (int y = 0; y < canvas_size.height(); y++) {
    const uint32_t* actual_row = actual_pixels.addr32(0, y);
    const uint32_t* expected_row = expected_pixels.addr32(0, y);
    for (int x = 0; x < canvas_size.width(); x++) {
      if (actual_row[x] != expected_row[x]) {
        different_pixels++;
      }
    }
  }
  return different_pixels;
}

TEST_F(PhysicalShapeLayerTest, ShadowNotDependsPathSize) {
  constexpr SkRect test_cases[][2] = {
      {{20, -100, 80, 80}, {20, -1000, 80, 80}},
      {{20, 20, 80, 200}, {20, 20, 80, 2000}},
  };

  for (const SkRect* test_case : test_cases) {
    EXPECT_EQ(RasterizedDifferenceInPixels(
                  [=](SkCanvas* canvas) {
                    SkPath path;
                    path.addRect(test_case[0]).close();
                    DisplayListCanvasDispatcher::DrawShadow(
                        canvas, path, SK_ColorBLACK, 1.0f, false, 1.0f);
                  },
                  [=](SkCanvas* canvas) {
                    SkPath path;
                    path.addRect(test_case[1]).close();
                    DisplayListCanvasDispatcher::DrawShadow(
                        canvas, path, SK_ColorBLACK, 1.0f, false, 1.0f);
                  },
                  SkSize::Make(100, 100)),
              0);
  }
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
  auto reader = std::make_shared<MockLayer>(path, paint, false, true);
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

TEST_F(PhysicalShapeLayerTest, OpacityInheritance) {
  SkPath layer_path;
  layer_path.addRect(5.0f, 6.0f, 20.5f, 21.5f);
  auto layer =
      std::make_shared<PhysicalShapeLayer>(SK_ColorGREEN, SK_ColorBLACK,
                                           0.0f,  // elevation
                                           layer_path, Clip::none);

  PrerollContext* context = preroll_context();
  context->subtree_can_inherit_opacity = false;
  layer->Preroll(context, SkMatrix());
  EXPECT_FALSE(context->subtree_can_inherit_opacity);
}

using PhysicalShapeLayerDiffTest = DiffContextTest;

TEST_F(PhysicalShapeLayerDiffTest, NoClipPaintRegion) {
  MockLayerTree tree1;
  const SkPath layer_path = SkPath().addRect(SkRect::MakeXYWH(0, 0, 100, 100));
  auto layer =
      std::make_shared<PhysicalShapeLayer>(SK_ColorGREEN, SK_ColorBLACK,
                                           0.0f,  // elevation
                                           layer_path, Clip::none);

  const SkPath layer_path2 =
      SkPath().addRect(SkRect::MakeXYWH(200, 200, 200, 200));
  auto layer2 = std::make_shared<MockLayer>(layer_path2);
  layer->Add(layer2);
  tree1.root()->Add(layer);

  auto damage = DiffLayerTree(tree1, MockLayerTree());
  EXPECT_EQ(damage.frame_damage, SkIRect::MakeLTRB(0, 0, 400, 400));
}

TEST_F(PhysicalShapeLayerDiffTest, ClipPaintRegion) {
  MockLayerTree tree1;
  const SkPath layer_path = SkPath().addRect(SkRect::MakeXYWH(0, 0, 100, 100));
  auto layer =
      std::make_shared<PhysicalShapeLayer>(SK_ColorGREEN, SK_ColorBLACK,
                                           0.0f,  // elevation
                                           layer_path, Clip::hardEdge);

  const SkPath layer_path2 =
      SkPath().addRect(SkRect::MakeXYWH(200, 200, 200, 200));
  auto layer2 = std::make_shared<MockLayer>(layer_path2);
  layer->Add(layer2);
  tree1.root()->Add(layer);

  auto damage = DiffLayerTree(tree1, MockLayerTree());
  EXPECT_EQ(damage.frame_damage, SkIRect::MakeLTRB(0, 0, 100, 100));
}

}  // namespace testing
}  // namespace flutter
