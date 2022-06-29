// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/display_list_attributes_testing.h"
#include "flutter/display_list/display_list_builder.h"
#include "flutter/display_list/display_list_comparable.h"
#include "flutter/display_list/display_list_image_filter.h"
#include "flutter/display_list/display_list_sampling_options.h"
#include "flutter/display_list/types.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

TEST(DisplayListImageFilter, BuilderSetGet) {
  DlBlurImageFilter filter(5.0, 5.0, DlTileMode::kDecal);
  DisplayListBuilder builder;

  ASSERT_EQ(builder.getImageFilter(), nullptr);

  builder.setImageFilter(&filter);
  ASSERT_NE(builder.getImageFilter(), nullptr);
  ASSERT_TRUE(
      Equals(builder.getImageFilter(), static_cast<DlImageFilter*>(&filter)));

  builder.setImageFilter(nullptr);
  ASSERT_EQ(builder.getImageFilter(), nullptr);
}

TEST(DisplayListImageFilter, FromSkiaNullFilter) {
  std::shared_ptr<DlImageFilter> filter = DlImageFilter::From(nullptr);

  ASSERT_EQ(filter, nullptr);
  ASSERT_EQ(filter.get(), nullptr);
}

TEST(DisplayListImageFilter, FromSkiaBlurImageFilter) {
  sk_sp<SkImageFilter> sk_image_filter =
      SkImageFilters::Blur(5.0, 5.0, SkTileMode::kRepeat, nullptr);
  std::shared_ptr<DlImageFilter> filter = DlImageFilter::From(sk_image_filter);

  ASSERT_EQ(filter->type(), DlImageFilterType::kUnknown);

  // We cannot recapture the blur parameters from an SkBlurImageFilter
  ASSERT_EQ(filter->asBlur(), nullptr);
  ASSERT_EQ(filter->asDilate(), nullptr);
  ASSERT_EQ(filter->asErode(), nullptr);
  ASSERT_EQ(filter->asMatrix(), nullptr);
  ASSERT_EQ(filter->asCompose(), nullptr);
  ASSERT_EQ(filter->asColorFilter(), nullptr);
}

TEST(DisplayListImageFilter, FromSkiaDilateImageFilter) {
  sk_sp<SkImageFilter> sk_image_filter =
      SkImageFilters::Dilate(5.0, 5.0, nullptr);
  std::shared_ptr<DlImageFilter> filter = DlImageFilter::From(sk_image_filter);

  ASSERT_EQ(filter->type(), DlImageFilterType::kUnknown);

  // We cannot recapture the dilate parameters from an SkDilateImageFilter
  ASSERT_EQ(filter->asBlur(), nullptr);
  ASSERT_EQ(filter->asDilate(), nullptr);
  ASSERT_EQ(filter->asErode(), nullptr);
  ASSERT_EQ(filter->asMatrix(), nullptr);
  ASSERT_EQ(filter->asCompose(), nullptr);
  ASSERT_EQ(filter->asColorFilter(), nullptr);
}

TEST(DisplayListImageFilter, FromSkiaErodeImageFilter) {
  sk_sp<SkImageFilter> sk_image_filter =
      SkImageFilters::Erode(5.0, 5.0, nullptr);
  std::shared_ptr<DlImageFilter> filter = DlImageFilter::From(sk_image_filter);

  ASSERT_EQ(filter->type(), DlImageFilterType::kUnknown);

  // We cannot recapture the erode parameters from an SkErodeImageFilter
  ASSERT_EQ(filter->asBlur(), nullptr);
  ASSERT_EQ(filter->asDilate(), nullptr);
  ASSERT_EQ(filter->asErode(), nullptr);
  ASSERT_EQ(filter->asMatrix(), nullptr);
  ASSERT_EQ(filter->asCompose(), nullptr);
  ASSERT_EQ(filter->asColorFilter(), nullptr);
}

