// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/clip_rect_layer.h"
#include "flutter/flow/layers/platform_view_layer.h"

#include "flutter/flow/testing/layer_test.h"
#include "flutter/flow/testing/mock_embedder.h"
#include "flutter/flow/testing/mock_layer.h"
#include "flutter/fml/macros.h"
#include "flutter/testing/mock_canvas.h"

namespace flutter {
namespace testing {

using PlatformViewLayerTest = LayerTest;

TEST_F(PlatformViewLayerTest, NullViewEmbedderDoesntPrerollCompositeOrPaint) {
  const SkPoint layer_offset = SkPoint::Make(0.0f, 0.0f);
  const SkSize layer_size = SkSize::Make(8.0f, 8.0f);
  const int64_t view_id = 0;
  auto layer =
      std::make_shared<PlatformViewLayer>(layer_offset, layer_size, view_id);

  layer->Preroll(preroll_context(), SkMatrix());
  EXPECT_FALSE(preroll_context()->has_platform_view);
  EXPECT_EQ(layer->paint_bounds(),
            SkRect::MakeSize(layer_size)
                .makeOffset(layer_offset.fX, layer_offset.fY));
  EXPECT_TRUE(layer->needs_painting(paint_context()));
  EXPECT_FALSE(layer->subtree_has_platform_view());

  layer->Paint(paint_context());
  EXPECT_EQ(paint_context().leaf_nodes_canvas, &mock_canvas());
  EXPECT_EQ(mock_canvas().draw_calls(), std::vector<MockCanvas::DrawCall>());
}

TEST_F(PlatformViewLayerTest, ClippedPlatformViewPrerollsAndPaintsNothing) {
  const SkPoint layer_offset = SkPoint::Make(0.0f, 0.0f);
  const SkSize layer_size = SkSize::Make(8.0f, 8.0f);
  const SkRect child_clip = SkRect::MakeLTRB(20.0f, 20.0f, 40.0f, 40.0f);
  const SkRect parent_clip = SkRect::MakeLTRB(50.0f, 50.0f, 80.0f, 80.0f);
  const int64_t view_id = 0;
  auto layer =
      std::make_shared<PlatformViewLayer>(layer_offset, layer_size, view_id);
  auto child_clip_layer =
      std::make_shared<ClipRectLayer>(child_clip, Clip::hardEdge);
  auto parent_clip_layer =
      std::make_shared<ClipRectLayer>(parent_clip, Clip::hardEdge);
  parent_clip_layer->Add(child_clip_layer);
  child_clip_layer->Add(layer);

  auto embedder = MockViewEmbedder();
  preroll_context()->view_embedder = &embedder;

  parent_clip_layer->Preroll(preroll_context(), SkMatrix());
  EXPECT_TRUE(preroll_context()->has_platform_view);
  EXPECT_EQ(layer->paint_bounds(),
            SkRect::MakeSize(layer_size)
                .makeOffset(layer_offset.fX, layer_offset.fY));
  EXPECT_TRUE(layer->needs_painting(paint_context()));
  EXPECT_TRUE(child_clip_layer->needs_painting(paint_context()));
  EXPECT_TRUE(parent_clip_layer->needs_painting(paint_context()));
  EXPECT_TRUE(layer->subtree_has_platform_view());
  EXPECT_TRUE(child_clip_layer->subtree_has_platform_view());
  EXPECT_TRUE(parent_clip_layer->subtree_has_platform_view());

  parent_clip_layer->Paint(paint_context());
  EXPECT_EQ(paint_context().leaf_nodes_canvas, &mock_canvas());
  EXPECT_EQ(
      mock_canvas().draw_calls(),
      std::vector(
          {MockCanvas::DrawCall{0, MockCanvas::SaveData{1}},
           MockCanvas::DrawCall{
               1, MockCanvas::ClipRectData{parent_clip, SkClipOp::kIntersect,
                                           MockCanvas::kHard_ClipEdgeStyle}},
           MockCanvas::DrawCall{1, MockCanvas::SaveData{2}},
           MockCanvas::DrawCall{
               2, MockCanvas::ClipRectData{child_clip, SkClipOp::kIntersect,
                                           MockCanvas::kHard_ClipEdgeStyle}},
           MockCanvas::DrawCall{2, MockCanvas::RestoreData{1}},
           MockCanvas::DrawCall{1, MockCanvas::RestoreData{0}}}));
}

TEST_F(PlatformViewLayerTest, OpacityInheritance) {
  const SkPoint layer_offset = SkPoint::Make(0.0f, 0.0f);
  const SkSize layer_size = SkSize::Make(8.0f, 8.0f);
  const int64_t view_id = 0;
  auto layer =
      std::make_shared<PlatformViewLayer>(layer_offset, layer_size, view_id);

  PrerollContext* context = preroll_context();
  context->subtree_can_inherit_opacity = false;
  layer->Preroll(preroll_context(), SkMatrix());
  EXPECT_FALSE(context->subtree_can_inherit_opacity);
}

}  // namespace testing
}  // namespace flutter
