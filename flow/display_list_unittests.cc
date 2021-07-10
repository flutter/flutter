// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/display_list_canvas.h"

#include "third_party/skia/include/core/SkColor.h"
#include "third_party/skia/include/core/SkImageInfo.h"
#include "third_party/skia/include/core/SkPath.h"
#include "third_party/skia/include/core/SkPicture.h"
#include "third_party/skia/include/core/SkPictureRecorder.h"
#include "third_party/skia/include/core/SkRRect.h"
#include "third_party/skia/include/core/SkRSXform.h"
#include "third_party/skia/include/core/SkSurface.h"
#include "third_party/skia/include/core/SkTextBlob.h"
#include "third_party/skia/include/core/SkVertices.h"
#include "third_party/skia/include/effects/SkDashPathEffect.h"
#include "third_party/skia/include/effects/SkGradientShader.h"
#include "third_party/skia/include/effects/SkImageFilters.h"

#include <cmath>

#include "gtest/gtest.h"

namespace flutter {
namespace testing {

constexpr SkPoint end_points[] = {
    {0, 0},
    {100, 100},
};
constexpr SkColor colors[] = {
    SK_ColorGREEN,
    SK_ColorYELLOW,
    SK_ColorBLUE,
};
constexpr float stops[] = {
    0.0,
    0.5,
    1.0,
};

// clang-format off
constexpr float rotate_color_matrix[20] = {
    0, 1, 0, 0, 0,
    0, 0, 1, 0, 0,
    1, 0, 0, 0, 0,
    0, 0, 0, 1, 0,
};
constexpr float invert_color_matrix[20] = {
    -1.0,    0,    0, 1.0,   0,
       0, -1.0,    0, 1.0,   0,
       0,    0, -1.0, 1.0,   0,
     1.0,  1.0,  1.0, 1.0,   0,
};
// clang-format on

const SkScalar TestDashes1[] = {4.0, 2.0};
const SkScalar TestDashes2[] = {1.0, 1.5};

constexpr SkPoint TestPoints[] = {
    {10, 10},
    {20, 20},
    {10, 20},
    {20, 10},
};
#define TestPointCount sizeof(TestPoints) / (sizeof(TestPoints[0]))

static const sk_sp<SkShader> TestShader1 =
    SkGradientShader::MakeLinear(end_points,
                                 colors,
                                 stops,
                                 3,
                                 SkTileMode::kMirror,
                                 0,
                                 nullptr);
// TestShader2 is identical to TestShader1 and points out that we cannot
// perform a deep compare over our various sk_sp objects because the
// DisplayLists constructed with the two do not compare == below.
static const sk_sp<SkShader> TestShader2 =
    SkGradientShader::MakeLinear(end_points,
                                 colors,
                                 stops,
                                 3,
                                 SkTileMode::kMirror,
                                 0,
                                 nullptr);
static const sk_sp<SkShader> TestShader3 =
    SkGradientShader::MakeLinear(end_points,
                                 colors,
                                 stops,
                                 3,
                                 SkTileMode::kDecal,
                                 0,
                                 nullptr);
static const sk_sp<SkImageFilter> TestImageFilter1 =
    SkImageFilters::Blur(5.0, 5.0, SkTileMode::kDecal, nullptr, nullptr);
static const sk_sp<SkImageFilter> TestImageFilter2 =
    SkImageFilters::Blur(5.0, 5.0, SkTileMode::kClamp, nullptr, nullptr);
static const sk_sp<SkColorFilter> TestColorFilter1 =
    SkColorFilters::Matrix(rotate_color_matrix);
static const sk_sp<SkColorFilter> TestColorFilter2 =
    SkColorFilters::Matrix(invert_color_matrix);
static const sk_sp<SkPathEffect> TestPathEffect1 =
    SkDashPathEffect::Make(TestDashes1, 2, 0.0f);
static const sk_sp<SkPathEffect> TestPathEffect2 =
    SkDashPathEffect::Make(TestDashes2, 2, 0.0f);
static const sk_sp<SkMaskFilter> TestMaskFilter =
    SkMaskFilter::MakeBlur(kNormal_SkBlurStyle, 5.0);
constexpr SkRect TestBounds = SkRect::MakeLTRB(10, 10, 50, 60);
static const SkRRect TestRRect = SkRRect::MakeRectXY(TestBounds, 5, 5);
static const SkRRect TestRRectRect = SkRRect::MakeRect(TestBounds);
static const SkRRect TestInnerRRect =
    SkRRect::MakeRectXY(TestBounds.makeInset(5, 5), 2, 2);
static const SkPath TestPathRect = SkPath::Rect(TestBounds);
static const SkPath TestPathOval = SkPath::Oval(TestBounds);
static const SkPath TestPath1 =
    SkPath::Polygon({{0, 0}, {10, 10}, {10, 0}, {0, 10}}, true);
static const SkPath TestPath2 =
    SkPath::Polygon({{0, 0}, {10, 10}, {0, 10}, {10, 0}}, true);
static const SkPath TestPath3 =
    SkPath::Polygon({{0, 0}, {10, 10}, {10, 0}, {0, 10}}, false);
static const SkMatrix TestMatrix1 = SkMatrix::Scale(2, 2);
static const SkMatrix TestMatrix2 = SkMatrix::RotateDeg(45);

static sk_sp<SkImage> MakeTestImage(int w, int h, int checker_size) {
  sk_sp<SkSurface> surface = SkSurface::MakeRasterN32Premul(w, h);
  SkCanvas* canvas = surface->getCanvas();
  SkPaint p0, p1;
  p0.setStyle(SkPaint::kFill_Style);
  p0.setColor(SK_ColorGREEN);
  p1.setStyle(SkPaint::kFill_Style);
  p1.setColor(SK_ColorBLUE);
  p1.setAlpha(128);
  for (int y = 0; y < w; y += checker_size) {
    for (int x = 0; x < h; x += checker_size) {
      SkPaint& cellp = ((x + y) & 1) == 0 ? p0 : p1;
      canvas->drawRect(SkRect::MakeXYWH(x, y, checker_size, checker_size),
                       cellp);
    }
  }
  return surface->makeImageSnapshot();
}
static sk_sp<SkImage> TestImage1 = MakeTestImage(40, 40, 5);
static sk_sp<SkImage> TestImage2 = MakeTestImage(50, 50, 5);

static sk_sp<SkVertices> TestVertices1 =
    SkVertices::MakeCopy(SkVertices::kTriangles_VertexMode,
                         3,
                         TestPoints,
                         nullptr,
                         colors);
static sk_sp<SkVertices> TestVertices2 =
    SkVertices::MakeCopy(SkVertices::kTriangleFan_VertexMode,
                         3,
                         TestPoints,
                         nullptr,
                         colors);

static constexpr int TestDivs1[] = {10, 20, 30};
static constexpr int TestDivs2[] = {15, 20, 25};
static constexpr int TestDivs3[] = {15, 25};
static constexpr SkCanvas::Lattice::RectType TestRTypes[] = {
    SkCanvas::Lattice::RectType::kDefault,
    SkCanvas::Lattice::RectType::kTransparent,
    SkCanvas::Lattice::RectType::kFixedColor,
    SkCanvas::Lattice::RectType::kDefault,
    SkCanvas::Lattice::RectType::kTransparent,
    SkCanvas::Lattice::RectType::kFixedColor,
    SkCanvas::Lattice::RectType::kDefault,
    SkCanvas::Lattice::RectType::kTransparent,
    SkCanvas::Lattice::RectType::kFixedColor,
};
static constexpr SkColor TestLatticeColors[] = {
    SK_ColorBLUE, SK_ColorGREEN, SK_ColorYELLOW,
    SK_ColorBLUE, SK_ColorGREEN, SK_ColorYELLOW,
    SK_ColorBLUE, SK_ColorGREEN, SK_ColorYELLOW,
};
static constexpr SkIRect TestLatticeSrcRect = {1, 1, 39, 39};

static sk_sp<SkPicture> MakeTestPicture(int w, int h, SkColor color) {
  SkPictureRecorder recorder;
  SkCanvas* cv = recorder.beginRecording(TestBounds);
  SkPaint paint;
  paint.setColor(color);
  paint.setStyle(SkPaint::kFill_Style);
  cv->drawRect(SkRect::MakeWH(w, h), paint);
  return recorder.finishRecordingAsPicture();
}
static sk_sp<SkPicture> TestPicture1 = MakeTestPicture(20, 20, SK_ColorGREEN);
static sk_sp<SkPicture> TestPicture2 = MakeTestPicture(25, 25, SK_ColorBLUE);

static sk_sp<DisplayList> MakeTestDisplayList(int w, int h, SkColor color) {
  DisplayListBuilder builder;
  builder.setColor(color);
  builder.drawRect(SkRect::MakeWH(w, h));
  return builder.Build();
}
static sk_sp<DisplayList> TestDisplayList1 =
    MakeTestDisplayList(20, 20, SK_ColorGREEN);
static sk_sp<DisplayList> TestDisplayList2 =
    MakeTestDisplayList(25, 25, SK_ColorBLUE);

static sk_sp<SkTextBlob> MakeTextBlob(std::string string) {
  return SkTextBlob::MakeFromText(string.c_str(), string.size(), SkFont(),
                                  SkTextEncoding::kUTF8);
}
static sk_sp<SkTextBlob> TestBlob1 = MakeTextBlob("TestBlob1");
static sk_sp<SkTextBlob> TestBlob2 = MakeTextBlob("TestBlob2");

// ---------------
// Test Suite data
// ---------------

typedef const std::function<void(DisplayListBuilder&)> DlInvoker;

struct DisplayListInvocation {
  int op_count;
  size_t byte_count;