TEST(DisplayListImageFilter, FromSkiaMatrixImageFilter) {
  sk_sp<SkImageFilter> sk_image_filter = SkImageFilters::MatrixTransform(
      SkMatrix::RotateDeg(45), ToSk(DlImageSampling::kLinear), nullptr);
  std::shared_ptr<DlImageFilter> filter = DlImageFilter::From(sk_image_filter);

  ASSERT_EQ(filter->type(), DlImageFilterType::kUnknown);

  // We cannot recapture the blur parameters from an SkMatrixImageFilter
  ASSERT_EQ(filter->asBlur(), nullptr);
  ASSERT_EQ(filter->asDilate(), nullptr);
  ASSERT_EQ(filter->asErode(), nullptr);
  ASSERT_EQ(filter->asMatrix(), nullptr);
  ASSERT_EQ(filter->asCompose(), nullptr);
  ASSERT_EQ(filter->asColorFilter(), nullptr);
}

TEST(DisplayListImageFilter, FromSkiaComposeImageFilter) {
  sk_sp<SkImageFilter> sk_blur_filter =
      SkImageFilters::Blur(5.0, 5.0, SkTileMode::kRepeat, nullptr);
  sk_sp<SkImageFilter> sk_matrix_filter = SkImageFilters::MatrixTransform(
      SkMatrix::RotateDeg(45), ToSk(DlImageSampling::kLinear), nullptr);
  sk_sp<SkImageFilter> sk_image_filter =
      SkImageFilters::Compose(sk_blur_filter, sk_matrix_filter);
  std::shared_ptr<DlImageFilter> filter = DlImageFilter::From(sk_image_filter);

  ASSERT_EQ(filter->type(), DlImageFilterType::kUnknown);

  // We cannot recapture the blur parameters from an SkComposeImageFilter
  ASSERT_EQ(filter->asBlur(), nullptr);
  ASSERT_EQ(filter->asDilate(), nullptr);
  ASSERT_EQ(filter->asErode(), nullptr);
  ASSERT_EQ(filter->asMatrix(), nullptr);
  ASSERT_EQ(filter->asCompose(), nullptr);
  ASSERT_EQ(filter->asColorFilter(), nullptr);
}

TEST(DisplayListImageFilter, FromSkiaColorFilterImageFilter) {
  sk_sp<SkColorFilter> sk_color_filter =
      SkColorFilters::Blend(SK_ColorRED, SkBlendMode::kSrcIn);
  sk_sp<SkImageFilter> sk_image_filter =
      SkImageFilters::ColorFilter(sk_color_filter, nullptr);
  std::shared_ptr<DlImageFilter> filter = DlImageFilter::From(sk_image_filter);
  DlBlendColorFilter dl_color_filter(DlColor::kRed(), DlBlendMode::kSrcIn);
  DlColorFilterImageFilter dl_image_filter(dl_color_filter.shared());

  ASSERT_EQ(filter->type(), DlImageFilterType::kColorFilter);

  ASSERT_TRUE(*filter->asColorFilter() == dl_image_filter);
  ASSERT_EQ(*filter.get(), dl_image_filter);
  ASSERT_EQ(*filter->asColorFilter()->color_filter(), dl_color_filter);

  ASSERT_EQ(filter->asBlur(), nullptr);
  ASSERT_EQ(filter->asDilate(), nullptr);
  ASSERT_EQ(filter->asErode(), nullptr);
  ASSERT_EQ(filter->asMatrix(), nullptr);
  ASSERT_EQ(filter->asCompose(), nullptr);
  ASSERT_NE(filter->asColorFilter(), nullptr);
}

// SkRect::contains treats the rect as a half-open interval which is
// appropriate for so many operations. Unfortunately, we are using
// it here to test containment of the corners of a transformed quad
// so the corners of the quad that are measured against the right
// and bottom edges are contained even if they are on the right or
// bottom edge. This method does the "all sides inclusive" version
// of SkRect::contains.
static bool containsInclusive(const SkRect rect, const SkPoint p) {
  // Test with a slight offset of 1E-9 to "forgive" IEEE bit-rounding
  // Ending up with bounds that are off by 1E-9 (these numbers are all
  // being tested in device space with this method) will be off by a
  // negligible amount of a pixel that wouldn't contribute to changing
  // the color of a pixel.
  return (p.fX >= rect.fLeft - 1E-9 &&   //
          p.fX <= rect.fRight + 1E-9 &&  //
          p.fY >= rect.fTop - 1E-9 &&    //
          p.fY <= rect.fBottom + 1E-9);
}

