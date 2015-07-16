// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/compiler_specific.h"
#include "base/memory/scoped_ptr.h"
#include "cc/test/geometry_test_utils.h"
#include "skia/ext/pixel_ref_utils.h"
#include "skia/ext/refptr.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "third_party/skia/include/core/SkBitmap.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkPictureRecorder.h"
#include "third_party/skia/include/core/SkPixelRef.h"
#include "third_party/skia/include/core/SkPoint.h"
#include "third_party/skia/include/core/SkShader.h"
#include "third_party/skia/src/core/SkOrderedReadBuffer.h"
#include "ui/gfx/geometry/rect.h"
#include "ui/gfx/skia_util.h"

namespace skia {

namespace {

void CreateBitmap(gfx::Size size, const char* uri, SkBitmap* bitmap);

class TestDiscardableShader : public SkShader {
 public:
  TestDiscardableShader() {
    CreateBitmap(gfx::Size(50, 50), "discardable", &bitmap_);
  }

  TestDiscardableShader(SkReadBuffer& buffer) {
    CreateBitmap(gfx::Size(50, 50), "discardable", &bitmap_);
  }

  SkShader::BitmapType asABitmap(SkBitmap* bitmap,
                                 SkMatrix* matrix,
                                 TileMode xy[2]) const override {
    if (bitmap)
      *bitmap = bitmap_;
    return SkShader::kDefault_BitmapType;
  }

  // not indended to return an actual context. Just need to supply this.
  size_t contextSize() const override { return sizeof(SkShader::Context); }

  void flatten(SkWriteBuffer&) const override {}

  // Manual expansion of SK_DECLARE_PUBLIC_FLATTENABLE_DESERIALIZATION_PROCS to
  // satisfy Chrome's style checker, since Skia isn't ready to make the C++11
  // leap yet.
 private:
  static SkFlattenable* CreateProc(SkReadBuffer&);
  friend class SkPrivateEffectInitializer;

 public:
  Factory getFactory() const override { return CreateProc; }

