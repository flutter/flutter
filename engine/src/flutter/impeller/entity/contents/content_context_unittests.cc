// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/content_context.h"

#include <memory>
#include <string>
#include <string_view>
#include <unordered_set>
#include <vector>

#include "gmock/gmock.h"
#include "gtest/gtest.h"
#include "impeller/base/comparable.h"
#include "impeller/base/promise.h"
#include "impeller/renderer/capabilities.h"
#include "impeller/renderer/pipeline.h"
#include "impeller/renderer/pipeline_descriptor.h"
#include "impeller/renderer/testing/mocks.h"

namespace impeller {
namespace testing {

namespace {

using ::testing::_;
using ::testing::AtLeast;
using ::testing::Contains;
using ::testing::NiceMock;
using ::testing::Return;
using ::testing::ReturnRef;

PipelineFuture<PipelineDescriptor> MakeRealizedPipelineFuture(
    PipelineDescriptor descriptor) {
  return {
      std::move(descriptor),
      RealizedFuture<std::shared_ptr<Pipeline<PipelineDescriptor>>>(nullptr)};
}

/// A context with no GPU behind it. It resolves every shader and hands out a
/// mock pipeline library that records each pipeline requested from it.
class ContentContextTest : public ::testing::Test {
 public:
  void SetUp() override {
    capabilities_ =
        CapabilitiesBuilder()
            .SetDefaultColorFormat(PixelFormat::kR8G8B8A8UNormInt)
            .SetDefaultDepthStencilFormat(PixelFormat::kD24UnormS8Uint)
            .SetDefaultGlyphAtlasFormat(PixelFormat::kA8UNormInt)
            .Build();
    ON_CALL(*context_, IsValid()).WillByDefault(Return(true));
    ON_CALL(*context_, GetBackendType())
        .WillByDefault(Return(Context::BackendType::kVulkan));
    ON_CALL(*context_, GetCapabilities())
        .WillByDefault(ReturnRef(capabilities_));
    ON_CALL(*context_, GetShaderLibrary())
        .WillByDefault(Return(shader_library_));
    ON_CALL(*context_, GetPipelineLibrary())
        .WillByDefault(Return(pipeline_library_));
    // Resolve every entrypoint, as if every shader had been compiled in.
    ON_CALL(*shader_library_, GetFunction(_, _))
        .WillByDefault([](std::string_view name, ShaderStage stage) {
          return std::make_shared<MockShaderFunction>(std::string(name), stage);
        });
    ON_CALL(*pipeline_library_, GetPipeline(_, _, _))
        .WillByDefault([this](PipelineDescriptor descriptor, bool /*async*/,
                              bool /*threadsafe*/) {
          requested_.push_back(descriptor);
          return MakeRealizedPipelineFuture(std::move(descriptor));
        });
  }

 protected:
  std::shared_ptr<const Capabilities> capabilities_;
  std::shared_ptr<NiceMock<MockShaderLibrary>> shader_library_ =
      std::make_shared<NiceMock<MockShaderLibrary>>();
  std::shared_ptr<NiceMock<MockPipelineLibrary>> pipeline_library_ =
      std::make_shared<NiceMock<MockPipelineLibrary>>();
  std::shared_ptr<NiceMock<MockImpellerContext>> context_ =
      std::make_shared<NiceMock<MockImpellerContext>>();
  /// Every descriptor requested from `pipeline_library_`, in order.
  std::vector<PipelineDescriptor> requested_;
};

}  // namespace

TEST_F(ContentContextTest, WarmDefaultPipelinesRequestsDefaultPipelines) {
  ContentContext::WarmDefaultPipelines(*context_);

  std::vector<std::string> labels;
  for (const PipelineDescriptor& descriptor : requested_) {
    labels.emplace_back(descriptor.GetLabel());
  }
  EXPECT_THAT(labels, Contains("SolidFill Pipeline"));
  EXPECT_THAT(labels, Contains("GlyphAtlas Pipeline"));
  EXPECT_THAT(labels, Contains("TextureFill Pipeline"));
}

TEST_F(ContentContextTest, WarmDefaultPipelinesRequestsPipelinesAsync) {
  // Compiling synchronously would stall the calling thread, and on OpenGL ES
  // would need a context to be current on it.
  EXPECT_CALL(*pipeline_library_, GetPipeline(_, /*async=*/false, _)).Times(0);
  EXPECT_CALL(*pipeline_library_, GetPipeline(_, /*async=*/true, _))
      .Times(AtLeast(1));

  ContentContext::WarmDefaultPipelines(*context_);
}

TEST_F(ContentContextTest, WarmDefaultPipelinesRequestsEachPipelineOnce) {
  ContentContext::WarmDefaultPipelines(*context_);

  ASSERT_FALSE(requested_.empty());
  std::unordered_set<PipelineDescriptor, ComparableHash<PipelineDescriptor>,
                     ComparableEqual<PipelineDescriptor>>
      unique(requested_.begin(), requested_.end());
  EXPECT_EQ(unique.size(), requested_.size());
}

TEST_F(ContentContextTest, WarmDefaultPipelinesDoesNoGpuWork) {
  // Embedders call this before there is a surface, when no rendering context
  // may be current. It must only request pipelines.
  EXPECT_CALL(*context_, GetResourceAllocator()).Times(0);
  EXPECT_CALL(*context_, CreateCommandBuffer()).Times(0);
  EXPECT_CALL(*context_, GetCommandQueue()).Times(0);

  ContentContext::WarmDefaultPipelines(*context_);

  EXPECT_FALSE(requested_.empty());
}

TEST_F(ContentContextTest, WarmDefaultPipelinesIgnoresInvalidContext) {
  ON_CALL(*context_, IsValid()).WillByDefault(Return(false));
  EXPECT_CALL(*pipeline_library_, GetPipeline(_, _, _)).Times(0);

  ContentContext::WarmDefaultPipelines(*context_);
}

}  // namespace testing
}  // namespace impeller