static bool containsInclusive(const SkRect rect, const SkPoint quad[4]) {
  return (containsInclusive(rect, quad[0]) &&  //
          containsInclusive(rect, quad[1]) &&  //
          containsInclusive(rect, quad[2]) &&  //
          containsInclusive(rect, quad[3]));
}

static bool containsInclusive(const SkIRect rect, const SkPoint quad[4]) {
  return containsInclusive(SkRect::Make(rect), quad);
}

static bool containsInclusive(const SkIRect rect, const SkRect bounds) {
  return (bounds.fLeft >= rect.fLeft - 1E-9 &&
          bounds.fTop >= rect.fTop - 1E-9 &&
          bounds.fRight <= rect.fRight + 1E-9 &&
          bounds.fBottom <= rect.fBottom + 1E-9);
}

// Used to verify that the expected output bounds and revers engineered
// "input bounds for output bounds" rectangles are included in the rectangle
// returned from the various bounds computation methods under the specified
// matrix.
static void TestBoundsWithMatrix(const DlImageFilter& filter,
                                 const SkMatrix& matrix,
                                 const SkRect& sourceBounds,
                                 const SkPoint expectedLocalOutputQuad[4]) {
  SkRect deviceInputBounds = matrix.mapRect(sourceBounds);
  SkPoint expectedDeviceOutputQuad[4];
  matrix.mapPoints(expectedDeviceOutputQuad, expectedLocalOutputQuad, 4);

  SkIRect deviceFilterIBounds;
  ASSERT_EQ(filter.map_device_bounds(deviceInputBounds.roundOut(), matrix,
                                     deviceFilterIBounds),
            &deviceFilterIBounds);
  ASSERT_TRUE(containsInclusive(deviceFilterIBounds, expectedDeviceOutputQuad));

  SkIRect reverseInputIBounds;
  ASSERT_EQ(filter.get_input_device_bounds(deviceFilterIBounds, matrix,
                                           reverseInputIBounds),
            &reverseInputIBounds);
  ASSERT_TRUE(containsInclusive(reverseInputIBounds, deviceInputBounds));
}

static void TestInvalidBounds(const DlImageFilter& filter,
                              const SkMatrix& matrix,
                              const SkRect& localInputBounds) {
  SkIRect deviceInputBounds = matrix.mapRect(localInputBounds).roundOut();

  SkRect localFilterBounds;
  ASSERT_EQ(filter.map_local_bounds(localInputBounds, localFilterBounds),
            nullptr);
  ASSERT_EQ(localFilterBounds, localInputBounds);

  SkIRect deviceFilterIBounds;
  ASSERT_EQ(
      filter.map_device_bounds(deviceInputBounds, matrix, deviceFilterIBounds),
      nullptr);
  ASSERT_EQ(deviceFilterIBounds, deviceInputBounds);

  SkIRect reverseInputIBounds;
  ASSERT_EQ(filter.get_input_device_bounds(deviceInputBounds, matrix,
                                           reverseInputIBounds),
            nullptr);
  ASSERT_EQ(reverseInputIBounds, deviceInputBounds);
}

// localInputBounds is a sample bounds for testing as input to the filter.
// localExpectOutputBounds is the theoretical output bounds for applying
// the filter to the localInputBounds.
// localExpectInputBounds is the theoretical input bounds required for the
// filter to cover the localExpectOutputBounds
// If either of the expected bounds are nullptr then the bounds methods will
// be assumed to be unable to perform their computations for the given
// image filter and will be returning null.
static void TestBounds(const DlImageFilter& filter,
                       const SkRect& sourceBounds,
                       const SkPoint expectedLocalOutputQuad[4]) {
  SkRect localFilterBounds;
  ASSERT_EQ(filter.map_local_bounds(sourceBounds, localFilterBounds),
            &localFilterBounds);
  ASSERT_TRUE(containsInclusive(localFilterBounds, expectedLocalOutputQuad));

  for (int scale = 1; scale <= 4; scale++) {
    for (int skew = 0; skew < 8; skew++) {
      for (int degrees = 0; degrees <= 360; degrees += 15) {
        SkMatrix matrix;
        matrix.setScale(scale, scale);
        matrix.postSkew(skew / 8.0, skew / 8.0);
        matrix.postRotate(degrees);
        ASSERT_TRUE(matrix.invert(nullptr));
        TestBoundsWithMatrix(filter, matrix, sourceBounds,
                             expectedLocalOutputQuad);
        matrix.setPerspX(0.01);
        matrix.setPerspY(0.01);
        ASSERT_TRUE(matrix.invert(nullptr));
        TestBoundsWithMatrix(filter, matrix, sourceBounds,
                             expectedLocalOutputQuad);
      }
    }
  }
}

