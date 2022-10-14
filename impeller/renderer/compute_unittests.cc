// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/synchronization/waitable_event.h"
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

  static constexpr size_t kCount = 5;

  pass->SetGridSize(ISize(kCount, 1));
  pass->SetThreadGroupSize(ISize(kCount, 1));

  ComputeCommand cmd;
  cmd.label = "Compute";
  cmd.pipeline = compute_pipeline;

  CS::Info info{.count = kCount};
  CS::Input0<kCount> input_0;
  CS::Input1<kCount> input_1;
  for (uint i = 0; i < kCount; i++) {
    input_0.elements[i] = Vector4(2.0 + i, 3.0 + i, 4.0 + i, 5.0 * i);
    input_1.elements[i] = Vector4(6.0, 7.0, 8.0, 9.0);
  }

  input_0.fixed_array[1] = IPoint32(2, 2);
  input_1.fixed_array[0] = UintPoint32(3, 3);
  input_0.some_int = 5;

  DeviceBufferDescriptor buffer_desc;
  buffer_desc.storage_mode = StorageMode::kHostVisible;
  buffer_desc.size = sizeof(CS::Output<kCount>);

  auto output_buffer =
      context->GetResourceAllocator()->CreateBuffer(buffer_desc);
  output_buffer->SetLabel("Output Buffer");

  CS::BindInfo(cmd, pass->GetTransientsBuffer().EmplaceUniform(info));
  CS::BindInput0(cmd,
                 pass->GetTransientsBuffer().EmplaceStorageBuffer(input_0));
  CS::BindInput1(cmd,
                 pass->GetTransientsBuffer().EmplaceStorageBuffer(input_1));
  CS::BindOutput(cmd, output_buffer->AsBufferView());

  ASSERT_TRUE(pass->AddCommand(std::move(cmd)));
  ASSERT_TRUE(pass->EncodeCommands());

  fml::AutoResetWaitableEvent latch;
  ASSERT_TRUE(
      cmd_buffer->SubmitCommands([&latch, output_buffer, &input_0,
                                  &input_1](CommandBuffer::Status status) {
        EXPECT_EQ(status, CommandBuffer::Status::kCompleted);

        auto view = output_buffer->AsBufferView();
        EXPECT_EQ(view.range.length, sizeof(CS::Output<kCount>));

        CS::Output<kCount>* output =
            reinterpret_cast<CS::Output<kCount>*>(view.contents);
        EXPECT_TRUE(output);
        for (size_t i = 0; i < kCount; i++) {
          Vector4 vector = output->elements[i];
          Vector4 computed = input_0.elements[i] * input_1.elements[i];
          EXPECT_EQ(vector, Vector4(computed.x + 2, computed.y + 3,
                                    computed.z + 5, computed.w));
        }
        latch.Signal();
      }));

  latch.Wait();
}

}  // namespace testing
}  // namespace impeller
