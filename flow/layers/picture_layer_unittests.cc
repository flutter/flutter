// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include "flutter/flow/layers/picture_layer.h"

#include "flutter/flow/testing/skia_gpu_object_layer_test.h"
#include "flutter/fml/macros.h"
#include "flutter/testing/mock_canvas.h"
#include "third_party/skia/include/core/SkPicture.h"

#ifndef SUPPORT_FRACTIONAL_TRANSLATION
#include "flutter/flow/raster_cache.h"
#endif

namespace flutter {
namespace testing {

using PictureLayerTest = SkiaGPUObjectLayerTest;

#ifndef NDEBUG
TEST_F(PictureLayerTest, PaintBeforePrerollInvalidPictureDies) {
  const SkPoint layer_offset = SkPoint::Make(0.0f, 0.0f);
  auto layer = std::make_shared<PictureLayer>(
      layer_offset, SkiaGPUObject<SkPicture>(), false, false);

  EXPECT_DEATH_IF_SUPPORTED(layer->Paint(paint_context()),
                            "picture_\\.get\\(\\)");
}

TEST_F(PictureLayerTest, PaintBeforePreollDies) {
  const SkPoint layer_offset = SkPoint::Make(0.0f, 0.0f);
  const SkRect picture_bounds = SkRect::MakeLTRB(5.0f, 6.0f, 20.5f, 21.5f);
  auto mock_picture = SkPicture::MakePlaceholder(picture_bounds);
  auto layer = std::make_shared<PictureLayer>(
      layer_offset, SkiaGPUObject(mock_picture, unref_queue()), false, false);

  EXPECT_EQ(layer->paint_bounds(), SkRect::MakeEmpty());
  EXPECT_DEATH_IF_SUPPORTED(layer->Paint(paint_context()),
                            "needs_painting\\(context\\)");
}

TEST_F(PictureLayerTest, PaintingEmptyLayerDies) {
  const SkPoint layer_offset = SkPoint::Make(0.0f, 0.0f);
  const SkRect picture_bounds = SkRect::MakeEmpty();
  auto mock_picture = SkPicture::MakePlaceholder(picture_bounds);
  auto layer = std::make_shared<PictureLayer>(
      layer_offset, SkiaGPUObject(mock_picture, unref_queue()), false, false);

  layer->Preroll(preroll_context(), SkMatrix());
  EXPECT_EQ(layer->paint_bounds(), SkRect::MakeEmpty());
  EXPECT_FALSE(layer->needs_painting(paint_context()));
  EXPECT_FALSE(layer->needs_system_composite());

  EXPECT_DEATH_IF_SUPPORTED(layer->Paint(paint_context()),
                            "needs_painting\\(context\\)");
}
#endif

TEST_F(PictureLayerTest, InvalidPictureDies) {
  const SkPoint layer_offset = SkPoint::Make(0.0f, 0.0f);
  auto layer = std::make_shared<PictureLayer>(
      layer_offset, SkiaGPUObject<SkPicture>(), false, false);

  // Crashes reading a nullptr.
  EXPECT_DEATH_IF_SUPPORTED(layer->Preroll(preroll_context(), SkMatrix()), "");
}

TEST_F(PictureLayerTest, SimplePicture) {
  const SkPoint layer_offset = SkPoint::Make(1.5f, -0.5f);
  const SkMatrix layer_offset_matrix =
      SkMatrix::Translate(layer_offset.fX, layer_offset.fY);
  const SkRect picture_bounds = SkRect::MakeLTRB(5.0f, 6.0f, 20.5f, 21.5f);
  auto mock_picture = SkPicture::MakePlaceholder(picture_bounds);
  auto layer = std::make_shared<PictureLayer>(
      layer_offset, SkiaGPUObject(mock_picture, unref_queue()), false, false);

  layer->Preroll(preroll_context(), SkMatrix());
  EXPECT_EQ(layer->paint_bounds(),
            picture_bounds.makeOffset(layer_offset.fX, layer_offset.fY));
  EXPECT_EQ(layer->picture(), mock_picture.get());
  EXPECT_TRUE(layer->needs_painting(paint_context()));
  EXPECT_FALSE(layer->needs_system_composite());

  layer->Paint(paint_context());
  auto expected_draw_calls = std::vector(
      {MockCanvas::DrawCall{0, MockCanvas::SaveData{1}},
       MockCanvas::DrawCall{1,
                            MockCanvas::ConcatMatrixData{layer_offset_matrix}},
#ifndef SUPPORT_FRACTIONAL_TRANSLATION
       MockCanvas::DrawCall{
           1, MockCanvas::SetMatrixData{RasterCache::GetIntegralTransCTM(
                  layer_offset_matrix)}},
#endif
       MockCanvas::DrawCall{1, MockCanvas::RestoreData{0}}});
  EXPECT_EQ(mock_canvas().draw_calls(), expected_draw_calls);
}

}  // namespace testing
}  // namespace flutter