static void TestBounds(const DlImageFilter& filter,
                       const SkRect& sourceBounds,
                       const SkRect& expectedLocalOutputBounds) {
  SkPoint expectedLocalOutputQuad[4];
  expectedLocalOutputBounds.toQuad(expectedLocalOutputQuad);
  TestBounds(filter, sourceBounds, expectedLocalOutputQuad);
}

TEST(DisplayListImageFilter, BlurConstructor) {
  DlBlurImageFilter filter(5.0, 6.0, DlTileMode::kMirror);
}

TEST(DisplayListImageFilter, BlurShared) {
  DlBlurImageFilter filter(5.0, 6.0, DlTileMode::kMirror);

  ASSERT_NE(filter.shared().get(), &filter);
  ASSERT_EQ(*filter.shared(), filter);
}

TEST(DisplayListImageFilter, BlurAsBlur) {
  DlBlurImageFilter filter(5.0, 6.0, DlTileMode::kMirror);

  ASSERT_NE(filter.asBlur(), nullptr);
  ASSERT_EQ(filter.asBlur(), &filter);
}

TEST(DisplayListImageFilter, BlurContents) {
  DlBlurImageFilter filter(5.0, 6.0, DlTileMode::kMirror);

  ASSERT_EQ(filter.sigma_x(), 5.0);
  ASSERT_EQ(filter.sigma_y(), 6.0);
  ASSERT_EQ(filter.tile_mode(), DlTileMode::kMirror);
}

TEST(DisplayListImageFilter, BlurEquals) {
  DlBlurImageFilter filter1(5.0, 6.0, DlTileMode::kMirror);
  DlBlurImageFilter filter2(5.0, 6.0, DlTileMode::kMirror);

  TestEquals(filter1, filter2);
}

TEST(DisplayListImageFilter, BlurNotEquals) {
  DlBlurImageFilter filter1(5.0, 6.0, DlTileMode::kMirror);
  DlBlurImageFilter filter2(7.0, 6.0, DlTileMode::kMirror);
  DlBlurImageFilter filter3(5.0, 8.0, DlTileMode::kMirror);
  DlBlurImageFilter filter4(5.0, 6.0, DlTileMode::kRepeat);

  TestNotEquals(filter1, filter2, "Sigma X differs");
  TestNotEquals(filter1, filter3, "Sigma Y differs");
  TestNotEquals(filter1, filter4, "Tile Mode differs");
}

TEST(DisplayListImageFilter, BlurBounds) {
  DlBlurImageFilter filter = DlBlurImageFilter(5, 10, DlTileMode::kDecal);
  SkRect inputBounds = SkRect::MakeLTRB(20, 20, 80, 80);
  SkRect expectOutputBounds = inputBounds.makeOutset(15, 30);
  // SkRect expectInputBounds = expectOutputBounds.makeOutset(15, 30);
  TestBounds(filter, inputBounds, expectOutputBounds);
}

TEST(DisplayListImageFilter, DilateConstructor) {
  DlDilateImageFilter filter(5.0, 6.0);
}

TEST(DisplayListImageFilter, DilateShared) {
  DlDilateImageFilter filter(5.0, 6.0);

  ASSERT_NE(filter.shared().get(), &filter);
  ASSERT_EQ(*filter.shared(), filter);
}

TEST(DisplayListImageFilter, DilateAsDilate) {
  DlDilateImageFilter filter(5.0, 6.0);

  ASSERT_NE(filter.asDilate(), nullptr);
  ASSERT_EQ(filter.asDilate(), &filter);
}

TEST(DisplayListImageFilter, DilateContents) {
  DlDilateImageFilter filter(5.0, 6.0);

  ASSERT_EQ(filter.radius_x(), 5.0);
  ASSERT_EQ(filter.radius_y(), 6.0);
}

