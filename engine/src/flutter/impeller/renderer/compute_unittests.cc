// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <mutex>
#include <string>
#include <vector>

#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/testing/testing.h"
#include "gmock/gmock.h"
#include "impeller/base/validation.h"
#include "impeller/core/host_buffer.h"
#include "impeller/fixtures/sample.comp.h"
#include "impeller/fixtures/stage1.comp.h"
#include "impeller/fixtures/stage2.comp.h"
#include "impeller/playground/compute_playground_test.h"
#include "impeller/renderer/blit_pass.h"
#include "impeller/renderer/command_buffer.h"
#include "impeller/renderer/compute_3d_test.comp.h"
#include "impeller/renderer/compute_pipeline_builder.h"
#include "impeller/renderer/computed_vertices_test.frag.h"
#include "impeller/renderer/computed_vertices_test.vert.h"
#include "impeller/renderer/increment_test.comp.h"
#include "impeller/renderer/oversized_workgroup_test.comp.h"
#include "impeller/renderer/pipeline_builder.h"
#include "impeller/renderer/pipeline_library.h"
#include "impeller/renderer/prefix_sum_test.comp.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/render_target.h"
#include "impeller/renderer/texture_reader_test.comp.h"
#include "impeller/renderer/threadgroup_sizing_test.comp.h"
#include "impeller/renderer/vertex_writer_test.comp.h"

namespace {
std::shared_ptr<impeller::HostBuffer> CreateHostBufferFromContext(
    const std::shared_ptr<impeller::Context>& context) {
  return impeller::HostBuffer::Create(
      context->GetResourceAllocator(), context->GetIdleWaiter(),
      context->GetCapabilities()->GetMinimumUniformAlignment());
}

// The number of workgroups needed to cover `invocations` invocations given a
// per-workgroup `local_size`.
constexpr uint32_t WorkgroupCount(size_t invocations, uint32_t local_size) {
  return static_cast<uint32_t>((invocations + local_size - 1) / local_size);
}
}  // namespace

