// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <memory>
#include "flutter/display_list/display_list.h"
#include "flutter/display_list/display_list_blend_mode.h"
#include "flutter/display_list/display_list_builder.h"
#include "flutter/display_list/display_list_canvas_recorder.h"
#include "flutter/display_list/display_list_utils.h"
#include "flutter/fml/math.h"
#include "flutter/testing/display_list_testing.h"
#include "flutter/testing/testing.h"
#include "third_party/skia/include/core/SkPictureRecorder.h"
#include "third_party/skia/include/core/SkSurface.h"
#include "third_party/skia/include/effects/SkBlenders.h"
#include "third_party/skia/include/effects/SkDashPathEffect.h"
#include "third_party/skia/include/effects/SkGradientShader.h"
#include "third_party/skia/include/effects/SkImageFilters.h"

namespace flutter {
namespace testing {

constexpr SkPoint kEndPoints[] = {
    {0, 0},
    {100, 100},
};
const DlColor kColors[] = {
    DlColor::kGreen(),
    DlColor::kYellow(),
    DlColor::kBlue(),
};
constexpr float kStops[] = {
    0.0,
    0.5,
    1.0,
};
std::vector<uint32_t> color_vector(kColors, kColors + 3);
std::vector<float> stops_vector(kStops, kStops + 3);

// clang-format off
constexpr float kRotateColorMatrix[20] = {
    0, 1, 0, 0, 0,
    0, 0, 1, 0, 0,
    1, 0, 0, 0, 0,
    0, 0, 0, 1, 0,
};
constexpr float kInvertColorMatrix[20] = {
    -1.0,    0,    0, 1.0,   0,
       0, -1.0,    0, 1.0,   0,
       0,    0, -1.0, 1.0,   0,
     1.0,  1.0,  1.0, 1.0,   0,
};
// clang-format on

const SkScalar kTestDashes1[] = {4.0, 2.0};
const SkScalar kTestDashes2[] = {1.0, 1.5};

constexpr SkPoint TestPoints[] = {
    {10, 10},
    {20, 20},
    {10, 20},
    {20, 10},
};
#define TestPointCount sizeof(TestPoints) / (sizeof(TestPoints[0]))

static DlImageSampling kNearestSampling = DlImageSampling::kNearestNeighbor;
static DlImageSampling kLinearSampling = DlImageSampling::kLinear;

static sk_sp<DlImage> MakeTestImage(int w, int h, int checker_size) {
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
  return DlImage::Make(surface->makeImageSnapshot());
}

static auto TestImage1 = MakeTestImage(40, 40, 5);
static auto TestImage2 = MakeTestImage(50, 50, 5);

static const sk_sp<SkBlender> kTestBlender1 =
    SkBlenders::Arithmetic(0.2, 0.2, 0.2, 0.2, false);
static const sk_sp<SkBlender> kTestBlender2 =
    SkBlenders::Arithmetic(0.2, 0.2, 0.2, 0.2, true);
static const sk_sp<SkBlender> kTestBlender3 =
    SkBlenders::Arithmetic(0.3, 0.3, 0.3, 0.3, true);
static const DlImageColorSource kTestSource1(TestImage1->skia_image(),
                                             DlTileMode::kClamp,
                                             DlTileMode::kMirror,
                                             kLinearSampling);
static const std::shared_ptr<DlColorSource> kTestSource2 =
    DlColorSource::MakeLinear(kEndPoints[0],
                              kEndPoints[1],
                              3,
                              kColors,
                              kStops,
                              DlTileMode::kMirror);
static const std::shared_ptr<DlColorSource> kTestSource3 =
    DlColorSource::MakeRadial(kEndPoints[0],
                              10.0,
                              3,
                              kColors,
                              kStops,
                              DlTileMode::kMirror);
static const std::shared_ptr<DlColorSource> kTestSource4 =
    DlColorSource::MakeConical(kEndPoints[0],
                               10.0,
                               kEndPoints[1],
                               200.0,
                               3,
                               kColors,
                               kStops,
                               DlTileMode::kDecal);
static const std::shared_ptr<DlColorSource> kTestSource5 =
    DlColorSource::MakeSweep(kEndPoints[0],
                             0.0,
                             360.0,
                             3,
                             kColors,
                             kStops,
                             DlTileMode::kDecal);
static const DlBlendColorFilter kTestBlendColorFilter1(DlColor::kRed(),
                                                       DlBlendMode::kDstATop);
static const DlBlendColorFilter kTestBlendColorFilter2(DlColor::kBlue(),
                                                       DlBlendMode::kDstATop);
static const DlBlendColorFilter kTestBlendColorFilter3(DlColor::kRed(),
                                                       DlBlendMode::kDstIn);
static const DlMatrixColorFilter kTestMatrixColorFilter1(kRotateColorMatrix);
static const DlMatrixColorFilter kTestMatrixColorFilter2(kInvertColorMatrix);
static const DlBlurImageFilter kTestBlurImageFilter1(5.0,
                                                     5.0,
                                                     DlTileMode::kClamp);
static const DlBlurImageFilter kTestBlurImageFilter2(6.0,
                                                     5.0,
                                                     DlTileMode::kClamp);
static const DlBlurImageFilter kTestBlurImageFilter3(5.0,
                                                     6.0,
                                                     DlTileMode::kClamp);
static const DlBlurImageFilter kTestBlurImageFilter4(5.0,
                                                     5.0,
                                                     DlTileMode::kDecal);
static const DlDilateImageFilter kTestDilateImageFilter1(5.0, 5.0);
static const DlDilateImageFilter kTestDilateImageFilter2(6.0, 5.0);
static const DlDilateImageFilter kTestDilateImageFilter3(5.0, 6.0);
static const DlErodeImageFilter kTestErodeImageFilter1(5.0, 5.0);
static const DlErodeImageFilter kTestErodeImageFilter2(6.0, 5.0);
static const DlErodeImageFilter kTestErodeImageFilter3(5.0, 6.0);
static const DlMatrixImageFilter kTestMatrixImageFilter1(
    SkMatrix::RotateDeg(45),
    kNearestSampling);
static const DlMatrixImageFilter kTestMatrixImageFilter2(
    SkMatrix::RotateDeg(85),
    kNearestSampling);
static const DlMatrixImageFilter kTestMatrixImageFilter3(
    SkMatrix::RotateDeg(45),
    kLinearSampling);
static const DlComposeImageFilter kTestComposeImageFilter1(
    kTestBlurImageFilter1,
    kTestMatrixImageFilter1);
static const DlComposeImageFilter kTestComposeImageFilter2(
    kTestBlurImageFilter2,
    kTestMatrixImageFilter1);
static const DlComposeImageFilter kTestComposeImageFilter3(
    kTestBlurImageFilter1,
    kTestMatrixImageFilter2);
static const DlColorFilterImageFilter kTestCFImageFilter1(
    kTestBlendColorFilter1);
static const DlColorFilterImageFilter kTestCFImageFilter2(
    kTestBlendColorFilter2);
static const std::shared_ptr<DlPathEffect> kTestPathEffect1 =
    DlDashPathEffect::Make(kTestDashes1, 2, 0.0f);
static const std::shared_ptr<DlPathEffect> kTestPathEffect2 =
    DlDashPathEffect::Make(kTestDashes2, 2, 0.0f);
static const DlBlurMaskFilter kTestMaskFilter1(kNormal_SkBlurStyle, 3.0);
static const DlBlurMaskFilter kTestMaskFilter2(kNormal_SkBlurStyle, 5.0);
static const DlBlurMaskFilter kTestMaskFilter3(kSolid_SkBlurStyle, 3.0);
static const DlBlurMaskFilter kTestMaskFilter4(kInner_SkBlurStyle, 3.0);
static const DlBlurMaskFilter kTestMaskFilter5(kOuter_SkBlurStyle, 3.0);
constexpr SkRect kTestBounds = SkRect::MakeLTRB(10, 10, 50, 60);
static const SkRRect kTestRRect = SkRRect::MakeRectXY(kTestBounds, 5, 5);
static const SkRRect kTestRRectRect = SkRRect::MakeRect(kTestBounds);
static const SkRRect kTestInnerRRect =
    SkRRect::MakeRectXY(kTestBounds.makeInset(5, 5), 2, 2);
static const SkPath kTestPathRect = SkPath::Rect(kTestBounds);
static const SkPath kTestPathOval = SkPath::Oval(kTestBounds);
static const SkPath kTestPath1 =
    SkPath::Polygon({{0, 0}, {10, 10}, {10, 0}, {0, 10}}, true);
static const SkPath kTestPath2 =
    SkPath::Polygon({{0, 0}, {10, 10}, {0, 10}, {10, 0}}, true);
static const SkPath kTestPath3 =
    SkPath::Polygon({{0, 0}, {10, 10}, {10, 0}, {0, 10}}, false);
static const SkMatrix kTestMatrix1 = SkMatrix::Scale(2, 2);
static const SkMatrix kTestMatrix2 = SkMatrix::RotateDeg(45);

static std::shared_ptr<const DlVertices> TestVertices1 =
    DlVertices::Make(DlVertexMode::kTriangles,  //
                     3,
                     TestPoints,
                     nullptr,
                     kColors);
static std::shared_ptr<const DlVertices> TestVertices2 =
    DlVertices::Make(DlVertexMode::kTriangleFan,  //
                     3,
                     TestPoints,
                     nullptr,
                     kColors);

static constexpr int kTestDivs1[] = {10, 20, 30};
static constexpr int kTestDivs2[] = {15, 20, 25};
static constexpr int kTestDivs3[] = {15, 25};
static constexpr SkCanvas::Lattice::RectType kTestRTypes[] = {
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
static constexpr SkColor kTestLatticeColors[] = {
    SK_ColorBLUE, SK_ColorGREEN, SK_ColorYELLOW,
    SK_ColorBLUE, SK_ColorGREEN, SK_ColorYELLOW,
    SK_ColorBLUE, SK_ColorGREEN, SK_ColorYELLOW,
};
static constexpr SkIRect kTestLatticeSrcRect = {1, 1, 39, 39};

static sk_sp<SkPicture> MakeTestPicture(int w, int h, SkColor color) {
  SkPictureRecorder recorder;
  SkRTreeFactory rtree_factory;
  SkCanvas* cv = recorder.beginRecording(kTestBounds, &rtree_factory);
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
  unsigned int op_count_;
  size_t byte_count_;

  // in some cases, running the sequence through an SkCanvas will result
  // in fewer ops/bytes. Attribute invocations are recorded in an SkPaint
  // and not forwarded on, and SkCanvas culls unused save/restore/transforms.
  int sk_op_count_;
  size_t sk_byte_count_;

  DlInvoker invoker;
  bool supports_group_opacity_ = false;

  bool sk_version_matches() {
    return (static_cast<int>(op_count_) == sk_op_count_ &&
            byte_count_ == sk_byte_count_);
  }

  // A negative sk_op_count means "do not test this op".
  // Used mainly for these cases:
  // - we cannot encode a DrawShadowRec (Skia private header)
  // - SkCanvas cannot receive a DisplayList
  // - SkCanvas may or may not inline an SkPicture
  bool sk_testing_invalid() { return sk_op_count_ < 0; }

  bool is_empty() { return byte_count_ == 0; }

  bool supports_group_opacity() { return supports_group_opacity_; }

  unsigned int op_count() { return op_count_; }
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
      {0, 8, 0, 0, [](DisplayListBuilder& b) {b.setStrokeCap(DlStrokeCap::kRound);}},
      {0, 8, 0, 0, [](DisplayListBuilder& b) {b.setStrokeCap(DlStrokeCap::kSquare);}},
      {0, 0, 0, 0, [](DisplayListBuilder& b) {b.setStrokeCap(DlStrokeCap::kButt);}},
    }
  },
  { "SetStrokeJoin", {
      {0, 8, 0, 0, [](DisplayListBuilder& b) {b.setStrokeJoin(DlStrokeJoin::kBevel);}},
      {0, 8, 0, 0, [](DisplayListBuilder& b) {b.setStrokeJoin(DlStrokeJoin::kRound);}},
      {0, 0, 0, 0, [](DisplayListBuilder& b) {b.setStrokeJoin(DlStrokeJoin::kMiter);}},
    }
  },
  { "SetStyle", {
      {0, 8, 0, 0, [](DisplayListBuilder& b) {b.setStyle(DlDrawStyle::kStroke);}},
      {0, 8, 0, 0, [](DisplayListBuilder& b) {b.setStyle(DlDrawStyle::kStrokeAndFill);}},
      {0, 0, 0, 0, [](DisplayListBuilder& b) {b.setStyle(DlDrawStyle::kFill);}},
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
      {0, 8, 0, 0, [](DisplayListBuilder& b) {b.setBlendMode(DlBlendMode::kSrcIn);}},
      {0, 8, 0, 0, [](DisplayListBuilder& b) {b.setBlendMode(DlBlendMode::kDstIn);}},
      {0, 16, 0, 0, [](DisplayListBuilder& b) {b.setBlender(kTestBlender1);}},
      {0, 16, 0, 0, [](DisplayListBuilder& b) {b.setBlender(kTestBlender2);}},
      {0, 16, 0, 0, [](DisplayListBuilder& b) {b.setBlender(kTestBlender3);}},
      {0, 0, 0, 0, [](DisplayListBuilder& b) {b.setBlendMode(DlBlendMode::kSrcOver);}},
      {0, 0, 0, 0, [](DisplayListBuilder& b) {b.setBlender(nullptr);}},
    }
  },
  { "SetColorSource", {
      {0, 96, 0, 0, [](DisplayListBuilder& b) {b.setColorSource(&kTestSource1);}},
      // stop_count * (sizeof(float) + sizeof(uint32_t)) = 80
      {0, 80 + 6 * 4, 0, 0, [](DisplayListBuilder& b) {b.setColorSource(kTestSource2.get());}},
      {0, 80 + 6 * 4, 0, 0, [](DisplayListBuilder& b) {b.setColorSource(kTestSource3.get());}},
      {0, 88 + 6 * 4, 0, 0, [](DisplayListBuilder& b) {b.setColorSource(kTestSource4.get());}},
      {0, 80 + 6 * 4, 0, 0, [](DisplayListBuilder& b) {b.setColorSource(kTestSource5.get());}},
      {0, 0, 0, 0, [](DisplayListBuilder& b) {b.setColorSource(nullptr);}},
    }
  },
  { "SetImageFilter", {
      {0, 32, 0, 0, [](DisplayListBuilder& b) {b.setImageFilter(&kTestBlurImageFilter1);}},
      {0, 32, 0, 0, [](DisplayListBuilder& b) {b.setImageFilter(&kTestBlurImageFilter2);}},
      {0, 32, 0, 0, [](DisplayListBuilder& b) {b.setImageFilter(&kTestBlurImageFilter3);}},
      {0, 32, 0, 0, [](DisplayListBuilder& b) {b.setImageFilter(&kTestBlurImageFilter4);}},
      {0, 24, 0, 0, [](DisplayListBuilder& b) {b.setImageFilter(&kTestDilateImageFilter1);}},
      {0, 24, 0, 0, [](DisplayListBuilder& b) {b.setImageFilter(&kTestDilateImageFilter2);}},
      {0, 24, 0, 0, [](DisplayListBuilder& b) {b.setImageFilter(&kTestDilateImageFilter3);}},
      {0, 24, 0, 0, [](DisplayListBuilder& b) {b.setImageFilter(&kTestErodeImageFilter1);}},
      {0, 24, 0, 0, [](DisplayListBuilder& b) {b.setImageFilter(&kTestErodeImageFilter2);}},
      {0, 24, 0, 0, [](DisplayListBuilder& b) {b.setImageFilter(&kTestErodeImageFilter3);}},
      {0, 64, 0, 0, [](DisplayListBuilder& b) {b.setImageFilter(&kTestMatrixImageFilter1);}},
      {0, 64, 0, 0, [](DisplayListBuilder& b) {b.setImageFilter(&kTestMatrixImageFilter2);}},
      {0, 64, 0, 0, [](DisplayListBuilder& b) {b.setImageFilter(&kTestMatrixImageFilter3);}},
      {0, 24, 0, 0, [](DisplayListBuilder& b) {b.setImageFilter(&kTestComposeImageFilter1);}},
      {0, 24, 0, 0, [](DisplayListBuilder& b) {b.setImageFilter(&kTestComposeImageFilter2);}},
      {0, 24, 0, 0, [](DisplayListBuilder& b) {b.setImageFilter(&kTestComposeImageFilter3);}},
      {0, 24, 0, 0, [](DisplayListBuilder& b) {b.setImageFilter(&kTestCFImageFilter1);}},
      {0, 24, 0, 0, [](DisplayListBuilder& b) {b.setImageFilter(&kTestCFImageFilter2);}},
      {0, 0, 0, 0, [](DisplayListBuilder& b) {b.setImageFilter(nullptr);}},
    }
  },
  { "SetColorFilter", {
      {0, 24, 0, 0, [](DisplayListBuilder& b) {b.setColorFilter(&kTestBlendColorFilter1);}},
      {0, 24, 0, 0, [](DisplayListBuilder& b) {b.setColorFilter(&kTestBlendColorFilter2);}},
      {0, 24, 0, 0, [](DisplayListBuilder& b) {b.setColorFilter(&kTestBlendColorFilter3);}},
      {0, 96, 0, 0, [](DisplayListBuilder& b) {b.setColorFilter(&kTestMatrixColorFilter1);}},
      {0, 96, 0, 0, [](DisplayListBuilder& b) {b.setColorFilter(&kTestMatrixColorFilter2);}},
      {0, 16, 0, 0, [](DisplayListBuilder& b) {b.setColorFilter(DlSrgbToLinearGammaColorFilter::instance.get());}},
      {0, 16, 0, 0, [](DisplayListBuilder& b) {b.setColorFilter(DlLinearToSrgbGammaColorFilter::instance.get());}},
      {0, 0, 0, 0, [](DisplayListBuilder& b) {b.setColorFilter(nullptr);}},
    }
  },
  { "SetPathEffect", {
      // sizeof(DlDashPathEffect) + 2 * sizeof(SkScalar)
      {0, 32, 0, 0, [](DisplayListBuilder& b) {b.setPathEffect(kTestPathEffect1.get());}},
      {0, 32, 0, 0, [](DisplayListBuilder& b) {b.setPathEffect(kTestPathEffect2.get());}},
      {0, 0, 0, 0, [](DisplayListBuilder& b) {b.setPathEffect(nullptr);}},
    }
  },
  { "SetMaskFilter", {
      {0, 24, 0, 0, [](DisplayListBuilder& b) {b.setMaskFilter(&kTestMaskFilter1);}},
      {0, 24, 0, 0, [](DisplayListBuilder& b) {b.setMaskFilter(&kTestMaskFilter2);}},
      {0, 24, 0, 0, [](DisplayListBuilder& b) {b.setMaskFilter(&kTestMaskFilter3);}},
      {0, 24, 0, 0, [](DisplayListBuilder& b) {b.setMaskFilter(&kTestMaskFilter4);}},
      {0, 24, 0, 0, [](DisplayListBuilder& b) {b.setMaskFilter(&kTestMaskFilter5);}},
      {0, 0, 0, 0, [](DisplayListBuilder& b) {b.setMaskFilter(nullptr);}},
    }
  },
  { "Save(Layer)+Restore", {
      {5, 104, 5, 104, [](DisplayListBuilder& b) {
        b.saveLayer(nullptr, SaveLayerOptions::kNoAttributes, &kTestCFImageFilter1);
        b.clipRect({0, 0, 25, 25}, SkClipOp::kIntersect, true);
        b.drawRect({5, 5, 15, 15});
        b.drawRect({10, 10, 20, 20});
        b.restore();
      }},
    // There are many reasons that save and restore can elide content, including
    // whether or not there are any draw operations between them, whether or not
    // there are any state changes to restore, and whether group rendering (opacity)
    // optimizations can allow attributes to be distributed to the children.
    // To prevent those cases we include at least one clip operation and 2 overlapping
    // rendering primitives between each save/restore pair.
      {5, 88, 5, 88, [](DisplayListBuilder& b) {
        b.save();
        b.clipRect({0, 0, 25, 25}, SkClipOp::kIntersect, true);
        b.drawRect({5, 5, 15, 15});
        b.drawRect({10, 10, 20, 20});
        b.restore();
      }},
      {5, 88, 5, 88, [](DisplayListBuilder& b) {
        b.saveLayer(nullptr, false);
        b.clipRect({0, 0, 25, 25}, SkClipOp::kIntersect, true);
        b.drawRect({5, 5, 15, 15});
        b.drawRect({10, 10, 20, 20});
        b.restore();
      }},
      {5, 88, 5, 88, [](DisplayListBuilder& b) {
        b.saveLayer(nullptr, true);
        b.clipRect({0, 0, 25, 25}, SkClipOp::kIntersect, true);
        b.drawRect({5, 5, 15, 15});
        b.drawRect({10, 10, 20, 20});
        b.restore();
      }},
      {5, 104, 5, 104, [](DisplayListBuilder& b) {
        b.saveLayer(&kTestBounds, false);
        b.clipRect({0, 0, 25, 25}, SkClipOp::kIntersect, true);
        b.drawRect({5, 5, 15, 15});
        b.drawRect({10, 10, 20, 20});
        b.restore();
      }},
      {5, 104, 5, 104, [](DisplayListBuilder& b) {
        b.saveLayer(&kTestBounds, true);
        b.clipRect({0, 0, 25, 25}, SkClipOp::kIntersect, true);
        b.drawRect({5, 5, 15, 15});
        b.drawRect({10, 10, 20, 20});
        b.restore();
      }},
      // backdrop variants - using the TestCFImageFilter because it can be
      // reconstituted in the DL->SkCanvas->DL stream
      // {5, 104, 5, 104, [](DisplayListBuilder& b) {
      //   b.saveLayer(nullptr, SaveLayerOptions::kNoAttributes, &kTestCFImageFilter1);
      //   b.clipRect({0, 0, 25, 25}, SkClipOp::kIntersect, true);
      //   b.drawRect({5, 5, 15, 15});
      //   b.drawRect({10, 10, 20, 20});
      //   b.restore();
      // }},
      {5, 104, 5, 104, [](DisplayListBuilder& b) {
        b.saveLayer(nullptr, SaveLayerOptions::kWithAttributes, &kTestCFImageFilter1);
        b.clipRect({0, 0, 25, 25}, SkClipOp::kIntersect, true);
        b.drawRect({5, 5, 15, 15});
        b.drawRect({10, 10, 20, 20});
        b.restore();
      }},
      {5, 120, 5, 120, [](DisplayListBuilder& b) {
        b.saveLayer(&kTestBounds, SaveLayerOptions::kNoAttributes, &kTestCFImageFilter1);
        b.clipRect({0, 0, 25, 25}, SkClipOp::kIntersect, true);
        b.drawRect({5, 5, 15, 15});
        b.drawRect({10, 10, 20, 20});
        b.restore();
      }},
      {5, 120, 5, 120, [](DisplayListBuilder& b) {
        b.saveLayer(&kTestBounds, SaveLayerOptions::kWithAttributes, &kTestCFImageFilter1);
        b.clipRect({0, 0, 25, 25}, SkClipOp::kIntersect, true);
        b.drawRect({5, 5, 15, 15});
        b.drawRect({10, 10, 20, 20});
        b.restore();
      }},
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
      {1, 24, 1, 24, [](DisplayListBuilder& b) {b.clipRect(kTestBounds, SkClipOp::kIntersect, true);}},
      {1, 24, 1, 24, [](DisplayListBuilder& b) {b.clipRect(kTestBounds.makeOffset(1, 1),
                                                           SkClipOp::kIntersect, true);}},
      {1, 24, 1, 24, [](DisplayListBuilder& b) {b.clipRect(kTestBounds, SkClipOp::kIntersect, false);}},
      {1, 24, 1, 24, [](DisplayListBuilder& b) {b.clipRect(kTestBounds, SkClipOp::kDifference, true);}},
      {1, 24, 1, 24, [](DisplayListBuilder& b) {b.clipRect(kTestBounds, SkClipOp::kDifference, false);}},
    }
  },
  { "ClipRRect", {
      {1, 64, 1, 64, [](DisplayListBuilder& b) {b.clipRRect(kTestRRect, SkClipOp::kIntersect, true);}},
      {1, 64, 1, 64, [](DisplayListBuilder& b) {b.clipRRect(kTestRRect.makeOffset(1, 1),
                                                            SkClipOp::kIntersect, true);}},
      {1, 64, 1, 64, [](DisplayListBuilder& b) {b.clipRRect(kTestRRect, SkClipOp::kIntersect, false);}},
      {1, 64, 1, 64, [](DisplayListBuilder& b) {b.clipRRect(kTestRRect, SkClipOp::kDifference, true);}},
      {1, 64, 1, 64, [](DisplayListBuilder& b) {b.clipRRect(kTestRRect, SkClipOp::kDifference, false);}},
    }
  },
  { "ClipPath", {
      {1, 24, 1, 24, [](DisplayListBuilder& b) {b.clipPath(kTestPath1, SkClipOp::kIntersect, true);}},
      {1, 24, 1, 24, [](DisplayListBuilder& b) {b.clipPath(kTestPath2, SkClipOp::kIntersect, true);}},
      {1, 24, 1, 24, [](DisplayListBuilder& b) {b.clipPath(kTestPath3, SkClipOp::kIntersect, true);}},
      {1, 24, 1, 24, [](DisplayListBuilder& b) {b.clipPath(kTestPath1, SkClipOp::kIntersect, false);}},
      {1, 24, 1, 24, [](DisplayListBuilder& b) {b.clipPath(kTestPath1, SkClipOp::kDifference, true);}},
      {1, 24, 1, 24, [](DisplayListBuilder& b) {b.clipPath(kTestPath1, SkClipOp::kDifference, false);}},
      // clipPath(rect) becomes clipRect
      {1, 24, 1, 24, [](DisplayListBuilder& b) {b.clipPath(kTestPathRect, SkClipOp::kIntersect, true);}},
      // clipPath(oval) becomes clipRRect
      {1, 64, 1, 64, [](DisplayListBuilder& b) {b.clipPath(kTestPathOval, SkClipOp::kIntersect, true);}},
    }
  },
  { "DrawPaint", {
      {1, 8, 1, 8, [](DisplayListBuilder& b) {b.drawPaint();}},
    }
  },
  { "DrawColor", {
      // cv.drawColor becomes cv.drawPaint(paint)
      {1, 16, 1, 24, [](DisplayListBuilder& b) {b.drawColor(SK_ColorBLUE, DlBlendMode::kSrcIn);}},
      {1, 16, 1, 24, [](DisplayListBuilder& b) {b.drawColor(SK_ColorBLUE, DlBlendMode::kDstIn);}},
      {1, 16, 1, 24, [](DisplayListBuilder& b) {b.drawColor(SK_ColorCYAN, DlBlendMode::kSrcIn);}},
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
      {1, 56, 1, 56, [](DisplayListBuilder& b) {b.drawRRect(kTestRRect);}},
      {1, 56, 1, 56, [](DisplayListBuilder& b) {b.drawRRect(kTestRRect.makeOffset(5, 5));}},
    }
  },
  { "DrawDRRect", {
      {1, 112, 1, 112, [](DisplayListBuilder& b) {b.drawDRRect(kTestRRect, kTestInnerRRect);}},
      {1, 112, 1, 112, [](DisplayListBuilder& b) {b.drawDRRect(kTestRRect.makeOffset(5, 5),
                                                               kTestInnerRRect.makeOffset(4, 4));}},
    }
  },
  { "DrawPath", {
      {1, 24, 1, 24, [](DisplayListBuilder& b) {b.drawPath(kTestPath1);}},
      {1, 24, 1, 24, [](DisplayListBuilder& b) {b.drawPath(kTestPath2);}},
      {1, 24, 1, 24, [](DisplayListBuilder& b) {b.drawPath(kTestPath3);}},
      {1, 24, 1, 24, [](DisplayListBuilder& b) {b.drawPath(kTestPathRect);}},
      {1, 24, 1, 24, [](DisplayListBuilder& b) {b.drawPath(kTestPathOval);}},
    }
  },
  { "DrawArc", {
      {1, 32, 1, 32, [](DisplayListBuilder& b) {b.drawArc(kTestBounds, 45, 270, false);}},
      {1, 32, 1, 32, [](DisplayListBuilder& b) {b.drawArc(kTestBounds.makeOffset(1, 1),
                                                          45, 270, false);}},
      {1, 32, 1, 32, [](DisplayListBuilder& b) {b.drawArc(kTestBounds, 30, 270, false);}},
      {1, 32, 1, 32, [](DisplayListBuilder& b) {b.drawArc(kTestBounds, 45, 260, false);}},
      {1, 32, 1, 32, [](DisplayListBuilder& b) {b.drawArc(kTestBounds, 45, 270, true);}},
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
      {1, 112, 1, 16, [](DisplayListBuilder& b) {b.drawVertices(TestVertices1, DlBlendMode::kSrcIn);}},
      {1, 112, 1, 16, [](DisplayListBuilder& b) {b.drawVertices(TestVertices1, DlBlendMode::kDstIn);}},
      {1, 112, 1, 16, [](DisplayListBuilder& b) {b.drawVertices(TestVertices2, DlBlendMode::kSrcIn);}},
    }
  },
  { "DrawImage", {
      {1, 24, -1, 48, [](DisplayListBuilder& b) {b.drawImage(TestImage1, {10, 10}, kNearestSampling, false);}},
      {1, 24, -1, 48, [](DisplayListBuilder& b) {b.drawImage(TestImage1, {10, 10}, kNearestSampling, true);}},
      {1, 24, -1, 48, [](DisplayListBuilder& b) {b.drawImage(TestImage1, {20, 10}, kNearestSampling, false);}},
      {1, 24, -1, 48, [](DisplayListBuilder& b) {b.drawImage(TestImage1, {10, 20}, kNearestSampling, false);}},
      {1, 24, -1, 48, [](DisplayListBuilder& b) {b.drawImage(TestImage1, {10, 10}, kLinearSampling, false);}},
      {1, 24, -1, 48, [](DisplayListBuilder& b) {b.drawImage(TestImage2, {10, 10}, kNearestSampling, false);}},
    }
  },
  { "DrawImageRect", {
      {1, 56, -1, 80, [](DisplayListBuilder& b) {b.drawImageRect(TestImage1, {10, 10, 20, 20}, {10, 10, 80, 80},
                                                                kNearestSampling, false);}},
      {1, 56, -1, 80, [](DisplayListBuilder& b) {b.drawImageRect(TestImage1, {10, 10, 20, 20}, {10, 10, 80, 80},
                                                                kNearestSampling, true);}},
      {1, 56, -1, 80, [](DisplayListBuilder& b) {b.drawImageRect(TestImage1, {10, 10, 20, 20}, {10, 10, 80, 80},
                                                                kNearestSampling, false,
                                                                SkCanvas::SrcRectConstraint::kStrict_SrcRectConstraint);}},
      {1, 56, -1, 80, [](DisplayListBuilder& b) {b.drawImageRect(TestImage1, {10, 10, 25, 20}, {10, 10, 80, 80},
                                                                kNearestSampling, false);}},
      {1, 56, -1, 80, [](DisplayListBuilder& b) {b.drawImageRect(TestImage1, {10, 10, 20, 20}, {10, 10, 85, 80},
                                                                kNearestSampling, false);}},
      {1, 56, -1, 80, [](DisplayListBuilder& b) {b.drawImageRect(TestImage1, {10, 10, 20, 20}, {10, 10, 80, 80},
                                                                kLinearSampling, false);}},
      {1, 56, -1, 80, [](DisplayListBuilder& b) {b.drawImageRect(TestImage2, {10, 10, 15, 15}, {10, 10, 80, 80},
                                                                kNearestSampling, false);}},
    }
  },
  { "DrawImageNine", {
      // SkVanvas::drawImageNine is immediately converted to drawImageLattice
      {1, 48, -1, 80, [](DisplayListBuilder& b) {b.drawImageNine(TestImage1, {10, 10, 20, 20}, {10, 10, 80, 80},
                                                                DlFilterMode::kNearest, false);}},
      {1, 48, -1, 80, [](DisplayListBuilder& b) {b.drawImageNine(TestImage1, {10, 10, 20, 20}, {10, 10, 80, 80},
                                                                DlFilterMode::kNearest, true);}},
      {1, 48, -1, 80, [](DisplayListBuilder& b) {b.drawImageNine(TestImage1, {10, 10, 25, 20}, {10, 10, 80, 80},
                                                                DlFilterMode::kNearest, false);}},
      {1, 48, -1, 80, [](DisplayListBuilder& b) {b.drawImageNine(TestImage1, {10, 10, 20, 20}, {10, 10, 85, 80},
                                                                DlFilterMode::kNearest, false);}},
      {1, 48, -1, 80, [](DisplayListBuilder& b) {b.drawImageNine(TestImage1, {10, 10, 20, 20}, {10, 10, 80, 80},
                                                                DlFilterMode::kLinear, false);}},
      {1, 48, -1, 80, [](DisplayListBuilder& b) {b.drawImageNine(TestImage2, {10, 10, 15, 15}, {10, 10, 80, 80},
                                                                DlFilterMode::kNearest, false);}},
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
      {1, 88, -1, 88, [](DisplayListBuilder& b) {b.drawImageLattice(TestImage1,
                                                                   {kTestDivs1, kTestDivs1, nullptr, 3, 3, nullptr, nullptr},
                                                                   {10, 10, 40, 40}, DlFilterMode::kNearest, false);}},
      {1, 88, -1, 88, [](DisplayListBuilder& b) {b.drawImageLattice(TestImage1,
                                                                   {kTestDivs1, kTestDivs1, nullptr, 3, 3, nullptr, nullptr},
                                                                   {10, 10, 40, 45}, DlFilterMode::kNearest, false);}},
      {1, 88, -1, 88, [](DisplayListBuilder& b) {b.drawImageLattice(TestImage1,
                                                                   {kTestDivs2, kTestDivs1, nullptr, 3, 3, nullptr, nullptr},
                                                                   {10, 10, 40, 40}, DlFilterMode::kNearest, false);}},
      // One less yDiv does not change the allocation due to 8-byte alignment
      {1, 88, -1, 88, [](DisplayListBuilder& b) {b.drawImageLattice(TestImage1,
                                                                   {kTestDivs1, kTestDivs1, nullptr, 3, 2, nullptr, nullptr},
                                                                   {10, 10, 40, 40}, DlFilterMode::kNearest, false);}},
      {1, 88, -1, 88, [](DisplayListBuilder& b) {b.drawImageLattice(TestImage1,
                                                                   {kTestDivs1, kTestDivs1, nullptr, 3, 3, nullptr, nullptr},
                                                                   {10, 10, 40, 40}, DlFilterMode::kLinear, false);}},
      {1, 96, -1, 96, [](DisplayListBuilder& b) {b.setColor(SK_ColorMAGENTA);
                                                b.drawImageLattice(TestImage1,
                                                                   {kTestDivs1, kTestDivs1, nullptr, 3, 3, nullptr, nullptr},
                                                                   {10, 10, 40, 40}, DlFilterMode::kNearest, true);}},
      {1, 88, -1, 88, [](DisplayListBuilder& b) {b.drawImageLattice(TestImage2,
                                                                   {kTestDivs1, kTestDivs1, nullptr, 3, 3, nullptr, nullptr},
                                                                   {10, 10, 40, 40}, DlFilterMode::kNearest, false);}},
      // Supplying fBounds does not change size because the Op record always includes it
      {1, 88, -1, 88, [](DisplayListBuilder& b) {b.drawImageLattice(TestImage1,
                                                                   {kTestDivs1, kTestDivs1, nullptr, 3, 3, &kTestLatticeSrcRect, nullptr},
                                                                   {10, 10, 40, 40}, DlFilterMode::kNearest, false);}},
      {1, 128, -1, 128, [](DisplayListBuilder& b) {b.drawImageLattice(TestImage1,
                                                                     {kTestDivs3, kTestDivs3, kTestRTypes, 2, 2, nullptr, kTestLatticeColors},
                                                                     {10, 10, 40, 40}, DlFilterMode::kNearest, false);}},
    }
  },
  { "DrawAtlas", {
      {1, 48 + 32 + 8, -1, 48 + 32 + 32, [](DisplayListBuilder& b) {
        static SkRSXform xforms[] = { {1, 0, 0, 0}, {0, 1, 0, 0} };
        static SkRect texs[] = { { 10, 10, 20, 20 }, {20, 20, 30, 30} };
        b.drawAtlas(TestImage1, xforms, texs, nullptr, 2, DlBlendMode::kSrcIn,
                    kNearestSampling, nullptr, false);}},
      {1, 48 + 32 + 8, -1, 48 + 32 + 32, [](DisplayListBuilder& b) {
        static SkRSXform xforms[] = { {1, 0, 0, 0}, {0, 1, 0, 0} };
        static SkRect texs[] = { { 10, 10, 20, 20 }, {20, 20, 30, 30} };
        b.drawAtlas(TestImage1, xforms, texs, nullptr, 2, DlBlendMode::kSrcIn,
                    kNearestSampling, nullptr, true);}},
      {1, 48 + 32 + 8, -1, 48 + 32 + 32, [](DisplayListBuilder& b) {
        static SkRSXform xforms[] = { {0, 1, 0, 0}, {0, 1, 0, 0} };
        static SkRect texs[] = { { 10, 10, 20, 20 }, {20, 20, 30, 30} };
        b.drawAtlas(TestImage1, xforms, texs, nullptr, 2, DlBlendMode::kSrcIn,
                    kNearestSampling, nullptr, false);}},
      {1, 48 + 32 + 8, -1, 48 + 32 + 32, [](DisplayListBuilder& b) {
        static SkRSXform xforms[] = { {1, 0, 0, 0}, {0, 1, 0, 0} };
        static SkRect texs[] = { { 10, 10, 20, 20 }, {20, 25, 30, 30} };
        b.drawAtlas(TestImage1, xforms, texs, nullptr, 2, DlBlendMode::kSrcIn,
                    kNearestSampling, nullptr, false);}},
      {1, 48 + 32 + 8, -1, 48 + 32 + 32, [](DisplayListBuilder& b) {
        static SkRSXform xforms[] = { {1, 0, 0, 0}, {0, 1, 0, 0} };
        static SkRect texs[] = { { 10, 10, 20, 20 }, {20, 20, 30, 30} };
        b.drawAtlas(TestImage1, xforms, texs, nullptr, 2, DlBlendMode::kSrcIn,
                    kLinearSampling, nullptr, false);}},
      {1, 48 + 32 + 8, -1, 48 + 32 + 32, [](DisplayListBuilder& b) {
        static SkRSXform xforms[] = { {1, 0, 0, 0}, {0, 1, 0, 0} };
        static SkRect texs[] = { { 10, 10, 20, 20 }, {20, 20, 30, 30} };
        b.drawAtlas(TestImage1, xforms, texs, nullptr, 2, DlBlendMode::kDstIn,
                    kNearestSampling, nullptr, false);}},
      {1, 64 + 32 + 8, -1, 64 + 32 + 32, [](DisplayListBuilder& b) {
        static SkRSXform xforms[] = { {1, 0, 0, 0}, {0, 1, 0, 0} };
        static SkRect texs[] = { { 10, 10, 20, 20 }, {20, 20, 30, 30} };
        static SkRect cullRect = { 0, 0, 200, 200 };
        b.drawAtlas(TestImage2, xforms, texs, nullptr, 2, DlBlendMode::kSrcIn,
                    kNearestSampling, &cullRect, false);}},
      {1, 48 + 32 + 8 + 8, -1, 48 + 32 + 32 + 8, [](DisplayListBuilder& b) {
        static SkRSXform xforms[] = { {1, 0, 0, 0}, {0, 1, 0, 0} };
        static SkRect texs[] = { { 10, 10, 20, 20 }, {20, 20, 30, 30} };
        static DlColor colors[] = { DlColor::kBlue(), DlColor::kGreen() };
        b.drawAtlas(TestImage1, xforms, texs, colors, 2, DlBlendMode::kSrcIn,
                    kNearestSampling, nullptr, false);}},
      {1, 64 + 32 + 8 + 8, -1, 64 + 32 + 32 + 8, [](DisplayListBuilder& b) {
        static SkRSXform xforms[] = { {1, 0, 0, 0}, {0, 1, 0, 0} };
        static SkRect texs[] = { { 10, 10, 20, 20 }, {20, 20, 30, 30} };
        static DlColor colors[] = { DlColor::kBlue(), DlColor::kGreen() };
        static SkRect cullRect = { 0, 0, 200, 200 };
        b.drawAtlas(TestImage1, xforms, texs, colors, 2, DlBlendMode::kSrcIn,
                    kNearestSampling, &cullRect, false);}},
    }
  },
  { "DrawPicture", {
      // cv.drawPicture cannot be compared as SkCanvas may inline it
      {1, 16, -1, 16, [](DisplayListBuilder& b) {b.drawPicture(TestPicture1, nullptr, false);}},
      {1, 16, -1, 16, [](DisplayListBuilder& b) {b.drawPicture(TestPicture2, nullptr, false);}},
      {1, 16, -1, 16, [](DisplayListBuilder& b) {b.drawPicture(TestPicture1, nullptr, true);}},
      {1, 56, -1, 56, [](DisplayListBuilder& b) {b.drawPicture(TestPicture1, &kTestMatrix1, false);}},
      {1, 56, -1, 56, [](DisplayListBuilder& b) {b.drawPicture(TestPicture1, &kTestMatrix2, false);}},
      {1, 56, -1, 56, [](DisplayListBuilder& b) {b.drawPicture(TestPicture1, &kTestMatrix1, true);}},
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
      {1, 32, -1, 32, [](DisplayListBuilder& b) {b.drawShadow(kTestPath1, SK_ColorGREEN, 1.0, false, 1.0);}},
      {1, 32, -1, 32, [](DisplayListBuilder& b) {b.drawShadow(kTestPath2, SK_ColorGREEN, 1.0, false, 1.0);}},
      {1, 32, -1, 32, [](DisplayListBuilder& b) {b.drawShadow(kTestPath1, SK_ColorBLUE, 1.0, false, 1.0);}},
      {1, 32, -1, 32, [](DisplayListBuilder& b) {b.drawShadow(kTestPath1, SK_ColorGREEN, 2.0, false, 1.0);}},
      {1, 32, -1, 32, [](DisplayListBuilder& b) {b.drawShadow(kTestPath1, SK_ColorGREEN, 1.0, true, 1.0);}},
      {1, 32, -1, 32, [](DisplayListBuilder& b) {b.drawShadow(kTestPath1, SK_ColorGREEN, 1.0, false, 2.5);}},
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
      ASSERT_EQ(dl->bytes(false), invocation.byte_count()) << desc;
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
        ASSERT_TRUE(DisplayListsEQ_Verbose(dl, empty));
        ASSERT_TRUE(empty->Equals(*dl)) << desc;
      } else {
        ASSERT_TRUE(DisplayListsNE_Verbose(dl, empty));
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
      EXPECT_EQ(static_cast<int>(sk_copy->op_count(false)),
                group.variants[i].sk_op_count())
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
  ASSERT_EQ(dl->op_count(false), 0u);
  ASSERT_EQ(dl->op_count(true), 0u);
}

TEST(DisplayList, AllBlendModeNops) {
  DisplayListBuilder builder;
  builder.setBlendMode(DlBlendMode::kSrcOver);
  builder.setBlender(nullptr);
  sk_sp<DisplayList> dl = builder.Build();
  ASSERT_EQ(dl->bytes(false), sizeof(DisplayList));
  ASSERT_EQ(dl->bytes(true), sizeof(DisplayList));
  ASSERT_EQ(dl->op_count(false), 0u);
  ASSERT_EQ(dl->op_count(true), 0u);
}

static sk_sp<DisplayList> Build(size_t g_index, size_t v_index) {
  DisplayListBuilder builder;
  unsigned int op_count = 0;
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
  DlMatrixColorFilter base_color_filter(color_matrix);
  // clang-format off
  const float alpha_matrix[] = {
    0, 0, 0, 0, 0,
    0, 1, 0, 0, 0,
    0, 0, 1, 0, 0,
    0, 0, 0, 0, 1,
  };
  // clang-format on
  DlMatrixColorFilter alpha_color_filter(alpha_matrix);

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
    builder.setColorFilter(&base_color_filter);
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
    SkRTreeFactory rtree_factory;
    SkCanvas* canvas = recorder.beginRecording(build_bounds, &rtree_factory);
    SkPaint p1;
    p1.setColorFilter(alpha_color_filter.skia_object());
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
    builder.setColorFilter(&alpha_color_filter);
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
    builder.setColorFilter(&alpha_color_filter);
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
    DlColorFilterImageFilter color_filter_image_filter(base_color_filter);
    builder.setImageFilter(&color_filter_image_filter);
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
    DlColorFilterImageFilter color_filter_image_filter(alpha_color_filter);
    builder.setImageFilter(&color_filter_image_filter);
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
    DlColorFilterImageFilter color_filter_image_filter(alpha_color_filter);
    builder.setImageFilter(&color_filter_image_filter);
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
    builder.setBlendMode(DlBlendMode::kClear);
    builder.saveLayer(&save_bounds, true);
    builder.setBlendMode(DlBlendMode::kSrcOver);
    builder.drawRect(rect);
    builder.restore();
    sk_sp<DisplayList> display_list = builder.Build();
    ASSERT_EQ(display_list->bounds(), build_bounds);
  }

  {
    // Same as previous with no save bounds
    DisplayListBuilder builder(build_bounds);
    builder.setBlendMode(DlBlendMode::kClear);
    builder.saveLayer(nullptr, true);
    builder.setBlendMode(DlBlendMode::kSrcOver);
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
  ASSERT_EQ(display_list->op_count(), 1u);
  ASSERT_EQ(display_list->op_count(true), 36u);

  ASSERT_EQ(picture->approximateOpCount(),
            static_cast<int>(display_list->op_count()));
  ASSERT_EQ(picture->approximateOpCount(true),
            static_cast<int>(display_list->op_count(true)));

  DisplayListCanvasRecorder dl_recorder(SkRect::MakeWH(150, 100));
  picture->playback(&dl_recorder);

  auto sk_display_list = dl_recorder.Build();
  ASSERT_EQ(display_list->op_count(), 1u);
  ASSERT_EQ(display_list->op_count(true), 36u);
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

TEST(DisplayList, DisplayListBlenderRefHandling) {
  class BlenderRefTester : public virtual AttributeRefTester {
   public:
    void setRefToPaint(SkPaint& paint) const override {
      paint.setBlender(blender_);
    }
    void setRefToDisplayList(DisplayListBuilder& builder) const override {
      builder.setBlender(blender_);
    }
    bool ref_is_unique() const override { return blender_->unique(); }

   private:
    sk_sp<SkBlender> blender_ =
        SkBlenders::Arithmetic(0.25, 0.25, 0.25, 0.25, true);
  };

  BlenderRefTester tester;
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

TEST(DisplayList, DisplayListTransformResetHandling) {
  DisplayListBuilder builder;
  builder.scale(20.0, 20.0);
  builder.transformReset();
  auto list = builder.Build();
  ASSERT_NE(list, nullptr);
  sk_sp<SkSurface> surface = SkSurface::MakeRasterN32Premul(10, 10);
  SkCanvas* canvas = surface->getCanvas();
  list->RenderTo(canvas);
  ASSERT_TRUE(canvas->getTotalMatrix().isIdentity());
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
      builder.setBlendMode(DlBlendMode::kSrc);
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
  RUN_TESTS2(builder.drawColor(SK_ColorRED, DlBlendMode::kSrcOver);, true);
  RUN_TESTS2(builder.drawColor(SK_ColorRED, DlBlendMode::kSrc);, false);
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
  RUN_TESTS2(builder.drawVertices(TestVertices1, DlBlendMode::kSrc);, false);
  RUN_TESTS(builder.drawImage(TestImage1, {0, 0}, kLinearSampling, true););
  RUN_TESTS2(builder.drawImage(TestImage1, {0, 0}, kLinearSampling, false);
             , true);
  RUN_TESTS(builder.drawImageRect(TestImage1, {10, 10, 20, 20}, {0, 0, 10, 10},
                                  kNearestSampling, true););
  RUN_TESTS2(builder.drawImageRect(TestImage1, {10, 10, 20, 20}, {0, 0, 10, 10},
                                   kNearestSampling, false);
             , true);
  RUN_TESTS(builder.drawImageNine(TestImage2, {20, 20, 30, 30}, {0, 0, 20, 20},
                                  DlFilterMode::kLinear, true););
  RUN_TESTS2(builder.drawImageNine(TestImage2, {20, 20, 30, 30}, {0, 0, 20, 20},
                                   DlFilterMode::kLinear, false);
             , true);
  RUN_TESTS(builder.drawImageLattice(
      TestImage1,
      {kTestDivs1, kTestDivs1, nullptr, 3, 3, &kTestLatticeSrcRect, nullptr},
      {10, 10, 40, 40}, DlFilterMode::kNearest, true););
  RUN_TESTS2(builder.drawImageLattice(
      TestImage1,
      {kTestDivs1, kTestDivs1, nullptr, 3, 3, &kTestLatticeSrcRect, nullptr},
      {10, 10, 40, 40}, DlFilterMode::kNearest, false);
             , true);
  static SkRSXform xforms[] = {{1, 0, 0, 0}, {0, 1, 0, 0}};
  static SkRect texs[] = {{10, 10, 20, 20}, {20, 20, 30, 30}};
  RUN_TESTS2(
      builder.drawAtlas(TestImage1, xforms, texs, nullptr, 2,
                        DlBlendMode::kSrcIn, kNearestSampling, nullptr, true);
      , false);
  RUN_TESTS2(
      builder.drawAtlas(TestImage1, xforms, texs, nullptr, 2,
                        DlBlendMode::kSrcIn, kNearestSampling, nullptr, false);
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
  RUN_TESTS2(builder.drawShadow(kTestPath1, SK_ColorBLACK, 1.0, false, 1.0);
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
  builder.setBlendMode(DlBlendMode::kSrc);
  builder.saveLayer(nullptr, false);
  builder.drawRect({0, 0, 10, 10});
  builder.restore();
  auto display_list = builder.Build();
  EXPECT_TRUE(display_list->can_apply_group_opacity());
}

TEST(DisplayList, SaveLayerTrueWithSrcBlendDoesNotSupportGroupOpacity) {
  DisplayListBuilder builder;
  builder.setBlendMode(DlBlendMode::kSrc);
  builder.saveLayer(nullptr, true);
  builder.drawRect({0, 0, 10, 10});
  builder.restore();
  auto display_list = builder.Build();
  EXPECT_FALSE(display_list->can_apply_group_opacity());
}

TEST(DisplayList, SaveLayerFalseSupportsGroupOpacityWithChildSrcBlend) {
  DisplayListBuilder builder;
  builder.saveLayer(nullptr, false);
  builder.setBlendMode(DlBlendMode::kSrc);
  builder.drawRect({0, 0, 10, 10});
  builder.restore();
  auto display_list = builder.Build();
  EXPECT_TRUE(display_list->can_apply_group_opacity());
}

TEST(DisplayList, SaveLayerTrueSupportsGroupOpacityWithChildSrcBlend) {
  DisplayListBuilder builder;
  builder.saveLayer(nullptr, true);
  builder.setBlendMode(DlBlendMode::kSrc);
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
  builder.setImageFilter(&kTestBlurImageFilter1);
  builder.restore();
  SkRect bounds = builder.Build()->bounds();
  EXPECT_EQ(bounds, SkRect::MakeLTRB(50, 50, 100, 100));
}

class SaveLayerOptionsExpector : public virtual Dispatcher,
                                 public IgnoreAttributeDispatchHelper,
                                 public IgnoreClipDispatchHelper,
                                 public IgnoreTransformDispatchHelper,
                                 public IgnoreDrawDispatchHelper {
 public:
  explicit SaveLayerOptionsExpector(SaveLayerOptions expected) {
    expected_.push_back(expected);
  }

  explicit SaveLayerOptionsExpector(std::vector<SaveLayerOptions> expected)
      : expected_(expected) {}

  void saveLayer(const SkRect* bounds,
                 const SaveLayerOptions options,
                 const DlImageFilter* backdrop) override {
    EXPECT_EQ(options, expected_[save_layer_count_]);
    save_layer_count_++;
  }

  int save_layer_count() { return save_layer_count_; }

 private:
  std::vector<SaveLayerOptions> expected_;
  int save_layer_count_ = 0;
};

TEST(DisplayList, SaveLayerOneSimpleOpSupportsOpacityOptimization) {
  SaveLayerOptions expected =
      SaveLayerOptions::kWithAttributes.with_can_distribute_opacity();
  SaveLayerOptionsExpector expector(expected);

  DisplayListBuilder builder;
  builder.setColor(SkColorSetARGB(127, 255, 255, 255));
  builder.saveLayer(nullptr, true);
  builder.drawRect({10, 10, 20, 20});
  builder.restore();

  builder.Build()->Dispatch(expector);
  EXPECT_EQ(expector.save_layer_count(), 1);
}

TEST(DisplayList, SaveLayerNoAttributesSupportsOpacityOptimization) {
  SaveLayerOptions expected =
      SaveLayerOptions::kNoAttributes.with_can_distribute_opacity();
  SaveLayerOptionsExpector expector(expected);

  DisplayListBuilder builder;
  builder.saveLayer(nullptr, false);
  builder.drawRect({10, 10, 20, 20});
  builder.restore();

  builder.Build()->Dispatch(expector);
  EXPECT_EQ(expector.save_layer_count(), 1);
}

TEST(DisplayList, SaveLayerTwoOverlappingOpsPreventsOpacityOptimization) {
  SaveLayerOptions expected = SaveLayerOptions::kWithAttributes;
  SaveLayerOptionsExpector expector(expected);

  DisplayListBuilder builder;
  builder.setColor(SkColorSetARGB(127, 255, 255, 255));
  builder.saveLayer(nullptr, true);
  builder.drawRect({10, 10, 20, 20});
  builder.drawRect({15, 15, 25, 25});
  builder.restore();

  builder.Build()->Dispatch(expector);
  EXPECT_EQ(expector.save_layer_count(), 1);
}

TEST(DisplayList, NestedSaveLayersMightSupportOpacityOptimization) {
  SaveLayerOptions expected1 =
      SaveLayerOptions::kWithAttributes.with_can_distribute_opacity();
  SaveLayerOptions expected2 = SaveLayerOptions::kWithAttributes;
  SaveLayerOptions expected3 =
      SaveLayerOptions::kWithAttributes.with_can_distribute_opacity();
  SaveLayerOptionsExpector expector({expected1, expected2, expected3});

  DisplayListBuilder builder;
  builder.setColor(SkColorSetARGB(127, 255, 255, 255));
  builder.saveLayer(nullptr, true);
  builder.saveLayer(nullptr, true);
  builder.drawRect({10, 10, 20, 20});
  builder.saveLayer(nullptr, true);
  builder.drawRect({15, 15, 25, 25});
  builder.restore();
  builder.restore();
  builder.restore();

  builder.Build()->Dispatch(expector);
  EXPECT_EQ(expector.save_layer_count(), 3);
}

TEST(DisplayList, NestedSaveLayersCanBothSupportOpacityOptimization) {
  SaveLayerOptions expected1 =
      SaveLayerOptions::kWithAttributes.with_can_distribute_opacity();
  SaveLayerOptions expected2 =
      SaveLayerOptions::kNoAttributes.with_can_distribute_opacity();
  SaveLayerOptionsExpector expector({expected1, expected2});

  DisplayListBuilder builder;
  builder.setColor(SkColorSetARGB(127, 255, 255, 255));
  builder.saveLayer(nullptr, true);
  builder.saveLayer(nullptr, false);
  builder.drawRect({10, 10, 20, 20});
  builder.restore();
  builder.restore();

  builder.Build()->Dispatch(expector);
  EXPECT_EQ(expector.save_layer_count(), 2);
}

TEST(DisplayList, SaveLayerImageFilterPreventsOpacityOptimization) {
  SaveLayerOptions expected = SaveLayerOptions::kWithAttributes;
  SaveLayerOptionsExpector expector(expected);

  DisplayListBuilder builder;
  builder.setColor(SkColorSetARGB(127, 255, 255, 255));
  builder.setImageFilter(&kTestBlurImageFilter1);
  builder.saveLayer(nullptr, true);
  builder.setImageFilter(nullptr);
  builder.drawRect({10, 10, 20, 20});
  builder.restore();

  builder.Build()->Dispatch(expector);
  EXPECT_EQ(expector.save_layer_count(), 1);
}

TEST(DisplayList, SaveLayerColorFilterPreventsOpacityOptimization) {
  SaveLayerOptions expected = SaveLayerOptions::kWithAttributes;
  SaveLayerOptionsExpector expector(expected);

  DisplayListBuilder builder;
  builder.setColor(SkColorSetARGB(127, 255, 255, 255));
  builder.setColorFilter(&kTestMatrixColorFilter1);
  builder.saveLayer(nullptr, true);
  builder.setColorFilter(nullptr);
  builder.drawRect({10, 10, 20, 20});
  builder.restore();

  builder.Build()->Dispatch(expector);
  EXPECT_EQ(expector.save_layer_count(), 1);
}

TEST(DisplayList, SaveLayerSrcBlendPreventsOpacityOptimization) {
  SaveLayerOptions expected = SaveLayerOptions::kWithAttributes;
  SaveLayerOptionsExpector expector(expected);

  DisplayListBuilder builder;
  builder.setColor(SkColorSetARGB(127, 255, 255, 255));
  builder.setBlendMode(DlBlendMode::kSrc);
  builder.saveLayer(nullptr, true);
  builder.setBlendMode(DlBlendMode::kSrcOver);
  builder.drawRect({10, 10, 20, 20});
  builder.restore();

  builder.Build()->Dispatch(expector);
  EXPECT_EQ(expector.save_layer_count(), 1);
}

TEST(DisplayList, SaveLayerImageFilterOnChildSupportsOpacityOptimization) {
  SaveLayerOptions expected =
      SaveLayerOptions::kWithAttributes.with_can_distribute_opacity();
  SaveLayerOptionsExpector expector(expected);

  DisplayListBuilder builder;
  builder.setColor(SkColorSetARGB(127, 255, 255, 255));
  builder.saveLayer(nullptr, true);
  builder.setImageFilter(&kTestBlurImageFilter1);
  builder.drawRect({10, 10, 20, 20});
  builder.restore();

  builder.Build()->Dispatch(expector);
  EXPECT_EQ(expector.save_layer_count(), 1);
}

TEST(DisplayList, SaveLayerColorFilterOnChildPreventsOpacityOptimization) {
  SaveLayerOptions expected = SaveLayerOptions::kWithAttributes;
  SaveLayerOptionsExpector expector(expected);

  DisplayListBuilder builder;
  builder.setColor(SkColorSetARGB(127, 255, 255, 255));
  builder.saveLayer(nullptr, true);
  builder.setColorFilter(&kTestMatrixColorFilter1);
  builder.drawRect({10, 10, 20, 20});
  builder.restore();

  builder.Build()->Dispatch(expector);
  EXPECT_EQ(expector.save_layer_count(), 1);
}

TEST(DisplayList, SaveLayerSrcBlendOnChildPreventsOpacityOptimization) {
  SaveLayerOptions expected = SaveLayerOptions::kWithAttributes;
  SaveLayerOptionsExpector expector(expected);

  DisplayListBuilder builder;
  builder.setColor(SkColorSetARGB(127, 255, 255, 255));
  builder.saveLayer(nullptr, true);
  builder.setBlendMode(DlBlendMode::kSrc);
  builder.drawRect({10, 10, 20, 20});
  builder.restore();

  builder.Build()->Dispatch(expector);
  EXPECT_EQ(expector.save_layer_count(), 1);
}

TEST(DisplayList, FlutterSvgIssue661BoundsWereEmpty) {
  // See https://github.com/dnfield/flutter_svg/issues/661

  SkPath path1;
  path1.setFillType(SkPathFillType::kWinding);
  path1.moveTo(25.54f, 37.52f);
  path1.cubicTo(20.91f, 37.52f, 16.54f, 33.39f, 13.62f, 30.58f);
  path1.lineTo(13, 30);
  path1.lineTo(12.45f, 29.42f);
  path1.cubicTo(8.39f, 25.15f, 1.61f, 18, 8.37f, 11.27f);
  path1.cubicTo(10.18f, 9.46f, 12.37f, 9.58f, 14.49f, 11.58f);
  path1.cubicTo(15.67f, 12.71f, 17.05f, 14.69f, 17.07f, 16.58f);
  path1.cubicTo(17.0968f, 17.458f, 16.7603f, 18.3081f, 16.14f, 18.93f);
  path1.cubicTo(15.8168f, 19.239f, 15.4653f, 19.5169f, 15.09f, 19.76f);
  path1.cubicTo(14.27f, 20.33f, 14.21f, 20.44f, 14.27f, 20.62f);
  path1.cubicTo(15.1672f, 22.3493f, 16.3239f, 23.9309f, 17.7f, 25.31f);
  path1.cubicTo(19.0791f, 26.6861f, 20.6607f, 27.8428f, 22.39f, 28.74f);
  path1.cubicTo(22.57f, 28.8f, 22.69f, 28.74f, 23.25f, 27.92f);
  path1.cubicTo(23.5f, 27.566f, 23.778f, 27.231f, 24.08f, 26.92f);
  path1.cubicTo(24.7045f, 26.3048f, 25.5538f, 25.9723f, 26.43f, 26);
  path1.cubicTo(28.29f, 26, 30.27f, 27.4f, 31.43f, 28.58f);
  path1.cubicTo(33.43f, 30.67f, 33.55f, 32.9f, 31.74f, 34.7f);
  path1.cubicTo(30.1477f, 36.4508f, 27.906f, 37.4704f, 25.54f, 37.52f);
  path1.close();
  path1.moveTo(11.17f, 12.23f);
  path1.cubicTo(10.6946f, 12.2571f, 10.2522f, 12.4819f, 9.95f, 12.85f);
  path1.cubicTo(5.12f, 17.67f, 8.95f, 22.5f, 14.05f, 27.85f);
  path1.lineTo(14.62f, 28.45f);
  path1.lineTo(15.16f, 28.96f);
  path1.cubicTo(20.52f, 34.06f, 25.35f, 37.89f, 30.16f, 33.06f);
  path1.cubicTo(30.83f, 32.39f, 31.25f, 31.56f, 29.81f, 30.06f);
  path1.cubicTo(28.9247f, 29.07f, 27.7359f, 28.4018f, 26.43f, 28.16f);
  path1.cubicTo(26.1476f, 28.1284f, 25.8676f, 28.2367f, 25.68f, 28.45f);
  path1.cubicTo(25.4633f, 28.6774f, 25.269f, 28.9252f, 25.1f, 29.19f);
  path1.cubicTo(24.53f, 30.01f, 23.47f, 31.54f, 21.54f, 30.79f);
  path1.lineTo(21.41f, 30.72f);
  path1.cubicTo(19.4601f, 29.7156f, 17.6787f, 28.4133f, 16.13f, 26.86f);
  path1.cubicTo(14.5748f, 25.3106f, 13.2693f, 23.5295f, 12.26f, 21.58f);
  path1.lineTo(12.2f, 21.44f);
  path1.cubicTo(11.45f, 19.51f, 12.97f, 18.44f, 13.8f, 17.88f);
  path1.cubicTo(14.061f, 17.706f, 14.308f, 17.512f, 14.54f, 17.3f);
  path1.cubicTo(14.7379f, 17.1067f, 14.8404f, 16.8359f, 14.82f, 16.56f);
  path1.cubicTo(14.5978f, 15.268f, 13.9585f, 14.0843f, 13, 13.19f);
  path1.cubicTo(12.5398f, 12.642f, 11.8824f, 12.2971f, 11.17f, 12.23f);
  path1.lineTo(11.17f, 12.23f);
  path1.close();
  path1.moveTo(27, 19.34f);
  path1.lineTo(24.74f, 19.34f);
  path1.cubicTo(24.7319f, 18.758f, 24.262f, 18.2881f, 23.68f, 18.28f);
  path1.lineTo(23.68f, 16.05f);
  path1.lineTo(23.7f, 16.05f);
  path1.cubicTo(25.5153f, 16.0582f, 26.9863f, 17.5248f, 27, 19.34f);
  path1.lineTo(27, 19.34f);
  path1.close();
  path1.moveTo(32.3f, 19.34f);
  path1.lineTo(30.07f, 19.34f);
  path1.cubicTo(30.037f, 15.859f, 27.171f, 13.011f, 23.69f, 13);
  path1.lineTo(23.69f, 10.72f);
  path1.cubicTo(28.415f, 10.725f, 32.3f, 14.615f, 32.3f, 19.34f);
  path1.close();

  SkPath path2;
  path2.setFillType(SkPathFillType::kWinding);
  path2.moveTo(37.5f, 19.33f);
  path2.lineTo(35.27f, 19.33f);
  path2.cubicTo(35.265f, 12.979f, 30.041f, 7.755f, 23.69f, 7.75f);
  path2.lineTo(23.69f, 5.52f);
  path2.cubicTo(31.264f, 5.525f, 37.495f, 11.756f, 37.5f, 19.33f);
  path2.close();

  DisplayListBuilder builder;
  {
    builder.save();
    builder.clipRect({0, 0, 100, 100}, SkClipOp::kIntersect, true);
    {
      builder.save();
      builder.transform2DAffine(2.17391, 0, -2547.83,  //
                                0, 2.04082, -500);
      {
        builder.save();
        builder.clipRect({1172, 245, 1218, 294}, SkClipOp::kIntersect, true);
        {
          builder.saveLayer(nullptr, SaveLayerOptions::kWithAttributes,
                            nullptr);
          {
            builder.save();
            builder.transform2DAffine(1.4375, 0, 1164.09,  //
                                      0, 1.53125, 236.548);
            builder.setAntiAlias(1);
            builder.setColor(0xffffffff);
            builder.drawPath(path1);
            builder.restore();
          }
          {
            builder.save();
            builder.transform2DAffine(1.4375, 0, 1164.09,  //
                                      0, 1.53125, 236.548);
            builder.drawPath(path2);
            builder.restore();
          }
          builder.restore();
        }
        builder.restore();
      }
      builder.restore();
    }
    builder.restore();
  }
  sk_sp<DisplayList> display_list = builder.Build();
  // Prior to the fix, the bounds were empty.
  EXPECT_FALSE(display_list->bounds().isEmpty());
  // These are the expected bounds, but testing float values can be
  // flaky wrt minor changes in the bounds calculations. If this
  // line has to be revised too often as the DL implementation is
  // improved and maintained, then we can eliminate this test and
  // just rely on the "rounded out" bounds test that follows.
  EXPECT_EQ(display_list->bounds(),
            SkRect::MakeLTRB(0, 0.00189208984375, 99.9839630127, 100));
  // This is the more practical result. The bounds are "almost" 0,0,100x100
  EXPECT_EQ(display_list->bounds().roundOut(), SkIRect::MakeWH(100, 100));
  EXPECT_EQ(display_list->op_count(), 19u);
  EXPECT_EQ(display_list->bytes(), sizeof(DisplayList) + 304u);
}

TEST(DisplayList, TranslateAffectsCurrentTransform) {
  DisplayListBuilder builder;
  builder.translate(12.3, 14.5);
  SkMatrix matrix = SkMatrix::Translate(12.3, 14.5);
  SkM44 m44 = SkM44(matrix);
  SkM44 curM44 = builder.getTransformFullPerspective();
  SkMatrix curMatrix = builder.getTransform();
  ASSERT_EQ(curM44, m44);
  ASSERT_EQ(curMatrix, matrix);
  builder.translate(10, 10);
  // CurrentTransform has changed
  ASSERT_NE(builder.getTransformFullPerspective(), m44);
  ASSERT_NE(builder.getTransform(), curMatrix);
  // Previous return values have not
  ASSERT_EQ(curM44, m44);
  ASSERT_EQ(curMatrix, matrix);
}

TEST(DisplayList, ScaleAffectsCurrentTransform) {
  DisplayListBuilder builder;
  builder.scale(12.3, 14.5);
  SkMatrix matrix = SkMatrix::Scale(12.3, 14.5);
  SkM44 m44 = SkM44(matrix);
  SkM44 curM44 = builder.getTransformFullPerspective();
  SkMatrix curMatrix = builder.getTransform();
  ASSERT_EQ(curM44, m44);
  ASSERT_EQ(curMatrix, matrix);
  builder.translate(10, 10);
  // CurrentTransform has changed
  ASSERT_NE(builder.getTransformFullPerspective(), m44);
  ASSERT_NE(builder.getTransform(), curMatrix);
  // Previous return values have not
  ASSERT_EQ(curM44, m44);
  ASSERT_EQ(curMatrix, matrix);
}

TEST(DisplayList, RotateAffectsCurrentTransform) {
  DisplayListBuilder builder;
  builder.rotate(12.3);
  SkMatrix matrix = SkMatrix::RotateDeg(12.3);
  SkM44 m44 = SkM44(matrix);
  SkM44 curM44 = builder.getTransformFullPerspective();
  SkMatrix curMatrix = builder.getTransform();
  ASSERT_EQ(curM44, m44);
  ASSERT_EQ(curMatrix, matrix);
  builder.translate(10, 10);
  // CurrentTransform has changed
  ASSERT_NE(builder.getTransformFullPerspective(), m44);
  ASSERT_NE(builder.getTransform(), curMatrix);
  // Previous return values have not
  ASSERT_EQ(curM44, m44);
  ASSERT_EQ(curMatrix, matrix);
}

TEST(DisplayList, SkewAffectsCurrentTransform) {
  DisplayListBuilder builder;
  builder.skew(12.3, 14.5);
  SkMatrix matrix = SkMatrix::Skew(12.3, 14.5);
  SkM44 m44 = SkM44(matrix);
  SkM44 curM44 = builder.getTransformFullPerspective();
  SkMatrix curMatrix = builder.getTransform();
  ASSERT_EQ(curM44, m44);
  ASSERT_EQ(curMatrix, matrix);
  builder.translate(10, 10);
  // CurrentTransform has changed
  ASSERT_NE(builder.getTransformFullPerspective(), m44);
  ASSERT_NE(builder.getTransform(), curMatrix);
  // Previous return values have not
  ASSERT_EQ(curM44, m44);
  ASSERT_EQ(curMatrix, matrix);
}

TEST(DisplayList, TransformAffectsCurrentTransform) {
  DisplayListBuilder builder;
  builder.transform2DAffine(3, 0, 12.3,  //
                            1, 5, 14.5);
  SkMatrix matrix = SkMatrix::MakeAll(3, 0, 12.3,  //
                                      1, 5, 14.5,  //
                                      0, 0, 1);
  SkM44 m44 = SkM44(matrix);
  SkM44 curM44 = builder.getTransformFullPerspective();
  SkMatrix curMatrix = builder.getTransform();
  ASSERT_EQ(curM44, m44);
  ASSERT_EQ(curMatrix, matrix);
  builder.translate(10, 10);
  // CurrentTransform has changed
  ASSERT_NE(builder.getTransformFullPerspective(), m44);
  ASSERT_NE(builder.getTransform(), curMatrix);
  // Previous return values have not
  ASSERT_EQ(curM44, m44);
  ASSERT_EQ(curMatrix, matrix);
}

TEST(DisplayList, FullTransformAffectsCurrentTransform) {
  DisplayListBuilder builder;
  builder.transformFullPerspective(3, 0, 4, 12.3,  //
                                   1, 5, 3, 14.5,  //
                                   0, 0, 7, 16.2,  //
                                   0, 0, 0, 1);
  SkMatrix matrix = SkMatrix::MakeAll(3, 0, 12.3,  //
                                      1, 5, 14.5,  //
                                      0, 0, 1);
  SkM44 m44 = SkM44(3, 0, 4, 12.3,  //
                    1, 5, 3, 14.5,  //
                    0, 0, 7, 16.2,  //
                    0, 0, 0, 1);
  SkM44 curM44 = builder.getTransformFullPerspective();
  SkMatrix curMatrix = builder.getTransform();
  ASSERT_EQ(curM44, m44);
  ASSERT_EQ(curMatrix, matrix);
  builder.translate(10, 10);
  // CurrentTransform has changed
  ASSERT_NE(builder.getTransformFullPerspective(), m44);
  ASSERT_NE(builder.getTransform(), curMatrix);
  // Previous return values have not
  ASSERT_EQ(curM44, m44);
  ASSERT_EQ(curMatrix, matrix);
}

TEST(DisplayList, ClipRectAffectsClipBounds) {
  DisplayListBuilder builder;
  SkRect clipBounds = SkRect::MakeLTRB(10.2, 11.3, 20.4, 25.7);
  SkRect clipExpandedBounds = SkRect::MakeLTRB(10, 11, 21, 26);
  builder.clipRect(clipBounds, SkClipOp::kIntersect, false);

  // Save initial return values for testing restored values
  SkRect initialLocalBounds = builder.getLocalClipBounds();
  SkRect initialDestinationBounds = builder.getDestinationClipBounds();
  ASSERT_EQ(initialLocalBounds, clipExpandedBounds);
  ASSERT_EQ(initialDestinationBounds, clipBounds);

  builder.save();
  builder.clipRect({0, 0, 15, 15}, SkClipOp::kIntersect, false);
  // Both clip bounds have changed
  ASSERT_NE(builder.getLocalClipBounds(), clipExpandedBounds);
  ASSERT_NE(builder.getDestinationClipBounds(), clipBounds);
  // Previous return values have not changed
  ASSERT_EQ(initialLocalBounds, clipExpandedBounds);
  ASSERT_EQ(initialDestinationBounds, clipBounds);
  builder.restore();

  // save/restore returned the values to their original values
  ASSERT_EQ(builder.getLocalClipBounds(), initialLocalBounds);
  ASSERT_EQ(builder.getDestinationClipBounds(), initialDestinationBounds);

  builder.save();
  builder.scale(2, 2);
  SkRect scaledExpandedBounds = SkRect::MakeLTRB(5, 5.5, 10.5, 13);
  ASSERT_EQ(builder.getLocalClipBounds(), scaledExpandedBounds);
  // Destination bounds are unaffected by transform
  ASSERT_EQ(builder.getDestinationClipBounds(), clipBounds);
  builder.restore();

  // save/restore returned the values to their original values
  ASSERT_EQ(builder.getLocalClipBounds(), initialLocalBounds);
  ASSERT_EQ(builder.getDestinationClipBounds(), initialDestinationBounds);
}

TEST(DisplayList, ClipRRectAffectsClipBounds) {
  DisplayListBuilder builder;
  SkRect clipBounds = SkRect::MakeLTRB(10.2, 11.3, 20.4, 25.7);
  SkRect clipExpandedBounds = SkRect::MakeLTRB(10, 11, 21, 26);
  SkRRect clip = SkRRect::MakeRectXY(clipBounds, 3, 2);
  builder.clipRRect(clip, SkClipOp::kIntersect, false);

  // Save initial return values for testing restored values
  SkRect initialLocalBounds = builder.getLocalClipBounds();
  SkRect initialDestinationBounds = builder.getDestinationClipBounds();
  ASSERT_EQ(initialLocalBounds, clipExpandedBounds);
  ASSERT_EQ(initialDestinationBounds, clipBounds);

  builder.save();
  builder.clipRect({0, 0, 15, 15}, SkClipOp::kIntersect, false);
  // Both clip bounds have changed
  ASSERT_NE(builder.getLocalClipBounds(), clipExpandedBounds);
  ASSERT_NE(builder.getDestinationClipBounds(), clipBounds);
  // Previous return values have not changed
  ASSERT_EQ(initialLocalBounds, clipExpandedBounds);
  ASSERT_EQ(initialDestinationBounds, clipBounds);
  builder.restore();

  // save/restore returned the values to their original values
  ASSERT_EQ(builder.getLocalClipBounds(), initialLocalBounds);
  ASSERT_EQ(builder.getDestinationClipBounds(), initialDestinationBounds);

  builder.save();
  builder.scale(2, 2);
  SkRect scaledExpandedBounds = SkRect::MakeLTRB(5, 5.5, 10.5, 13);
  ASSERT_EQ(builder.getLocalClipBounds(), scaledExpandedBounds);
  // Destination bounds are unaffected by transform
  ASSERT_EQ(builder.getDestinationClipBounds(), clipBounds);
  builder.restore();

  // save/restore returned the values to their original values
  ASSERT_EQ(builder.getLocalClipBounds(), initialLocalBounds);
  ASSERT_EQ(builder.getDestinationClipBounds(), initialDestinationBounds);
}

TEST(DisplayList, ClipPathAffectsClipBounds) {
  DisplayListBuilder builder;
  SkPath clip = SkPath().addCircle(10.2, 11.3, 2).addCircle(20.4, 25.7, 2);
  SkRect clipBounds = SkRect::MakeLTRB(8.2, 9.3, 22.4, 27.7);
  SkRect clipExpandedBounds = SkRect::MakeLTRB(8, 9, 23, 28);
  builder.clipPath(clip, SkClipOp::kIntersect, false);

  // Save initial return values for testing restored values
  SkRect initialLocalBounds = builder.getLocalClipBounds();
  SkRect initialDestinationBounds = builder.getDestinationClipBounds();
  ASSERT_EQ(initialLocalBounds, clipExpandedBounds);
  ASSERT_EQ(initialDestinationBounds, clipBounds);

  builder.save();
  builder.clipRect({0, 0, 15, 15}, SkClipOp::kIntersect, false);
  // Both clip bounds have changed
  ASSERT_NE(builder.getLocalClipBounds(), clipExpandedBounds);
  ASSERT_NE(builder.getDestinationClipBounds(), clipBounds);
  // Previous return values have not changed
  ASSERT_EQ(initialLocalBounds, clipExpandedBounds);
  ASSERT_EQ(initialDestinationBounds, clipBounds);
  builder.restore();

  // save/restore returned the values to their original values
  ASSERT_EQ(builder.getLocalClipBounds(), initialLocalBounds);
  ASSERT_EQ(builder.getDestinationClipBounds(), initialDestinationBounds);

  builder.save();
  builder.scale(2, 2);
  SkRect scaledExpandedBounds = SkRect::MakeLTRB(4, 4.5, 11.5, 14);
  ASSERT_EQ(builder.getLocalClipBounds(), scaledExpandedBounds);
  // Destination bounds are unaffected by transform
  ASSERT_EQ(builder.getDestinationClipBounds(), clipBounds);
  builder.restore();

  // save/restore returned the values to their original values
  ASSERT_EQ(builder.getLocalClipBounds(), initialLocalBounds);
  ASSERT_EQ(builder.getDestinationClipBounds(), initialDestinationBounds);
}

TEST(DisplayList, DiffClipRectDoesNotAffectClipBounds) {
  DisplayListBuilder builder;
  SkRect diff_clip = SkRect::MakeLTRB(0, 0, 15, 15);
  SkRect clipBounds = SkRect::MakeLTRB(10.2, 11.3, 20.4, 25.7);
  SkRect clipExpandedBounds = SkRect::MakeLTRB(10, 11, 21, 26);
  builder.clipRect(clipBounds, SkClipOp::kIntersect, false);

  // Save initial return values for testing after kDifference clip
  SkRect initialLocalBounds = builder.getLocalClipBounds();
  SkRect initialDestinationBounds = builder.getDestinationClipBounds();
  ASSERT_EQ(initialLocalBounds, clipExpandedBounds);
  ASSERT_EQ(initialDestinationBounds, clipBounds);

  builder.clipRect(diff_clip, SkClipOp::kDifference, false);
  ASSERT_EQ(builder.getLocalClipBounds(), initialLocalBounds);
  ASSERT_EQ(builder.getDestinationClipBounds(), initialDestinationBounds);
}

TEST(DisplayList, DiffClipRRectDoesNotAffectClipBounds) {
  DisplayListBuilder builder;
  SkRRect diff_clip = SkRRect::MakeRectXY({0, 0, 15, 15}, 1, 1);
  SkRect clipBounds = SkRect::MakeLTRB(10.2, 11.3, 20.4, 25.7);
  SkRect clipExpandedBounds = SkRect::MakeLTRB(10, 11, 21, 26);
  SkRRect clip = SkRRect::MakeRectXY({10.2, 11.3, 20.4, 25.7}, 3, 2);
  builder.clipRRect(clip, SkClipOp::kIntersect, false);

  // Save initial return values for testing after kDifference clip
  SkRect initialLocalBounds = builder.getLocalClipBounds();
  SkRect initialDestinationBounds = builder.getDestinationClipBounds();
  ASSERT_EQ(initialLocalBounds, clipExpandedBounds);
  ASSERT_EQ(initialDestinationBounds, clipBounds);

  builder.clipRRect(diff_clip, SkClipOp::kDifference, false);
  ASSERT_EQ(builder.getLocalClipBounds(), initialLocalBounds);
  ASSERT_EQ(builder.getDestinationClipBounds(), initialDestinationBounds);
}

TEST(DisplayList, DiffClipPathDoesNotAffectClipBounds) {
  DisplayListBuilder builder;
  SkPath diff_clip = SkPath().addRect({0, 0, 15, 15});
  SkPath clip = SkPath().addCircle(10.2, 11.3, 2).addCircle(20.4, 25.7, 2);
  SkRect clipBounds = SkRect::MakeLTRB(8.2, 9.3, 22.4, 27.7);
  SkRect clipExpandedBounds = SkRect::MakeLTRB(8, 9, 23, 28);
  builder.clipPath(clip, SkClipOp::kIntersect, false);

  // Save initial return values for testing after kDifference clip
  SkRect initialLocalBounds = builder.getLocalClipBounds();
  SkRect initialDestinationBounds = builder.getDestinationClipBounds();
  ASSERT_EQ(initialLocalBounds, clipExpandedBounds);
  ASSERT_EQ(initialDestinationBounds, clipBounds);

  builder.clipPath(diff_clip, SkClipOp::kDifference, false);
  ASSERT_EQ(builder.getLocalClipBounds(), initialLocalBounds);
  ASSERT_EQ(builder.getDestinationClipBounds(), initialDestinationBounds);
}

TEST(DisplayList, FlatDrawPointsProducesBounds) {
  SkPoint horizontal_points[2] = {{10, 10}, {20, 10}};
  SkPoint vertical_points[2] = {{10, 10}, {10, 20}};
  {
    DisplayListBuilder builder;
    builder.drawPoints(SkCanvas::kPolygon_PointMode, 2, horizontal_points);
    SkRect bounds = builder.Build()->bounds();
    EXPECT_TRUE(bounds.contains(10, 10));
    EXPECT_TRUE(bounds.contains(20, 10));
    EXPECT_GE(bounds.width(), 10);
  }
  {
    DisplayListBuilder builder;
    builder.drawPoints(SkCanvas::kPolygon_PointMode, 2, vertical_points);
    SkRect bounds = builder.Build()->bounds();
    EXPECT_TRUE(bounds.contains(10, 10));
    EXPECT_TRUE(bounds.contains(10, 20));
    EXPECT_GE(bounds.height(), 10);
  }
  {
    DisplayListBuilder builder;
    builder.drawPoints(SkCanvas::kPoints_PointMode, 1, horizontal_points);
    SkRect bounds = builder.Build()->bounds();
    EXPECT_TRUE(bounds.contains(10, 10));
  }
  {
    DisplayListBuilder builder;
    builder.setStrokeWidth(2);
    builder.drawPoints(SkCanvas::kPolygon_PointMode, 2, horizontal_points);
    SkRect bounds = builder.Build()->bounds();
    EXPECT_TRUE(bounds.contains(10, 10));
    EXPECT_TRUE(bounds.contains(20, 10));
    EXPECT_EQ(bounds, SkRect::MakeLTRB(9, 9, 21, 11));
  }
  {
    DisplayListBuilder builder;
    builder.setStrokeWidth(2);
    builder.drawPoints(SkCanvas::kPolygon_PointMode, 2, vertical_points);
    SkRect bounds = builder.Build()->bounds();
    EXPECT_TRUE(bounds.contains(10, 10));
    EXPECT_TRUE(bounds.contains(10, 20));
    EXPECT_EQ(bounds, SkRect::MakeLTRB(9, 9, 11, 21));
  }
  {
    DisplayListBuilder builder;
    builder.setStrokeWidth(2);
    builder.drawPoints(SkCanvas::kPoints_PointMode, 1, horizontal_points);
    SkRect bounds = builder.Build()->bounds();
    EXPECT_TRUE(bounds.contains(10, 10));
    EXPECT_EQ(bounds, SkRect::MakeLTRB(9, 9, 11, 11));
  }
}

}  // namespace testing
}  // namespace flutter