TEST(DisplayListImageFilter, DilateEquals) {
  DlDilateImageFilter filter1(5.0, 6.0);
  DlDilateImageFilter filter2(5.0, 6.0);

  TestEquals(filter1, filter2);
}

TEST(DisplayListImageFilter, DilateNotEquals) {
  DlDilateImageFilter filter1(5.0, 6.0);
  DlDilateImageFilter filter2(7.0, 6.0);
  DlDilateImageFilter filter3(5.0, 8.0);

  TestNotEquals(filter1, filter2, "Radius X differs");
  TestNotEquals(filter1, filter3, "Radius Y differs");
}

TEST(DisplayListImageFilter, DilateBounds) {
  DlDilateImageFilter filter = DlDilateImageFilter(5, 10);
  SkRect inputBounds = SkRect::MakeLTRB(20, 20, 80, 80);
  SkRect expectOutputBounds = inputBounds.makeOutset(5, 10);
  TestBounds(filter, inputBounds, expectOutputBounds);
}

TEST(DisplayListImageFilter, ErodeConstructor) {
  DlErodeImageFilter filter(5.0, 6.0);
}

TEST(DisplayListImageFilter, ErodeShared) {
  DlErodeImageFilter filter(5.0, 6.0);

  ASSERT_NE(filter.shared().get(), &filter);
  ASSERT_EQ(*filter.shared(), filter);
}

TEST(DisplayListImageFilter, ErodeAsErode) {
  DlErodeImageFilter filter(5.0, 6.0);

  ASSERT_NE(filter.asErode(), nullptr);
  ASSERT_EQ(filter.asErode(), &filter);
}

TEST(DisplayListImageFilter, ErodeContents) {
  DlErodeImageFilter filter(5.0, 6.0);

  ASSERT_EQ(filter.radius_x(), 5.0);
  ASSERT_EQ(filter.radius_y(), 6.0);
}

TEST(DisplayListImageFilter, ErodeEquals) {
  DlErodeImageFilter filter1(5.0, 6.0);
  DlErodeImageFilter filter2(5.0, 6.0);

  TestEquals(filter1, filter2);
}

TEST(DisplayListImageFilter, ErodeNotEquals) {
  DlErodeImageFilter filter1(5.0, 6.0);
  DlErodeImageFilter filter2(7.0, 6.0);
  DlErodeImageFilter filter3(5.0, 8.0);

  TestNotEquals(filter1, filter2, "Radius X differs");
  TestNotEquals(filter1, filter3, "Radius Y differs");
}

TEST(DisplayListImageFilter, ErodeBounds) {
  DlErodeImageFilter filter = DlErodeImageFilter(5, 10);
  SkRect inputBounds = SkRect::MakeLTRB(20, 20, 80, 80);
  SkRect expectOutputBounds = inputBounds.makeInset(5, 10);
  TestBounds(filter, inputBounds, expectOutputBounds);
}

TEST(DisplayListImageFilter, MatrixConstructor) {
  DlMatrixImageFilter filter(SkMatrix::MakeAll(2.0, 0.0, 10,  //
                                               0.5, 3.0, 15,  //
                                               0.0, 0.0, 1),
                             DlImageSampling::kLinear);
}

TEST(DisplayListImageFilter, MatrixShared) {
  DlMatrixImageFilter filter(SkMatrix::MakeAll(2.0, 0.0, 10,  //
                                               0.5, 3.0, 15,  //
                                               0.0, 0.0, 1),
                             DlImageSampling::kLinear);

  ASSERT_NE(filter.shared().get(), &filter);
  ASSERT_EQ(*filter.shared(), filter);
}

TEST(DisplayListImageFilter, MatrixAsMatrix) {
  DlMatrixImageFilter filter(SkMatrix::MakeAll(2.0, 0.0, 10,  //
                                               0.5, 3.0, 15,  //
                                               0.0, 0.0, 1),
                             DlImageSampling::kLinear);

  ASSERT_NE(filter.asMatrix(), nullptr);
  ASSERT_EQ(filter.asMatrix(), &filter);
}