 private:
  SkBitmap bitmap_;
};

SkFlattenable* TestDiscardableShader::CreateProc(SkReadBuffer&) {
  return new TestDiscardableShader;
}

void CreateBitmap(gfx::Size size, const char* uri, SkBitmap* bitmap) {
  bitmap->allocN32Pixels(size.width(), size.height());
  bitmap->pixelRef()->setImmutable();
  bitmap->pixelRef()->setURI(uri);
}

SkCanvas* StartRecording(SkPictureRecorder* recorder, gfx::Rect layer_rect) {
  SkCanvas* canvas =
      recorder->beginRecording(layer_rect.width(), layer_rect.height());

  canvas->save();
  canvas->translate(-layer_rect.x(), -layer_rect.y());
  canvas->clipRect(SkRect::MakeXYWH(
      layer_rect.x(), layer_rect.y(), layer_rect.width(), layer_rect.height()));

  return canvas;
}

SkPicture* StopRecording(SkPictureRecorder* recorder, SkCanvas* canvas) {
  canvas->restore();
  return recorder->endRecording();
}

}  // namespace

TEST(PixelRefUtilsTest, DrawPaint) {
  gfx::Rect layer_rect(0, 0, 256, 256);

  SkPictureRecorder recorder;
  SkCanvas* canvas = StartRecording(&recorder, layer_rect);

  TestDiscardableShader first_shader;
  SkPaint first_paint;
  first_paint.setShader(&first_shader);

  TestDiscardableShader second_shader;
  SkPaint second_paint;
  second_paint.setShader(&second_shader);

  TestDiscardableShader third_shader;
  SkPaint third_paint;
  third_paint.setShader(&third_shader);

  canvas->drawPaint(first_paint);
  canvas->clipRect(SkRect::MakeXYWH(34, 45, 56, 67));
  canvas->drawPaint(second_paint);
  // Total clip is now (34, 45, 56, 55)
  canvas->clipRect(SkRect::MakeWH(100, 100));
  canvas->drawPaint(third_paint);

  skia::RefPtr<SkPicture> picture = skia::AdoptRef(StopRecording(&recorder, canvas));

  std::vector<skia::PixelRefUtils::PositionPixelRef> pixel_refs;
  skia::PixelRefUtils::GatherDiscardablePixelRefs(picture.get(), &pixel_refs);

  EXPECT_EQ(3u, pixel_refs.size());
  EXPECT_FLOAT_RECT_EQ(gfx::RectF(0, 0, 256, 256),
                       gfx::SkRectToRectF(pixel_refs[0].pixel_ref_rect));
  EXPECT_FLOAT_RECT_EQ(gfx::RectF(34, 45, 56, 67),
                       gfx::SkRectToRectF(pixel_refs[1].pixel_ref_rect));
  EXPECT_FLOAT_RECT_EQ(gfx::RectF(34, 45, 56, 55),
                       gfx::SkRectToRectF(pixel_refs[2].pixel_ref_rect));
}

TEST(PixelRefUtilsTest, DrawPoints) {
  gfx::Rect layer_rect(0, 0, 256, 256);

  SkPictureRecorder recorder;
  SkCanvas* canvas = StartRecording(&recorder, layer_rect);

  TestDiscardableShader first_shader;
  SkPaint first_paint;
  first_paint.setShader(&first_shader);

  TestDiscardableShader second_shader;
  SkPaint second_paint;
  second_paint.setShader(&second_shader);

  TestDiscardableShader third_shader;
  SkPaint third_paint;
  third_paint.setShader(&third_shader);

  SkPoint points[3];
  points[0].set(10, 10);
  points[1].set(100, 20);
  points[2].set(50, 100);
  // (10, 10, 90, 90).
  canvas->drawPoints(SkCanvas::kPolygon_PointMode, 3, points, first_paint);

  canvas->save();

  canvas->clipRect(SkRect::MakeWH(50, 50));
  // (10, 10, 40, 40).
  canvas->drawPoints(SkCanvas::kPolygon_PointMode, 3, points, second_paint);

  canvas->restore();

  points[0].set(50, 55);
  points[1].set(50, 55);
  points[2].set(200, 200);
  // (50, 55, 150, 145).
  canvas->drawPoints(SkCanvas::kPolygon_PointMode, 3, points, third_paint);

  skia::RefPtr<SkPicture> picture = skia::AdoptRef(StopRecording(&recorder, canvas));

  std::vector<skia::PixelRefUtils::PositionPixelRef> pixel_refs;
  skia::PixelRefUtils::GatherDiscardablePixelRefs(picture.get(), &pixel_refs);

  EXPECT_EQ(3u, pixel_refs.size());
  EXPECT_FLOAT_RECT_EQ(gfx::RectF(10, 10, 90, 90),
                       gfx::SkRectToRectF(pixel_refs[0].pixel_ref_rect));
  EXPECT_FLOAT_RECT_EQ(gfx::RectF(10, 10, 40, 40),
                       gfx::SkRectToRectF(pixel_refs[1].pixel_ref_rect));
  EXPECT_FLOAT_RECT_EQ(gfx::RectF(50, 55, 150, 145),
                       gfx::SkRectToRectF(pixel_refs[2].pixel_ref_rect));
}

TEST(PixelRefUtilsTest, DrawRect) {
  gfx::Rect layer_rect(0, 0, 256, 256);

  SkPictureRecorder recorder;
  SkCanvas* canvas = StartRecording(&recorder, layer_rect);

  TestDiscardableShader first_shader;
  SkPaint first_paint;
  first_paint.setShader(&first_shader);

  TestDiscardableShader second_shader;
  SkPaint second_paint;
  second_paint.setShader(&second_shader);

  TestDiscardableShader third_shader;
  SkPaint third_paint;
  third_paint.setShader(&third_shader);

  // (10, 20, 30, 40).
  canvas->drawRect(SkRect::MakeXYWH(10, 20, 30, 40), first_paint);

  canvas->save();

  canvas->translate(5, 17);
  // (5, 50, 25, 35)
  canvas->drawRect(SkRect::MakeXYWH(0, 33, 25, 35), second_paint);

  canvas->restore();

  canvas->clipRect(SkRect::MakeXYWH(50, 50, 50, 50));
  canvas->translate(20, 20);
  // (50, 50, 50, 50)
  canvas->drawRect(SkRect::MakeXYWH(0, 0, 100, 100), third_paint);

  skia::RefPtr<SkPicture> picture = skia::AdoptRef(StopRecording(&recorder, canvas));

  std::vector<skia::PixelRefUtils::PositionPixelRef> pixel_refs;
  skia::PixelRefUtils::GatherDiscardablePixelRefs(picture.get(), &pixel_refs);

  EXPECT_EQ(3u, pixel_refs.size());
  EXPECT_FLOAT_RECT_EQ(gfx::RectF(10, 20, 30, 40),
                       gfx::SkRectToRectF(pixel_refs[0].pixel_ref_rect));
  EXPECT_FLOAT_RECT_EQ(gfx::RectF(5, 50, 25, 35),
                       gfx::SkRectToRectF(pixel_refs[1].pixel_ref_rect));
  EXPECT_FLOAT_RECT_EQ(gfx::RectF(50, 50, 50, 50),
                       gfx::SkRectToRectF(pixel_refs[2].pixel_ref_rect));
}

TEST(PixelRefUtilsTest, DrawRRect) {
  gfx::Rect layer_rect(0, 0, 256, 256);

  SkPictureRecorder recorder;
  SkCanvas* canvas = StartRecording(&recorder, layer_rect);

  TestDiscardableShader first_shader;
  SkPaint first_paint;
  first_paint.setShader(&first_shader);

  TestDiscardableShader second_shader;
  SkPaint second_paint;
  second_paint.setShader(&second_shader);

  TestDiscardableShader third_shader;
  SkPaint third_paint;
  third_paint.setShader(&third_shader);

  SkRRect rrect;
  rrect.setRect(SkRect::MakeXYWH(10, 20, 30, 40));

  // (10, 20, 30, 40).
  canvas->drawRRect(rrect, first_paint);

  canvas->save();

  canvas->translate(5, 17);
  rrect.setRect(SkRect::MakeXYWH(0, 33, 25, 35));
  // (5, 50, 25, 35)
  canvas->drawRRect(rrect, second_paint);

  canvas->restore();

  canvas->clipRect(SkRect::MakeXYWH(50, 50, 50, 50));
  canvas->translate(20, 20);
  rrect.setRect(SkRect::MakeXYWH(0, 0, 100, 100));
  // (50, 50, 50, 50)
  canvas->drawRRect(rrect, third_paint);

  skia::RefPtr<SkPicture> picture = skia::AdoptRef(StopRecording(&recorder, canvas));

  std::vector<skia::PixelRefUtils::PositionPixelRef> pixel_refs;
  skia::PixelRefUtils::GatherDiscardablePixelRefs(picture.get(), &pixel_refs);

  EXPECT_EQ(3u, pixel_refs.size());
  EXPECT_FLOAT_RECT_EQ(gfx::RectF(10, 20, 30, 40),
                       gfx::SkRectToRectF(pixel_refs[0].pixel_ref_rect));
  EXPECT_FLOAT_RECT_EQ(gfx::RectF(5, 50, 25, 35),
                       gfx::SkRectToRectF(pixel_refs[1].pixel_ref_rect));
  EXPECT_FLOAT_RECT_EQ(gfx::RectF(50, 50, 50, 50),
                       gfx::SkRectToRectF(pixel_refs[2].pixel_ref_rect));
}

TEST(PixelRefUtilsTest, DrawOval) {
  gfx::Rect layer_rect(0, 0, 256, 256);

  SkPictureRecorder recorder;
  SkCanvas* canvas = StartRecording(&recorder, layer_rect);

  TestDiscardableShader first_shader;
  SkPaint first_paint;
  first_paint.setShader(&first_shader);

  TestDiscardableShader second_shader;
  SkPaint second_paint;
  second_paint.setShader(&second_shader);

  TestDiscardableShader third_shader;
  SkPaint third_paint;
  third_paint.setShader(&third_shader);

  canvas->save();

  canvas->scale(2, 0.5);
  // (20, 10, 60, 20).
  canvas->drawOval(SkRect::MakeXYWH(10, 20, 30, 40), first_paint);

  canvas->restore();
  canvas->save();

  canvas->translate(1, 2);
  // (1, 35, 25, 35)
  canvas->drawRect(SkRect::MakeXYWH(0, 33, 25, 35), second_paint);

  canvas->restore();

  canvas->clipRect(SkRect::MakeXYWH(50, 50, 50, 50));
  canvas->translate(20, 20);
  // (50, 50, 50, 50)
  canvas->drawRect(SkRect::MakeXYWH(0, 0, 100, 100), third_paint);

  skia::RefPtr<SkPicture> picture = skia::AdoptRef(StopRecording(&recorder, canvas));

  std::vector<skia::PixelRefUtils::PositionPixelRef> pixel_refs;
  skia::PixelRefUtils::GatherDiscardablePixelRefs(picture.get(), &pixel_refs);

  EXPECT_EQ(3u, pixel_refs.size());
  EXPECT_FLOAT_RECT_EQ(gfx::RectF(20, 10, 60, 20),
                       gfx::SkRectToRectF(pixel_refs[0].pixel_ref_rect));
  EXPECT_FLOAT_RECT_EQ(gfx::RectF(1, 35, 25, 35),
                       gfx::SkRectToRectF(pixel_refs[1].pixel_ref_rect));
  EXPECT_FLOAT_RECT_EQ(gfx::RectF(50, 50, 50, 50),
                       gfx::SkRectToRectF(pixel_refs[2].pixel_ref_rect));
}

TEST(PixelRefUtilsTest, DrawPath) {
  gfx::Rect layer_rect(0, 0, 256, 256);

  SkPictureRecorder recorder;
  SkCanvas* canvas = StartRecording(&recorder, layer_rect);

  TestDiscardableShader first_shader;
  SkPaint first_paint;
  first_paint.setShader(&first_shader);

  TestDiscardableShader second_shader;
  SkPaint second_paint;
  second_paint.setShader(&second_shader);

  SkPath path;
  path.moveTo(12, 13);
  path.lineTo(50, 50);
  path.lineTo(22, 101);

  // (12, 13, 38, 88).
  canvas->drawPath(path, first_paint);

  canvas->save();
  canvas->clipRect(SkRect::MakeWH(50, 50));

  // (12, 13, 38, 37).
  canvas->drawPath(path, second_paint);

  canvas->restore();

  skia::RefPtr<SkPicture> picture = skia::AdoptRef(StopRecording(&recorder, canvas));

  std::vector<skia::PixelRefUtils::PositionPixelRef> pixel_refs;
  skia::PixelRefUtils::GatherDiscardablePixelRefs(picture.get(), &pixel_refs);

  EXPECT_EQ(2u, pixel_refs.size());
  EXPECT_FLOAT_RECT_EQ(gfx::RectF(12, 13, 38, 88),
                       gfx::SkRectToRectF(pixel_refs[0].pixel_ref_rect));
  EXPECT_FLOAT_RECT_EQ(gfx::RectF(12, 13, 38, 37),
                       gfx::SkRectToRectF(pixel_refs[1].pixel_ref_rect));
}

TEST(PixelRefUtilsTest, DrawBitmap) {
  gfx::Rect layer_rect(0, 0, 256, 256);

  SkPictureRecorder recorder;
  SkCanvas* canvas = StartRecording(&recorder, layer_rect);

  SkBitmap first;
  CreateBitmap(gfx::Size(50, 50), "discardable", &first);
  SkBitmap second;
  CreateBitmap(gfx::Size(50, 50), "discardable", &second);
  SkBitmap third;
  CreateBitmap(gfx::Size(50, 50), "discardable", &third);
  SkBitmap fourth;
  CreateBitmap(gfx::Size(50, 1), "discardable", &fourth);
  SkBitmap fifth;
  CreateBitmap(gfx::Size(10, 10), "discardable", &fifth);

  canvas->save();

  // At (0, 0).
  canvas->drawBitmap(first, 0, 0);
  canvas->translate(25, 0);
  // At (25, 0).
  canvas->drawBitmap(second, 0, 0);
  canvas->translate(0, 50);
  // At (50, 50).
  canvas->drawBitmap(third, 25, 0);

  canvas->restore();
  canvas->save();

  canvas->translate(1, 0);
  canvas->rotate(90);
  // At (1, 0), rotated 90 degrees
  canvas->drawBitmap(fourth, 0, 0);

  canvas->restore();

  canvas->scale(5, 6);
  // At (0, 0), scaled by 5 and 6
  canvas->drawBitmap(fifth, 0, 0);

  skia::RefPtr<SkPicture> picture = skia::AdoptRef(StopRecording(&recorder, canvas));

  std::vector<skia::PixelRefUtils::PositionPixelRef> pixel_refs;
  skia::PixelRefUtils::GatherDiscardablePixelRefs(picture.get(), &pixel_refs);

  EXPECT_EQ(5u, pixel_refs.size());
  EXPECT_FLOAT_RECT_EQ(gfx::RectF(0, 0, 50, 50),
                       gfx::SkRectToRectF(pixel_refs[0].pixel_ref_rect));
  EXPECT_FLOAT_RECT_EQ(gfx::RectF(25, 0, 50, 50),
                       gfx::SkRectToRectF(pixel_refs[1].pixel_ref_rect));
  EXPECT_FLOAT_RECT_EQ(gfx::RectF(50, 50, 50, 50),
                       gfx::SkRectToRectF(pixel_refs[2].pixel_ref_rect));
  EXPECT_FLOAT_RECT_EQ(gfx::RectF(0, 0, 1, 50),
                       gfx::SkRectToRectF(pixel_refs[3].pixel_ref_rect));
  EXPECT_FLOAT_RECT_EQ(gfx::RectF(0, 0, 50, 60),
                       gfx::SkRectToRectF(pixel_refs[4].pixel_ref_rect));

}

TEST(PixelRefUtilsTest, DrawBitmapRect) {
  gfx::Rect layer_rect(0, 0, 256, 256);

  SkPictureRecorder recorder;
  SkCanvas* canvas = StartRecording(&recorder, layer_rect);

  SkBitmap first;
  CreateBitmap(gfx::Size(50, 50), "discardable", &first);
  SkBitmap second;
  CreateBitmap(gfx::Size(50, 50), "discardable", &second);
  SkBitmap third;
  CreateBitmap(gfx::Size(50, 50), "discardable", &third);

  TestDiscardableShader first_shader;
  SkPaint first_paint;
  first_paint.setShader(&first_shader);

  SkPaint non_discardable_paint;

  canvas->save();

  // (0, 0, 100, 100).
  canvas->drawBitmapRect(
      first, SkRect::MakeWH(100, 100), &non_discardable_paint);
  canvas->translate(25, 0);
  // (75, 50, 10, 10).
  canvas->drawBitmapRect(
      second, SkRect::MakeXYWH(50, 50, 10, 10), &non_discardable_paint);
  canvas->translate(5, 50);
  // (0, 30, 100, 100). One from bitmap, one from paint.
  canvas->drawBitmapRect(
      third, SkRect::MakeXYWH(-30, -20, 100, 100), &first_paint);

  canvas->restore();

  skia::RefPtr<SkPicture> picture = skia::AdoptRef(StopRecording(&recorder, canvas));

  std::vector<skia::PixelRefUtils::PositionPixelRef> pixel_refs;
  skia::PixelRefUtils::GatherDiscardablePixelRefs(picture.get(), &pixel_refs);

  EXPECT_EQ(4u, pixel_refs.size());
  EXPECT_FLOAT_RECT_EQ(gfx::RectF(0, 0, 100, 100),
                       gfx::SkRectToRectF(pixel_refs[0].pixel_ref_rect));
  EXPECT_FLOAT_RECT_EQ(gfx::RectF(75, 50, 10, 10),
                       gfx::SkRectToRectF(pixel_refs[1].pixel_ref_rect));
  EXPECT_FLOAT_RECT_EQ(gfx::RectF(0, 30, 100, 100),
                       gfx::SkRectToRectF(pixel_refs[2].pixel_ref_rect));
  EXPECT_FLOAT_RECT_EQ(gfx::RectF(0, 30, 100, 100),
                       gfx::SkRectToRectF(pixel_refs[3].pixel_ref_rect));
}

TEST(PixelRefUtilsTest, DrawSprite) {
  gfx::Rect layer_rect(0, 0, 256, 256);

  SkPictureRecorder recorder;
  SkCanvas* canvas = StartRecording(&recorder, layer_rect);

  SkBitmap first;
  CreateBitmap(gfx::Size(50, 50), "discardable", &first);
  SkBitmap second;
  CreateBitmap(gfx::Size(50, 50), "discardable", &second);
  SkBitmap third;
  CreateBitmap(gfx::Size(50, 50), "discardable", &third);
  SkBitmap fourth;
  CreateBitmap(gfx::Size(50, 50), "discardable", &fourth);
  SkBitmap fifth;
  CreateBitmap(gfx::Size(50, 50), "discardable", &fifth);

  canvas->save();

  // Sprites aren't affected by the current matrix.

  // (0, 0, 50, 50).
  canvas->drawSprite(first, 0, 0);
  canvas->translate(25, 0);
  // (10, 0, 50, 50).
  canvas->drawSprite(second, 10, 0);
  canvas->translate(0, 50);
  // (25, 0, 50, 50).
  canvas->drawSprite(third, 25, 0);

  canvas->restore();
  canvas->save();

  canvas->rotate(90);
  // (0, 0, 50, 50).
  canvas->drawSprite(fourth, 0, 0);

  canvas->restore();

  TestDiscardableShader first_shader;
  SkPaint first_paint;
  first_paint.setShader(&first_shader);

  canvas->scale(5, 6);
  // (100, 100, 50, 50).
  canvas->drawSprite(fifth, 100, 100, &first_paint);

  skia::RefPtr<SkPicture> picture = skia::AdoptRef(StopRecording(&recorder, canvas));

  std::vector<skia::PixelRefUtils::PositionPixelRef> pixel_refs;
  skia::PixelRefUtils::GatherDiscardablePixelRefs(picture.get(), &pixel_refs);

  EXPECT_EQ(6u, pixel_refs.size());
  EXPECT_FLOAT_RECT_EQ(gfx::RectF(0, 0, 50, 50),
                       gfx::SkRectToRectF(pixel_refs[0].pixel_ref_rect));
  EXPECT_FLOAT_RECT_EQ(gfx::RectF(10, 0, 50, 50),
                       gfx::SkRectToRectF(pixel_refs[1].pixel_ref_rect));
  EXPECT_FLOAT_RECT_EQ(gfx::RectF(25, 0, 50, 50),
                       gfx::SkRectToRectF(pixel_refs[2].pixel_ref_rect));
  EXPECT_FLOAT_RECT_EQ(gfx::RectF(0, 0, 50, 50),
                       gfx::SkRectToRectF(pixel_refs[3].pixel_ref_rect));
  EXPECT_FLOAT_RECT_EQ(gfx::RectF(100, 100, 50, 50),
                       gfx::SkRectToRectF(pixel_refs[4].pixel_ref_rect));
  EXPECT_FLOAT_RECT_EQ(gfx::RectF(100, 100, 50, 50),
                       gfx::SkRectToRectF(pixel_refs[5].pixel_ref_rect));
}

TEST(PixelRefUtilsTest, DrawText) {
  gfx::Rect layer_rect(0, 0, 256, 256);

  SkPictureRecorder recorder;
  SkCanvas* canvas = StartRecording(&recorder, layer_rect);

  TestDiscardableShader first_shader;
  SkPaint first_paint;
  first_paint.setShader(&first_shader);

  SkPoint points[4];
  points[0].set(10, 50);
  points[1].set(20, 50);
  points[2].set(30, 50);
  points[3].set(40, 50);

  SkPath path;
  path.moveTo(10, 50);
  path.lineTo(20, 50);
  path.lineTo(30, 50);
  path.lineTo(40, 50);
  path.lineTo(50, 50);

  canvas->drawText("text", 4, 50, 50, first_paint);
  canvas->drawPosText("text", 4, points, first_paint);
  canvas->drawTextOnPath("text", 4, path, NULL, first_paint);

  skia::RefPtr<SkPicture> picture = skia::AdoptRef(StopRecording(&recorder, canvas));

  std::vector<skia::PixelRefUtils::PositionPixelRef> pixel_refs;
  skia::PixelRefUtils::GatherDiscardablePixelRefs(picture.get(), &pixel_refs);

  EXPECT_EQ(3u, pixel_refs.size());
}

TEST(PixelRefUtilsTest, DrawVertices) {
  gfx::Rect layer_rect(0, 0, 256, 256);

  SkPictureRecorder recorder;
  SkCanvas* canvas = StartRecording(&recorder, layer_rect);

  TestDiscardableShader first_shader;
  SkPaint first_paint;
  first_paint.setShader(&first_shader);

  TestDiscardableShader second_shader;
  SkPaint second_paint;
  second_paint.setShader(&second_shader);

  TestDiscardableShader third_shader;
  SkPaint third_paint;
  third_paint.setShader(&third_shader);

  SkPoint points[3];
  SkColor colors[3];
  uint16_t indecies[3] = {0, 1, 2};
  points[0].set(10, 10);
  points[1].set(100, 20);
  points[2].set(50, 100);
  // (10, 10, 90, 90).
  canvas->drawVertices(SkCanvas::kTriangles_VertexMode,
                       3,
                       points,
                       points,
                       colors,
                       NULL,
                       indecies,
                       3,
                       first_paint);

  canvas->save();

  canvas->clipRect(SkRect::MakeWH(50, 50));
  // (10, 10, 40, 40).
  canvas->drawVertices(SkCanvas::kTriangles_VertexMode,
                       3,
                       points,
                       points,
                       colors,
                       NULL,
                       indecies,
                       3,
                       second_paint);

  canvas->restore();

  points[0].set(50, 55);
  points[1].set(50, 55);
  points[2].set(200, 200);
  // (50, 55, 150, 145).
  canvas->drawVertices(SkCanvas::kTriangles_VertexMode,
                       3,
                       points,
                       points,
                       colors,
                       NULL,
                       indecies,
                       3,
                       third_paint);

  skia::RefPtr<SkPicture> picture = skia::AdoptRef(StopRecording(&recorder, canvas));

  std::vector<skia::PixelRefUtils::PositionPixelRef> pixel_refs;
  skia::PixelRefUtils::GatherDiscardablePixelRefs(picture.get(), &pixel_refs);

  EXPECT_EQ(3u, pixel_refs.size());
  EXPECT_FLOAT_RECT_EQ(gfx::RectF(10, 10, 90, 90),
                       gfx::SkRectToRectF(pixel_refs[0].pixel_ref_rect));
  EXPECT_FLOAT_RECT_EQ(gfx::RectF(10, 10, 40, 40),
                       gfx::SkRectToRectF(pixel_refs[1].pixel_ref_rect));
  EXPECT_FLOAT_RECT_EQ(gfx::RectF(50, 55, 150, 145),
                       gfx::SkRectToRectF(pixel_refs[2].pixel_ref_rect));
}

}  // namespace skia
