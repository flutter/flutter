// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/dl_blend_mode.h"
#include "flutter/display_list/dl_color.h"
#include "flutter/display_list/dl_sampling_options.h"
#include "flutter/display_list/dl_tile_mode.h"
#include "flutter/display_list/effects/dl_color_filter.h"
#include "flutter/display_list/effects/dl_image_filter.h"
#include "flutter/display_list/testing/dl_test_equality.h"
#include "flutter/display_list/utils/dl_comparable.h"
#include "gtest/gtest.h"

#include "third_party/skia/include/effects/SkImageFilters.h"

namespace flutter {
namespace testing {

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

// Used to verify that the expected output bounds and reverse-engineered
// "input bounds for output bounds" rectangles are included in the rectangle
// returned from the various bounds computation methods under the specified
// matrix.
static void TestBoundsWithMatrix(const DlImageFilter& filter,
                                 const SkMatrix& matrix,
                                 const SkRect& sourceBounds,
                                 const SkPoint expectedLocalOutputQuad[4]) {
  SkRect device_input_bounds = matrix.mapRect(sourceBounds);
  SkPoint expected_output_quad[4];
  matrix.mapPoints(expected_output_quad, expectedLocalOutputQuad, 4);

  SkIRect device_filter_ibounds;
  ASSERT_EQ(filter.map_device_bounds(device_input_bounds.roundOut(), matrix,
                                     device_filter_ibounds),
            &device_filter_ibounds);
  ASSERT_TRUE(containsInclusive(device_filter_ibounds, expected_output_quad));

  SkIRect reverse_input_ibounds;
  ASSERT_EQ(filter.get_input_device_bounds(device_filter_ibounds, matrix,
                                           reverse_input_ibounds),
            &reverse_input_ibounds);
  ASSERT_TRUE(containsInclusive(reverse_input_ibounds, device_input_bounds));
}

static void TestInvalidBounds(const DlImageFilter& filter,
                              const SkMatrix& matrix,
                              const SkRect& localInputBounds) {
  SkIRect device_input_bounds = matrix.mapRect(localInputBounds).roundOut();

  SkRect local_filter_bounds;
  ASSERT_EQ(filter.map_local_bounds(localInputBounds, local_filter_bounds),
            nullptr);
  ASSERT_EQ(local_filter_bounds, localInputBounds);

  SkIRect device_filter_ibounds;
  ASSERT_EQ(filter.map_device_bounds(device_input_bounds, matrix,
                                     device_filter_ibounds),
            nullptr);
  ASSERT_EQ(device_filter_ibounds, device_input_bounds);

  SkIRect reverse_input_ibounds;
  ASSERT_EQ(filter.get_input_device_bounds(device_input_bounds, matrix,
                                           reverse_input_ibounds),
            nullptr);
  ASSERT_EQ(reverse_input_ibounds, device_input_bounds);
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
  SkRect local_filter_bounds;
  ASSERT_EQ(filter.map_local_bounds(sourceBounds, local_filter_bounds),
            &local_filter_bounds);
  ASSERT_TRUE(containsInclusive(local_filter_bounds, expectedLocalOutputQuad));

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
        matrix.setPerspX(0.001);
        matrix.setPerspY(0.001);
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
  SkPoint expected_local_output_quad[4];
  expectedLocalOutputBounds.toQuad(expected_local_output_quad);
  TestBounds(filter, sourceBounds, expected_local_output_quad);
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

TEST(DisplayListImageFilter, BlurWithLocalMatrixEquals) {
  DlBlurImageFilter filter1(5.0, 6.0, DlTileMode::kMirror);
  DlBlurImageFilter filter2(5.0, 6.0, DlTileMode::kMirror);

  SkMatrix local_matrix = SkMatrix::Translate(10, 10);
  TestEquals(*filter1.makeWithLocalMatrix(local_matrix),
             *filter2.makeWithLocalMatrix(local_matrix));
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
  SkRect input_bounds = SkRect::MakeLTRB(20, 20, 80, 80);
  SkRect expected_output_bounds = input_bounds.makeOutset(15, 30);
  TestBounds(filter, input_bounds, expected_output_bounds);
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

TEST(DisplayListImageFilter, DilateWithLocalMatrixEquals) {
  DlDilateImageFilter filter1(5.0, 6.0);
  DlDilateImageFilter filter2(5.0, 6.0);

  SkMatrix local_matrix = SkMatrix::Translate(10, 10);
  TestEquals(*filter1.makeWithLocalMatrix(local_matrix),
             *filter2.makeWithLocalMatrix(local_matrix));
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
  SkRect input_bounds = SkRect::MakeLTRB(20, 20, 80, 80);
  SkRect expected_output_bounds = input_bounds.makeOutset(5, 10);
  TestBounds(filter, input_bounds, expected_output_bounds);
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

TEST(DisplayListImageFilter, ErodeWithLocalMatrixEquals) {
  DlErodeImageFilter filter1(5.0, 6.0);
  DlErodeImageFilter filter2(5.0, 6.0);

  SkMatrix local_matrix = SkMatrix::Translate(10, 10);
  TestEquals(*filter1.makeWithLocalMatrix(local_matrix),
             *filter2.makeWithLocalMatrix(local_matrix));
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
  SkRect input_bounds = SkRect::MakeLTRB(20, 20, 80, 80);
  SkRect expected_output_bounds = input_bounds.makeInset(5, 10);
  TestBounds(filter, input_bounds, expected_output_bounds);
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

TEST(DisplayListImageFilter, MatrixWithLocalMatrixEquals) {
  SkMatrix matrix = SkMatrix::MakeAll(2.0, 0.0, 10,  //
                                      0.5, 3.0, 15,  //
                                      0.0, 0.0, 1);
  DlMatrixImageFilter filter1(matrix, DlImageSampling::kLinear);
  DlMatrixImageFilter filter2(matrix, DlImageSampling::kLinear);

  SkMatrix local_matrix = SkMatrix::Translate(10, 10);
  TestEquals(*filter1.makeWithLocalMatrix(local_matrix),
             *filter2.makeWithLocalMatrix(local_matrix));
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
  SkRect input_bounds = SkRect::MakeLTRB(20, 20, 80, 80);
  SkPoint expectedOutputQuad[4] = {
      {50, 77},    // (20,20) => (20*2 + 10, 20/2 + 20*3 + 7) == (50, 77)
      {50, 257},   // (20,80) => (20*2 + 10, 20/2 + 80*3 + 7) == (50, 257)
      {170, 287},  // (80,80) => (80*2 + 10, 80/2 + 80*3 + 7) == (170, 287)
      {170, 107},  // (80,20) => (80*2 + 10, 80/2 + 20*3 + 7) == (170, 107)
  };
  TestBounds(filter, input_bounds, expectedOutputQuad);
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

TEST(DisplayListImageFilter, ComposeWithLocalMatrixEquals) {
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

  SkMatrix local_matrix = SkMatrix::Translate(10, 10);
  TestEquals(*filter1.makeWithLocalMatrix(local_matrix),
             *filter2.makeWithLocalMatrix(local_matrix));
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
  SkRect input_bounds = SkRect::MakeLTRB(20, 20, 80, 80);
  SkRect expected_output_bounds =
      input_bounds.makeOutset(36, 15).makeOutset(5, 10);
  TestBounds(filter, input_bounds, expected_output_bounds);
}

static void TestUnboundedBounds(DlImageFilter& filter,
                                const SkRect& sourceBounds,
                                const SkRect& expectedOutputBounds,
                                const SkRect& expectedInputBounds) {
  SkRect bounds;
  EXPECT_EQ(filter.map_local_bounds(sourceBounds, bounds), nullptr);
  EXPECT_EQ(bounds, expectedOutputBounds);

  SkIRect ibounds;
  EXPECT_EQ(
      filter.map_device_bounds(sourceBounds.roundOut(), SkMatrix::I(), ibounds),
      nullptr);
  EXPECT_EQ(ibounds, expectedOutputBounds.roundOut());

  EXPECT_EQ(filter.get_input_device_bounds(sourceBounds.roundOut(),
                                           SkMatrix::I(), ibounds),
            nullptr);
  EXPECT_EQ(ibounds, expectedInputBounds.roundOut());
}

TEST(DisplayListImageFilter, ComposeBoundsWithUnboundedInner) {
  auto input_bounds = SkRect::MakeLTRB(20, 20, 80, 80);
  auto expected_bounds = SkRect::MakeLTRB(5, 2, 95, 98);

  DlBlendColorFilter color_filter(DlColor::kRed(), DlBlendMode::kSrcOver);
  auto outer = DlBlurImageFilter(5.0, 6.0, DlTileMode::kRepeat);
  auto inner = DlColorFilterImageFilter(color_filter.shared());
  auto composed = DlComposeImageFilter(outer.shared(), inner.shared());

  TestUnboundedBounds(composed, input_bounds, expected_bounds, expected_bounds);
}

TEST(DisplayListImageFilter, ComposeBoundsWithUnboundedOuter) {
  auto input_bounds = SkRect::MakeLTRB(20, 20, 80, 80);
  auto expected_bounds = SkRect::MakeLTRB(5, 2, 95, 98);

  DlBlendColorFilter color_filter(DlColor::kRed(), DlBlendMode::kSrcOver);
  auto outer = DlColorFilterImageFilter(color_filter.shared());
  auto inner = DlBlurImageFilter(5.0, 6.0, DlTileMode::kRepeat);
  auto composed = DlComposeImageFilter(outer.shared(), inner.shared());

  TestUnboundedBounds(composed, input_bounds, expected_bounds, expected_bounds);
}

TEST(DisplayListImageFilter, ComposeBoundsWithUnboundedInnerAndOuter) {
  auto input_bounds = SkRect::MakeLTRB(20, 20, 80, 80);
  auto expected_bounds = input_bounds;

  DlBlendColorFilter color_filter1(DlColor::kRed(), DlBlendMode::kSrcOver);
  DlBlendColorFilter color_filter2(DlColor::kBlue(), DlBlendMode::kSrcOver);
  auto outer = DlColorFilterImageFilter(color_filter1.shared());
  auto inner = DlColorFilterImageFilter(color_filter2.shared());
  auto composed = DlComposeImageFilter(outer.shared(), inner.shared());

  TestUnboundedBounds(composed, input_bounds, expected_bounds, expected_bounds);
}

// See https://github.com/flutter/flutter/issues/108433
TEST(DisplayListImageFilter, Issue108433) {
  auto input_bounds = SkIRect::MakeLTRB(20, 20, 80, 80);

  auto sk_filter = SkColorFilters::Blend(SK_ColorRED, SkBlendMode::kSrcOver);
  auto sk_outer = SkImageFilters::Blur(5.0, 6.0, SkTileMode::kRepeat, nullptr);
  auto sk_inner = SkImageFilters::ColorFilter(sk_filter, nullptr);
  auto sk_compose = SkImageFilters::Compose(sk_outer, sk_inner);

  DlBlendColorFilter dl_color_filter(DlColor::kRed(), DlBlendMode::kSrcOver);
  auto dl_outer = DlBlurImageFilter(5.0, 6.0, DlTileMode::kRepeat);
  auto dl_inner = DlColorFilterImageFilter(dl_color_filter.shared());
  auto dl_compose = DlComposeImageFilter(dl_outer, dl_inner);

  auto sk_bounds = sk_compose->filterBounds(
      input_bounds, SkMatrix::I(),
      SkImageFilter::MapDirection::kForward_MapDirection);

  SkIRect dl_bounds;
  EXPECT_EQ(
      dl_compose.map_device_bounds(input_bounds, SkMatrix::I(), dl_bounds),
      nullptr);
  ASSERT_EQ(dl_bounds, sk_bounds);
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

TEST(DisplayListImageFilter, ColorFilterWithLocalMatrixEquals) {
  DlBlendColorFilter dl_color_filter1(DlColor::kRed(), DlBlendMode::kLighten);
  DlColorFilterImageFilter filter1(dl_color_filter1);

  DlBlendColorFilter dl_color_filter2(DlColor::kRed(), DlBlendMode::kLighten);
  DlColorFilterImageFilter filter2(dl_color_filter2);

  SkMatrix local_matrix = SkMatrix::Translate(10, 10);
  TestEquals(*filter1.makeWithLocalMatrix(local_matrix),
             *filter2.makeWithLocalMatrix(local_matrix));
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
  SkRect input_bounds = SkRect::MakeLTRB(20, 20, 80, 80);
  TestBounds(filter, input_bounds, input_bounds);
}

TEST(DisplayListImageFilter, ColorFilterModifiesTransparencyBounds) {
  DlBlendColorFilter dl_color_filter(DlColor::kRed(), DlBlendMode::kSrcOver);
  DlColorFilterImageFilter filter(dl_color_filter);
  SkRect input_bounds = SkRect::MakeLTRB(20, 20, 80, 80);
  TestInvalidBounds(filter, SkMatrix::I(), input_bounds);
}

TEST(DisplayListImageFilter, LocalImageFilterBounds) {
  auto filter_matrix = SkMatrix::MakeAll(2.0, 0.0, 10,  //
                                         0.5, 3.0, 15,  //
                                         0.0, 0.0, 1);
  std::vector<sk_sp<SkImageFilter>> sk_filters{
      SkImageFilters::Blur(5.0, 6.0, SkTileMode::kRepeat, nullptr),
      SkImageFilters::ColorFilter(
          SkColorFilters::Blend(SK_ColorRED, SkBlendMode::kSrcOver), nullptr),
      SkImageFilters::Dilate(5.0, 10.0, nullptr),
      SkImageFilters::MatrixTransform(
          filter_matrix, SkSamplingOptions(SkFilterMode::kLinear), nullptr),
      SkImageFilters::Compose(
          SkImageFilters::Blur(5.0, 6.0, SkTileMode::kRepeat, nullptr),
          SkImageFilters::ColorFilter(
              SkColorFilters::Blend(SK_ColorRED, SkBlendMode::kSrcOver),
              nullptr))};

  DlBlendColorFilter dl_color_filter(DlColor::kRed(), DlBlendMode::kSrcOver);
  std::vector<std::shared_ptr<DlImageFilter>> dl_filters{
      std::make_shared<DlBlurImageFilter>(5.0, 6.0, DlTileMode::kRepeat),
      std::make_shared<DlColorFilterImageFilter>(dl_color_filter.shared()),
      std::make_shared<DlDilateImageFilter>(5, 10),
      std::make_shared<DlMatrixImageFilter>(filter_matrix,
                                            DlImageSampling::kLinear),
      std::make_shared<DlComposeImageFilter>(
          std::make_shared<DlBlurImageFilter>(5.0, 6.0, DlTileMode::kRepeat),
          std::make_shared<DlColorFilterImageFilter>(
              dl_color_filter.shared()))};

  auto persp = SkMatrix::I();
  persp.setPerspY(0.001);
  std::vector<SkMatrix> matrices = {
      SkMatrix::Translate(10.0, 10.0),
      SkMatrix::Scale(2.0, 2.0).preTranslate(10.0, 10.0),
      SkMatrix::RotateDeg(45).preTranslate(5.0, 5.0), persp};
  std::vector<SkMatrix> bounds_matrices{SkMatrix::Translate(5.0, 10.0),
                                        SkMatrix::Scale(2.0, 2.0)};

  for (unsigned i = 0; i < sk_filters.size(); i++) {
    for (unsigned j = 0; j < matrices.size(); j++) {
      for (unsigned k = 0; k < bounds_matrices.size(); k++) {
        auto& m = matrices[j];
        auto& bounds_matrix = bounds_matrices[k];
        auto sk_local_filter = sk_filters[i]->makeWithLocalMatrix(m);
        auto dl_local_filter = dl_filters[i]->makeWithLocalMatrix(m);
        if (!sk_local_filter || !dl_local_filter) {
          // Temporarily relax the equivalence testing to allow Skia to expand
          // their behavior. Once the Skia fixes are rolled in, the
          // DlImageFilter should adapt  to the new rules.
          // See https://github.com/flutter/flutter/issues/114723
          ASSERT_TRUE(sk_local_filter || !dl_local_filter);
          continue;
        }
        {
          auto input_bounds = SkIRect::MakeLTRB(20, 20, 80, 80);
          SkIRect sk_rect, dl_rect;
          sk_rect = sk_local_filter->filterBounds(
              input_bounds, bounds_matrix,
              SkImageFilter::MapDirection::kForward_MapDirection);
          dl_local_filter->map_device_bounds(input_bounds, bounds_matrix,
                                             dl_rect);
          ASSERT_EQ(sk_rect, dl_rect);
        }
        {
          // Test for: Know the outset bounds to get the inset bounds
          // Skia have some bounds calculate error of DilateFilter and
          // MatrixFilter
          // Skia issue: https://bugs.chromium.org/p/skia/issues/detail?id=13444
          // flutter issue: https://github.com/flutter/flutter/issues/108693
          if (i == 2 || i == 3) {
            continue;
          }
          auto outset_bounds = SkIRect::MakeLTRB(20, 20, 80, 80);
          SkIRect sk_rect, dl_rect;
          sk_rect = sk_local_filter->filterBounds(
              outset_bounds, bounds_matrix,
              SkImageFilter::MapDirection::kReverse_MapDirection);
          dl_local_filter->get_input_device_bounds(outset_bounds, bounds_matrix,
                                                   dl_rect);
          ASSERT_EQ(sk_rect, dl_rect);
        }
      }
    }
  }
}

}  // namespace testing
}  // namespace flutter
