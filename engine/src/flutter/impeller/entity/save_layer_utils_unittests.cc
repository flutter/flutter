// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/testing.h"
#include "impeller/entity/contents/filters/filter_contents.h"
#include "impeller/entity/save_layer_utils.h"

// TODO(zanderso): https://github.com/flutter/flutter/issues/127701
// NOLINTBEGIN(bugprone-unchecked-optional-access)

namespace impeller {
namespace testing {

using SaveLayerUtilsTest = ::testing::Test;

namespace {
std::shared_ptr<FilterContents> MakeRuntimeEffectFilter(FilterInput::Ref input,
                                                        bool unclipped_input) {
  return FilterContents::MakeRuntimeEffect(
      std::move(input), /*runtime_stage=*/nullptr,
      std::make_shared<std::vector<uint8_t>>(), /*texture_inputs=*/{},
      unclipped_input);
}
}  // namespace

TEST(SaveLayerUtilsTest, SimplePaintComputedCoverage) {
  // Basic Case, simple paint, computed coverage
  auto coverage = ComputeSaveLayerCoverage(
      /*content_coverage=*/Rect::MakeLTRB(0, 0, 10, 10),    //
      /*effect_transform=*/{},                              //
      /*coverage_limit=*/Rect::MakeLTRB(0, 0, 2400, 1800),  //
      /*image_filter=*/nullptr                              //
  );
  ASSERT_TRUE(coverage.has_value());
  EXPECT_EQ(coverage.value(), Rect::MakeLTRB(0, 0, 10, 10));
}

TEST(SaveLayerUtilsTest, BackdropFiterComputedCoverage) {
  // Backdrop Filter, computed coverage
  auto coverage = ComputeSaveLayerCoverage(
      /*content_coverage=*/Rect::MakeLTRB(0, 0, 10, 10),    //
      /*effect_transform=*/{},                              //
      /*coverage_limit=*/Rect::MakeLTRB(0, 0, 2400, 1800),  //
      /*image_filter=*/nullptr,
      /*flood_output_coverage=*/false,  //
      /*flood_input_coverage=*/true     //
  );

  ASSERT_TRUE(coverage.has_value());
  EXPECT_EQ(coverage.value(), Rect::MakeLTRB(0, 0, 2400, 1800));
}

TEST(SaveLayerUtilsTest, ImageFiterComputedCoverage) {
  // Image Filter, computed coverage
  auto image_filter = FilterContents::MakeMatrixFilter(
      FilterInput::Make(Rect()), Matrix::MakeScale({2, 2, 1}), {});

  auto coverage = ComputeSaveLayerCoverage(
      /*content_coverage=*/Rect::MakeLTRB(0, 0, 10, 10),    //
      /*effect_transform=*/{},                              //
      /*coverage_limit=*/Rect::MakeLTRB(0, 0, 2400, 1800),  //
      /*image_filter=*/image_filter                         //
  );

  ASSERT_TRUE(coverage.has_value());
  EXPECT_EQ(coverage.value(), Rect::MakeLTRB(0, 0, 10, 10));
}

TEST(SaveLayerUtilsTest,
     ImageFiterSmallScaleComputedCoverageLargerThanBoundsLimit) {
  // Image Filter scaling large, computed coverage is larger than bounds limit.
  auto image_filter = FilterContents::MakeMatrixFilter(
      FilterInput::Make(Rect()), Matrix::MakeScale({2, 2, 1}), {});

  auto coverage = ComputeSaveLayerCoverage(
      /*content_coverage=*/Rect::MakeLTRB(0, 0, 10, 10),  //
      /*effect_transform=*/{},                            //
      /*coverage_limit=*/Rect::MakeLTRB(0, 0, 5, 5),      //
      /*image_filter=*/image_filter                       //
  );

  ASSERT_TRUE(coverage.has_value());
  EXPECT_EQ(coverage.value(), Rect::MakeLTRB(0, 0, 2.5, 2.5));
}

TEST(SaveLayerUtilsTest,
     ImageFiterLargeScaleComputedCoverageLargerThanBoundsLimit) {
  // Image Filter scaling small, computed coverage is larger than bounds limit.
  auto image_filter = FilterContents::MakeMatrixFilter(
      FilterInput::Make(Rect()), Matrix::MakeScale({0.5, 0.5, 1}), {});

  auto coverage = ComputeSaveLayerCoverage(
      /*content_coverage=*/Rect::MakeLTRB(0, 0, 10, 10),  //
      /*effect_transform=*/{},                            //
      /*coverage_limit=*/Rect::MakeLTRB(0, 0, 5, 5),      //
      /*image_filter=*/image_filter                       //
  );

  ASSERT_TRUE(coverage.has_value());
  EXPECT_EQ(coverage.value(), Rect::MakeLTRB(0, 0, 10, 10));
}

TEST(SaveLayerUtilsTest, DisjointCoverage) {
  // No intersection in coverage
  auto coverage = ComputeSaveLayerCoverage(
      /*content_coverage=*/Rect::MakeLTRB(200, 200, 210, 210),  //
      /*effect_transform=*/{},                                  //
      /*coverage_limit=*/Rect::MakeLTRB(0, 0, 100, 100),        //
      /*image_filter=*/nullptr                                  //
  );

  EXPECT_FALSE(coverage.has_value());
}

TEST(SaveLayerUtilsTest, DisjointCoverageTransformedByImageFilter) {
  // Coverage disjoint from parent coverage but transformed into parent space
  // with image filter.
  auto image_filter = FilterContents::MakeMatrixFilter(
      FilterInput::Make(Rect()), Matrix::MakeTranslation({-200, -200, 0}), {});

  auto coverage = ComputeSaveLayerCoverage(
      /*content_coverage=*/Rect::MakeLTRB(200, 200, 210, 210),  //
      /*effect_transform=*/{},                                  //
      /*coverage_limit=*/Rect::MakeLTRB(0, 0, 100, 100),        //
      /*image_filter=*/image_filter                             //
  );

  ASSERT_TRUE(coverage.has_value());
  EXPECT_EQ(coverage.value(), Rect::MakeLTRB(200, 200, 210, 210));
}

TEST(SaveLayerUtilsTest, DisjointCoveragTransformedByCTM) {
  // Coverage disjoint from parent coverage.
  Matrix ctm = Matrix::MakeTranslation({-200, -200, 0});
  auto coverage = ComputeSaveLayerCoverage(
      /*content_coverage=*/Rect::MakeLTRB(200, 200, 210, 210),  //
      /*effect_transform=*/ctm,                                 //
      /*coverage_limit=*/Rect::MakeLTRB(0, 0, 100, 100),        //
      /*image_filter=*/nullptr                                  //
  );

  ASSERT_TRUE(coverage.has_value());
  EXPECT_EQ(coverage.value(), Rect::MakeLTRB(0, 0, 10, 10));
}

TEST(SaveLayerUtilsTest, BasicEmptyCoverage) {
  auto coverage = ComputeSaveLayerCoverage(
      /*content_coverage=*/Rect::MakeLTRB(0, 0, 0, 0),      //
      /*effect_transform=*/{},                              //
      /*coverage_limit=*/Rect::MakeLTRB(0, 0, 2400, 1800),  //
      /*image_filter=*/nullptr                              //
  );

  ASSERT_FALSE(coverage.has_value());
}

TEST(SaveLayerUtilsTest, ImageFilterEmptyCoverage) {
  // Empty coverage with Image Filter
  auto image_filter = FilterContents::MakeMatrixFilter(
      FilterInput::Make(Rect()), Matrix::MakeTranslation({-200, -200, 0}), {});

  auto coverage = ComputeSaveLayerCoverage(
      /*content_coverage=*/Rect::MakeLTRB(0, 0, 0, 0),      //
      /*effect_transform=*/{},                              //
      /*coverage_limit=*/Rect::MakeLTRB(0, 0, 2400, 1800),  //
      /*image_filter=*/image_filter                         //
  );

  ASSERT_FALSE(coverage.has_value());
}

TEST(SaveLayerUtilsTest, BackdropFilterEmptyCoverage) {
  // Empty coverage with backdrop filter.
  auto coverage = ComputeSaveLayerCoverage(
      /*content_coverage=*/Rect::MakeLTRB(0, 0, 0, 0),      //
      /*effect_transform=*/{},                              //
      /*coverage_limit=*/Rect::MakeLTRB(0, 0, 2400, 1800),  //
      /*image_filter=*/nullptr,                             //
      /*flood_output_coverage=*/true                        //
  );

  ASSERT_TRUE(coverage.has_value());
  EXPECT_EQ(coverage.value(), Rect::MakeLTRB(0, 0, 2400, 1800));
}

TEST(SaveLayerUtilsTest, FloodInputCoverage) {
  auto coverage = ComputeSaveLayerCoverage(
      /*content_coverage=*/Rect::MakeLTRB(0, 0, 0, 0),      //
      /*effect_transform=*/{},                              //
      /*coverage_limit=*/Rect::MakeLTRB(0, 0, 2400, 1800),  //
      /*image_filter=*/nullptr,                             //
      /*flood_output_coverage=*/false,                      //
      /*flood_input_coverage=*/true                         //
  );

  ASSERT_TRUE(coverage.has_value());
  EXPECT_EQ(coverage.value(), Rect::MakeLTRB(0, 0, 2400, 1800));
}

TEST(SaveLayerUtilsTest, FloodInputCoverageWithImageFilter) {
  auto image_filter = FilterContents::MakeMatrixFilter(
      FilterInput::Make(Rect()), Matrix::MakeScale({0.5, 0.5, 1}), {});

  auto coverage = ComputeSaveLayerCoverage(
      /*content_coverage=*/Rect::MakeLTRB(0, 0, 0, 0),      //
      /*effect_transform=*/{},                              //
      /*coverage_limit=*/Rect::MakeLTRB(0, 0, 2400, 1800),  //
      /*image_filter=*/image_filter,                        //
      /*flood_output_coverage=*/false,                      //
      /*flood_input_coverage=*/true                         //
  );

  ASSERT_TRUE(coverage.has_value());
  EXPECT_EQ(coverage.value(), Rect::MakeLTRB(0, 0, 4800, 3600));
}

TEST(SaveLayerUtilsTest,
     FloodInputCoverageWithImageFilterWithNoCoverageProducesNoCoverage) {
  // Even if we flood the input coverage due to a bdf, we can still cull out the
  // layer if the image filter results in no coverage.
  auto image_filter = FilterContents::MakeMatrixFilter(
      FilterInput::Make(Rect()), Matrix::MakeScale({1, 1, 0}), {});

  auto coverage = ComputeSaveLayerCoverage(
      /*content_coverage=*/Rect::MakeLTRB(0, 0, 0, 0),      //
      /*effect_transform=*/{},                              //
      /*coverage_limit=*/Rect::MakeLTRB(0, 0, 2400, 1800),  //
      /*image_filter=*/image_filter,                        //
      /*flood_output_coverage=*/false,                      //
      /*flood_input_coverage=*/true                         //
  );

  ASSERT_FALSE(coverage.has_value());
}

TEST(
    SaveLayerUtilsTest,
    CoverageLimitIgnoredIfIntersectedValueIsCloseToActualCoverageSmallerWithImageFilter) {
  // Create an image filter that slightly shrinks the coverage limit
  auto image_filter = FilterContents::MakeMatrixFilter(
      FilterInput::Make(Rect()), Matrix::MakeScale({1.1, 1.1, 1}), {});

  auto coverage = ComputeSaveLayerCoverage(
      /*content_coverage=*/Rect::MakeLTRB(0, 0, 100, 100),  //
      /*effect_transform=*/{},                              //
      /*coverage_limit=*/Rect::MakeLTRB(0, 0, 100, 100),    //
      /*image_filter=*/image_filter                         //
  );

  ASSERT_TRUE(coverage.has_value());
  // The transfomed coverage limit is ((0, 0), (90.9091, 90.9091)).
  EXPECT_EQ(coverage.value(), Rect::MakeLTRB(0, 0, 100, 100));
}

TEST(
    SaveLayerUtilsTest,
    CoverageLimitIgnoredIfIntersectedValueIsCloseToActualCoverageLargerWithImageFilter) {
  // Create an image filter that slightly stretches the coverage limit. Even
  // without the special logic for using the original content coverage, we
  // verify that we don't introduce any artifacts from the intersection.
  auto image_filter = FilterContents::MakeMatrixFilter(
      FilterInput::Make(Rect()), Matrix::MakeScale({0.9, 0.9, 1}), {});

  auto coverage = ComputeSaveLayerCoverage(
      /*content_coverage=*/Rect::MakeLTRB(0, 0, 100, 100),  //
      /*effect_transform=*/{},                              //
      /*coverage_limit=*/Rect::MakeLTRB(0, 0, 100, 100),    //
      /*image_filter=*/image_filter                         //
  );

  ASSERT_TRUE(coverage.has_value());
  // The transfomed coverage limit is ((0, 0), (111.111, 111.111)).
  EXPECT_EQ(coverage.value(), Rect::MakeLTRB(0, 0, 100, 100));
}

TEST(SaveLayerUtilsTest,
     CoverageLimitRespectedIfSubstantiallyDifferentFromContentCoverage) {
  auto image_filter = FilterContents::MakeMatrixFilter(
      FilterInput::Make(Rect()), Matrix::MakeScale({2, 2, 1}), {});

  auto coverage = ComputeSaveLayerCoverage(
      /*content_coverage=*/Rect::MakeLTRB(0, 0, 1000, 1000),  //
      /*effect_transform=*/{},                                //
      /*coverage_limit=*/Rect::MakeLTRB(0, 0, 100, 100),      //
      /*image_filter=*/image_filter                           //
  );

  ASSERT_TRUE(coverage.has_value());
  EXPECT_EQ(coverage.value(), Rect::MakeLTRB(0, 0, 50, 50));
}

TEST(SaveLayerUtilsTest, RoundUpCoverageWhenCloseToCoverageLimit) {
  // X varies, translation is performed on coverage.
  auto coverage = ComputeSaveLayerCoverage(
      /*content_coverage=*/Rect::MakeLTRB(0, 0, 90, 90),  //
      /*effect_transform=*/{},                            //
      /*coverage_limit=*/Rect::MakeLTRB(0, 0, 100, 100),  //
      /*image_filter=*/nullptr                            //
  );

  ASSERT_TRUE(coverage.has_value());
  // Size that matches coverage limit
  EXPECT_EQ(coverage.value(), Rect::MakeLTRB(0, 0, 100, 100));
}

TEST(SaveLayerUtilsTest, DontRoundUpCoverageWhenNotCloseToCoverageLimitWidth) {
  // X varies, translation is performed on coverage.
  auto coverage = ComputeSaveLayerCoverage(
      /*content_coverage=*/Rect::MakeLTRB(0, 0, 50, 90),  //
      /*effect_transform=*/{},                            //
      /*coverage_limit=*/Rect::MakeLTRB(0, 0, 100, 100),  //
      /*image_filter=*/nullptr                            //
  );

  ASSERT_TRUE(coverage.has_value());
  // Size that matches coverage limit
  EXPECT_EQ(coverage.value(), Rect::MakeLTRB(0, 0, 50, 90));
}

TEST(SaveLayerUtilsTest, DontRoundUpCoverageWhenNotCloseToCoverageLimitHeight) {
  // X varies, translation is performed on coverage.
  auto coverage = ComputeSaveLayerCoverage(
      /*content_coverage=*/Rect::MakeLTRB(0, 0, 90, 50),  //
      /*effect_transform=*/{},                            //
      /*coverage_limit=*/Rect::MakeLTRB(0, 0, 100, 100),  //
      /*image_filter=*/nullptr                            //
  );

  ASSERT_TRUE(coverage.has_value());
  // Size that matches coverage limit
  EXPECT_EQ(coverage.value(), Rect::MakeLTRB(0, 0, 90, 50));
}

TEST(SaveLayerUtilsTest,
     DontRoundUpCoverageWhenNotCloseToCoverageLimitWidthHeight) {
  // X varies, translation is performed on coverage.
  auto coverage = ComputeSaveLayerCoverage(
      /*content_coverage=*/Rect::MakeLTRB(0, 0, 50, 50),  //
      /*effect_transform=*/{},                            //
      /*coverage_limit=*/Rect::MakeLTRB(0, 0, 100, 100),  //
      /*image_filter=*/nullptr                            //
  );

  ASSERT_TRUE(coverage.has_value());
  // Size that matches coverage limit
  EXPECT_EQ(coverage.value(), Rect::MakeLTRB(0, 0, 50, 50));
}

TEST(SaveLayerUtilsTest, RuntimeEffectFilterInputIsClippedByDefault) {
  // Content that is half outside of the coverage limit is trimmed to it.
  auto image_filter = MakeRuntimeEffectFilter(FilterInput::Make(Rect()),
                                              /*unclipped_input=*/false);

  auto coverage = ComputeSaveLayerCoverage(
      /*content_coverage=*/Rect::MakeLTRB(0, 0, 400, 400),         //
      /*effect_transform=*/Matrix::MakeTranslation({-200, 0, 0}),  //
      /*coverage_limit=*/Rect::MakeLTRB(0, 0, 2400, 1800),         //
      /*image_filter=*/image_filter                                //
  );

  ASSERT_TRUE(coverage.has_value());
  EXPECT_EQ(coverage.value(), Rect::MakeLTRB(0, 0, 200, 400));
}

TEST(SaveLayerUtilsTest, RuntimeEffectFilterWithUnclippedInputIsNotClipped) {
  auto image_filter = MakeRuntimeEffectFilter(FilterInput::Make(Rect()),
                                              /*unclipped_input=*/true);

  // Moving the content further outside of the coverage limit never changes
  // the size of the input.
  for (Scalar dx : {0.f, -100.f, -200.f, -350.f}) {
    auto coverage = ComputeSaveLayerCoverage(
        /*content_coverage=*/Rect::MakeLTRB(0, 0, 400, 400),       //
        /*effect_transform=*/Matrix::MakeTranslation({dx, 0, 0}),  //
        /*coverage_limit=*/Rect::MakeLTRB(0, 0, 2400, 1800),       //
        /*image_filter=*/image_filter                              //
    );

    ASSERT_TRUE(coverage.has_value());
    EXPECT_EQ(coverage.value(), Rect::MakeLTRB(dx, 0, dx + 400, 400));
  }
}

TEST(SaveLayerUtilsTest,
     RuntimeEffectFilterWithUnclippedInputAndUnboundedContent) {
  auto image_filter = MakeRuntimeEffectFilter(FilterInput::Make(Rect()),
                                              /*unclipped_input=*/true);

  // Unbounded content can't be allocated entirely, so the coverage limit is
  // used instead.
  auto coverage = ComputeSaveLayerCoverage(
      /*content_coverage=*/Rect::MakeMaximum(),             //
      /*effect_transform=*/{},                              //
      /*coverage_limit=*/Rect::MakeLTRB(0, 0, 2400, 1800),  //
      /*image_filter=*/image_filter                         //
  );

  ASSERT_TRUE(coverage.has_value());
  EXPECT_EQ(coverage.value(), Rect::MakeLTRB(0, 0, 2400, 1800));

  coverage = ComputeSaveLayerCoverage(
      /*content_coverage=*/Rect::MakeLTRB(0, 0, 10, 10),    //
      /*effect_transform=*/{},                              //
      /*coverage_limit=*/Rect::MakeLTRB(0, 0, 2400, 1800),  //
      /*image_filter=*/image_filter,                        //
      /*flood_output_coverage=*/false,                      //
      /*flood_input_coverage=*/true                         //
  );

  ASSERT_TRUE(coverage.has_value());
  EXPECT_EQ(coverage.value(), Rect::MakeLTRB(0, 0, 2400, 1800));
}

TEST(SaveLayerUtilsTest,
     RuntimeEffectFilterWithUnclippedInputAndFloodedOutput) {
  auto image_filter = MakeRuntimeEffectFilter(FilterInput::Make(Rect()),
                                              /*unclipped_input=*/true);

  auto coverage = ComputeSaveLayerCoverage(
      /*content_coverage=*/Rect::MakeLTRB(0, 0, 10, 10),    //
      /*effect_transform=*/{},                              //
      /*coverage_limit=*/Rect::MakeLTRB(0, 0, 2400, 1800),  //
      /*image_filter=*/image_filter,                        //
      /*flood_output_coverage=*/true                        //
  );

  ASSERT_TRUE(coverage.has_value());
  EXPECT_EQ(coverage.value(), Rect::MakeLTRB(0, 0, 2400, 1800));
}

TEST(SaveLayerUtilsTest,
     RuntimeEffectFilterWithUnclippedInputLargerThanMaxTextureSize) {
  auto image_filter = MakeRuntimeEffectFilter(FilterInput::Make(Rect()),
                                              /*unclipped_input=*/true);

  auto coverage = ComputeSaveLayerCoverage(
      /*content_coverage=*/Rect::MakeLTRB(0, 0, 5000, 400),        //
      /*effect_transform=*/Matrix::MakeTranslation({-200, 0, 0}),  //
      /*coverage_limit=*/Rect::MakeLTRB(0, 0, 2400, 1800),         //
      /*image_filter=*/image_filter,                               //
      /*flood_output_coverage=*/false,                             //
      /*flood_input_coverage=*/false,                              //
      /*max_texture_size=*/ISize(8192, 8192)                       //
  );

  ASSERT_TRUE(coverage.has_value());
  EXPECT_EQ(coverage.value(), Rect::MakeLTRB(-200, 0, 4800, 400));

  // The entire input would exceed the maximum texture size, so it falls back
  // to being trimmed by the coverage limit.
  coverage = ComputeSaveLayerCoverage(
      /*content_coverage=*/Rect::MakeLTRB(0, 0, 5000, 400),        //
      /*effect_transform=*/Matrix::MakeTranslation({-200, 0, 0}),  //
      /*coverage_limit=*/Rect::MakeLTRB(0, 0, 2400, 1800),         //
      /*image_filter=*/image_filter,                               //
      /*flood_output_coverage=*/false,                             //
      /*flood_input_coverage=*/false,                              //
      /*max_texture_size=*/ISize(4096, 4096)                       //
  );

  ASSERT_TRUE(coverage.has_value());
  EXPECT_EQ(coverage.value(), Rect::MakeLTRB(0, 0, 2400, 400));
}

TEST(SaveLayerUtilsTest,
     RuntimeEffectFilterWithUnclippedInputComposedWithMatrixFilter) {
  // A rotation with a small scale maps the maximum rect to non-finite values,
  // which must not leak into the computed coverage.
  Matrix matrix =
      Matrix::MakeRotationZ(Degrees(30)) * Matrix::MakeScale({0.25, 0.25, 1});

  // The runtime effect is the outer filter.
  auto inner_matrix_filter =
      FilterContents::MakeMatrixFilter(FilterInput::Make(Rect()), matrix, {});
  auto outer_runtime_filter = MakeRuntimeEffectFilter(
      FilterInput::Make(inner_matrix_filter), /*unclipped_input=*/true);

  auto coverage = ComputeSaveLayerCoverage(
      /*content_coverage=*/Rect::MakeLTRB(0, 0, 400, 400),         //
      /*effect_transform=*/Matrix::MakeTranslation({-200, 0, 0}),  //
      /*coverage_limit=*/Rect::MakeLTRB(0, 0, 2400, 1800),         //
      /*image_filter=*/outer_runtime_filter                        //
  );

  ASSERT_TRUE(coverage.has_value());
  EXPECT_EQ(coverage.value(), Rect::MakeLTRB(-200, 0, 200, 400));

  // The runtime effect is the inner filter.
  auto inner_runtime_filter = MakeRuntimeEffectFilter(FilterInput::Make(Rect()),
                                                      /*unclipped_input=*/true);
  auto outer_matrix_filter = FilterContents::MakeMatrixFilter(
      FilterInput::Make(inner_runtime_filter), matrix, {});

  coverage = ComputeSaveLayerCoverage(
      /*content_coverage=*/Rect::MakeLTRB(0, 0, 400, 400),         //
      /*effect_transform=*/Matrix::MakeTranslation({-200, 0, 0}),  //
      /*coverage_limit=*/Rect::MakeLTRB(0, 0, 2400, 1800),         //
      /*image_filter=*/outer_matrix_filter                         //
  );

  ASSERT_TRUE(coverage.has_value());
  EXPECT_EQ(coverage.value(), Rect::MakeLTRB(-200, 0, 200, 400));
}

TEST(SaveLayerUtilsTest, ImageFilterNeedsEntireInput) {
  Rect coverage_limit = Rect::MakeLTRB(0, 0, 2400, 1800);
  Matrix scale = Matrix::MakeScale({2, 2, 1});

  EXPECT_FALSE(ImageFilterNeedsEntireInput(nullptr, {}, coverage_limit));

  auto matrix_filter =
      FilterContents::MakeMatrixFilter(FilterInput::Make(Rect()), scale, {});
  EXPECT_FALSE(ImageFilterNeedsEntireInput(matrix_filter, {}, coverage_limit));

  auto clipped_filter = MakeRuntimeEffectFilter(FilterInput::Make(Rect()),
                                                /*unclipped_input=*/false);
  EXPECT_FALSE(ImageFilterNeedsEntireInput(clipped_filter, {}, coverage_limit));

  auto unclipped_filter = MakeRuntimeEffectFilter(FilterInput::Make(Rect()),
                                                  /*unclipped_input=*/true);
  EXPECT_TRUE(
      ImageFilterNeedsEntireInput(unclipped_filter, {}, coverage_limit));

  // The unclipped input is needed no matter where in a filter chain the
  // runtime effect is.
  auto matrix_outer = FilterContents::MakeMatrixFilter(
      FilterInput::Make(unclipped_filter), scale, {});
  EXPECT_TRUE(ImageFilterNeedsEntireInput(matrix_outer, {}, coverage_limit));

  auto runtime_effect_outer = MakeRuntimeEffectFilter(
      FilterInput::Make(matrix_filter), /*unclipped_input=*/true);
  EXPECT_TRUE(
      ImageFilterNeedsEntireInput(runtime_effect_outer, {}, coverage_limit));
}

}  // namespace testing
}  // namespace impeller

// NOLINTEND(bugprone-unchecked-optional-access)
