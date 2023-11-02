// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_DISPLAY_LIST_TESTING_DL_TEST_SNIPPETS_H_
#define FLUTTER_DISPLAY_LIST_TESTING_DL_TEST_SNIPPETS_H_

#include "flutter/display_list/display_list.h"
#include "flutter/display_list/dl_builder.h"
#include "flutter/testing/testing.h"

#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkSurface.h"
#include "third_party/skia/include/effects/SkDashPathEffect.h"
#include "third_party/skia/include/effects/SkGradientShader.h"
#include "third_party/skia/include/effects/SkImageFilters.h"

namespace flutter {
namespace testing {

sk_sp<DisplayList> GetSampleDisplayList();
sk_sp<DisplayList> GetSampleDisplayList(int ops);
sk_sp<DisplayList> GetSampleNestedDisplayList();

typedef const std::function<void(DlOpReceiver&)> DlInvoker;

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
  sk_sp<SkSurface> surface =
      SkSurfaces::Raster(SkImageInfo::MakeN32Premul(w, h));
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
static auto TestSkImage = MakeTestImage(30, 30, 5)->skia_image();

static const DlImageColorSource kTestSource1(TestImage1,
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
static const DlErodeImageFilter kTestErodeImageFilter1(4.0, 4.0);
static const DlErodeImageFilter kTestErodeImageFilter2(4.0, 3.0);
static const DlErodeImageFilter kTestErodeImageFilter3(3.0, 4.0);
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
static const DlBlurMaskFilter kTestMaskFilter1(DlBlurStyle::kNormal, 3.0);
static const DlBlurMaskFilter kTestMaskFilter2(DlBlurStyle::kNormal, 5.0);
static const DlBlurMaskFilter kTestMaskFilter3(DlBlurStyle::kSolid, 3.0);
static const DlBlurMaskFilter kTestMaskFilter4(DlBlurStyle::kInner, 3.0);
static const DlBlurMaskFilter kTestMaskFilter5(DlBlurStyle::kOuter, 3.0);
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

static sk_sp<DisplayList> MakeTestDisplayList(int w, int h, SkColor color) {
  DisplayListBuilder builder;
  builder.DrawRect(SkRect::MakeWH(w, h), DlPaint(DlColor(color)));
  return builder.Build();
}
static sk_sp<DisplayList> TestDisplayList1 =
    MakeTestDisplayList(20, 20, SK_ColorGREEN);
static sk_sp<DisplayList> TestDisplayList2 =
    MakeTestDisplayList(25, 25, SK_ColorBLUE);

SkFont CreateTestFontOfSize(SkScalar scalar);

sk_sp<SkTextBlob> GetTestTextBlob(int index);

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

  bool is_empty() { return byte_count_ == 0; }

  bool supports_group_opacity() { return supports_group_opacity_; }

  unsigned int op_count() { return op_count_; }
  // byte count for the individual ops, no DisplayList overhead
  size_t raw_byte_count() { return byte_count_; }
  // byte count for the ops with DisplayList overhead, comparable
  // to |DisplayList.byte_count().
  size_t byte_count() { return sizeof(DisplayList) + byte_count_; }

  void Invoke(DlOpReceiver& builder) { invoker(builder); }

  // sk_sp<DisplayList> Build() {
  //   DisplayListBuilder builder;
  //   invoker(builder.asReceiver());
  //   return builder.Build();
  // }
};

struct DisplayListInvocationGroup {
  std::string op_name;
  std::vector<DisplayListInvocation> variants;
};

std::vector<DisplayListInvocationGroup> CreateAllRenderingOps();
std::vector<DisplayListInvocationGroup> CreateAllGroups();

}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_DISPLAY_LIST_TESTING_DL_TEST_SNIPPETS_H_
