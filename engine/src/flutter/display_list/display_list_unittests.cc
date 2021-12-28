// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/display_list.h"
#include "flutter/display_list/display_list_builder.h"
#include "flutter/display_list/display_list_canvas_recorder.h"
#include "flutter/fml/math.h"
#include "flutter/testing/testing.h"
#include "third_party/skia/include/core/SkPictureRecorder.h"
#include "third_party/skia/include/core/SkSurface.h"
#include "third_party/skia/include/effects/SkBlenders.h"
#include "third_party/skia/include/effects/SkDashPathEffect.h"
#include "third_party/skia/include/effects/SkGradientShader.h"
#include "third_party/skia/include/effects/SkImageFilters.h"

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

static const sk_sp<SkBlender> TestBlender1 =
    SkBlenders::Arithmetic(0.2, 0.2, 0.2, 0.2, false);
static const sk_sp<SkBlender> TestBlender2 =
    SkBlenders::Arithmetic(0.2, 0.2, 0.2, 0.2, true);
static const sk_sp<SkBlender> TestBlender3 =
    SkBlenders::Arithmetic(0.3, 0.3, 0.3, 0.3, true);
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
  int op_count_;
  size_t byte_count_;

  // in some cases, running the sequence through an SkCanvas will result
  // in fewer ops/bytes. Attribute invocations are recorded in an SkPaint
  // and not forwarded on, and SkCanvas culls unused save/restore/transforms.
  int sk_op_count_;
  size_t sk_byte_count_;

  DlInvoker invoker;
  bool supports_group_opacity_ = false;

  bool sk_version_matches() {
    return (op_count_ == sk_op_count_ && byte_count_ == sk_byte_count_);
  }

  // A negative sk_op_count means "do not test this op".
  // Used mainly for these cases:
  // - we cannot encode a DrawShadowRec (Skia private header)
  // - SkCanvas cannot receive a DisplayList
  // - SkCanvas may or may not inline an SkPicture
  bool sk_testing_invalid() { return sk_op_count_ < 0; }

  bool is_empty() { return byte_count_ == 0; }

  bool supports_group_opacity() { return supports_group_opacity_; }

  int op_count() { return op_count_; }
  // byte count for the individual ops, no DisplayList overhead
  size_t raw_byte_count() { return byte_count_; }
  // byte count for the ops with DisplayList overhead, comparable
  // to |DisplayList.byte_count().
  size_t byte_count() { return sizeof(DisplayList) + byte_count_; }

  int sk_op_count() { return sk_op_count_; }
  // byte count for the ops with DisplayList overhead as translated
  // through an SkCanvas interface, comparable to |DisplayList.byte_count().
  size_t sk_byte_count() { return sizeof(DisplayList) + sk_byte_count_; }

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
  { "SetAntiAlias", {
      {0, 8, 0, 0, [](DisplayListBuilder& b) {b.setAntiAlias(true);}},
      {0, 0, 0, 0, [](DisplayListBuilder& b) {b.setAntiAlias(false);}},
    }
  },
  { "SetDither", {
      {0, 8, 0, 0, [](DisplayListBuilder& b) {b.setDither(true);}},
      {0, 0, 0, 0, [](DisplayListBuilder& b) {b.setDither(false);}},
    }
  },
  { "SetInvertColors", {
      {0, 8, 0, 0, [](DisplayListBuilder& b) {b.setInvertColors(true);}},
      {0, 0, 0, 0, [](DisplayListBuilder& b) {b.setInvertColors(false);}},
    }
  },
  { "SetStrokeCap", {
      {0, 8, 0, 0, [](DisplayListBuilder& b) {b.setStrokeCap(SkPaint::kRound_Cap);}},
      {0, 8, 0, 0, [](DisplayListBuilder& b) {b.setStrokeCap(SkPaint::kSquare_Cap);}},
      {0, 0, 0, 0, [](DisplayListBuilder& b) {b.setStrokeCap(SkPaint::kButt_Cap);}},
    }
  },
  { "SetStrokeJoin", {
      {0, 8, 0, 0, [](DisplayListBuilder& b) {b.setStrokeJoin(SkPaint::kBevel_Join);}},
      {0, 8, 0, 0, [](DisplayListBuilder& b) {b.setStrokeJoin(SkPaint::kRound_Join);}},
      {0, 0, 0, 0, [](DisplayListBuilder& b) {b.setStrokeJoin(SkPaint::kMiter_Join);}},
    }
  },
  { "SetStyle", {
      {0, 8, 0, 0, [](DisplayListBuilder& b) {b.setStyle(SkPaint::kStroke_Style);}},
      {0, 8, 0, 0, [](DisplayListBuilder& b) {b.setStyle(SkPaint::kStrokeAndFill_Style);}},
      {0, 0, 0, 0, [](DisplayListBuilder& b) {b.setStyle(SkPaint::kFill_Style);}},
    }
  },
  { "SetStrokeWidth", {
      {0, 8, 0, 0, [](DisplayListBuilder& b) {b.setStrokeWidth(1.0);}},
      {0, 8, 0, 0, [](DisplayListBuilder& b) {b.setStrokeWidth(5.0);}},
      {0, 0, 0, 0, [](DisplayListBuilder& b) {b.setStrokeWidth(0.0);}},
    }
  },
  { "SetStrokeMiter", {
      {0, 8, 0, 0, [](DisplayListBuilder& b) {b.setStrokeMiter(0.0);}},
      {0, 8, 0, 0, [](DisplayListBuilder& b) {b.setStrokeMiter(5.0);}},
      {0, 0, 0, 0, [](DisplayListBuilder& b) {b.setStrokeMiter(4.0);}},
    }
  },
  { "SetColor", {
      {0, 8, 0, 0, [](DisplayListBuilder& b) {b.setColor(SK_ColorGREEN);}},
      {0, 8, 0, 0, [](DisplayListBuilder& b) {b.setColor(SK_ColorBLUE);}},
      {0, 0, 0, 0, [](DisplayListBuilder& b) {b.setColor(SK_ColorBLACK);}},
    }
  },
  { "SetBlendModeOrBlender", {
      {0, 8, 0, 0, [](DisplayListBuilder& b) {b.setBlendMode(SkBlendMode::kSrcIn);}},
      {0, 8, 0, 0, [](DisplayListBuilder& b) {b.setBlendMode(SkBlendMode::kDstIn);}},
      {0, 16, 0, 0, [](DisplayListBuilder& b) {b.setBlender(TestBlender1);}},
      {0, 16, 0, 0, [](DisplayListBuilder& b) {b.setBlender(TestBlender2);}},
      {0, 16, 0, 0, [](DisplayListBuilder& b) {b.setBlender(TestBlender3);}},
      {0, 0, 0, 0, [](DisplayListBuilder& b) {b.setBlendMode(SkBlendMode::kSrcOver);}},
      {0, 0, 0, 0, [](DisplayListBuilder& b) {b.setBlender(nullptr);}},
    }
  },
  { "SetShader", {
      {0, 16, 0, 0, [](DisplayListBuilder& b) {b.setShader(TestShader1);}},
      {0, 16, 0, 0, [](DisplayListBuilder& b) {b.setShader(TestShader2);}},
      {0, 16, 0, 0, [](DisplayListBuilder& b) {b.setShader(TestShader3);}},
      {0, 0, 0, 0, [](DisplayListBuilder& b) {b.setShader(nullptr);}},
    }
  },
  { "SetImageFilter", {
      {0, 16, 0, 0, [](DisplayListBuilder& b) {b.setImageFilter(TestImageFilter1);}},
      {0, 16, 0, 0, [](DisplayListBuilder& b) {b.setImageFilter(TestImageFilter2);}},
      {0, 0, 0, 0, [](DisplayListBuilder& b) {b.setImageFilter(nullptr);}},
    }
  },
  { "SetColorFilter", {
      {0, 16, 0, 0, [](DisplayListBuilder& b) {b.setColorFilter(TestColorFilter1);}},
      {0, 16, 0, 0, [](DisplayListBuilder& b) {b.setColorFilter(TestColorFilter2);}},
      {0, 0, 0, 0, [](DisplayListBuilder& b) {b.setColorFilter(nullptr);}},
    }
  },
  { "SetPathEffect", {
      {0, 16, 0, 0, [](DisplayListBuilder& b) {b.setPathEffect(TestPathEffect1);}},
      {0, 16, 0, 0, [](DisplayListBuilder& b) {b.setPathEffect(TestPathEffect2);}},
      {0, 0, 0, 0, [](DisplayListBuilder& b) {b.setPathEffect(nullptr);}},
    }
  },
  { "SetMaskFilter", {
      {0, 16, 0, 0, [](DisplayListBuilder& b) {b.setMaskFilter(TestMaskFilter);}},
      {0, 8, 0, 0, [](DisplayListBuilder& b) {b.setMaskBlurFilter(kNormal_SkBlurStyle, 3.0);}},
      {0, 8, 0, 0, [](DisplayListBuilder& b) {b.setMaskBlurFilter(kNormal_SkBlurStyle, 5.0);}},
      {0, 8, 0, 0, [](DisplayListBuilder& b) {b.setMaskBlurFilter(kSolid_SkBlurStyle, 3.0);}},
      {0, 8, 0, 0, [](DisplayListBuilder& b) {b.setMaskBlurFilter(kInner_SkBlurStyle, 3.0);}},
      {0, 8, 0, 0, [](DisplayListBuilder& b) {b.setMaskBlurFilter(kOuter_SkBlurStyle, 3.0);}},
      {0, 0, 0, 0, [](DisplayListBuilder& b) {b.setMaskFilter(nullptr);}},
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
      {1, 16, 1, 16, [](DisplayListBuilder& b) {b.translate(10, 10);}},
      {1, 16, 1, 16, [](DisplayListBuilder& b) {b.translate(10, 15);}},
      {1, 16, 1, 16, [](DisplayListBuilder& b) {b.translate(15, 10);}},
      {0, 0, 0, 0, [](DisplayListBuilder& b) {b.translate(0, 0);}},
    }
  },
  { "Scale", {
      // cv.scale(1, 1) is ignored
      {1, 16, 1, 16, [](DisplayListBuilder& b) {b.scale(2, 2);}},
      {1, 16, 1, 16, [](DisplayListBuilder& b) {b.scale(2, 3);}},
      {1, 16, 1, 16, [](DisplayListBuilder& b) {b.scale(3, 2);}},
      {0, 0, 0, 0, [](DisplayListBuilder& b) {b.scale(1, 1);}},
    }
  },
  { "Rotate", {
      // cv.rotate(0) is ignored, otherwise expressed as concat(rotmatrix)
      {1, 8, 1, 32, [](DisplayListBuilder& b) {b.rotate(30);}},
      {1, 8, 1, 32, [](DisplayListBuilder& b) {b.rotate(45);}},
      {0, 0, 0, 0, [](DisplayListBuilder& b) {b.rotate(0);}},
      {0, 0, 0, 0, [](DisplayListBuilder& b) {b.rotate(360);}},
    }
  },
  { "Skew", {
      // cv.skew(0, 0) is ignored, otherwise expressed as concat(skewmatrix)
      {1, 16, 1, 32, [](DisplayListBuilder& b) {b.skew(0.1, 0.1);}},
      {1, 16, 1, 32, [](DisplayListBuilder& b) {b.skew(0.1, 0.2);}},
      {1, 16, 1, 32, [](DisplayListBuilder& b) {b.skew(0.2, 0.1);}},
      {0, 0, 0, 0, [](DisplayListBuilder& b) {b.skew(0, 0);}},
    }
  },
  { "Transform2DAffine", {
      {1, 32, 1, 32, [](DisplayListBuilder& b) {b.transform2DAffine(0, 1, 12, 1, 0, 33);}},
      // b.transform(identity) is ignored
      {0, 0, 0, 0, [](DisplayListBuilder& b) {b.transform2DAffine(1, 0, 0, 0, 1, 0);}},
    }
  },
  { "TransformFullPerspective", {
      {1, 72, 1, 72, [](DisplayListBuilder& b) {b.transformFullPerspective(0, 1, 0, 12,
                                                                           1, 0, 0, 33,
                                                                           3, 2, 5, 29,
                                                                           0, 0, 0, 12);}},
      // b.transform(2D affine) is reduced to 2x3
      {1, 32, 1, 32, [](DisplayListBuilder& b) {b.transformFullPerspective(2, 1, 0, 4,
                                                                           1, 3, 0, 5,
                                                                           0, 0, 1, 0,
                                                                           0, 0, 0, 1);}},
      // b.transform(identity) is ignored
      {0, 0, 0, 0, [](DisplayListBuilder& b) {b.transformFullPerspective(1, 0, 0, 0,
                                                                         0, 1, 0, 0,
                                                                         0, 0, 1, 0,
                                                                         0, 0, 0, 1);}},
    }
  },
  { "ClipRect", {
      {1, 24, 1, 24, [](DisplayListBuilder& b) {b.clipRect(TestBounds, SkClipOp::kIntersect, true);}},
      {1, 24, 1, 24, [](DisplayListBuilder& b) {b.clipRect(TestBounds.makeOffset(1, 1),
                                                           SkClipOp::kIntersect, true);}},
      {1, 24, 1, 24, [](DisplayListBuilder& b) {b.clipRect(TestBounds, SkClipOp::kIntersect, false);}},
      {1, 24, 1, 24, [](DisplayListBuilder& b) {b.clipRect(TestBounds, SkClipOp::kDifference, true);}},
      {1, 24, 1, 24, [](DisplayListBuilder& b) {b.clipRect(TestBounds, SkClipOp::kDifference, false);}},
    }
  },
  { "ClipRRect", {
      {1, 64, 1, 64, [](DisplayListBuilder& b) {b.clipRRect(TestRRect, SkClipOp::kIntersect, true);}},
      {1, 64, 1, 64, [](DisplayListBuilder& b) {b.clipRRect(TestRRect.makeOffset(1, 1),
                                                            SkClipOp::kIntersect, true);}},
      {1, 64, 1, 64, [](DisplayListBuilder& b) {b.clipRRect(TestRRect, SkClipOp::kIntersect, false);}},
      {1, 64, 1, 64, [](DisplayListBuilder& b) {b.clipRRect(TestRRect, SkClipOp::kDifference, true);}},
      {1, 64, 1, 64, [](DisplayListBuilder& b) {b.clipRRect(TestRRect, SkClipOp::kDifference, false);}},
    }
  },
  { "ClipPath", {
      {1, 24, 1, 24, [](DisplayListBuilder& b) {b.clipPath(TestPath1, SkClipOp::kIntersect, true);}},
      {1, 24, 1, 24, [](DisplayListBuilder& b) {b.clipPath(TestPath2, SkClipOp::kIntersect, true);}},
      {1, 24, 1, 24, [](DisplayListBuilder& b) {b.clipPath(TestPath3, SkClipOp::kIntersect, true);}},
      {1, 24, 1, 24, [](DisplayListBuilder& b) {b.clipPath(TestPath1, SkClipOp::kIntersect, false);}},
      {1, 24, 1, 24, [](DisplayListBuilder& b) {b.clipPath(TestPath1, SkClipOp::kDifference, true);}},
      {1, 24, 1, 24, [](DisplayListBuilder& b) {b.clipPath(TestPath1, SkClipOp::kDifference, false);}},
      // clipPath(rect) becomes clipRect
      {1, 24, 1, 24, [](DisplayListBuilder& b) {b.clipPath(TestPathRect, SkClipOp::kIntersect, true);}},
      // clipPath(oval) becomes clipRRect
      {1, 64, 1, 64, [](DisplayListBuilder& b) {b.clipPath(TestPathOval, SkClipOp::kIntersect, true);}},
    }
  },
  { "DrawPaint", {
      {1, 8, 1, 8, [](DisplayListBuilder& b) {b.drawPaint();}},
    }
  },
  { "DrawColor", {
      // cv.drawColor becomes cv.drawPaint(paint)
      {1, 16, 1, 24, [](DisplayListBuilder& b) {b.drawColor(SK_ColorBLUE, SkBlendMode::kSrcIn);}},
      {1, 16, 1, 24, [](DisplayListBuilder& b) {b.drawColor(SK_ColorBLUE, SkBlendMode::kDstIn);}},
      {1, 16, 1, 24, [](DisplayListBuilder& b) {b.drawColor(SK_ColorCYAN, SkBlendMode::kSrcIn);}},
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
      {1, 40, 1, 40, [](DisplayListBuilder& b) {b.drawImage(TestImage1, {10, 10}, DisplayList::NearestSampling, false);}},
      {1, 40, 1, 40, [](DisplayListBuilder& b) {b.drawImage(TestImage1, {10, 10}, DisplayList::NearestSampling, true);}},
      {1, 40, 1, 40, [](DisplayListBuilder& b) {b.drawImage(TestImage1, {20, 10}, DisplayList::NearestSampling, false);}},
      {1, 40, 1, 40, [](DisplayListBuilder& b) {b.drawImage(TestImage1, {10, 20}, DisplayList::NearestSampling, false);}},
      {1, 40, 1, 40, [](DisplayListBuilder& b) {b.drawImage(TestImage1, {10, 10}, DisplayList::LinearSampling, false);}},
      {1, 40, 1, 40, [](DisplayListBuilder& b) {b.drawImage(TestImage2, {10, 10}, DisplayList::NearestSampling, false);}},
    }
  },
  { "DrawImageRect", {
      {1, 72, 1, 72, [](DisplayListBuilder& b) {b.drawImageRect(TestImage1, {10, 10, 20, 20}, {10, 10, 80, 80},
                                                                DisplayList::NearestSampling, false);}},
      {1, 72, 1, 72, [](DisplayListBuilder& b) {b.drawImageRect(TestImage1, {10, 10, 20, 20}, {10, 10, 80, 80},
                                                                DisplayList::NearestSampling, true);}},
      {1, 72, 1, 72, [](DisplayListBuilder& b) {b.drawImageRect(TestImage1, {10, 10, 20, 20}, {10, 10, 80, 80},
                                                                DisplayList::NearestSampling, false,
                                                                SkCanvas::SrcRectConstraint::kStrict_SrcRectConstraint);}},
      {1, 72, 1, 72, [](DisplayListBuilder& b) {b.drawImageRect(TestImage1, {10, 10, 25, 20}, {10, 10, 80, 80},
                                                                DisplayList::NearestSampling, false);}},
      {1, 72, 1, 72, [](DisplayListBuilder& b) {b.drawImageRect(TestImage1, {10, 10, 20, 20}, {10, 10, 85, 80},
                                                                DisplayList::NearestSampling, false);}},
      {1, 72, 1, 72, [](DisplayListBuilder& b) {b.drawImageRect(TestImage1, {10, 10, 20, 20}, {10, 10, 80, 80},
                                                                DisplayList::LinearSampling, false);}},
      {1, 72, 1, 72, [](DisplayListBuilder& b) {b.drawImageRect(TestImage2, {10, 10, 15, 15}, {10, 10, 80, 80},
                                                                DisplayList::NearestSampling, false);}},
    }
  },
  { "DrawImageNine", {
      // SkVanvas::drawImageNine is immediately converted to drawImageLattice
      {1, 48, 1, 80, [](DisplayListBuilder& b) {b.drawImageNine(TestImage1, {10, 10, 20, 20}, {10, 10, 80, 80},
                                                                SkFilterMode::kNearest, false);}},
      {1, 48, 1, 80, [](DisplayListBuilder& b) {b.drawImageNine(TestImage1, {10, 10, 20, 20}, {10, 10, 80, 80},
                                                                SkFilterMode::kNearest, true);}},
      {1, 48, 1, 80, [](DisplayListBuilder& b) {b.drawImageNine(TestImage1, {10, 10, 25, 20}, {10, 10, 80, 80},
                                                                SkFilterMode::kNearest, false);}},
      {1, 48, 1, 80, [](DisplayListBuilder& b) {b.drawImageNine(TestImage1, {10, 10, 20, 20}, {10, 10, 85, 80},
                                                                SkFilterMode::kNearest, false);}},
      {1, 48, 1, 80, [](DisplayListBuilder& b) {b.drawImageNine(TestImage1, {10, 10, 20, 20}, {10, 10, 80, 80},
                                                                SkFilterMode::kLinear, false);}},
      {1, 48, 1, 80, [](DisplayListBuilder& b) {b.drawImageNine(TestImage2, {10, 10, 15, 15}, {10, 10, 80, 80},
                                                                SkFilterMode::kNearest, false);}},
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
      {1, 96, 1, 96, [](DisplayListBuilder& b) {b.setColor(SK_ColorMAGENTA);
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
                    DisplayList::NearestSampling, nullptr, false);}},
      {1, 40 + 32 + 32, 1, 40 + 32 + 32, [](DisplayListBuilder& b) {
        static SkRSXform xforms[] = { {1, 0, 0, 0}, {0, 1, 0, 0} };
        static SkRect texs[] = { { 10, 10, 20, 20 }, {20, 20, 30, 30} };
        b.drawAtlas(TestImage1, xforms, texs, nullptr, 2, SkBlendMode::kSrcIn,
                    DisplayList::NearestSampling, nullptr, true);}},
      {1, 40 + 32 + 32, 1, 40 + 32 + 32, [](DisplayListBuilder& b) {
        static SkRSXform xforms[] = { {0, 1, 0, 0}, {0, 1, 0, 0} };
        static SkRect texs[] = { { 10, 10, 20, 20 }, {20, 20, 30, 30} };
        b.drawAtlas(TestImage1, xforms, texs, nullptr, 2, SkBlendMode::kSrcIn,
                    DisplayList::NearestSampling, nullptr, false);}},
      {1, 40 + 32 + 32, 1, 40 + 32 + 32, [](DisplayListBuilder& b) {
        static SkRSXform xforms[] = { {1, 0, 0, 0}, {0, 1, 0, 0} };
        static SkRect texs[] = { { 10, 10, 20, 20 }, {20, 25, 30, 30} };
        b.drawAtlas(TestImage1, xforms, texs, nullptr, 2, SkBlendMode::kSrcIn,
                    DisplayList::NearestSampling, nullptr, false);}},
      {1, 40 + 32 + 32, 1, 40 + 32 + 32, [](DisplayListBuilder& b) {
        static SkRSXform xforms[] = { {1, 0, 0, 0}, {0, 1, 0, 0} };
        static SkRect texs[] = { { 10, 10, 20, 20 }, {20, 20, 30, 30} };
        b.drawAtlas(TestImage1, xforms, texs, nullptr, 2, SkBlendMode::kSrcIn,
                    DisplayList::LinearSampling, nullptr, false);}},
      {1, 40 + 32 + 32, 1, 40 + 32 + 32, [](DisplayListBuilder& b) {
        static SkRSXform xforms[] = { {1, 0, 0, 0}, {0, 1, 0, 0} };
        static SkRect texs[] = { { 10, 10, 20, 20 }, {20, 20, 30, 30} };
        b.drawAtlas(TestImage1, xforms, texs, nullptr, 2, SkBlendMode::kDstIn,
                    DisplayList::NearestSampling, nullptr, false);}},
      {1, 56 + 32 + 32, 1, 56 + 32 + 32, [](DisplayListBuilder& b) {
        static SkRSXform xforms[] = { {1, 0, 0, 0}, {0, 1, 0, 0} };
        static SkRect texs[] = { { 10, 10, 20, 20 }, {20, 20, 30, 30} };
        static SkRect cullRect = { 0, 0, 200, 200 };
        b.drawAtlas(TestImage2, xforms, texs, nullptr, 2, SkBlendMode::kSrcIn,
                    DisplayList::NearestSampling, &cullRect, false);}},
      {1, 40 + 32 + 32 + 8, 1, 40 + 32 + 32 + 8, [](DisplayListBuilder& b) {
        static SkRSXform xforms[] = { {1, 0, 0, 0}, {0, 1, 0, 0} };
        static SkRect texs[] = { { 10, 10, 20, 20 }, {20, 20, 30, 30} };
        static SkColor colors[] = { SK_ColorBLUE, SK_ColorGREEN };
        b.drawAtlas(TestImage1, xforms, texs, colors, 2, SkBlendMode::kSrcIn,
                    DisplayList::NearestSampling, nullptr, false);}},
      {1, 56 + 32 + 32 + 8, 1, 56 + 32 + 32 + 8, [](DisplayListBuilder& b) {
        static SkRSXform xforms[] = { {1, 0, 0, 0}, {0, 1, 0, 0} };
        static SkRect texs[] = { { 10, 10, 20, 20 }, {20, 20, 30, 30} };
        static SkColor colors[] = { SK_ColorBLUE, SK_ColorGREEN };
        static SkRect cullRect = { 0, 0, 200, 200 };
        b.drawAtlas(TestImage1, xforms, texs, colors, 2, SkBlendMode::kSrcIn,
                    DisplayList::NearestSampling, &cullRect, false);}},
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
      ASSERT_EQ(dl->op_count(false), invocation.op_count()) << desc;
      EXPECT_EQ(dl->bytes(false), invocation.byte_count()) << desc;
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
      if (group.variants[i].is_empty()) {
        ASSERT_TRUE(dl->Equals(*empty)) << desc;
        ASSERT_TRUE(empty->Equals(*dl)) << desc;
      } else {
        ASSERT_FALSE(dl->Equals(*empty)) << desc;
        ASSERT_FALSE(empty->Equals(*dl)) << desc;
      }
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
      ASSERT_EQ(copy->op_count(false), dl->op_count(false)) << desc;
      ASSERT_EQ(copy->bytes(false), dl->bytes(false)) << desc;
      ASSERT_EQ(copy->op_count(true), dl->op_count(true)) << desc;
      ASSERT_EQ(copy->bytes(true), dl->bytes(true)) << desc;
      ASSERT_EQ(copy->bounds(), dl->bounds()) << desc;
      ASSERT_TRUE(copy->Equals(*dl)) << desc;
      ASSERT_TRUE(dl->Equals(*copy)) << desc;
    }
  }
}