  // in some cases, running the sequence through an SkCanvas will result
  // in fewer ops/bytes. Attribute invocations are recorded in an SkPaint
  // and not forwarded on, and SkCanvas culls unused save/restore/transforms.
  int sk_op_count;
  size_t sk_byte_count;

  DlInvoker invoker;

  bool sk_version_matches() {
    return (op_count == sk_op_count && byte_count == sk_byte_count);
  }

  sk_sp<DisplayList> Build() {
    DisplayListBuilder builder;
    invoker(builder);
    return builder.Build();
  }
};

struct DisplayListInvocationGroup {
  std::string op_name;
  std::vector<DisplayListInvocation> variants;
};

std::vector<DisplayListInvocationGroup> allGroups = {
  { "SetAA", {
      {1, 8, 0, 0, [](DisplayListBuilder& b) {b.setAA(false);}},
      {1, 8, 0, 0, [](DisplayListBuilder& b) {b.setAA(true);}},
    }
  },
  { "SetDither", {
      {1, 8, 0, 0, [](DisplayListBuilder& b) {b.setDither(false);}},
      {1, 8, 0, 0, [](DisplayListBuilder& b) {b.setDither(true);}},
    }
  },
  { "SetInvertColors", {
      {1, 8, 0, 0, [](DisplayListBuilder& b) {b.setInvertColors(false);}},
      {1, 8, 0, 0, [](DisplayListBuilder& b) {b.setInvertColors(true);}},
    }
  },
  { "SetStrokeCap", {
      {1, 8, 0, 0, [](DisplayListBuilder& b) {b.setCaps(SkPaint::kButt_Cap);}},
      {1, 8, 0, 0, [](DisplayListBuilder& b) {b.setCaps(SkPaint::kRound_Cap);}},
      {1, 8, 0, 0, [](DisplayListBuilder& b) {b.setCaps(SkPaint::kSquare_Cap);}},
    }
  },
  { "SetStrokeJoin", {
      {1, 8, 0, 0, [](DisplayListBuilder& b) {b.setJoins(SkPaint::kBevel_Join);}},
      {1, 8, 0, 0, [](DisplayListBuilder& b) {b.setJoins(SkPaint::kRound_Join);}},
      {1, 8, 0, 0, [](DisplayListBuilder& b) {b.setJoins(SkPaint::kMiter_Join);}},
    }
  },
  { "SetDrawStyle", {
      {1, 8, 0, 0, [](DisplayListBuilder& b) {b.setDrawStyle(SkPaint::kFill_Style);}},
      {1, 8, 0, 0, [](DisplayListBuilder& b) {b.setDrawStyle(SkPaint::kStroke_Style);}},
    }
  },
  { "SetStrokeWidth", {
      {1, 8, 0, 0, [](DisplayListBuilder& b) {b.setStrokeWidth(0.0);}},
      {1, 8, 0, 0, [](DisplayListBuilder& b) {b.setStrokeWidth(5.0);}},
    }
  },
  { "SetMiterLimit", {
      {1, 8, 0, 0, [](DisplayListBuilder& b) {b.setMiterLimit(0.0);}},
      {1, 8, 0, 0, [](DisplayListBuilder& b) {b.setMiterLimit(5.0);}},
    }
  },
  { "SetColor", {
      {1, 8, 0, 0, [](DisplayListBuilder& b) {b.setColor(SK_ColorGREEN);}},
      {1, 8, 0, 0, [](DisplayListBuilder& b) {b.setColor(SK_ColorBLUE);}},
    }
  },
  { "SetBlendMode", {
      {1, 8, 0, 0, [](DisplayListBuilder& b) {b.setBlendMode(SkBlendMode::kSrcIn);}},
      {1, 8, 0, 0, [](DisplayListBuilder& b) {b.setBlendMode(SkBlendMode::kDstIn);}},
    }
  },
  { "SetShader", {
      {1, 8, 0, 0, [](DisplayListBuilder& b) {b.setShader(nullptr);}},
      {1, 16, 0, 0, [](DisplayListBuilder& b) {b.setShader(TestShader1);}},
      {1, 16, 0, 0, [](DisplayListBuilder& b) {b.setShader(TestShader2);}},
      {1, 16, 0, 0, [](DisplayListBuilder& b) {b.setShader(TestShader3);}},
    }
  },
  { "SetImageFilter", {
      {1, 8, 0, 0, [](DisplayListBuilder& b) {b.setImageFilter(nullptr);}},
      {1, 16, 0, 0, [](DisplayListBuilder& b) {b.setImageFilter(TestImageFilter1);}},
      {1, 16, 0, 0, [](DisplayListBuilder& b) {b.setImageFilter(TestImageFilter2);}},
    }
  },
  { "SetColorFilter", {
      {1, 8, 0, 0, [](DisplayListBuilder& b) {b.setColorFilter(nullptr);}},
      {1, 16, 0, 0, [](DisplayListBuilder& b) {b.setColorFilter(TestColorFilter1);}},
      {1, 16, 0, 0, [](DisplayListBuilder& b) {b.setColorFilter(TestColorFilter2);}},
    }
  },
  { "SetPathEffect", {
      {1, 8, 0, 0, [](DisplayListBuilder& b) {b.setPathEffect(nullptr);}},
      {1, 16, 0, 0, [](DisplayListBuilder& b) {b.setPathEffect(TestPathEffect1);}},
      {1, 16, 0, 0, [](DisplayListBuilder& b) {b.setPathEffect(TestPathEffect2);}},
    }
  },
  { "SetMaskFilter", {
      {1, 16, 0, 0, [](DisplayListBuilder& b) {b.setMaskFilter(nullptr);}},
      {1, 16, 0, 0, [](DisplayListBuilder& b) {b.setMaskFilter(TestMaskFilter);}},
      {1, 8, 0, 0, [](DisplayListBuilder& b) {b.setMaskBlurFilter(kNormal_SkBlurStyle, 3.0);}},
      {1, 8, 0, 0, [](DisplayListBuilder& b) {b.setMaskBlurFilter(kNormal_SkBlurStyle, 5.0);}},
      {1, 8, 0, 0, [](DisplayListBuilder& b) {b.setMaskBlurFilter(kSolid_SkBlurStyle, 3.0);}},
      {1, 8, 0, 0, [](DisplayListBuilder& b) {b.setMaskBlurFilter(kInner_SkBlurStyle, 3.0);}},
      {1, 8, 0, 0, [](DisplayListBuilder& b) {b.setMaskBlurFilter(kOuter_SkBlurStyle, 3.0);}},
    }
  },
  { "Save(Layer)+Restore", {
      // cv.save/restore are ignored if there are no draw calls between them
      {2, 16, 0, 0, [](DisplayListBuilder& b) {b.save(); b.restore();}},
      {2, 16, 2, 16, [](DisplayListBuilder& b) {b.saveLayer(nullptr, false); b.restore(); }},
      {2, 16, 2, 16, [](DisplayListBuilder& b) {b.saveLayer(nullptr, true); b.restore(); }},
      {2, 32, 2, 32, [](DisplayListBuilder& b) {b.saveLayer(&TestBounds, false); b.restore(); }},
      {2, 32, 2, 32, [](DisplayListBuilder& b) {b.saveLayer(&TestBounds, true); b.restore(); }},
    }
  },
  { "Translate", {
      // cv.translate(0, 0) is ignored
      {1, 16, 0, 0, [](DisplayListBuilder& b) {b.translate(0, 0);}},
      {1, 16, 1, 16, [](DisplayListBuilder& b) {b.translate(10, 10);}},
      {1, 16, 1, 16, [](DisplayListBuilder& b) {b.translate(10, 15);}},
      {1, 16, 1, 16, [](DisplayListBuilder& b) {b.translate(15, 10);}},
    }
  },
  { "Scale", {
      // cv.scale(1, 1) is ignored
      {1, 16, 0, 0, [](DisplayListBuilder& b) {b.scale(1, 1);}},
      {1, 16, 1, 16, [](DisplayListBuilder& b) {b.scale(2, 2);}},
      {1, 16, 1, 16, [](DisplayListBuilder& b) {b.scale(2, 3);}},
      {1, 16, 1, 16, [](DisplayListBuilder& b) {b.scale(3, 2);}},
    }
  },
  { "Rotate", {
      // cv.rotate(0) is ignored, otherwise expressed as concat(rotmatrix)
      {1, 8, 0, 0, [](DisplayListBuilder& b) {b.rotate(0);}},
      {1, 8, 1, 32, [](DisplayListBuilder& b) {b.rotate(30);}},
      {1, 8, 1, 32, [](DisplayListBuilder& b) {b.rotate(45);}},
    }
  },
  { "Skew", {
      // cv.skew(0, 0) is ignored, otherwise expressed as concat(skewmatrix)
      {1, 16, 0, 0, [](DisplayListBuilder& b) {b.skew(0, 0);}},
      {1, 16, 1, 32, [](DisplayListBuilder& b) {b.skew(0.1, 0.1);}},
      {1, 16, 1, 32, [](DisplayListBuilder& b) {b.skew(0.1, 0.2);}},
      {1, 16, 1, 32, [](DisplayListBuilder& b) {b.skew(0.2, 0.1);}},
    }
  },
  { "Transform2x3", {
      // cv.transform(identity) is ignored
      {1, 32, 0, 0, [](DisplayListBuilder& b) {b.transform2x3(1, 0, 0, 0, 1, 0);}},
      {1, 32, 1, 32, [](DisplayListBuilder& b) {b.transform2x3(0, 1, 12, 1, 0, 33);}},
    }
  },
  { "Transform3x3", {
      // cv.transform(identity) is ignored
      {1, 40, 0, 0, [](DisplayListBuilder& b) {b.transform3x3(1, 0, 0, 0, 1, 0, 0, 0, 1);}},
      {1, 40, 1, 40, [](DisplayListBuilder& b) {b.transform3x3(0, 1, 12, 1, 0, 33, 0, 0, 12);}},
    }
  },
  { "ClipRect", {
      {1, 24, 1, 24, [](DisplayListBuilder& b) {b.clipRect(TestBounds, true, SkClipOp::kIntersect);}},
      {1, 24, 1, 24, [](DisplayListBuilder& b) {b.clipRect(TestBounds.makeOffset(1, 1),
                                                           true, SkClipOp::kIntersect);}},
      {1, 24, 1, 24, [](DisplayListBuilder& b) {b.clipRect(TestBounds, false, SkClipOp::kIntersect);}},
      {1, 24, 1, 24, [](DisplayListBuilder& b) {b.clipRect(TestBounds, true, SkClipOp::kDifference);}},
      {1, 24, 1, 24, [](DisplayListBuilder& b) {b.clipRect(TestBounds, false, SkClipOp::kDifference);}},
    }
  },
  { "ClipRRect", {
      {1, 64, 1, 64, [](DisplayListBuilder& b) {b.clipRRect(TestRRect, true, SkClipOp::kIntersect);}},
      {1, 64, 1, 64, [](DisplayListBuilder& b) {b.clipRRect(TestRRect.makeOffset(1, 1),
                                                            true, SkClipOp::kIntersect);}},
      {1, 64, 1, 64, [](DisplayListBuilder& b) {b.clipRRect(TestRRect, false, SkClipOp::kIntersect);}},
      {1, 64, 1, 64, [](DisplayListBuilder& b) {b.clipRRect(TestRRect, true, SkClipOp::kDifference);}},
      {1, 64, 1, 64, [](DisplayListBuilder& b) {b.clipRRect(TestRRect, false, SkClipOp::kDifference);}},
    }
  },
  { "ClipPath", {
      {1, 24, 1, 24, [](DisplayListBuilder& b) {b.clipPath(TestPath1, true, SkClipOp::kIntersect);}},
      {1, 24, 1, 24, [](DisplayListBuilder& b) {b.clipPath(TestPath2, true, SkClipOp::kIntersect);}},
      {1, 24, 1, 24, [](DisplayListBuilder& b) {b.clipPath(TestPath3, true, SkClipOp::kIntersect);}},
      {1, 24, 1, 24, [](DisplayListBuilder& b) {b.clipPath(TestPath1, false, SkClipOp::kIntersect);}},
      {1, 24, 1, 24, [](DisplayListBuilder& b) {b.clipPath(TestPath1, true, SkClipOp::kDifference);}},
      {1, 24, 1, 24, [](DisplayListBuilder& b) {b.clipPath(TestPath1, false, SkClipOp::kDifference);}},
      // clipPath(rect) becomes clipRect
      {1, 24, 1, 24, [](DisplayListBuilder& b) {b.clipPath(TestPathRect, true, SkClipOp::kIntersect);}},
      // clipPath(oval) becomes clipRRect
      {1, 64, 1, 64, [](DisplayListBuilder& b) {b.clipPath(TestPathOval, true, SkClipOp::kIntersect);}},
    }
  },
  { "DrawPaint", {
      {1, 8, 1, 8, [](DisplayListBuilder& b) {b.drawPaint();}},
    }
  },
  { "DrawColor", {
      // cv.drawColor becomes cv.drawPaint(paint)
      {1, 16, 3, 24, [](DisplayListBuilder& b) {b.drawColor(SK_ColorBLUE, SkBlendMode::kSrcIn);}},
      {1, 16, 3, 24, [](DisplayListBuilder& b) {b.drawColor(SK_ColorBLUE, SkBlendMode::kDstIn);}},
      {1, 16, 3, 24, [](DisplayListBuilder& b) {b.drawColor(SK_ColorCYAN, SkBlendMode::kSrcIn);}},
    }
  },
  { "DrawLine", {
      {1, 24, 1, 24, [](DisplayListBuilder& b) {b.drawLine({0, 0}, {10, 10});}},
      {1, 24, 1, 24, [](DisplayListBuilder& b) {b.drawLine({0, 1}, {10, 10});}},
      {1, 24, 1, 24, [](DisplayListBuilder& b) {b.drawLine({0, 0}, {20, 10});}},
      {1, 24, 1, 24, [](DisplayListBuilder& b) {b.drawLine({0, 0}, {10, 20});}},
    }
  },
  { "DrawRect", {
      {1, 24, 1, 24, [](DisplayListBuilder& b) {b.drawRect({0, 0, 10, 10});}},
      {1, 24, 1, 24, [](DisplayListBuilder& b) {b.drawRect({0, 1, 10, 10});}},
      {1, 24, 1, 24, [](DisplayListBuilder& b) {b.drawRect({0, 0, 20, 10});}},
      {1, 24, 1, 24, [](DisplayListBuilder& b) {b.drawRect({0, 0, 10, 20});}},
    }
  },
  { "DrawOval", {
      {1, 24, 1, 24, [](DisplayListBuilder& b) {b.drawOval({0, 0, 10, 10});}},
      {1, 24, 1, 24, [](DisplayListBuilder& b) {b.drawOval({0, 1, 10, 10});}},
      {1, 24, 1, 24, [](DisplayListBuilder& b) {b.drawOval({0, 0, 20, 10});}},
      {1, 24, 1, 24, [](DisplayListBuilder& b) {b.drawOval({0, 0, 10, 20});}},
    }
  },
  { "DrawCircle", {
      // cv.drawCircle becomes cv.drawOval
      {1, 16, 1, 24, [](DisplayListBuilder& b) {b.drawCircle({0, 0}, 10);}},
      {1, 16, 1, 24, [](DisplayListBuilder& b) {b.drawCircle({0, 5}, 10);}},
      {1, 16, 1, 24, [](DisplayListBuilder& b) {b.drawCircle({0, 0}, 20);}},
    }
  },
  { "DrawRRect", {
      {1, 56, 1, 56, [](DisplayListBuilder& b) {b.drawRRect(TestRRect);}},
      {1, 56, 1, 56, [](DisplayListBuilder& b) {b.drawRRect(TestRRect.makeOffset(5, 5));}},
    }
  },
  { "DrawDRRect", {
      {1, 112, 1, 112, [](DisplayListBuilder& b) {b.drawDRRect(TestRRect, TestInnerRRect);}},
      {1, 112, 1, 112, [](DisplayListBuilder& b) {b.drawDRRect(TestRRect.makeOffset(5, 5),
                                                               TestInnerRRect.makeOffset(4, 4));}},
    }
  },
  { "DrawPath", {
      {1, 24, 1, 24, [](DisplayListBuilder& b) {b.drawPath(TestPath1);}},
      {1, 24, 1, 24, [](DisplayListBuilder& b) {b.drawPath(TestPath2);}},
      {1, 24, 1, 24, [](DisplayListBuilder& b) {b.drawPath(TestPath3);}},
      {1, 24, 1, 24, [](DisplayListBuilder& b) {b.drawPath(TestPathRect);}},
      {1, 24, 1, 24, [](DisplayListBuilder& b) {b.drawPath(TestPathOval);}},
    }
  },
  { "DrawArc", {
      {1, 32, 1, 32, [](DisplayListBuilder& b) {b.drawArc(TestBounds, 45, 270, false);}},
      {1, 32, 1, 32, [](DisplayListBuilder& b) {b.drawArc(TestBounds.makeOffset(1, 1),
                                                          45, 270, false);}},
      {1, 32, 1, 32, [](DisplayListBuilder& b) {b.drawArc(TestBounds, 30, 270, false);}},
      {1, 32, 1, 32, [](DisplayListBuilder& b) {b.drawArc(TestBounds, 45, 260, false);}},
      {1, 32, 1, 32, [](DisplayListBuilder& b) {b.drawArc(TestBounds, 45, 270, true);}},
    }
  },
  { "DrawPoints", {
      {1, 8 + TestPointCount * 8, 1, 8 + TestPointCount * 8,
       [](DisplayListBuilder& b) {b.drawPoints(SkCanvas::kPoints_PointMode,
                                               TestPointCount,
                                               TestPoints);}},
      {1, 8 + (TestPointCount - 1) * 8, 1, 8 + (TestPointCount - 1) * 8,
       [](DisplayListBuilder& b) {b.drawPoints(SkCanvas::kPoints_PointMode,
                                               TestPointCount - 1,
                                               TestPoints);}},
      {1, 8 + TestPointCount * 8, 1, 8 + TestPointCount * 8,
       [](DisplayListBuilder& b) {b.drawPoints(SkCanvas::kLines_PointMode,
                                               TestPointCount,
                                               TestPoints);}},
      {1, 8 + TestPointCount * 8, 1, 8 + TestPointCount * 8,
       [](DisplayListBuilder& b) {b.drawPoints(SkCanvas::kPolygon_PointMode,
                                               TestPointCount,
                                               TestPoints);}},
    }
  },
  { "DrawVertices", {
      {1, 16, 1, 16, [](DisplayListBuilder& b) {b.drawVertices(TestVertices1, SkBlendMode::kSrcIn);}},
      {1, 16, 1, 16, [](DisplayListBuilder& b) {b.drawVertices(TestVertices1, SkBlendMode::kDstIn);}},
      {1, 16, 1, 16, [](DisplayListBuilder& b) {b.drawVertices(TestVertices2, SkBlendMode::kSrcIn);}},
    }
  },
  { "DrawImage", {
      {1, 40, 1, 40, [](DisplayListBuilder& b) {b.drawImage(TestImage1, {10, 10}, DisplayList::NearestSampling);}},
      {1, 40, 1, 40, [](DisplayListBuilder& b) {b.drawImage(TestImage1, {20, 10}, DisplayList::NearestSampling);}},
      {1, 40, 1, 40, [](DisplayListBuilder& b) {b.drawImage(TestImage1, {10, 20}, DisplayList::NearestSampling);}},
      {1, 40, 1, 40, [](DisplayListBuilder& b) {b.drawImage(TestImage1, {10, 10}, DisplayList::LinearSampling);}},
      {1, 40, 1, 40, [](DisplayListBuilder& b) {b.drawImage(TestImage2, {10, 10}, DisplayList::NearestSampling);}},
    }
  },
  { "DrawImageRect", {
      {1, 64, 1, 64, [](DisplayListBuilder& b) {b.drawImageRect(TestImage1, {10, 10, 20, 20}, {10, 10, 80, 80},
                                                                DisplayList::NearestSampling);}},
      {1, 64, 1, 64, [](DisplayListBuilder& b) {b.drawImageRect(TestImage1, {10, 10, 20, 20}, {10, 10, 80, 80},
                                                                DisplayList::NearestSampling,
                                                                SkCanvas::SrcRectConstraint::kStrict_SrcRectConstraint);}},
      {1, 64, 1, 64, [](DisplayListBuilder& b) {b.drawImageRect(TestImage1, {10, 10, 25, 20}, {10, 10, 80, 80},
                                                                DisplayList::NearestSampling);}},
      {1, 64, 1, 64, [](DisplayListBuilder& b) {b.drawImageRect(TestImage1, {10, 10, 20, 20}, {10, 10, 85, 80},
                                                                DisplayList::NearestSampling);}},
      {1, 64, 1, 64, [](DisplayListBuilder& b) {b.drawImageRect(TestImage1, {10, 10, 20, 20}, {10, 10, 80, 80},
                                                                DisplayList::LinearSampling);}},
      {1, 64, 1, 64, [](DisplayListBuilder& b) {b.drawImageRect(TestImage2, {10, 10, 15, 15}, {10, 10, 80, 80},
                                                                DisplayList::NearestSampling);}},
    }
  },
  { "DrawImageNine", {
      // SkVanvas::drawImageNine is immediately converted to drawImageLattice
      {1, 48, 1, 80, [](DisplayListBuilder& b) {b.drawImageNine(TestImage1, {10, 10, 20, 20}, {10, 10, 80, 80},
                                                                SkFilterMode::kNearest);}},
      {1, 48, 1, 80, [](DisplayListBuilder& b) {b.drawImageNine(TestImage1, {10, 10, 25, 20}, {10, 10, 80, 80},
                                                                SkFilterMode::kNearest);}},
      {1, 48, 1, 80, [](DisplayListBuilder& b) {b.drawImageNine(TestImage1, {10, 10, 20, 20}, {10, 10, 85, 80},
                                                                SkFilterMode::kNearest);}},
      {1, 48, 1, 80, [](DisplayListBuilder& b) {b.drawImageNine(TestImage1, {10, 10, 20, 20}, {10, 10, 80, 80},
                                                                SkFilterMode::kLinear);}},
      {1, 48, 1, 80, [](DisplayListBuilder& b) {b.drawImageNine(TestImage2, {10, 10, 15, 15}, {10, 10, 80, 80},
                                                                SkFilterMode::kNearest);}},
    }
  },
  { "DrawImageLattice", {
      // Lattice:
      // const int*      fXDivs;     //!< x-axis values dividing bitmap
      // const int*      fYDivs;     //!< y-axis values dividing bitmap
      // const RectType* fRectTypes; //!< array of fill types
      // int             fXCount;    //!< number of x-coordinates
      // int             fYCount;    //!< number of y-coordinates
      // const SkIRect*  fBounds;    //!< source bounds to draw from
      // const SkColor*  fColors;    //!< array of colors
      // size = 64 + fXCount * 4 + fYCount * 4
      // if fColors and fRectTypes are not null, add (fXCount + 1) * (fYCount + 1) * 5
      {1, 88, 1, 88, [](DisplayListBuilder& b) {b.drawImageLattice(TestImage1,
                                                                   {TestDivs1, TestDivs1, nullptr, 3, 3, nullptr, nullptr},
                                                                   {10, 10, 40, 40}, SkFilterMode::kNearest, false);}},
      {1, 88, 1, 88, [](DisplayListBuilder& b) {b.drawImageLattice(TestImage1,
                                                                   {TestDivs1, TestDivs1, nullptr, 3, 3, nullptr, nullptr},
                                                                   {10, 10, 40, 45}, SkFilterMode::kNearest, false);}},
      {1, 88, 1, 88, [](DisplayListBuilder& b) {b.drawImageLattice(TestImage1,
                                                                   {TestDivs2, TestDivs1, nullptr, 3, 3, nullptr, nullptr},
                                                                   {10, 10, 40, 40}, SkFilterMode::kNearest, false);}},
      // One less yDiv does not change the allocation due to 8-byte alignment
      {1, 88, 1, 88, [](DisplayListBuilder& b) {b.drawImageLattice(TestImage1,
                                                                   {TestDivs1, TestDivs1, nullptr, 3, 2, nullptr, nullptr},
                                                                   {10, 10, 40, 40}, SkFilterMode::kNearest, false);}},
      {1, 88, 1, 88, [](DisplayListBuilder& b) {b.drawImageLattice(TestImage1,
                                                                   {TestDivs1, TestDivs1, nullptr, 3, 3, nullptr, nullptr},
                                                                   {10, 10, 40, 40}, SkFilterMode::kLinear, false);}},
      {2, 96, 2, 96, [](DisplayListBuilder& b) {b.setColor(SK_ColorMAGENTA);
                                                b.drawImageLattice(TestImage1,
                                                                   {TestDivs1, TestDivs1, nullptr, 3, 3, nullptr, nullptr},
                                                                   {10, 10, 40, 40}, SkFilterMode::kNearest, true);}},
      {1, 88, 1, 88, [](DisplayListBuilder& b) {b.drawImageLattice(TestImage2,
                                                                   {TestDivs1, TestDivs1, nullptr, 3, 3, nullptr, nullptr},
                                                                   {10, 10, 40, 40}, SkFilterMode::kNearest, false);}},
      // Supplying fBounds does not change size because the Op record always includes it
      {1, 88, 1, 88, [](DisplayListBuilder& b) {b.drawImageLattice(TestImage1,
                                                                   {TestDivs1, TestDivs1, nullptr, 3, 3, &TestLatticeSrcRect, nullptr},
                                                                   {10, 10, 40, 40}, SkFilterMode::kNearest, false);}},
      {1, 128, 1, 128, [](DisplayListBuilder& b) {b.drawImageLattice(TestImage1,
                                                                     {TestDivs3, TestDivs3, TestRTypes, 2, 2, nullptr, TestLatticeColors},
                                                                     {10, 10, 40, 40}, SkFilterMode::kNearest, false);}},
    }
  },
  { "DrawAtlas", {
      {1, 40 + 32 + 32, 1, 40 + 32 + 32, [](DisplayListBuilder& b) {
        static SkRSXform xforms[] = { {1, 0, 0, 0}, {0, 1, 0, 0} };
        static SkRect texs[] = { { 10, 10, 20, 20 }, {20, 20, 30, 30} };
        b.drawAtlas(TestImage1, xforms, texs, nullptr, 2, SkBlendMode::kSrcIn,
                    DisplayList::NearestSampling, nullptr);}},
      {1, 40 + 32 + 32, 1, 40 + 32 + 32, [](DisplayListBuilder& b) {
        static SkRSXform xforms[] = { {0, 1, 0, 0}, {0, 1, 0, 0} };
        static SkRect texs[] = { { 10, 10, 20, 20 }, {20, 20, 30, 30} };
        b.drawAtlas(TestImage1, xforms, texs, nullptr, 2, SkBlendMode::kSrcIn,
                    DisplayList::NearestSampling, nullptr);}},
      {1, 40 + 32 + 32, 1, 40 + 32 + 32, [](DisplayListBuilder& b) {
        static SkRSXform xforms[] = { {1, 0, 0, 0}, {0, 1, 0, 0} };
        static SkRect texs[] = { { 10, 10, 20, 20 }, {20, 25, 30, 30} };
        b.drawAtlas(TestImage1, xforms, texs, nullptr, 2, SkBlendMode::kSrcIn,
                    DisplayList::NearestSampling, nullptr);}},
      {1, 40 + 32 + 32, 1, 40 + 32 + 32, [](DisplayListBuilder& b) {
        static SkRSXform xforms[] = { {1, 0, 0, 0}, {0, 1, 0, 0} };
        static SkRect texs[] = { { 10, 10, 20, 20 }, {20, 20, 30, 30} };
        b.drawAtlas(TestImage1, xforms, texs, nullptr, 2, SkBlendMode::kSrcIn,
                    DisplayList::LinearSampling, nullptr);}},
      {1, 40 + 32 + 32, 1, 40 + 32 + 32, [](DisplayListBuilder& b) {
        static SkRSXform xforms[] = { {1, 0, 0, 0}, {0, 1, 0, 0} };
        static SkRect texs[] = { { 10, 10, 20, 20 }, {20, 20, 30, 30} };
        b.drawAtlas(TestImage1, xforms, texs, nullptr, 2, SkBlendMode::kDstIn,
                    DisplayList::NearestSampling, nullptr);}},
      {1, 56 + 32 + 32, 1, 56 + 32 + 32, [](DisplayListBuilder& b) {
        static SkRSXform xforms[] = { {1, 0, 0, 0}, {0, 1, 0, 0} };
        static SkRect texs[] = { { 10, 10, 20, 20 }, {20, 20, 30, 30} };
        static SkRect cullRect = { 0, 0, 200, 200 };
        b.drawAtlas(TestImage2, xforms, texs, nullptr, 2, SkBlendMode::kSrcIn,
                    DisplayList::NearestSampling, &cullRect);}},
      {1, 40 + 32 + 32 + 8, 1, 40 + 32 + 32 + 8, [](DisplayListBuilder& b) {
        static SkRSXform xforms[] = { {1, 0, 0, 0}, {0, 1, 0, 0} };
        static SkRect texs[] = { { 10, 10, 20, 20 }, {20, 20, 30, 30} };
        static SkColor colors[] = { SK_ColorBLUE, SK_ColorGREEN };
        b.drawAtlas(TestImage1, xforms, texs, colors, 2, SkBlendMode::kSrcIn,
                    DisplayList::NearestSampling, nullptr);}},
      {1, 56 + 32 + 32 + 8, 1, 56 + 32 + 32 + 8, [](DisplayListBuilder& b) {
        static SkRSXform xforms[] = { {1, 0, 0, 0}, {0, 1, 0, 0} };
        static SkRect texs[] = { { 10, 10, 20, 20 }, {20, 20, 30, 30} };
        static SkColor colors[] = { SK_ColorBLUE, SK_ColorGREEN };
        static SkRect cullRect = { 0, 0, 200, 200 };
        b.drawAtlas(TestImage1, xforms, texs, colors, 2, SkBlendMode::kSrcIn,
                    DisplayList::NearestSampling, &cullRect);}},
    }
  },
  { "DrawPicture", {
      // cv.drawPicture cannot be compared as SkCanvas may inline it
      {1, 16, -1, 16, [](DisplayListBuilder& b) {b.drawPicture(TestPicture1, nullptr, false);}},
      {1, 16, -1, 16, [](DisplayListBuilder& b) {b.drawPicture(TestPicture2, nullptr, false);}},
      {1, 16, -1, 16, [](DisplayListBuilder& b) {b.drawPicture(TestPicture1, nullptr, true);}},
      {1, 56, -1, 56, [](DisplayListBuilder& b) {b.drawPicture(TestPicture1, &TestMatrix1, false);}},
      {1, 56, -1, 56, [](DisplayListBuilder& b) {b.drawPicture(TestPicture1, &TestMatrix2, false);}},
      {1, 56, -1, 56, [](DisplayListBuilder& b) {b.drawPicture(TestPicture1, &TestMatrix1, true);}},
    }
  },
  { "DrawDisplayList", {
      // cv.drawDL does not exist
      {1, 16, -1, 16, [](DisplayListBuilder& b) {b.drawDisplayList(TestDisplayList1);}},
      {1, 16, -1, 16, [](DisplayListBuilder& b) {b.drawDisplayList(TestDisplayList2);}},
    }
  },
  { "DrawTextBlob", {
      {1, 24, 1, 24, [](DisplayListBuilder& b) {b.drawTextBlob(TestBlob1, 10, 10);}},
      {1, 24, 1, 24, [](DisplayListBuilder& b) {b.drawTextBlob(TestBlob1, 20, 10);}},
      {1, 24, 1, 24, [](DisplayListBuilder& b) {b.drawTextBlob(TestBlob1, 10, 20);}},
      {1, 24, 1, 24, [](DisplayListBuilder& b) {b.drawTextBlob(TestBlob2, 10, 10);}},
    }
  },
  // The -1 op counts below are to indicate to the framework not to test
  // SkCanvas conversion of these ops as it converts the operation into a
  // format that is not exposed publicly and so we cannot recapture the
  // operation.
  // See: https://bugs.chromium.org/p/skia/issues/detail?id=12125
  { "DrawShadow", {
      // cv shadows are turned into an opaque ShadowRec which is not exposed
      {1, 32, -1, 32, [](DisplayListBuilder& b) {b.drawShadow(TestPath1, SK_ColorGREEN, 1.0, false, 1.0);}},
      {1, 32, -1, 32, [](DisplayListBuilder& b) {b.drawShadow(TestPath2, SK_ColorGREEN, 1.0, false, 1.0);}},
      {1, 32, -1, 32, [](DisplayListBuilder& b) {b.drawShadow(TestPath1, SK_ColorBLUE, 1.0, false, 1.0);}},
      {1, 32, -1, 32, [](DisplayListBuilder& b) {b.drawShadow(TestPath1, SK_ColorGREEN, 2.0, false, 1.0);}},
      {1, 32, -1, 32, [](DisplayListBuilder& b) {b.drawShadow(TestPath1, SK_ColorGREEN, 1.0, true, 1.0);}},
      {1, 32, -1, 32, [](DisplayListBuilder& b) {b.drawShadow(TestPath1, SK_ColorGREEN, 1.0, false, 2.5);}},
    }
  },
};

TEST(DisplayList, SingleOpSizes) {
  for (auto& group : allGroups) {
    for (size_t i = 0; i < group.variants.size(); i++) {
      auto& invocation = group.variants[i];
      sk_sp<DisplayList> dl = invocation.Build();
      auto desc = group.op_name + "(variant " + std::to_string(i + 1) + ")";
      ASSERT_EQ(dl->op_count(), invocation.op_count) << desc;
      EXPECT_EQ(dl->bytes(), invocation.byte_count) << desc;
    }
  }
}

TEST(DisplayList, SingleOpDisplayListsNotEqualEmpty) {
  sk_sp<DisplayList> empty = DisplayListBuilder().Build();
  for (auto& group : allGroups) {
    for (size_t i = 0; i < group.variants.size(); i++) {
      sk_sp<DisplayList> dl = group.variants[i].Build();
      auto desc =
          group.op_name + "(variant " + std::to_string(i + 1) + " != empty)";
      ASSERT_FALSE(dl->Equals(*empty)) << desc;
      ASSERT_FALSE(empty->Equals(*dl)) << desc;
    }
  }
}

TEST(DisplayList, SingleOpDisplayListsRecapturedAreEqual) {
  for (auto& group : allGroups) {
    for (size_t i = 0; i < group.variants.size(); i++) {
      sk_sp<DisplayList> dl = group.variants[i].Build();
      // Verify recapturing the replay of the display list is Equals()
      // when dispatching directly from the DL to another builder
      DisplayListBuilder builder;
      dl->Dispatch(builder);
      sk_sp<DisplayList> copy = builder.Build();
      auto desc =
          group.op_name + "(variant " + std::to_string(i + 1) + " == copy)";
      ASSERT_EQ(copy->op_count(), dl->op_count()) << desc;
      ASSERT_EQ(copy->bytes(), dl->bytes()) << desc;
      ASSERT_EQ(copy->bounds(), dl->bounds()) << desc;
      ASSERT_TRUE(copy->Equals(*dl)) << desc;
      ASSERT_TRUE(dl->Equals(*copy)) << desc;
    }
  }
}

TEST(DisplayList, SingleOpDisplayListsRecapturedViaSkCanvasAreEqual) {
  for (auto& group : allGroups) {
    for (size_t i = 0; i < group.variants.size(); i++) {
      if (group.variants[i].sk_op_count < 0) {
        // A negative sk_op_count means "do not test this op".
        // Used mainly for these cases:
        // - we cannot encode a DrawShadowRec (Skia private header)
        // - SkCanvas cannot receive a DisplayList
        // - SkCanvas may or may not inline an SkPicture
        continue;
      }
      // Verify a DisplayList (re)built by "rendering" it to an
      // [SkCanvas->DisplayList] recorder recaptures an equivalent
      // sequence.
      // Note that sometimes the rendering ops can be optimized out by
      // SkCanvas so the transfer is not always 1:1. We control for
      // this by having separate op counts and sizes for the sk results
      // and changing our expectation of Equals() results accordingly.
      sk_sp<DisplayList> dl = group.variants[i].Build();

      DisplayListCanvasRecorder recorder(dl->bounds());
      dl->RenderTo(&recorder);
      sk_sp<DisplayList> sk_copy = recorder.Build();
      auto desc = group.op_name + "[variant " + std::to_string(i + 1) + "]";
      EXPECT_EQ(sk_copy->op_count(), group.variants[i].sk_op_count) << desc;
      EXPECT_EQ(sk_copy->bytes(), group.variants[i].sk_byte_count) << desc;
      if (group.variants[i].sk_version_matches()) {
        EXPECT_EQ(sk_copy->bounds(), dl->bounds()) << desc;
        EXPECT_TRUE(dl->Equals(*sk_copy)) << desc << " == sk_copy";
        EXPECT_TRUE(sk_copy->Equals(*dl)) << "sk_copy == " << desc;
      } else {
        // No assertion on bounds
        // they could be equal, hard to tell
        EXPECT_FALSE(dl->Equals(*sk_copy)) << desc << " != sk_copy";
        EXPECT_FALSE(sk_copy->Equals(*dl)) << "sk_copy != " << desc;
      }
    }
  }
}

TEST(DisplayList, SingleOpDisplayListsCompareToEachOther) {
  for (auto& group : allGroups) {
    std::vector<sk_sp<DisplayList>> listsA;
    std::vector<sk_sp<DisplayList>> listsB;
    for (size_t i = 0; i < group.variants.size(); i++) {
      listsA.push_back(group.variants[i].Build());
      listsB.push_back(group.variants[i].Build());
    }

    for (size_t i = 0; i < listsA.size(); i++) {
      sk_sp<DisplayList> listA = listsA[i];
      for (size_t j = 0; j < listsB.size(); j++) {
        sk_sp<DisplayList> listB = listsB[j];
        auto desc = group.op_name + "(variant " + std::to_string(i + 1) +
                    " ==? variant " + std::to_string(j + 1) + ")";
        if (i == j) {
          ASSERT_EQ(listA->op_count(), listB->op_count()) << desc;
          ASSERT_EQ(listA->bytes(), listB->bytes()) << desc;
          ASSERT_EQ(listA->bounds(), listB->bounds()) << desc;
          ASSERT_TRUE(listA->Equals(*listB)) << desc;
          ASSERT_TRUE(listB->Equals(*listA)) << desc;
        } else {
          // No assertion on op/byte counts or bounds
          // they may or may not be equal between variants
          ASSERT_FALSE(listA->Equals(*listB)) << desc;
          ASSERT_FALSE(listB->Equals(*listA)) << desc;
        }
      }
    }
  }
}

static sk_sp<DisplayList> Build(size_t g_index, size_t v_index) {
  DisplayListBuilder builder;
  int op_count = 0;
  size_t byte_count = 0;
  for (size_t i = 0; i < allGroups.size(); i++) {
    DisplayListInvocationGroup& group = allGroups[i];
    size_t j = (i == g_index ? v_index : 0);
    if (j >= group.variants.size())
      continue;
    DisplayListInvocation& invocation = group.variants[j];
    op_count += invocation.op_count;
    byte_count += invocation.byte_count;
    invocation.invoker(builder);
  }
  sk_sp<DisplayList> dl = builder.Build();
  std::string name;
  if (g_index >= allGroups.size()) {
    name = "Default";
  } else {
    name = allGroups[g_index].op_name;
    if (v_index < 0) {
      name += " skipped";
    } else {
      name += " variant " + std::to_string(v_index + 1);
    }
  }
  EXPECT_EQ(dl->op_count(), op_count) << name;
  EXPECT_EQ(dl->bytes(), byte_count) << name;
  return dl;
}

TEST(DisplayList, DisplayListsWithVaryingOpComparisons) {
  sk_sp<DisplayList> default_dl = Build(allGroups.size(), 0);
  ASSERT_TRUE(default_dl->Equals(*default_dl)) << "Default == itself";
  for (size_t gi = 0; gi < allGroups.size(); gi++) {
    DisplayListInvocationGroup& group = allGroups[gi];
    sk_sp<DisplayList> missing_dl = Build(gi, group.variants.size());
    auto desc = "[Group " + std::to_string(gi + 1) + " omitted]";
    ASSERT_TRUE(missing_dl->Equals(*missing_dl)) << desc << " == itself";
    ASSERT_FALSE(missing_dl->Equals(*default_dl)) << desc << " != Default";
    ASSERT_FALSE(default_dl->Equals(*missing_dl)) << "Default != " << desc;
    for (size_t vi = 0; vi < group.variants.size(); vi++) {
      auto desc = "[Group " + std::to_string(gi + 1) + " variant " +
                  std::to_string(vi + 1) + "]";
      sk_sp<DisplayList> variant_dl = Build(gi, vi);
      ASSERT_TRUE(variant_dl->Equals(*variant_dl)) << desc << " == itself";
      if (vi == 0) {
        ASSERT_TRUE(variant_dl->Equals(*default_dl)) << desc << " == Default";
        ASSERT_TRUE(default_dl->Equals(*variant_dl)) << "Default == " << desc;
      } else {
        ASSERT_FALSE(variant_dl->Equals(*default_dl)) << desc << " != Default";
        ASSERT_FALSE(default_dl->Equals(*variant_dl)) << "Default != " << desc;
      }
      ASSERT_FALSE(variant_dl->Equals(*missing_dl)) << desc << " != omitted";
      ASSERT_FALSE(missing_dl->Equals(*variant_dl)) << "omitted != " << desc;
    }
  }
}

}  // namespace testing
}  // namespace flutter