TEST(DisplayListImageFilter, MatrixContents) {
  SkMatrix matrix = SkMatrix::MakeAll(2.0, 0.0, 10,  //
                                      0.5, 3.0, 15,  //
                                      0.0, 0.0, 1);
  DlMatrixImageFilter filter(matrix, DlImageSampling::kLinear);

  ASSERT_EQ(filter.matrix(), matrix);
  ASSERT_EQ(filter.sampling(), DlImageSampling::kLinear);
}

TEST(DisplayListImageFilter, MatrixEquals) {
  SkMatrix matrix = SkMatrix::MakeAll(2.0, 0.0, 10,  //
                                      0.5, 3.0, 15,  //
                                      0.0, 0.0, 1);
  DlMatrixImageFilter filter1(matrix, DlImageSampling::kLinear);
  DlMatrixImageFilter filter2(matrix, DlImageSampling::kLinear);

  TestEquals(filter1, filter2);
}

TEST(DisplayListImageFilter, MatrixNotEquals) {
  SkMatrix matrix1 = SkMatrix::MakeAll(2.0, 0.0, 10,  //
                                       0.5, 3.0, 15,  //
                                       0.0, 0.0, 1);
  SkMatrix matrix2 = SkMatrix::MakeAll(5.0, 0.0, 10,  //
                                       0.5, 3.0, 15,  //
                                       0.0, 0.0, 1);
  DlMatrixImageFilter filter1(matrix1, DlImageSampling::kLinear);
  DlMatrixImageFilter filter2(matrix2, DlImageSampling::kLinear);
  DlMatrixImageFilter filter3(matrix1, DlImageSampling::kNearestNeighbor);

  TestNotEquals(filter1, filter2, "Matrix differs");
  TestNotEquals(filter1, filter3, "Sampling differs");
}

TEST(DisplayListImageFilter, MatrixBounds) {
  SkMatrix matrix = SkMatrix::MakeAll(2.0, 0.0, 10,  //
                                      0.5, 3.0, 7,   //
                                      0.0, 0.0, 1);
  SkMatrix inverse;
  ASSERT_TRUE(matrix.invert(&inverse));
  DlMatrixImageFilter filter(matrix, DlImageSampling::kLinear);
  SkRect inputBounds = SkRect::MakeLTRB(20, 20, 80, 80);
  SkPoint expectedOutputQuad[4] = {
      {50, 77},    // (20,20) => (20*2 + 10, 20/2 + 20*3 + 7) == (50, 77)
      {50, 257},   // (20,80) => (20*2 + 10, 20/2 + 80*3 + 7) == (50, 257)
      {170, 287},  // (80,80) => (80*2 + 10, 80/2 + 80*3 + 7) == (170, 287)
      {170, 107},  // (80,20) => (80*2 + 10, 80/2 + 20*3 + 7) == (170, 107)
  };
  TestBounds(filter, inputBounds, expectedOutputQuad);
}

TEST(DisplayListImageFilter, ComposeConstructor) {
  DlMatrixImageFilter outer(SkMatrix::MakeAll(2.0, 0.0, 10,  //
                                              0.5, 3.0, 15,  //
                                              0.0, 0.0, 1),
                            DlImageSampling::kLinear);
  DlBlurImageFilter inner(5.0, 6.0, DlTileMode::kMirror);
  DlComposeImageFilter filter(outer, inner);
}

TEST(DisplayListImageFilter, ComposeShared) {
  DlMatrixImageFilter outer(SkMatrix::MakeAll(2.0, 0.0, 10,  //
                                              0.5, 3.0, 15,  //
                                              0.0, 0.0, 1),
                            DlImageSampling::kLinear);
  DlBlurImageFilter inner(5.0, 6.0, DlTileMode::kMirror);
  DlComposeImageFilter filter(outer, inner);

  ASSERT_NE(filter.shared().get(), &filter);
  ASSERT_EQ(*filter.shared(), filter);
}

TEST(DisplayListImageFilter, ComposeAsCompose) {
  DlMatrixImageFilter outer(SkMatrix::MakeAll(2.0, 0.0, 10,  //
                                              0.5, 3.0, 15,  //
                                              0.0, 0.0, 1),
                            DlImageSampling::kLinear);
  DlBlurImageFilter inner(5.0, 6.0, DlTileMode::kMirror);
  DlComposeImageFilter filter(outer, inner);

  ASSERT_NE(filter.asCompose(), nullptr);
  ASSERT_EQ(filter.asCompose(), &filter);
}

