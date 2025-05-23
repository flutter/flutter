// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/fixtures/spec_constant.frag.h"
#include "impeller/fixtures/spec_constant.vert.h"
#include "impeller/playground/playground_test.h"
#include "impeller/renderer/backend/gles/handle_gles.h"
#include "impeller/renderer/backend/gles/pipeline_gles.h"
#include "impeller/renderer/backend/gles/pipeline_library_gles.h"
#include "impeller/renderer/pipeline_library.h"

namespace impeller::testing {

using PipelineLibraryGLESTest = PlaygroundTest;
INSTANTIATE_OPENGLES_PLAYGROUND_SUITE(PipelineLibraryGLESTest);

// NOLINTBEGIN(bugprone-unchecked-optional-access)
TEST_P(PipelineLibraryGLESTest, ProgramHandlesAreReused) {
  using VS = SpecConstantVertexShader;
  using FS = SpecConstantFragmentShader;
  auto context = GetContext();
  ASSERT_TRUE(context);
  auto desc = PipelineBuilder<VS, FS>::MakeDefaultPipelineDescriptor(*context);
  ASSERT_TRUE(desc.has_value());
  auto pipeline = context->GetPipelineLibrary()->GetPipeline(desc).Get();
  ASSERT_TRUE(pipeline && pipeline->IsValid());
  auto new_desc = desc;
  // Changing the sample counts should not result in a new program object.
  new_desc->SetSampleCount(SampleCount::kCount4);
  // Make sure we don't hit the top-level descriptor cache. This will cause
  // caching irrespective of backends.
  ASSERT_FALSE(desc->IsEqual(new_desc.value()));
  auto new_pipeline =
      context->GetPipelineLibrary()->GetPipeline(new_desc).Get();
  ASSERT_TRUE(new_pipeline && new_pipeline->IsValid());
  const auto& pipeline_gles = PipelineGLES::Cast(*pipeline);
  const auto& new_pipeline_gles = PipelineGLES::Cast(*new_pipeline);
  // The program handles should be live and equal.
  ASSERT_FALSE(pipeline_gles.GetProgramHandle().IsDead());
  ASSERT_FALSE(new_pipeline_gles.GetProgramHandle().IsDead());
  ASSERT_EQ(pipeline_gles.GetProgramHandle().GetName().value(),
            new_pipeline_gles.GetProgramHandle().GetName().value());
}

TEST_P(PipelineLibraryGLESTest, ChangingSpecConstantsCausesNewProgramObject) {
  using VS = SpecConstantVertexShader;
  using FS = SpecConstantFragmentShader;
  auto context = GetContext();
  ASSERT_TRUE(context);
  auto desc = PipelineBuilder<VS, FS>::MakeDefaultPipelineDescriptor(*context);
  ASSERT_TRUE(desc.has_value());
  desc->SetSpecializationConstants({2.0f});
  auto pipeline = context->GetPipelineLibrary()->GetPipeline(desc).Get();
  ASSERT_TRUE(pipeline && pipeline->IsValid());
  auto new_desc = desc;
  // Changing the spec. constants should result in a new program object.
  new_desc->SetSpecializationConstants({4.0f});
  auto new_pipeline =
      context->GetPipelineLibrary()->GetPipeline(new_desc).Get();
  ASSERT_TRUE(new_pipeline && new_pipeline->IsValid());
  const auto& pipeline_gles = PipelineGLES::Cast(*pipeline);
  const auto& new_pipeline_gles = PipelineGLES::Cast(*new_pipeline);
  // The program handles should be live and equal.
  ASSERT_FALSE(pipeline_gles.GetProgramHandle().IsDead());
  ASSERT_FALSE(new_pipeline_gles.GetProgramHandle().IsDead());
  ASSERT_FALSE(pipeline_gles.GetProgramHandle().GetName().value() ==
               new_pipeline_gles.GetProgramHandle().GetName().value());
}

TEST_P(PipelineLibraryGLESTest, ClearingPipelineWillAlsoClearProgramHandle) {
  using VS = SpecConstantVertexShader;
  using FS = SpecConstantFragmentShader;
  std::shared_ptr<Context> context = GetContext();
  std::optional<PipelineDescriptor> desc =
      PipelineBuilder<VS, FS>::MakeDefaultPipelineDescriptor(*context);

  std::shared_ptr<Pipeline<PipelineDescriptor>> pipeline =
      context->GetPipelineLibrary()->GetPipeline(desc).Get();
  ASSERT_TRUE(pipeline && pipeline->IsValid());
  const auto& pipeline_gles = PipelineGLES::Cast(*pipeline);
  HandleGLES handle = pipeline_gles.GetProgramHandle();

  // Clear the pipeline descriptor.
  auto entrypoint =
      pipeline->GetDescriptor().GetEntrypointForStage(ShaderStage::kFragment);
  context->GetPipelineLibrary()->RemovePipelinesWithEntryPoint(entrypoint);

  // Re-create the pipeline
  std::shared_ptr<Pipeline<PipelineDescriptor>> pipeline_2 =
      context->GetPipelineLibrary()->GetPipeline(desc).Get();
  ASSERT_TRUE(pipeline && pipeline->IsValid());
  const auto& pipeline_gles_2 = PipelineGLES::Cast(*pipeline_2);
  HandleGLES handle_2 = pipeline_gles_2.GetProgramHandle();

  EXPECT_FALSE(HandleGLES::Equal{}(handle, handle_2));
}
// NOLINTEND(bugprone-unchecked-optional-access)

}  // namespace impeller::testing