namespace impeller {
namespace testing {
using ComputeTest = ComputePlaygroundTest;
INSTANTIATE_COMPUTE_SUITE(ComputeTest);

TEST_P(ComputeTest, CapabilitiesReportSupport) {
  auto context = GetContext();
  ASSERT_TRUE(context);
  ASSERT_TRUE(context->GetCapabilities()->SupportsCompute());
}

TEST_P(ComputeTest, CanCreateComputePass) {
  using CS = SampleComputeShader;
  auto context = GetContext();
  auto host_buffer = CreateHostBufferFromContext(context);
  ASSERT_TRUE(context);
  ASSERT_TRUE(context->GetCapabilities()->SupportsCompute());

  using SamplePipelineBuilder = ComputePipelineBuilder<CS>;
  auto pipeline_desc =
      SamplePipelineBuilder::MakeDefaultPipelineDescriptor(*context);
  ASSERT_TRUE(pipeline_desc.has_value());
  auto compute_pipeline =
      context->GetPipelineLibrary()->GetPipeline(pipeline_desc).Get();
  ASSERT_TRUE(compute_pipeline);

  auto cmd_buffer = context->CreateCommandBuffer();
  auto pass = cmd_buffer->CreateComputePass();
  ASSERT_TRUE(pass && pass->IsValid());

  static constexpr size_t kCount = 5;

  pass->SetPipeline(compute_pipeline);

  CS::Info info{.count = kCount};
  CS::Input0<kCount> input_0;
  CS::Input1<kCount> input_1;
  for (size_t i = 0; i < kCount; i++) {
    input_0.elements[i] = Vector4(2.0 + i, 3.0 + i, 4.0 + i, 5.0 * i);
    input_1.elements[i] = Vector4(6.0, 7.0, 8.0, 9.0);
  }

  input_0.fixed_array[1] = IPoint32(2, 2);
  input_1.fixed_array[0] = UintPoint32(3, 3);
  input_0.some_int = 5;
  input_1.some_struct = CS::SomeStruct{.vf = Point(3, 4), .i = 42};

  auto output_buffer = CreateHostVisibleDeviceBuffer<CS::Output<kCount>>(
      context, "Output Buffer");

  CS::BindInfo(*pass, host_buffer->EmplaceUniform(info));
  CS::BindInput0(*pass, host_buffer->EmplaceStorageBuffer(input_0));
  CS::BindInput1(*pass, host_buffer->EmplaceStorageBuffer(input_1));
  CS::BindOutput(*pass, DeviceBuffer::AsBufferView(output_buffer));

  ASSERT_TRUE(
      pass->Compute({WorkgroupCount(kCount, CS::kWorkgroupSize[0]), 1, 1})
          .ok());
  ASSERT_TRUE(pass->EncodeCommands());

  fml::AutoResetWaitableEvent latch;
  ASSERT_TRUE(
      context->GetCommandQueue()
          ->Submit(
              {cmd_buffer},
              [&latch, output_buffer, &input_0,
               &input_1](CommandBuffer::Status status) {
                EXPECT_EQ(status, CommandBuffer::Status::kCompleted);

                auto view = DeviceBuffer::AsBufferView(output_buffer);
                EXPECT_EQ(view.GetRange().length, sizeof(CS::Output<kCount>));

                CS::Output<kCount>* output =
                    reinterpret_cast<CS::Output<kCount>*>(
                        output_buffer->OnGetContents());
                EXPECT_TRUE(output);
                for (size_t i = 0; i < kCount; i++) {
                  Vector4 vector = output->elements[i];
                  Vector4 computed = input_0.elements[i] * input_1.elements[i];
                  EXPECT_EQ(vector,
                            Vector4(computed.x + 2 + input_1.some_struct.i,
                                    computed.y + 3 + input_1.some_struct.vf.x,
                                    computed.z + 5 + input_1.some_struct.vf.y,
                                    computed.w));
                }
                latch.Signal();
              })
          .ok());

  latch.Wait();
}

TEST_P(ComputeTest, CanComputePrefixSum) {
  using CS = PrefixSumTestComputeShader;
  auto context = GetContext();
  auto host_buffer = CreateHostBufferFromContext(context);
  ASSERT_TRUE(context);
  ASSERT_TRUE(context->GetCapabilities()->SupportsCompute());

  using SamplePipelineBuilder = ComputePipelineBuilder<CS>;
  auto pipeline_desc =
      SamplePipelineBuilder::MakeDefaultPipelineDescriptor(*context);
  ASSERT_TRUE(pipeline_desc.has_value());
  auto compute_pipeline =
      context->GetPipelineLibrary()->GetPipeline(pipeline_desc).Get();
  ASSERT_TRUE(compute_pipeline);

  auto cmd_buffer = context->CreateCommandBuffer();
  auto pass = cmd_buffer->CreateComputePass();
  ASSERT_TRUE(pass && pass->IsValid());

  static constexpr size_t kCount = 5;

  pass->SetPipeline(compute_pipeline);

  CS::InputData<kCount> input_data;
  input_data.count = kCount;
  for (size_t i = 0; i < kCount; i++) {
    input_data.data[i] = 1 + i;
  }

  auto output_buffer = CreateHostVisibleDeviceBuffer<CS::OutputData<kCount>>(
      context, "Output Buffer");

  CS::BindInputData(*pass, host_buffer->EmplaceStorageBuffer(input_data));
  CS::BindOutputData(*pass, DeviceBuffer::AsBufferView(output_buffer));

  // The prefix sum is computed within a single workgroup whose literal size
  // covers the whole input, so dispatch exactly one.
  static_assert(CS::kWorkgroupSize[0] == 128u && CS::kWorkgroupSize[1] == 1u &&
                CS::kWorkgroupSize[2] == 1u);
  static_assert(kCount <= CS::kWorkgroupSize[0]);
  ASSERT_TRUE(pass->Compute({1, 1, 1}).ok());
  ASSERT_TRUE(pass->EncodeCommands());

  fml::AutoResetWaitableEvent latch;
  ASSERT_TRUE(
      context->GetCommandQueue()
          ->Submit({cmd_buffer},
                   [&latch, output_buffer](CommandBuffer::Status status) {
                     EXPECT_EQ(status, CommandBuffer::Status::kCompleted);

                     auto view = DeviceBuffer::AsBufferView(output_buffer);
                     EXPECT_EQ(view.GetRange().length,
                               sizeof(CS::OutputData<kCount>));

                     CS::OutputData<kCount>* output =
                         reinterpret_cast<CS::OutputData<kCount>*>(
                             output_buffer->OnGetContents());
                     EXPECT_TRUE(output);

                     constexpr uint32_t expected[kCount] = {1, 3, 6, 10, 15};
                     for (size_t i = 0; i < kCount; i++) {
                       auto computed_sum = output->data[i];
                       EXPECT_EQ(computed_sum, expected[i]);
                     }
                     latch.Signal();
                   })
          .ok());

  latch.Wait();
}

TEST_P(ComputeTest, 1DThreadgroupSizingIsCorrect) {
  using CS = ThreadgroupSizingTestComputeShader;
  auto context = GetContext();
  ASSERT_TRUE(context);
  ASSERT_TRUE(context->GetCapabilities()->SupportsCompute());

  using SamplePipelineBuilder = ComputePipelineBuilder<CS>;
  auto pipeline_desc =
      SamplePipelineBuilder::MakeDefaultPipelineDescriptor(*context);
  ASSERT_TRUE(pipeline_desc.has_value());
  auto compute_pipeline =
      context->GetPipelineLibrary()->GetPipeline(pipeline_desc).Get();
  ASSERT_TRUE(compute_pipeline);

  auto cmd_buffer = context->CreateCommandBuffer();
  auto pass = cmd_buffer->CreateComputePass();
  ASSERT_TRUE(pass && pass->IsValid());

  static constexpr size_t kCount = 2048;

  pass->SetPipeline(compute_pipeline);

  auto output_buffer = CreateHostVisibleDeviceBuffer<CS::OutputData<kCount>>(
      context, "Output Buffer");

  CS::BindOutputData(*pass, DeviceBuffer::AsBufferView(output_buffer));

  ASSERT_TRUE(
      pass->Compute({WorkgroupCount(kCount, CS::kWorkgroupSize[0]), 1, 1})
          .ok());
  ASSERT_TRUE(pass->EncodeCommands());

  fml::AutoResetWaitableEvent latch;
  ASSERT_TRUE(
      context->GetCommandQueue()
          ->Submit({cmd_buffer},
                   [&latch, output_buffer](CommandBuffer::Status status) {
                     EXPECT_EQ(status, CommandBuffer::Status::kCompleted);

                     auto view = DeviceBuffer::AsBufferView(output_buffer);
                     EXPECT_EQ(view.GetRange().length,
                               sizeof(CS::OutputData<kCount>));

                     CS::OutputData<kCount>* output =
                         reinterpret_cast<CS::OutputData<kCount>*>(
                             output_buffer->OnGetContents());
                     EXPECT_TRUE(output);
                     EXPECT_EQ(output->data[kCount - 1], kCount - 1);
                     latch.Signal();
                   })
          .ok());

  latch.Wait();
}

TEST_P(ComputeTest, 3DWorkgroupDispatchIsCorrect) {
  using CS = Compute3dTestComputeShader;
  auto context = GetContext();
  ASSERT_TRUE(context);
  ASSERT_TRUE(context->GetCapabilities()->SupportsCompute());

  using PipelineBuilder = ComputePipelineBuilder<CS>;
  auto pipeline_desc = PipelineBuilder::MakeDefaultPipelineDescriptor(*context);
  ASSERT_TRUE(pipeline_desc.has_value());
  auto compute_pipeline =
      context->GetPipelineLibrary()->GetPipeline(pipeline_desc).Get();
  ASSERT_TRUE(compute_pipeline);

  auto cmd_buffer = context->CreateCommandBuffer();
  auto pass = cmd_buffer->CreateComputePass();
  ASSERT_TRUE(pass && pass->IsValid());

  // The shader's local size is (2, 3, 4). Dispatching (3, 2, 1) workgroups
  // covers a (6, 6, 4) invocation grid, which exercises all three dimensions
  // and confirms the reflected local size is honored on every axis.
  static_assert(CS::kWorkgroupSize[0] == 2 && CS::kWorkgroupSize[1] == 3 &&
                CS::kWorkgroupSize[2] == 4);
  constexpr std::array<uint32_t, 3> kWorkgroups = {3, 2, 1};
  constexpr uint32_t kWidth = kWorkgroups[0] * CS::kWorkgroupSize[0];
  constexpr uint32_t kHeight = kWorkgroups[1] * CS::kWorkgroupSize[1];
  constexpr uint32_t kDepth = kWorkgroups[2] * CS::kWorkgroupSize[2];
  constexpr size_t kCount = kWidth * kHeight * kDepth;

  pass->SetPipeline(compute_pipeline);

  auto output_buffer = CreateHostVisibleDeviceBuffer<CS::OutputData<kCount>>(
      context, "Output Buffer");
  CS::BindOutputData(*pass, DeviceBuffer::AsBufferView(output_buffer));

  ASSERT_TRUE(pass->Compute(kWorkgroups).ok());
  ASSERT_TRUE(pass->EncodeCommands());

  fml::AutoResetWaitableEvent latch;
  ASSERT_TRUE(
      context->GetCommandQueue()
          ->Submit({cmd_buffer},
                   [&latch, output_buffer](CommandBuffer::Status status) {
                     EXPECT_EQ(status, CommandBuffer::Status::kCompleted);

                     CS::OutputData<kCount>* output =
                         reinterpret_cast<CS::OutputData<kCount>*>(
                             output_buffer->OnGetContents());
                     EXPECT_TRUE(output);
                     for (uint32_t i = 0; i < kCount; i++) {
                       EXPECT_EQ(output->data[i], i);
                     }
                     latch.Signal();
                   })
          .ok());

  latch.Wait();
}

TEST_P(ComputeTest, CanComputePrefixSumLargeInteractive) {
  using CS = PrefixSumTestComputeShader;

  auto context = GetContext();
  auto host_buffer = CreateHostBufferFromContext(context);

  ASSERT_TRUE(context);
  ASSERT_TRUE(context->GetCapabilities()->SupportsCompute());

  auto callback = [&](RenderPass& render_pass) -> bool {
    using SamplePipelineBuilder = ComputePipelineBuilder<CS>;
    auto pipeline_desc =
        SamplePipelineBuilder::MakeDefaultPipelineDescriptor(*context);
    auto compute_pipeline =
        context->GetPipelineLibrary()->GetPipeline(pipeline_desc).Get();

    auto cmd_buffer = context->CreateCommandBuffer();
    auto pass = cmd_buffer->CreateComputePass();

    // The largest input one workgroup can sum.
    static constexpr size_t kCount = CS::kWorkgroupSize[0];

    pass->SetPipeline(compute_pipeline);

    CS::InputData<kCount> input_data;
    input_data.count = kCount;
    for (size_t i = 0; i < kCount; i++) {
      input_data.data[i] = 1 + i;
    }

    auto output_buffer = CreateHostVisibleDeviceBuffer<CS::OutputData<kCount>>(
        context, "Output Buffer");

    CS::BindInputData(*pass, host_buffer->EmplaceStorageBuffer(input_data));
    CS::BindOutputData(*pass, DeviceBuffer::AsBufferView(output_buffer));

    // Single workgroup; see CanComputePrefixSum.
    pass->Compute({1, 1, 1});
    pass->EncodeCommands();
    host_buffer->Reset();
    return context->GetCommandQueue()->Submit({cmd_buffer}).ok();
  };
  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

TEST_P(ComputeTest, MultiStageInputAndOutput) {
  using CS1 = Stage1ComputeShader;
  using Stage1PipelineBuilder = ComputePipelineBuilder<CS1>;
  using CS2 = Stage2ComputeShader;
  using Stage2PipelineBuilder = ComputePipelineBuilder<CS2>;

  auto context = GetContext();
  auto host_buffer = CreateHostBufferFromContext(context);
  ASSERT_TRUE(context);
  ASSERT_TRUE(context->GetCapabilities()->SupportsCompute());

  auto pipeline_desc_1 =
      Stage1PipelineBuilder::MakeDefaultPipelineDescriptor(*context);
  ASSERT_TRUE(pipeline_desc_1.has_value());
  auto compute_pipeline_1 =
      context->GetPipelineLibrary()->GetPipeline(pipeline_desc_1).Get();
  ASSERT_TRUE(compute_pipeline_1);

  auto pipeline_desc_2 =
      Stage2PipelineBuilder::MakeDefaultPipelineDescriptor(*context);
  ASSERT_TRUE(pipeline_desc_2.has_value());
  auto compute_pipeline_2 =
      context->GetPipelineLibrary()->GetPipeline(pipeline_desc_2).Get();
  ASSERT_TRUE(compute_pipeline_2);

  auto cmd_buffer = context->CreateCommandBuffer();
  auto pass = cmd_buffer->CreateComputePass();
  ASSERT_TRUE(pass && pass->IsValid());

  static constexpr size_t kCount1 = 5;
  static constexpr size_t kCount2 = kCount1 * 2;

  CS1::Input<kCount1> input_1;
  input_1.count = kCount1;
  for (size_t i = 0; i < kCount1; i++) {
    input_1.elements[i] = i;
  }

  CS2::Input<kCount2> input_2;
  input_2.count = kCount2;
  for (size_t i = 0; i < kCount2; i++) {
    input_2.elements[i] = i;
  }

  auto output_buffer_1 = CreateHostVisibleDeviceBuffer<CS1::Output<kCount2>>(
      context, "Output Buffer Stage 1");
  auto output_buffer_2 = CreateHostVisibleDeviceBuffer<CS2::Output<kCount2>>(
      context, "Output Buffer Stage 2");

  {
    pass->SetPipeline(compute_pipeline_1);

    CS1::BindInput(*pass, host_buffer->EmplaceStorageBuffer(input_1));
    CS1::BindOutput(*pass, DeviceBuffer::AsBufferView(output_buffer_1));

    ASSERT_TRUE(
        pass->Compute({WorkgroupCount(kCount1, CS1::kWorkgroupSize[0]), 1, 1})
            .ok());
    pass->AddBufferMemoryBarrier();
  }

  {
    pass->SetPipeline(compute_pipeline_2);

    CS1::BindInput(*pass, DeviceBuffer::AsBufferView(output_buffer_1));
    CS2::BindOutput(*pass, DeviceBuffer::AsBufferView(output_buffer_2));
    ASSERT_TRUE(
        pass->Compute({WorkgroupCount(kCount2, CS2::kWorkgroupSize[0]), 1, 1})
            .ok());
  }

  ASSERT_TRUE(pass->EncodeCommands());

  fml::AutoResetWaitableEvent latch;
  ASSERT_TRUE(
      context->GetCommandQueue()
          ->Submit({cmd_buffer},
                   [&latch, &output_buffer_1,
                    &output_buffer_2](CommandBuffer::Status status) {
                     EXPECT_EQ(status, CommandBuffer::Status::kCompleted);

                     CS1::Output<kCount2>* output_1 =
                         reinterpret_cast<CS1::Output<kCount2>*>(
                             output_buffer_1->OnGetContents());
                     EXPECT_TRUE(output_1);
                     EXPECT_EQ(output_1->count, 10u);
                     EXPECT_THAT(
                         output_1->elements,
                         ::testing::ElementsAre(0, 0, 2, 3, 4, 6, 6, 9, 8, 12));

                     CS2::Output<kCount2>* output_2 =
                         reinterpret_cast<CS2::Output<kCount2>*>(
                             output_buffer_2->OnGetContents());
                     EXPECT_TRUE(output_2);
                     EXPECT_EQ(output_2->count, 10u);
                     EXPECT_THAT(output_2->elements,
                                 ::testing::ElementsAre(0, 0, 4, 6, 8, 12, 12,
                                                        18, 16, 24));

                     latch.Signal();
                   })
          .ok());

  latch.Wait();
}

TEST_P(ComputeTest, CanCompute1DimensionalData) {
  using CS = SampleComputeShader;
  auto context = GetContext();
  auto host_buffer = CreateHostBufferFromContext(context);
  ASSERT_TRUE(context);
  ASSERT_TRUE(context->GetCapabilities()->SupportsCompute());

  using SamplePipelineBuilder = ComputePipelineBuilder<CS>;
  auto pipeline_desc =
      SamplePipelineBuilder::MakeDefaultPipelineDescriptor(*context);
  ASSERT_TRUE(pipeline_desc.has_value());
  auto compute_pipeline =
      context->GetPipelineLibrary()->GetPipeline(pipeline_desc).Get();
  ASSERT_TRUE(compute_pipeline);

  auto cmd_buffer = context->CreateCommandBuffer();
  auto pass = cmd_buffer->CreateComputePass();
  ASSERT_TRUE(pass && pass->IsValid());

  static constexpr size_t kCount = 5;

  pass->SetPipeline(compute_pipeline);

  CS::Info info{.count = kCount};
  CS::Input0<kCount> input_0;
  CS::Input1<kCount> input_1;
  for (size_t i = 0; i < kCount; i++) {
    input_0.elements[i] = Vector4(2.0 + i, 3.0 + i, 4.0 + i, 5.0 * i);
    input_1.elements[i] = Vector4(6.0, 7.0, 8.0, 9.0);
  }

  input_0.fixed_array[1] = IPoint32(2, 2);
  input_1.fixed_array[0] = UintPoint32(3, 3);
  input_0.some_int = 5;
  input_1.some_struct = CS::SomeStruct{.vf = Point(3, 4), .i = 42};

  auto output_buffer = CreateHostVisibleDeviceBuffer<CS::Output<kCount>>(
      context, "Output Buffer");

  CS::BindInfo(*pass, host_buffer->EmplaceUniform(info));
  CS::BindInput0(*pass, host_buffer->EmplaceStorageBuffer(input_0));
  CS::BindInput1(*pass, host_buffer->EmplaceStorageBuffer(input_1));
  CS::BindOutput(*pass, DeviceBuffer::AsBufferView(output_buffer));

  ASSERT_TRUE(
      pass->Compute({WorkgroupCount(kCount, CS::kWorkgroupSize[0]), 1, 1})
          .ok());
  ASSERT_TRUE(pass->EncodeCommands());

  fml::AutoResetWaitableEvent latch;
  ASSERT_TRUE(
      context->GetCommandQueue()
          ->Submit(
              {cmd_buffer},
              [&latch, output_buffer, &input_0,
               &input_1](CommandBuffer::Status status) {
                EXPECT_EQ(status, CommandBuffer::Status::kCompleted);

                auto view = DeviceBuffer::AsBufferView(output_buffer);
                EXPECT_EQ(view.GetRange().length, sizeof(CS::Output<kCount>));

                CS::Output<kCount>* output =
                    reinterpret_cast<CS::Output<kCount>*>(
                        output_buffer->OnGetContents());
                EXPECT_TRUE(output);
                for (size_t i = 0; i < kCount; i++) {
                  Vector4 vector = output->elements[i];
                  Vector4 computed = input_0.elements[i] * input_1.elements[i];
                  EXPECT_EQ(vector,
                            Vector4(computed.x + 2 + input_1.some_struct.i,
                                    computed.y + 3 + input_1.some_struct.vf.x,
                                    computed.z + 5 + input_1.some_struct.vf.y,
                                    computed.w));
                }
                latch.Signal();
              })
          .ok());

  latch.Wait();
}

TEST_P(ComputeTest, ZeroWorkgroupCountIsNoOp) {
  using CS = IncrementTestComputeShader;
  auto context = GetContext();
  ASSERT_TRUE(context);
  ASSERT_TRUE(context->GetCapabilities()->SupportsCompute());

  auto pipeline_desc =
      ComputePipelineBuilder<CS>::MakeDefaultPipelineDescriptor(*context);
  ASSERT_TRUE(pipeline_desc.has_value());
  auto compute_pipeline =
      context->GetPipelineLibrary()->GetPipeline(pipeline_desc).Get();
  ASSERT_TRUE(compute_pipeline);

  static constexpr size_t kCount = CS::kWorkgroupSize[0];
  auto buffer =
      CreateHostVisibleDeviceBuffer<CS::Data<kCount>>(context, "Data");
  CS::Data<kCount> initial = {};
  ASSERT_TRUE(buffer->CopyHostBuffer(reinterpret_cast<const uint8_t*>(&initial),
                                     Range{0, sizeof(initial)}, 0));

  auto cmd_buffer = context->CreateCommandBuffer();
  auto pass = cmd_buffer->CreateComputePass();
  ASSERT_TRUE(pass && pass->IsValid());
  pass->SetPipeline(compute_pipeline);
  CS::BindData(*pass, DeviceBuffer::AsBufferView(buffer));

  // A zero count in any dimension dispatches nothing and is not an error, like
  // a draw with no vertices.
  EXPECT_TRUE(pass->Compute({0, 1, 1}).ok());
  EXPECT_TRUE(pass->Compute({1, 0, 1}).ok());
  EXPECT_TRUE(pass->Compute({1, 1, 0}).ok());
  ASSERT_TRUE(pass->EncodeCommands());

  fml::AutoResetWaitableEvent latch;
  ASSERT_TRUE(context->GetCommandQueue()
                  ->Submit({cmd_buffer},
                           [&latch, buffer](CommandBuffer::Status status) {
                             EXPECT_EQ(status,
                                       CommandBuffer::Status::kCompleted);
                             buffer->Invalidate();
                             auto* output = reinterpret_cast<CS::Data<kCount>*>(
                                 buffer->OnGetContents());
                             for (size_t i = 0; i < kCount; i++) {
                               EXPECT_EQ(output->values[i], 0u);
                             }
                             latch.Signal();
                           })
                  .ok());
  latch.Wait();
}

TEST_P(ComputeTest, BindingsPersistAcrossDispatches) {
  using CS = IncrementTestComputeShader;
  auto context = GetContext();
  ASSERT_TRUE(context);
  ASSERT_TRUE(context->GetCapabilities()->SupportsCompute());

  auto pipeline_desc =
      ComputePipelineBuilder<CS>::MakeDefaultPipelineDescriptor(*context);
  ASSERT_TRUE(pipeline_desc.has_value());
  auto compute_pipeline =
      context->GetPipelineLibrary()->GetPipeline(pipeline_desc).Get();
  ASSERT_TRUE(compute_pipeline);

  static constexpr size_t kCount = CS::kWorkgroupSize[0] * 2;
  CS::Data<kCount> initial = {};
  auto buffer_a =
      CreateHostVisibleDeviceBuffer<CS::Data<kCount>>(context, "Data A");
  auto buffer_b =
      CreateHostVisibleDeviceBuffer<CS::Data<kCount>>(context, "Data B");
  ASSERT_TRUE(
      buffer_a->CopyHostBuffer(reinterpret_cast<const uint8_t*>(&initial),
                               Range{0, sizeof(initial)}, 0));
  ASSERT_TRUE(
      buffer_b->CopyHostBuffer(reinterpret_cast<const uint8_t*>(&initial),
                               Range{0, sizeof(initial)}, 0));

  auto cmd_buffer = context->CreateCommandBuffer();
  auto pass = cmd_buffer->CreateComputePass();
  ASSERT_TRUE(pass && pass->IsValid());

  const std::array<uint32_t, 3> workgroups = {
      WorkgroupCount(kCount, CS::kWorkgroupSize[0]), 1, 1};

  // Bind once and dispatch twice: the second dispatch reuses the pipeline and
  // the binding.
  pass->SetPipeline(compute_pipeline);
  CS::BindData(*pass, DeviceBuffer::AsBufferView(buffer_a));
  ASSERT_TRUE(pass->Compute(workgroups).ok());
  pass->AddBufferMemoryBarrier();
  ASSERT_TRUE(pass->Compute(workgroups).ok());
  pass->AddBufferMemoryBarrier();

  // Changing a binding applies to later dispatches only, and is kept for the
  // dispatch after that.
  CS::BindData(*pass, DeviceBuffer::AsBufferView(buffer_b));
  ASSERT_TRUE(pass->Compute(workgroups).ok());
  pass->AddBufferMemoryBarrier();
  ASSERT_TRUE(pass->Compute(workgroups).ok());
  pass->AddBufferMemoryBarrier();
  ASSERT_TRUE(pass->Compute(workgroups).ok());
  ASSERT_TRUE(pass->EncodeCommands());

  fml::AutoResetWaitableEvent latch;
  ASSERT_TRUE(
      context->GetCommandQueue()
          ->Submit({cmd_buffer},
                   [&latch, buffer_a, buffer_b](CommandBuffer::Status status) {
                     EXPECT_EQ(status, CommandBuffer::Status::kCompleted);
                     buffer_a->Invalidate();
                     buffer_b->Invalidate();
                     auto* a = reinterpret_cast<CS::Data<kCount>*>(
                         buffer_a->OnGetContents());
                     auto* b = reinterpret_cast<CS::Data<kCount>*>(
                         buffer_b->OnGetContents());
                     for (size_t i = 0; i < kCount; i++) {
                       EXPECT_EQ(a->values[i], 2u) << "index " << i;
                       EXPECT_EQ(b->values[i], 3u) << "index " << i;
                     }
                     latch.Signal();
                   })
          .ok());
  latch.Wait();
}

TEST_P(ComputeTest, OversizedWorkgroupFailsPipelineCreation) {
  using CS = OversizedWorkgroupTestComputeShader;
  auto context = GetContext();
  ASSERT_TRUE(context);
  ASSERT_TRUE(context->GetCapabilities()->SupportsCompute());

  auto pipeline_desc =
      ComputePipelineBuilder<CS>::MakeDefaultPipelineDescriptor(*context);
  ASSERT_TRUE(pipeline_desc.has_value());
  ASSERT_EQ(pipeline_desc->GetWorkgroupSize(),
            (std::array<uint32_t, 3>{1024u, 1024u, 1u}));

  std::mutex mutex;
  std::vector<std::string> messages;
  ImpellerValidationErrorsSetCallback(
      [&](const char* message, const char* file, int line) {
        std::scoped_lock lock(mutex);
        messages.emplace_back(message);
        return true;
      });
  auto compute_pipeline =
      context->GetPipelineLibrary()->GetPipeline(pipeline_desc).Get();
  ImpellerValidationErrorsSetCallback(nullptr);

  EXPECT_FALSE(compute_pipeline);
  std::scoped_lock lock(mutex);
  EXPECT_THAT(messages, ::testing::Contains(::testing::HasSubstr(
                            "has a workgroup size of 1024x1024x1")));
}

TEST_P(ComputeTest, CapabilitiesReportComputeLimits) {
  auto context = GetContext();
  ASSERT_TRUE(context);
  const auto& caps = context->GetCapabilities();
  ASSERT_TRUE(caps->SupportsCompute());

  // The minimums every Metal and Vulkan device meets.
  EXPECT_GE(caps->GetMaximumComputeWorkgroupInvocations(), 128u);
  const auto size = caps->GetMaximumComputeWorkgroupSize();
  EXPECT_GE(size[0], 128u);
  EXPECT_GE(size[1], 128u);
  EXPECT_GE(size[2], 64u);
  const auto count = caps->GetMaximumComputeWorkgroupCount();
  EXPECT_GE(count[0], 65535u);
  EXPECT_GE(count[1], 65535u);
  EXPECT_GE(count[2], 65535u);
  EXPECT_GE(caps->GetMaximumComputeSharedMemorySize(), 16384u);
  EXPECT_GT(caps->GetMinimumStorageBufferAlignment(), 0u);
}

TEST_P(ComputeTest, DependentDispatchesNeedNoBarrier) {
  using CS = IncrementTestComputeShader;
  auto context = GetContext();
  ASSERT_TRUE(context);
  ASSERT_TRUE(context->GetCapabilities()->SupportsCompute());

  auto pipeline_desc =
      ComputePipelineBuilder<CS>::MakeDefaultPipelineDescriptor(*context);
  ASSERT_TRUE(pipeline_desc.has_value());
  auto compute_pipeline =
      context->GetPipelineLibrary()->GetPipeline(pipeline_desc).Get();
  ASSERT_TRUE(compute_pipeline);

  static constexpr size_t kCount = CS::kWorkgroupSize[0] * 64;
  static constexpr uint32_t kDispatches = 8;
  CS::Data<kCount> initial = {};
  auto buffer =
      CreateHostVisibleDeviceBuffer<CS::Data<kCount>>(context, "Data");
  ASSERT_TRUE(buffer->CopyHostBuffer(reinterpret_cast<const uint8_t*>(&initial),
                                     Range{0, sizeof(initial)}, 0));

  auto cmd_buffer = context->CreateCommandBuffer();
  auto pass = cmd_buffer->CreateComputePass();
  ASSERT_TRUE(pass && pass->IsValid());
  pass->SetPipeline(compute_pipeline);
  CS::BindData(*pass, DeviceBuffer::AsBufferView(buffer));

  // Each dispatch reads what the previous one wrote. No manual barrier is
  // added between them.
  for (uint32_t i = 0; i < kDispatches; i++) {
    ASSERT_TRUE(
        pass->Compute({WorkgroupCount(kCount, CS::kWorkgroupSize[0]), 1, 1})
            .ok());
  }
  ASSERT_TRUE(pass->EncodeCommands());

  fml::AutoResetWaitableEvent latch;
  ASSERT_TRUE(context->GetCommandQueue()
                  ->Submit({cmd_buffer},
                           [&latch, buffer](CommandBuffer::Status status) {
                             EXPECT_EQ(status,
                                       CommandBuffer::Status::kCompleted);
                             buffer->Invalidate();
                             auto* output = reinterpret_cast<CS::Data<kCount>*>(
                                 buffer->OnGetContents());
                             for (size_t i = 0; i < kCount; i++) {
                               EXPECT_EQ(output->values[i], kDispatches)
                                   << "index " << i;
                             }
                             latch.Signal();
                           })
                  .ok());
  latch.Wait();
}

TEST_P(ComputeTest, RenderPassDrawsVerticesWrittenByComputePass) {
  using CS = VertexWriterTestComputeShader;
  using VS = ComputedVerticesTestVertexShader;
  using FS = ComputedVerticesTestFragmentShader;
  auto context = GetContext();
  ASSERT_TRUE(context);
  ASSERT_TRUE(context->GetCapabilities()->SupportsCompute());

  auto compute_desc =
      ComputePipelineBuilder<CS>::MakeDefaultPipelineDescriptor(*context);
  ASSERT_TRUE(compute_desc.has_value());
  auto compute_pipeline =
      context->GetPipelineLibrary()->GetPipeline(compute_desc).Get();
  ASSERT_TRUE(compute_pipeline);

  auto render_desc =
      PipelineBuilder<VS, FS>::MakeDefaultPipelineDescriptor(*context);
  ASSERT_TRUE(render_desc.has_value());
  render_desc->SetSampleCount(SampleCount::kCount1);
  render_desc->ClearStencilAttachments();
  render_desc->ClearDepthAttachment();
  auto render_pipeline =
      context->GetPipelineLibrary()->GetPipeline(render_desc).Get();
  ASSERT_TRUE(render_pipeline);

  // Three vertices of two floats each, written only by the compute pass.
  DeviceBufferDescriptor vertex_desc;
  vertex_desc.storage_mode = StorageMode::kDevicePrivate;
  vertex_desc.size = sizeof(float) * 2 * 3;
  auto vertex_buffer =
      context->GetResourceAllocator()->CreateBuffer(vertex_desc);
  ASSERT_TRUE(vertex_buffer);

  static constexpr ISize kSize = {4, 4};
  RenderTargetAllocator target_allocator(context->GetResourceAllocator());
  RenderTarget target = target_allocator.CreateOffscreen(
      *context, kSize, 1, "Computed Vertices",
      RenderTarget::kDefaultColorAttachmentConfig, std::nullopt);
  auto texture = target.GetRenderTargetTexture();
  ASSERT_TRUE(texture);

  DeviceBufferDescriptor readback_desc;
  readback_desc.storage_mode = StorageMode::kHostVisible;
  readback_desc.readback = true;
  readback_desc.size =
      texture->GetTextureDescriptor().GetByteSizeOfBaseMipLevel();
  auto readback = context->GetResourceAllocator()->CreateBuffer(readback_desc);
  ASSERT_TRUE(readback);

  auto cmd_buffer = context->CreateCommandBuffer();
  {
    auto pass = cmd_buffer->CreateComputePass();
    ASSERT_TRUE(pass && pass->IsValid());
    pass->SetPipeline(compute_pipeline);
    CS::BindVertices(*pass, DeviceBuffer::AsBufferView(vertex_buffer));
    ASSERT_TRUE(pass->Compute({1, 1, 1}).ok());
    ASSERT_TRUE(pass->EncodeCommands());
  }
  {
    auto pass = cmd_buffer->CreateRenderPass(target);
    ASSERT_TRUE(pass && pass->IsValid());
    pass->SetPipeline(render_pipeline);
    ASSERT_TRUE(
        pass->SetVertexBuffer(DeviceBuffer::AsBufferView(vertex_buffer)));
    pass->SetElementCount(3);
    ASSERT_TRUE(pass->Draw().ok());
    ASSERT_TRUE(pass->EncodeCommands());
  }
  {
    auto pass = cmd_buffer->CreateBlitPass();
    ASSERT_TRUE(pass->AddCopy(texture, readback));
    ASSERT_TRUE(pass->EncodeCommands());
  }

  fml::AutoResetWaitableEvent latch;
  ASSERT_TRUE(
      context->GetCommandQueue()
          ->Submit({cmd_buffer},
                   [&latch, readback](CommandBuffer::Status status) {
                     EXPECT_EQ(status, CommandBuffer::Status::kCompleted);
                     readback->Invalidate();
                     // The triangle covers the target, so every pixel is the
                     // fragment shader's opaque green in either RGBA or BGRA
                     // order. Without the computed vertices nothing is drawn
                     // and the pixels stay transparent black.
                     const uint8_t* pixels = readback->OnGetContents();
                     for (int i = 0; i < kSize.Area(); i++) {
                       EXPECT_EQ(pixels[i * 4 + 0], 0u) << "pixel " << i;
                       EXPECT_EQ(pixels[i * 4 + 1], 255u) << "pixel " << i;
                       EXPECT_EQ(pixels[i * 4 + 2], 0u) << "pixel " << i;
                       EXPECT_EQ(pixels[i * 4 + 3], 255u) << "pixel " << i;
                     }
                     latch.Signal();
                   })
          .ok());
  latch.Wait();
}

TEST_P(ComputeTest, ComputePassReadsTextureWrittenByRenderPass) {
  using CS = TextureReaderTestComputeShader;
  auto context = GetContext();
  ASSERT_TRUE(context);
  ASSERT_TRUE(context->GetCapabilities()->SupportsCompute());

  auto compute_desc =
      ComputePipelineBuilder<CS>::MakeDefaultPipelineDescriptor(*context);
  ASSERT_TRUE(compute_desc.has_value());
  auto compute_pipeline =
      context->GetPipelineLibrary()->GetPipeline(compute_desc).Get();
  ASSERT_TRUE(compute_pipeline);

  // The render pass writes the texture by clearing it.
  RenderTarget::AttachmentConfig color_config =
      RenderTarget::kDefaultColorAttachmentConfig;
  color_config.clear_color = Color(0.0, 1.0, 0.0, 1.0);
  RenderTargetAllocator target_allocator(context->GetResourceAllocator());
  RenderTarget target = target_allocator.CreateOffscreen(
      *context, {4, 4}, 1, "Cleared Texture", color_config, std::nullopt);
  auto texture = target.GetRenderTargetTexture();
  ASSERT_TRUE(texture);

  raw_ptr<const Sampler> sampler = context->GetSamplerLibrary()->GetSampler({});
  ASSERT_TRUE(sampler);

  auto output_buffer =
      CreateHostVisibleDeviceBuffer<CS::OutputData>(context, "Output Buffer");
  CS::OutputData initial = {};
  ASSERT_TRUE(
      output_buffer->CopyHostBuffer(reinterpret_cast<const uint8_t*>(&initial),
                                    Range{0, sizeof(initial)}, 0));

  auto cmd_buffer = context->CreateCommandBuffer();
  {
    auto pass = cmd_buffer->CreateRenderPass(target);
    ASSERT_TRUE(pass && pass->IsValid());
    ASSERT_TRUE(pass->EncodeCommands());
  }
  {
    auto pass = cmd_buffer->CreateComputePass();
    ASSERT_TRUE(pass && pass->IsValid());
    pass->SetPipeline(compute_pipeline);
    CS::BindInputTexture(*pass, texture, sampler);
    CS::BindOutputData(*pass, DeviceBuffer::AsBufferView(output_buffer));
    ASSERT_TRUE(pass->Compute({1, 1, 1}).ok());
    ASSERT_TRUE(pass->EncodeCommands());
  }

  fml::AutoResetWaitableEvent latch;
  ASSERT_TRUE(
      context->GetCommandQueue()
          ->Submit({cmd_buffer},
                   [&latch, output_buffer](CommandBuffer::Status status) {
                     EXPECT_EQ(status, CommandBuffer::Status::kCompleted);
                     output_buffer->Invalidate();
                     auto* output = reinterpret_cast<CS::OutputData*>(
                         output_buffer->OnGetContents());
                     EXPECT_EQ(output->color, Vector4(0, 1, 0, 1));
                     latch.Signal();
                   })
          .ok());
  latch.Wait();
}

}  // namespace testing
}  // namespace impeller