TEST(DisplayList, SingleOpDisplayListsRecapturedViaSkCanvasAreEqual) {
  for (auto& group : allGroups) {
    for (size_t i = 0; i < group.variants.size(); i++) {
      if (group.variants[i].sk_testing_invalid()) {
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
      EXPECT_EQ(sk_copy->op_count(false), group.variants[i].sk_op_count())
          << desc;
      EXPECT_EQ(sk_copy->bytes(false), group.variants[i].sk_byte_count())
          << desc;
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
        if (i == j ||
            (group.variants[i].is_empty() && group.variants[j].is_empty())) {
          // They are the same variant, or both variants are NOPs
          ASSERT_EQ(listA->op_count(false), listB->op_count(false)) << desc;
          ASSERT_EQ(listA->bytes(false), listB->bytes(false)) << desc;
          ASSERT_EQ(listA->op_count(true), listB->op_count(true)) << desc;
          ASSERT_EQ(listA->bytes(true), listB->bytes(true)) << desc;
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

TEST(DisplayList, FullRotationsAreNop) {
  DisplayListBuilder builder;
  builder.rotate(0);
  builder.rotate(360);
  builder.rotate(720);
  builder.rotate(1080);
  builder.rotate(1440);
  sk_sp<DisplayList> dl = builder.Build();
  ASSERT_EQ(dl->bytes(false), sizeof(DisplayList));
  ASSERT_EQ(dl->bytes(true), sizeof(DisplayList));
  ASSERT_EQ(dl->op_count(false), 0);
  ASSERT_EQ(dl->op_count(true), 0);
}

TEST(DisplayList, AllBlendModeNops) {
  DisplayListBuilder builder;
  builder.setBlendMode(SkBlendMode::kSrcOver);
  builder.setBlender(nullptr);
  sk_sp<DisplayList> dl = builder.Build();
  ASSERT_EQ(dl->bytes(false), sizeof(DisplayList));
  ASSERT_EQ(dl->bytes(true), sizeof(DisplayList));
  ASSERT_EQ(dl->op_count(false), 0);
  ASSERT_EQ(dl->op_count(true), 0);
}

static sk_sp<DisplayList> Build(size_t g_index, size_t v_index) {
  DisplayListBuilder builder;
  int op_count = 0;
  size_t byte_count = 0;
  for (size_t i = 0; i < allGroups.size(); i++) {
    DisplayListInvocationGroup& group = allGroups[i];
    size_t j = (i == g_index ? v_index : 0);
    if (j >= group.variants.size()) {
      continue;
    }
    DisplayListInvocation& invocation = group.variants[j];
    op_count += invocation.op_count();
    byte_count += invocation.raw_byte_count();
    invocation.invoker(builder);
  }
  sk_sp<DisplayList> dl = builder.Build();
  std::string name;
  if (g_index >= allGroups.size()) {
    name = "Default";
  } else {
    name = allGroups[g_index].op_name;
    if (v_index >= allGroups[g_index].variants.size()) {
      name += " skipped";
    } else {
      name += " variant " + std::to_string(v_index + 1);
    }
  }
  EXPECT_EQ(dl->op_count(false), op_count) << name;
  EXPECT_EQ(dl->bytes(false), byte_count + sizeof(DisplayList)) << name;
  return dl;
}

TEST(DisplayList, DisplayListsWithVaryingOpComparisons) {
  sk_sp<DisplayList> default_dl = Build(allGroups.size(), 0);
  ASSERT_TRUE(default_dl->Equals(*default_dl)) << "Default == itself";
  for (size_t gi = 0; gi < allGroups.size(); gi++) {
    DisplayListInvocationGroup& group = allGroups[gi];
    sk_sp<DisplayList> missing_dl = Build(gi, group.variants.size());
    auto desc = "[Group " + group.op_name + " omitted]";
    ASSERT_TRUE(missing_dl->Equals(*missing_dl)) << desc << " == itself";
    ASSERT_FALSE(missing_dl->Equals(*default_dl)) << desc << " != Default";
    ASSERT_FALSE(default_dl->Equals(*missing_dl)) << "Default != " << desc;
    for (size_t vi = 0; vi < group.variants.size(); vi++) {
      auto desc = "[Group " + group.op_name + " variant " +
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
      if (group.variants[vi].is_empty()) {
        ASSERT_TRUE(variant_dl->Equals(*missing_dl)) << desc << " != omitted";
        ASSERT_TRUE(missing_dl->Equals(*variant_dl)) << "omitted != " << desc;
      } else {
        ASSERT_FALSE(variant_dl->Equals(*missing_dl)) << desc << " != omitted";
        ASSERT_FALSE(missing_dl->Equals(*variant_dl)) << "omitted != " << desc;
      }
    }
  }
}

TEST(DisplayList, DisplayListSaveLayerBoundsWithAlphaFilter) {
  SkRect build_bounds = SkRect::MakeLTRB(-100, -100, 200, 200);
  SkRect save_bounds = SkRect::MakeWH(100, 100);
  SkRect rect = SkRect::MakeLTRB(30, 30, 70, 70);
  // clang-format off
  const float color_matrix[] = {
    0, 0, 0, 0, 0,
    0, 1, 0, 0, 0,
    0, 0, 1, 0, 0,
    0, 0, 0, 1, 0,
  };
  // clang-format on
  sk_sp<SkColorFilter> base_color_filter = SkColorFilters::Matrix(color_matrix);
  // clang-format off
  const float alpha_matrix[] = {
    0, 0, 0, 0, 0,
    0, 1, 0, 0, 0,
    0, 0, 1, 0, 0,
    0, 0, 0, 0, 1,
  };
  // clang-format on
  sk_sp<SkColorFilter> alpha_color_filter =
      SkColorFilters::Matrix(alpha_matrix);

  {
    // No tricky stuff, just verifying drawing a rect produces rect bounds
    DisplayListBuilder builder(build_bounds);
    builder.saveLayer(&save_bounds, true);
    builder.drawRect(rect);
    builder.restore();
    sk_sp<DisplayList> display_list = builder.Build();
    ASSERT_EQ(display_list->bounds(), rect);
  }

  {
    // Now checking that a normal color filter still produces rect bounds
    DisplayListBuilder builder(build_bounds);
    builder.setColorFilter(base_color_filter);
    builder.saveLayer(&save_bounds, true);
    builder.setColorFilter(nullptr);
    builder.drawRect(rect);
    builder.restore();
    sk_sp<DisplayList> display_list = builder.Build();
    ASSERT_EQ(display_list->bounds(), rect);
  }

  {
    // Now checking how SkPictureRecorder deals with a color filter
    // that modifies alpha channels (save layer bounds are meaningless
    // under those circumstances)
    SkPictureRecorder recorder;
    SkCanvas* canvas = recorder.beginRecording(build_bounds);
    SkPaint p1;
    p1.setColorFilter(alpha_color_filter);
    canvas->saveLayer(save_bounds, &p1);
    SkPaint p2;
    canvas->drawRect(rect, p2);
    canvas->restore();
    sk_sp<SkPicture> picture = recorder.finishRecordingAsPicture();
    ASSERT_EQ(picture->cullRect(), build_bounds);
  }

  {
    // Now checking that DisplayList has the same behavior that we
    // saw in the SkPictureRecorder example above - returning the
    // cull rect of the DisplayListBuilder when it encounters a
    // save layer that modifies an unbounded region
    DisplayListBuilder builder(build_bounds);
    builder.setColorFilter(alpha_color_filter);
    builder.saveLayer(&save_bounds, true);
    builder.setColorFilter(nullptr);
    builder.drawRect(rect);
    builder.restore();
    sk_sp<DisplayList> display_list = builder.Build();
    ASSERT_EQ(display_list->bounds(), build_bounds);
  }

  {
    // Verifying that the save layer bounds are not relevant
    // to the behavior in the previous example
    DisplayListBuilder builder(build_bounds);
    builder.setColorFilter(alpha_color_filter);
    builder.saveLayer(nullptr, true);
    builder.setColorFilter(nullptr);
    builder.drawRect(rect);
    builder.restore();
    sk_sp<DisplayList> display_list = builder.Build();
    ASSERT_EQ(display_list->bounds(), build_bounds);
  }

  {
    // Making sure hiding a ColorFilter as an ImageFilter will
    // generate the same behavior as setting it as a ColorFilter
    DisplayListBuilder builder(build_bounds);
    builder.setImageFilter(
        SkImageFilters::ColorFilter(base_color_filter, nullptr));
    builder.saveLayer(&save_bounds, true);
    builder.setImageFilter(nullptr);
    builder.drawRect(rect);
    builder.restore();
    sk_sp<DisplayList> display_list = builder.Build();
    ASSERT_EQ(display_list->bounds(), rect);
  }

  {
    // Making sure hiding a problematic ColorFilter as an ImageFilter
    // will generate the same behavior as setting it as a ColorFilter
    DisplayListBuilder builder(build_bounds);
    builder.setImageFilter(
        SkImageFilters::ColorFilter(alpha_color_filter, nullptr));
    builder.saveLayer(&save_bounds, true);
    builder.setImageFilter(nullptr);
    builder.drawRect(rect);
    builder.restore();
    sk_sp<DisplayList> display_list = builder.Build();
    ASSERT_EQ(display_list->bounds(), build_bounds);
  }

  {
    // Same as above (ImageFilter hiding ColorFilter) with no save bounds
    DisplayListBuilder builder(build_bounds);
    builder.setImageFilter(
        SkImageFilters::ColorFilter(alpha_color_filter, nullptr));
    builder.saveLayer(nullptr, true);
    builder.setImageFilter(nullptr);
    builder.drawRect(rect);
    builder.restore();
    sk_sp<DisplayList> display_list = builder.Build();
    ASSERT_EQ(display_list->bounds(), build_bounds);
  }

  {
    // Testing behavior with an unboundable blend mode
    DisplayListBuilder builder(build_bounds);
    builder.setBlendMode(SkBlendMode::kClear);
    builder.saveLayer(&save_bounds, true);
    builder.setBlendMode(SkBlendMode::kSrcOver);
    builder.drawRect(rect);
    builder.restore();
    sk_sp<DisplayList> display_list = builder.Build();
    ASSERT_EQ(display_list->bounds(), build_bounds);
  }

  {
    // Same as previous with no save bounds
    DisplayListBuilder builder(build_bounds);
    builder.setBlendMode(SkBlendMode::kClear);
    builder.saveLayer(nullptr, true);
    builder.setBlendMode(SkBlendMode::kSrcOver);
    builder.drawRect(rect);
    builder.restore();
    sk_sp<DisplayList> display_list = builder.Build();
    ASSERT_EQ(display_list->bounds(), build_bounds);
  }
}

TEST(DisplayList, NestedOpCountMetricsSameAsSkPicture) {
  SkPictureRecorder recorder;
  recorder.beginRecording(SkRect::MakeWH(150, 100));
  SkCanvas* canvas = recorder.getRecordingCanvas();
  SkPaint paint;
  for (int y = 10; y <= 60; y += 10) {
    for (int x = 10; x <= 60; x += 10) {
      paint.setColor(((x + y) % 20) == 10 ? SK_ColorRED : SK_ColorBLUE);
      canvas->drawRect(SkRect::MakeXYWH(x, y, 80, 80), paint);
    }
  }
  SkPictureRecorder outer_recorder;
  outer_recorder.beginRecording(SkRect::MakeWH(150, 100));
  canvas = outer_recorder.getRecordingCanvas();
  canvas->drawPicture(recorder.finishRecordingAsPicture());

  auto picture = outer_recorder.finishRecordingAsPicture();
  ASSERT_EQ(picture->approximateOpCount(), 1);
  ASSERT_EQ(picture->approximateOpCount(true), 36);

  DisplayListBuilder builder(SkRect::MakeWH(150, 100));
  for (int y = 10; y <= 60; y += 10) {
    for (int x = 10; x <= 60; x += 10) {
      builder.setColor(((x + y) % 20) == 10 ? SK_ColorRED : SK_ColorBLUE);
      builder.drawRect(SkRect::MakeXYWH(x, y, 80, 80));
    }
  }
  DisplayListBuilder outer_builder(SkRect::MakeWH(150, 100));
  outer_builder.drawDisplayList(builder.Build());

  auto display_list = outer_builder.Build();
  ASSERT_EQ(display_list->op_count(), 1);
  ASSERT_EQ(display_list->op_count(true), 36);

  ASSERT_EQ(picture->approximateOpCount(), display_list->op_count());
  ASSERT_EQ(picture->approximateOpCount(true), display_list->op_count(true));

  DisplayListCanvasRecorder dl_recorder(SkRect::MakeWH(150, 100));
  picture->playback(&dl_recorder);

  auto sk_display_list = dl_recorder.Build();
  ASSERT_EQ(display_list->op_count(), 1);
  ASSERT_EQ(display_list->op_count(true), 36);
}

class AttributeRefTester {
 public:
  virtual void setRefToPaint(SkPaint& paint) const = 0;
  virtual void setRefToDisplayList(DisplayListBuilder& builder) const = 0;
  virtual bool ref_is_unique() const = 0;

  void testDisplayList() {
    {
      DisplayListBuilder builder;
      setRefToDisplayList(builder);
      builder.drawRect(SkRect::MakeLTRB(50, 50, 100, 100));
      ASSERT_FALSE(ref_is_unique());
    }
    ASSERT_TRUE(ref_is_unique());
  }
  void testPaint() {
    {
      SkPaint paint;
      setRefToPaint(paint);
      ASSERT_FALSE(ref_is_unique());
    }
    ASSERT_TRUE(ref_is_unique());
  }
  void testCanvasRecorder() {
    {
      sk_sp<DisplayList> display_list;
      {
        DisplayListCanvasRecorder recorder(SkRect::MakeLTRB(0, 0, 200, 200));
        {
          {
            SkPaint paint;
            setRefToPaint(paint);
            recorder.drawRect(SkRect::MakeLTRB(50, 50, 100, 100), paint);
            ASSERT_FALSE(ref_is_unique());
          }
          ASSERT_FALSE(ref_is_unique());
        }
        display_list = recorder.Build();
        ASSERT_FALSE(ref_is_unique());
      }
      ASSERT_FALSE(ref_is_unique());
    }
    ASSERT_TRUE(ref_is_unique());
  }

  void test() {
    testDisplayList();
    testPaint();
    testCanvasRecorder();
  }
};

TEST(DisplayList, DisplayListImageFilterRefHandling) {
  class ImageFilterRefTester : public virtual AttributeRefTester {
   public:
    void setRefToPaint(SkPaint& paint) const override {
      paint.setImageFilter(image_filter);
    }
    void setRefToDisplayList(DisplayListBuilder& builder) const override {
      builder.setImageFilter(image_filter);
    }
    bool ref_is_unique() const override { return image_filter->unique(); }

   private:
    sk_sp<SkImageFilter> image_filter = SkImageFilters::Blur(2.0, 2.0, nullptr);
  };

  ImageFilterRefTester tester;
  tester.test();
  ASSERT_TRUE(tester.ref_is_unique());
}

TEST(DisplayList, DisplayListColorFilterRefHandling) {
  class ColorFilterRefTester : public virtual AttributeRefTester {
   public:
    void setRefToPaint(SkPaint& paint) const override {
      paint.setColorFilter(color_filter);
    }
    void setRefToDisplayList(DisplayListBuilder& builder) const override {
      builder.setColorFilter(color_filter);
    }
    bool ref_is_unique() const override { return color_filter->unique(); }

   private:
    sk_sp<SkColorFilter> color_filter =
        SkColorFilters::Blend(SK_ColorBLUE, SkBlendMode::kSrcIn);
  };

  ColorFilterRefTester tester;
  tester.test();
  ASSERT_TRUE(tester.ref_is_unique());
}

TEST(DisplayList, DisplayListMaskFilterRefHandling) {
  class MaskFilterRefTester : public virtual AttributeRefTester {
   public:
    void setRefToPaint(SkPaint& paint) const override {
      paint.setMaskFilter(mask_filter);
    }
    void setRefToDisplayList(DisplayListBuilder& builder) const override {
      builder.setMaskFilter(mask_filter);
    }
    bool ref_is_unique() const override { return mask_filter->unique(); }

   private:
    sk_sp<SkMaskFilter> mask_filter =
        SkMaskFilter::MakeBlur(SkBlurStyle::kNormal_SkBlurStyle, 2.0);
  };

  MaskFilterRefTester tester;
  tester.test();
  ASSERT_TRUE(tester.ref_is_unique());
}

TEST(DisplayList, DisplayListBlenderRefHandling) {
  class BlenderRefTester : public virtual AttributeRefTester {
   public:
    void setRefToPaint(SkPaint& paint) const override {
      paint.setBlender(blender);
    }
    void setRefToDisplayList(DisplayListBuilder& builder) const override {
      builder.setBlender(blender);
    }
    bool ref_is_unique() const override { return blender->unique(); }

   private:
    sk_sp<SkBlender> blender =
        SkBlenders::Arithmetic(0.25, 0.25, 0.25, 0.25, true);
  };

  BlenderRefTester tester;
  tester.test();
  ASSERT_TRUE(tester.ref_is_unique());
}

TEST(DisplayList, DisplayListShaderRefHandling) {
  class ShaderRefTester : public virtual AttributeRefTester {
   public:
    void setRefToPaint(SkPaint& paint) const override {
      paint.setShader(shader);
    }
    void setRefToDisplayList(DisplayListBuilder& builder) const override {
      builder.setShader(shader);
    }
    bool ref_is_unique() const override { return shader->unique(); }

   private:
    sk_sp<SkShader> shader = SkShaders::Color(SK_ColorBLUE);
  };

  ShaderRefTester tester;
  tester.test();
  ASSERT_TRUE(tester.ref_is_unique());
}

TEST(DisplayList, DisplayListPathEffectRefHandling) {
  class PathEffectRefTester : public virtual AttributeRefTester {
   public:
    void setRefToPaint(SkPaint& paint) const override {
      paint.setPathEffect(path_effect);
    }
    void setRefToDisplayList(DisplayListBuilder& builder) const override {
      builder.setPathEffect(path_effect);
    }
    bool ref_is_unique() const override { return path_effect->unique(); }

   private:
    sk_sp<SkPathEffect> path_effect =
        SkDashPathEffect::Make(TestDashes1, 2, 0.0);
  };

  PathEffectRefTester tester;
  tester.test();
  ASSERT_TRUE(tester.ref_is_unique());
}

TEST(DisplayList, DisplayListFullPerspectiveTransformHandling) {
  // SkM44 constructor takes row-major order
  SkM44 sk_matrix = SkM44(
      // clang-format off
       1,  2,  3,  4,
       5,  6,  7,  8,
       9, 10, 11, 12,
      13, 14, 15, 16
      // clang-format on
  );

  {  // First test ==
    DisplayListBuilder builder;
    // builder.transformFullPerspective takes row-major order
    builder.transformFullPerspective(
        // clang-format off
         1,  2,  3,  4,
         5,  6,  7,  8,
         9, 10, 11, 12,
        13, 14, 15, 16
        // clang-format on
    );
    sk_sp<DisplayList> display_list = builder.Build();
    sk_sp<SkSurface> surface = SkSurface::MakeRasterN32Premul(10, 10);
    SkCanvas* canvas = surface->getCanvas();
    display_list->RenderTo(canvas);
    SkM44 dl_matrix = canvas->getLocalToDevice();
    ASSERT_EQ(sk_matrix, dl_matrix);
  }
  {  // Next test !=
    DisplayListBuilder builder;
    // builder.transformFullPerspective takes row-major order
    builder.transformFullPerspective(
        // clang-format off
         1,  5,  9, 13,
         2,  6,  7, 11,
         3,  7, 11, 15,
         4,  8, 12, 16
        // clang-format on
    );
    sk_sp<DisplayList> display_list = builder.Build();
    sk_sp<SkSurface> surface = SkSurface::MakeRasterN32Premul(10, 10);
    SkCanvas* canvas = surface->getCanvas();
    display_list->RenderTo(canvas);
    SkM44 dl_matrix = canvas->getLocalToDevice();
    ASSERT_NE(sk_matrix, dl_matrix);
  }
}

TEST(DisplayList, SetMaskBlurSigmaZeroResetsMaskFilter) {
  DisplayListBuilder builder;
  builder.setMaskBlurFilter(SkBlurStyle::kNormal_SkBlurStyle, 2.0);
  builder.drawRect({10, 10, 20, 20});
  builder.setMaskBlurFilter(SkBlurStyle::kNormal_SkBlurStyle, 0.0);
  EXPECT_EQ(builder.getMaskFilter(), nullptr);
  builder.drawRect({30, 30, 40, 40});
  sk_sp<DisplayList> display_list = builder.Build();
  ASSERT_EQ(display_list->op_count(), 2);
  ASSERT_EQ(display_list->bytes(), sizeof(DisplayList) + 8u + 24u + 8u + 24u);
}

TEST(DisplayList, SetMaskFilterNullResetsMaskFilter) {
  DisplayListBuilder builder;
  builder.setMaskBlurFilter(SkBlurStyle::kNormal_SkBlurStyle, 2.0);
  builder.drawRect({10, 10, 20, 20});
  builder.setMaskFilter(nullptr);
  EXPECT_EQ(builder.getMaskFilter(), nullptr);
  builder.drawRect({30, 30, 40, 40});
  sk_sp<DisplayList> display_list = builder.Build();
  ASSERT_EQ(display_list->op_count(), 2);
  ASSERT_EQ(display_list->bytes(), sizeof(DisplayList) + 8u + 24u + 8u + 24u);
}

TEST(DisplayList, SingleOpsMightSupportGroupOpacityWithOrWithoutBlendMode) {
  auto run_tests = [](std::string name,
                      void build(DisplayListBuilder & builder),
                      bool expect_for_op, bool expect_with_kSrc) {
    {
      // First test is the draw op, by itself
      // (usually supports group opacity)
      DisplayListBuilder builder;
      build(builder);
      auto display_list = builder.Build();
      EXPECT_EQ(display_list->can_apply_group_opacity(), expect_for_op)
          << "{" << std::endl
          << "  " << name << std::endl
          << "}";
    }
    {
      // Second test i the draw op with kSrc,
      // (usually fails group opacity)
      DisplayListBuilder builder;
      builder.setBlendMode(SkBlendMode::kSrc);
      build(builder);
      auto display_list = builder.Build();
      EXPECT_EQ(display_list->can_apply_group_opacity(), expect_with_kSrc)
          << "{" << std::endl
          << "  builder.setBlendMode(kSrc);" << std::endl
          << "  " << name << std::endl
          << "}";
    }
  };

#define RUN_TESTS(body) \
  run_tests(            \
      #body, [](DisplayListBuilder& builder) { body }, true, false)
#define RUN_TESTS2(body, expect) \
  run_tests(                     \
      #body, [](DisplayListBuilder& builder) { body }, expect, expect)

  RUN_TESTS(builder.drawPaint(););
  RUN_TESTS2(builder.drawColor(SK_ColorRED, SkBlendMode::kSrcOver);, true);
  RUN_TESTS2(builder.drawColor(SK_ColorRED, SkBlendMode::kSrc);, false);
  RUN_TESTS(builder.drawLine({0, 0}, {10, 10}););
  RUN_TESTS(builder.drawRect({0, 0, 10, 10}););
  RUN_TESTS(builder.drawOval({0, 0, 10, 10}););
  RUN_TESTS(builder.drawCircle({10, 10}, 5););
  RUN_TESTS(builder.drawRRect(SkRRect::MakeRectXY({0, 0, 10, 10}, 2, 2)););
  RUN_TESTS(builder.drawDRRect(SkRRect::MakeRectXY({0, 0, 10, 10}, 2, 2),
                               SkRRect::MakeRectXY({2, 2, 8, 8}, 2, 2)););
  RUN_TESTS(builder.drawPath(
      SkPath().addOval({0, 0, 10, 10}).addOval({5, 5, 15, 15})););
  RUN_TESTS(builder.drawArc({0, 0, 10, 10}, 0, math::kPi, true););
  RUN_TESTS2(builder.drawPoints(SkCanvas::kPoints_PointMode, TestPointCount,
                                TestPoints);
             , false);
  RUN_TESTS2(builder.drawVertices(TestVertices1, SkBlendMode::kSrc);, false);
  RUN_TESTS(builder.drawImage(TestImage1, {0, 0}, DisplayList::LinearSampling,
                              true););
  RUN_TESTS2(
      builder.drawImage(TestImage1, {0, 0}, DisplayList::LinearSampling, false);
      , true);
  RUN_TESTS(builder.drawImageRect(TestImage1, {10, 10, 20, 20}, {0, 0, 10, 10},
                                  DisplayList::NearestSampling, true););
  RUN_TESTS2(builder.drawImageRect(TestImage1, {10, 10, 20, 20}, {0, 0, 10, 10},
                                   DisplayList::NearestSampling, false);
             , true);
  RUN_TESTS(builder.drawImageNine(TestImage2, {20, 20, 30, 30}, {0, 0, 20, 20},
                                  SkFilterMode::kLinear, true););
  RUN_TESTS2(builder.drawImageNine(TestImage2, {20, 20, 30, 30}, {0, 0, 20, 20},
                                   SkFilterMode::kLinear, false);
             , true);
  RUN_TESTS(builder.drawImageLattice(
      TestImage1,
      {TestDivs1, TestDivs1, nullptr, 3, 3, &TestLatticeSrcRect, nullptr},
      {10, 10, 40, 40}, SkFilterMode::kNearest, true););
  RUN_TESTS2(builder.drawImageLattice(
      TestImage1,
      {TestDivs1, TestDivs1, nullptr, 3, 3, &TestLatticeSrcRect, nullptr},
      {10, 10, 40, 40}, SkFilterMode::kNearest, false);
             , true);
  static SkRSXform xforms[] = {{1, 0, 0, 0}, {0, 1, 0, 0}};
  static SkRect texs[] = {{10, 10, 20, 20}, {20, 20, 30, 30}};
  RUN_TESTS2(builder.drawAtlas(TestImage1, xforms, texs, nullptr, 2,
                               SkBlendMode::kSrcIn,
                               DisplayList::NearestSampling, nullptr, true);
             , false);
  RUN_TESTS2(builder.drawAtlas(TestImage1, xforms, texs, nullptr, 2,
                               SkBlendMode::kSrcIn,
                               DisplayList::NearestSampling, nullptr, false);
             , false);
  RUN_TESTS(builder.drawPicture(TestPicture1, nullptr, true););
  RUN_TESTS2(builder.drawPicture(TestPicture1, nullptr, false);, true);
  EXPECT_TRUE(TestDisplayList1->can_apply_group_opacity());
  RUN_TESTS2(builder.drawDisplayList(TestDisplayList1);, true);
  {
    static DisplayListBuilder builder;
    builder.drawRect({0, 0, 10, 10});
    builder.drawRect({5, 5, 15, 15});
    static auto display_list = builder.Build();
    RUN_TESTS2(builder.drawDisplayList(display_list);, false);
  }
  RUN_TESTS(builder.drawTextBlob(TestBlob1, 0, 0););
  RUN_TESTS2(builder.drawShadow(TestPath1, SK_ColorBLACK, 1.0, false, 1.0);
             , false);

#undef RUN_TESTS2
#undef RUN_TESTS
}

TEST(DisplayList, OverlappingOpsDoNotSupportGroupOpacity) {
  DisplayListBuilder builder;
  for (int i = 0; i < 10; i++) {
    builder.drawRect(SkRect::MakeXYWH(i * 10, 0, 30, 30));
  }
  auto display_list = builder.Build();
  EXPECT_FALSE(display_list->can_apply_group_opacity());
}

TEST(DisplayList, SaveLayerFalseSupportsGroupOpacityWithOverlappingChidren) {
  DisplayListBuilder builder;
  builder.saveLayer(nullptr, false);
  for (int i = 0; i < 10; i++) {
    builder.drawRect(SkRect::MakeXYWH(i * 10, 0, 30, 30));
  }
  builder.restore();
  auto display_list = builder.Build();
  EXPECT_TRUE(display_list->can_apply_group_opacity());
}

TEST(DisplayList, SaveLayerTrueSupportsGroupOpacityWithOverlappingChidren) {
  DisplayListBuilder builder;
  builder.saveLayer(nullptr, true);
  for (int i = 0; i < 10; i++) {
    builder.drawRect(SkRect::MakeXYWH(i * 10, 0, 30, 30));
  }
  builder.restore();
  auto display_list = builder.Build();
  EXPECT_TRUE(display_list->can_apply_group_opacity());
}

TEST(DisplayList, SaveLayerFalseWithSrcBlendSupportsGroupOpacity) {
  DisplayListBuilder builder;
  builder.setBlendMode(SkBlendMode::kSrc);
  builder.saveLayer(nullptr, false);
  builder.drawRect({0, 0, 10, 10});
  builder.restore();
  auto display_list = builder.Build();
  EXPECT_TRUE(display_list->can_apply_group_opacity());
}

TEST(DisplayList, SaveLayerTrueWithSrcBlendDoesNotSupportGroupOpacity) {
  DisplayListBuilder builder;
  builder.setBlendMode(SkBlendMode::kSrc);
  builder.saveLayer(nullptr, true);
  builder.drawRect({0, 0, 10, 10});
  builder.restore();
  auto display_list = builder.Build();
  EXPECT_FALSE(display_list->can_apply_group_opacity());
}

TEST(DisplayList, SaveLayerFalseSupportsGroupOpacityWithChildSrcBlend) {
  DisplayListBuilder builder;
  builder.saveLayer(nullptr, false);
  builder.setBlendMode(SkBlendMode::kSrc);
  builder.drawRect({0, 0, 10, 10});
  builder.restore();
  auto display_list = builder.Build();
  EXPECT_TRUE(display_list->can_apply_group_opacity());
}

TEST(DisplayList, SaveLayerTrueSupportsGroupOpacityWithChildSrcBlend) {
  DisplayListBuilder builder;
  builder.saveLayer(nullptr, true);
  builder.setBlendMode(SkBlendMode::kSrc);
  builder.drawRect({0, 0, 10, 10});
  builder.restore();
  auto display_list = builder.Build();
  EXPECT_TRUE(display_list->can_apply_group_opacity());
}

TEST(DisplayList, SaveLayerBoundsSnapshotsImageFilter) {
  DisplayListBuilder builder;
  builder.saveLayer(nullptr, true);
  builder.drawRect({50, 50, 100, 100});
  // This image filter should be ignored since it was not set before saveLayer
  builder.setImageFilter(TestImageFilter1);
  builder.restore();
  SkRect bounds = builder.Build()->bounds();
  EXPECT_EQ(bounds, SkRect::MakeLTRB(50, 50, 100, 100));
}

}  // namespace testing
}  // namespace flutter
