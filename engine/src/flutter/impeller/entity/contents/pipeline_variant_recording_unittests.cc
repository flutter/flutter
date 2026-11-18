// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/pipeline_variant_recording.h"

#include <memory>
#include <vector>

#include "gtest/gtest.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/entity_playground.h"

namespace impeller {
namespace testing {

using PipelineVariantRecordingTest = EntityPlayground;
INSTANTIATE_PLAYGROUND_SUITE(PipelineVariantRecordingTest);

namespace {

/// Installs a pipeline variant observer that keeps what it is told, and
/// removes it again however the test ends.
class ScopedObserver {
 public:
  ScopedObserver() {
    SetPipelineVariantObserver(
        [this](const Context& /*context*/,
               const std::vector<RecordedPipelineVariant>& variants) {
          reports_.push_back(variants);
        });
  }

  ~ScopedObserver() { SetPipelineVariantObserver({}); }

  /// The variants of each `ContentContext` that reported, in order.
  const std::vector<std::vector<RecordedPipelineVariant>>& GetReports() const {
    return reports_;
  }

 private:
  std::vector<std::vector<RecordedPipelineVariant>> reports_;

  ScopedObserver(const ScopedObserver&) = delete;

  ScopedObserver& operator=(const ScopedObserver&) = delete;
};

/// Options that no `ContentContext` warms a solid fill pipeline with.
ContentContextOptions MakeLazyOptions(const Context& context) {
  ContentContextOptions options;
  options.color_attachment_pixel_format =
      context.GetCapabilities()->GetDefaultColorFormat();
  options.blend_mode = BlendMode::kXor;
  return options;
}

}  // namespace

TEST_P(PipelineVariantRecordingTest, ReportsWarmedAndLazyVariantsOnce) {
  if (!IMPELLER_PIPELINE_VARIANT_RECORDER_IS_SUPPORTED()) {
    GTEST_SKIP() << "Pipeline variant recording is only in debug builds.";
  }
  ScopedObserver observer;
  const ContentContextOptions lazy_options = MakeLazyOptions(*GetContext());
  {
    ContentContext content_context(GetContext(), GetTypographerContext());
    ASSERT_TRUE(content_context.IsValid());
    EXPECT_TRUE(content_context.GetSolidFillPipeline(lazy_options));
    // A variant that already exists is not recorded again.
    EXPECT_TRUE(content_context.GetSolidFillPipeline(lazy_options));
    EXPECT_TRUE(observer.GetReports().empty());
  }

  ASSERT_EQ(observer.GetReports().size(), 1u);
  size_t warmed_solid_fill = 0u;
  size_t lazy_solid_fill = 0u;
  for (const RecordedPipelineVariant& variant : observer.GetReports()[0]) {
    if (!variant.descriptor.GetLabel().starts_with("SolidFill")) {
      continue;
    }
    if (variant.warmed) {
      warmed_solid_fill++;
    } else {
      lazy_solid_fill++;
      EXPECT_EQ(variant.options.ToKey(), lazy_options.ToKey());
    }
  }
  EXPECT_EQ(warmed_solid_fill, 1u);
  EXPECT_EQ(lazy_solid_fill, 1u);
}

TEST_P(PipelineVariantRecordingTest, IgnoresContextsCreatedWithoutObserver) {
  if (!IMPELLER_PIPELINE_VARIANT_RECORDER_IS_SUPPORTED()) {
    GTEST_SKIP() << "Pipeline variant recording is only in debug builds.";
  }
  auto content_context =
      std::make_unique<ContentContext>(GetContext(), GetTypographerContext());
  ASSERT_TRUE(content_context->IsValid());

  ScopedObserver observer;
  EXPECT_TRUE(
      content_context->GetSolidFillPipeline(MakeLazyOptions(*GetContext())));
  content_context.reset();

  EXPECT_TRUE(observer.GetReports().empty());
}

TEST_P(PipelineVariantRecordingTest, ReportsEachContextSeparately) {
  if (!IMPELLER_PIPELINE_VARIANT_RECORDER_IS_SUPPORTED()) {
    GTEST_SKIP() << "Pipeline variant recording is only in debug builds.";
  }
  ScopedObserver observer;
  auto first =
      std::make_unique<ContentContext>(GetContext(), GetTypographerContext());
  auto second =
      std::make_unique<ContentContext>(GetContext(), GetTypographerContext());
  ASSERT_TRUE(first->IsValid());
  ASSERT_TRUE(second->IsValid());
  // Only the first context creates a lazy variant.
  EXPECT_TRUE(first->GetSolidFillPipeline(MakeLazyOptions(*GetContext())));

  second.reset();
  first.reset();

  ASSERT_EQ(observer.GetReports().size(), 2u);
  auto count_lazy = [](const std::vector<RecordedPipelineVariant>& variants) {
    size_t lazy = 0u;
    for (const RecordedPipelineVariant& variant : variants) {
      if (!variant.warmed &&
          variant.descriptor.GetLabel().starts_with("SolidFill")) {
        lazy++;
      }
    }
    return lazy;
  };
  EXPECT_EQ(count_lazy(observer.GetReports()[0]), 0u);
  EXPECT_EQ(count_lazy(observer.GetReports()[1]), 1u);
}

}  // namespace testing
}  // namespace impeller