TEST(DisplayListImageFilter, ComposeContents) {
  DlMatrixImageFilter outer(SkMatrix::MakeAll(2.0, 0.0, 10,  //
                                              0.5, 3.0, 15,  //
                                              0.0, 0.0, 1),
                            DlImageSampling::kLinear);
  DlBlurImageFilter inner(5.0, 6.0, DlTileMode::kMirror);
  DlComposeImageFilter filter(outer, inner);

  ASSERT_EQ(*filter.outer().get(), outer);
  ASSERT_EQ(*filter.inner().get(), inner);
}

TEST(DisplayListImageFilter, ComposeEquals) {
  DlMatrixImageFilter outer1(SkMatrix::MakeAll(2.0, 0.0, 10,  //
                                               0.5, 3.0, 15,  //
                                               0.0, 0.0, 1),
                             DlImageSampling::kLinear);
  DlBlurImageFilter inner1(5.0, 6.0, DlTileMode::kMirror);
  DlComposeImageFilter filter1(outer1, inner1);

  DlMatrixImageFilter outer2(SkMatrix::MakeAll(2.0, 0.0, 10,  //
                                               0.5, 3.0, 15,  //
                                               0.0, 0.0, 1),
                             DlImageSampling::kLinear);
  DlBlurImageFilter inner2(5.0, 6.0, DlTileMode::kMirror);
  DlComposeImageFilter filter2(outer1, inner1);

  TestEquals(filter1, filter2);
}

TEST(DisplayListImageFilter, ComposeNotEquals) {
  DlMatrixImageFilter outer1(SkMatrix::MakeAll(2.0, 0.0, 10,  //
                                               0.5, 3.0, 15,  //
                                               0.0, 0.0, 1),
                             DlImageSampling::kLinear);
  DlBlurImageFilter inner1(5.0, 6.0, DlTileMode::kMirror);

  DlMatrixImageFilter outer2(SkMatrix::MakeAll(5.0, 0.0, 10,  //
                                               0.5, 3.0, 15,  //
                                               0.0, 0.0, 1),
                             DlImageSampling::kLinear);
  DlBlurImageFilter inner2(7.0, 6.0, DlTileMode::kMirror);

  DlComposeImageFilter filter1(outer1, inner1);
  DlComposeImageFilter filter2(outer2, inner1);
  DlComposeImageFilter filter3(outer1, inner2);

  TestNotEquals(filter1, filter2, "Outer differs");
  TestNotEquals(filter1, filter3, "Inner differs");
}

TEST(DisplayListImageFilter, ComposeBounds) {
  DlDilateImageFilter outer = DlDilateImageFilter(5, 10);
  DlBlurImageFilter inner = DlBlurImageFilter(12, 5, DlTileMode::kDecal);
  DlComposeImageFilter filter = DlComposeImageFilter(outer, inner);
  SkRect inputBounds = SkRect::MakeLTRB(20, 20, 80, 80);
  SkRect expectOutputBounds = inputBounds.makeOutset(36, 15).makeOutset(5, 10);
  TestBounds(filter, inputBounds, expectOutputBounds);
}

TEST(DisplayListImageFilter, ColorFilterConstructor) {
  DlBlendColorFilter dl_color_filter(DlColor::kRed(), DlBlendMode::kLighten);
  DlColorFilterImageFilter filter(dl_color_filter);
}

TEST(DisplayListImageFilter, ColorFilterShared) {
  DlBlendColorFilter dl_color_filter(DlColor::kRed(), DlBlendMode::kLighten);
  DlColorFilterImageFilter filter(dl_color_filter);

  ASSERT_EQ(*filter.shared(), filter);
}

TEST(DisplayListImageFilter, ColorFilterAsColorFilter) {
  DlBlendColorFilter dl_color_filter(DlColor::kRed(), DlBlendMode::kLighten);
  DlColorFilterImageFilter filter(dl_color_filter);

  ASSERT_NE(filter.asColorFilter(), nullptr);
  ASSERT_EQ(filter.asColorFilter(), &filter);
}

