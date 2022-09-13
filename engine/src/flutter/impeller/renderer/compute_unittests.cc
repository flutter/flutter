// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/time/time_point.h"
#include "flutter/testing/testing.h"
#include "impeller/base/strings.h"
#include "impeller/fixtures/sample.comp.h"
#include "impeller/playground/playground_test.h"
#include "impeller/renderer/command_buffer.h"
#include "impeller/renderer/compute_command.h"
#include "impeller/renderer/compute_pipeline_builder.h"
#include "impeller/renderer/formats.h"
#include "impeller/renderer/pipeline_library.h"

namespace impeller {
namespace testing {

using ComputeTest = PlaygroundTest;
INSTANTIATE_PLAYGROUND_SUITE(ComputeTest);

TEST_P(ComputeTest, CanCreateComputePass) {
  if (GetParam() == PlaygroundBackend::kOpenGLES) {
    GTEST_SKIP_("Compute is not supported on GL.");
  }
  if (GetParam() == PlaygroundBackend::kVulkan) {
    GTEST_SKIP_("Compute is not supported on Vulkan yet.");
  }

  using CS = SampleComputeShader;
  auto context = GetContext();
  ASSERT_TRUE(context);
  using SamplePipelineBuilder = ComputePipelineBuilder<CS>;
  auto pipeline_desc =
      SamplePipelineBuilder::MakeDefaultPipelineDescriptor(*context);
  ASSERT_TRUE(pipeline_desc.has_value());
  auto compute_pipeline =
      context->GetPipelineLibrary()->GetPipeline(pipeline_desc).get();
  ASSERT_TRUE(compute_pipeline);

  auto cmd_buffer = context->CreateCommandBuffer();
  auto pass = cmd_buffer->CreateComputePass();
  ASSERT_TRUE(pass && pass->IsValid());

  ComputeCommand cmd;
  cmd.label = "Compute";
  cmd.pipeline = compute_pipeline;

  std::vector<CS::Input0> input_0;
  std::vector<CS::Input1> input_1;
  input_0.push_back(CS::Input0{Vector4(2.0, 3.0, 4.0, 5.0)});
  input_1.push_back(CS::Input1{Vector4(6.0, 7.0, 8.0, 9.0)});

  std::vector<CS::Output> output(5);
  CS::BindInput0(cmd,
                 pass->GetTransientsBuffer().EmplaceStorageBuffer(input_0));
  CS::BindInput1(cmd,
                 pass->GetTransientsBuffer().EmplaceStorageBuffer(input_1));
  CS::BindOutput(cmd, pass->GetTransientsBuffer().EmplaceStorageBuffer(output));

  ASSERT_TRUE(pass->AddCommand(std::move(cmd)));
  ASSERT_TRUE(pass->EncodeCommands());
}

}  // namespace testing
}  // namespace impeller
