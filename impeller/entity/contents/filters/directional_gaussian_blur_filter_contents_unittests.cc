// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/testing.h"
#include "gmock/gmock.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/contents/filters/directional_gaussian_blur_filter_contents.h"
#include "impeller/entity/entity_playground.h"
#include "impeller/renderer/testing/mocks.h"

namespace impeller {
namespace testing {

using ::testing::Return;

namespace {

Scalar CalculateSigmaForBlurRadius(Scalar blur_radius) {
  // See Sigma.h
  return (blur_radius / kKernelRadiusPerSigma) + 0.5;
}
}  // namespace

class DirectionalGaussianBlurFilterContentsTest : public EntityPlayground {
 public:
  // Stubs in the minimal support to make rendering pass.
  void SetupMinimalMockContext() {
    // This mocking code was removed since it wasn't strictly needed yet. If it
    // is needed you can find it here:
    // https://gist.github.com/gaaclarke/c2f6bf5fc6ecb10678da03789abc5843.
  }
};

INSTANTIATE_PLAYGROUND_SUITE(DirectionalGaussianBlurFilterContentsTest);

TEST_P(DirectionalGaussianBlurFilterContentsTest, CoverageWithEffectTransform) {
  TextureDescriptor desc = {
      .format = PixelFormat::kB8G8R8A8UNormInt,
      .size = ISize(100, 100),
  };
  Scalar sigma_radius_1 = CalculateSigmaForBlurRadius(1.0);
  auto contents = std::make_unique<DirectionalGaussianBlurFilterContents>();
  contents->SetSigma(Sigma{sigma_radius_1});
  contents->SetDirection({1.0, 0.0});
  std::shared_ptr<Texture> texture =
      GetContentContext()->GetContext()->GetResourceAllocator()->CreateTexture(
          desc);
  FilterInput::Vector inputs = {FilterInput::Make(texture)};
  Entity entity;
  entity.SetTransformation(Matrix::MakeTranslation({100, 100, 0}));
  std::optional<Rect> coverage = contents->GetFilterCoverage(
      inputs, entity, /*effect_transform=*/Matrix::MakeScale({2.0, 2.0, 1.0}));
  EXPECT_TRUE(coverage.has_value());
  if (coverage.has_value()) {
    EXPECT_NEAR(coverage->GetLeft(), 100 - 2,
                0.5);  // Higher tolerance for sigma scaling.
    EXPECT_NEAR(coverage->GetTop(), 100, 0.01);
    EXPECT_NEAR(coverage->GetRight(), 200 + 2,
                0.5);  // Higher tolerance for sigma scaling.
    EXPECT_NEAR(coverage->GetBottom(), 200, 0.01);
  }
}

TEST(DirectionalGaussianBlurFilterContentsTest, FilterSourceCoverage) {
  Scalar sigma_radius_1 = CalculateSigmaForBlurRadius(1.0);
  auto contents = std::make_unique<DirectionalGaussianBlurFilterContents>();
  contents->SetSigma(Sigma{sigma_radius_1});
  contents->SetDirection({1.0, 0.0});
  std::optional<Rect> coverage = contents->GetFilterSourceCoverage(
      /*effect_transform=*/Matrix::MakeScale({2.0, 2.0, 1.0}),
      /*output_limit=*/Rect::MakeLTRB(100, 100, 200, 200));
  ASSERT_EQ(coverage, Rect::MakeLTRB(100 - 2, 100, 200 + 2, 200));
}

TEST_P(DirectionalGaussianBlurFilterContentsTest, RenderNoCoverage) {
  Scalar sigma_radius_1 = CalculateSigmaForBlurRadius(1.0);
  auto contents = std::make_unique<DirectionalGaussianBlurFilterContents>();
  contents->SetSigma(Sigma{sigma_radius_1});
  contents->SetDirection({1.0, 0.0});
  std::shared_ptr<ContentContext> renderer = GetContentContext();
  Entity entity;
  Rect coverage_hint = Rect::MakeLTRB(0, 0, 0, 0);
  std::optional<Entity> result =
      contents->GetEntity(*renderer, entity, coverage_hint);
  ASSERT_FALSE(result.has_value());
}

TEST_P(DirectionalGaussianBlurFilterContentsTest,
       RenderCoverageMatchesGetCoverage) {
  TextureDescriptor desc = {
      .format = PixelFormat::kB8G8R8A8UNormInt,
      .size = ISize(100, 100),
  };
  std::shared_ptr<Texture> texture =
      GetContentContext()->GetContext()->GetResourceAllocator()->CreateTexture(
          desc);
  Scalar sigma_radius_1 = CalculateSigmaForBlurRadius(1.0);
  auto contents = std::make_unique<DirectionalGaussianBlurFilterContents>();
  contents->SetSigma(Sigma{sigma_radius_1});
  contents->SetDirection({1.0, 0.0});
  contents->SetInputs({FilterInput::Make(texture)});
  std::shared_ptr<ContentContext> renderer = GetContentContext();

  Entity entity;
  std::optional<Entity> result =
      contents->GetEntity(*renderer, entity, /*coverage_hint=*/{});
  EXPECT_TRUE(result.has_value());
  if (result.has_value()) {
    EXPECT_EQ(result.value().GetBlendMode(), BlendMode::kSourceOver);
    std::optional<Rect> result_coverage = result.value().GetCoverage();
    std::optional<Rect> contents_coverage = contents->GetCoverage(entity);
    EXPECT_TRUE(result_coverage.has_value());
    EXPECT_TRUE(contents_coverage.has_value());
    if (result_coverage.has_value() && contents_coverage.has_value()) {
      EXPECT_NEAR(result_coverage.value().GetLeft(),
                  contents_coverage.value().GetLeft(), kEhCloseEnough);
      EXPECT_NEAR(result_coverage.value().GetTop(),
                  contents_coverage.value().GetTop(), kEhCloseEnough);
      EXPECT_NEAR(result_coverage.value().GetRight(),
                  contents_coverage.value().GetRight(), kEhCloseEnough);
      EXPECT_NEAR(result_coverage.value().GetBottom(),
                  contents_coverage.value().GetBottom(), kEhCloseEnough);
    }
  }
}

}  // namespace testing
}  // namespace impeller