TEST(DisplayListImageFilter, ColorFilterContents) {
  DlBlendColorFilter dl_color_filter(DlColor::kRed(), DlBlendMode::kLighten);
  DlColorFilterImageFilter filter(dl_color_filter);

  ASSERT_EQ(*filter.color_filter().get(), dl_color_filter);
}

TEST(DisplayListImageFilter, ColorFilterEquals) {
  DlBlendColorFilter dl_color_filter1(DlColor::kRed(), DlBlendMode::kLighten);
  DlColorFilterImageFilter filter1(dl_color_filter1);

  DlBlendColorFilter dl_color_filter2(DlColor::kRed(), DlBlendMode::kLighten);
  DlColorFilterImageFilter filter2(dl_color_filter2);

  TestEquals(filter1, filter2);
}

TEST(DisplayListImageFilter, ColorFilterNotEquals) {
  DlBlendColorFilter dl_color_filter1(DlColor::kRed(), DlBlendMode::kLighten);
  DlColorFilterImageFilter filter1(dl_color_filter1);

  DlBlendColorFilter dl_color_filter2(DlColor::kBlue(), DlBlendMode::kLighten);
  DlColorFilterImageFilter filter2(dl_color_filter2);

  DlBlendColorFilter dl_color_filter3(DlColor::kRed(), DlBlendMode::kDarken);
  DlColorFilterImageFilter filter3(dl_color_filter3);

  TestNotEquals(filter1, filter2, "Color differs");
  TestNotEquals(filter1, filter3, "Blend Mode differs");
}

TEST(DisplayListImageFilter, ColorFilterBounds) {
  DlBlendColorFilter dl_color_filter(DlColor::kRed(), DlBlendMode::kSrcIn);
  DlColorFilterImageFilter filter(dl_color_filter);
  SkRect inputBounds = SkRect::MakeLTRB(20, 20, 80, 80);
  TestBounds(filter, inputBounds, inputBounds);
}

TEST(DisplayListImageFilter, ColorFilterModifiesTransparencyBounds) {
  DlBlendColorFilter dl_color_filter(DlColor::kRed(), DlBlendMode::kSrcOver);
  DlColorFilterImageFilter filter(dl_color_filter);
  SkRect inputBounds = SkRect::MakeLTRB(20, 20, 80, 80);
  TestInvalidBounds(filter, SkMatrix::I(), inputBounds);
}

TEST(DisplayListImageFilter, UnknownConstructor) {
  DlUnknownImageFilter filter(
      SkImageFilters::Blur(5.0, 6.0, SkTileMode::kRepeat, nullptr));
}

TEST(DisplayListImageFilter, UnknownShared) {
  DlUnknownImageFilter filter(
      SkImageFilters::Blur(5.0, 6.0, SkTileMode::kRepeat, nullptr));

  ASSERT_NE(filter.shared().get(), &filter);
  ASSERT_EQ(*filter.shared(), filter);
}

TEST(DisplayListImageFilter, UnknownContents) {
  sk_sp<SkImageFilter> sk_filter =
      SkImageFilters::Blur(5.0, 6.0, SkTileMode::kRepeat, nullptr);
  DlUnknownImageFilter filter(sk_filter);

  ASSERT_EQ(filter.skia_object(), sk_filter);
  ASSERT_EQ(filter.skia_object().get(), sk_filter.get());
}

TEST(DisplayListImageFilter, UnknownEquals) {
  sk_sp<SkImageFilter> sk_filter =
      SkImageFilters::Blur(5.0, 6.0, SkTileMode::kRepeat, nullptr);

  DlUnknownImageFilter filter1(sk_filter);
  DlUnknownImageFilter filter2(sk_filter);

  TestEquals(filter1, filter2);
}

TEST(DisplayListImageFilter, UnknownNotEquals) {
  DlUnknownImageFilter filter1(
      SkImageFilters::Blur(5.0, 6.0, SkTileMode::kRepeat, nullptr));
  DlUnknownImageFilter filter2(
      SkImageFilters::Blur(5.0, 6.0, SkTileMode::kRepeat, nullptr));

  // Even though the filter is the same, it is a different instance
  // and we cannot currently tell them apart because the Skia
  // ImageFilter objects do not implement ==
  TestNotEquals(filter1, filter2, "SkImageFilter instance differs");
}

}  // namespace testing
}  // namespace flutter
