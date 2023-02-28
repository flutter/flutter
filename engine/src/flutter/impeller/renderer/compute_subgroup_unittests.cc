// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/fml/time/time_point.h"
#include "flutter/testing/testing.h"
#include "gmock/gmock.h"
#include "impeller/base/strings.h"
#include "impeller/fixtures/cubic_to_quads.comp.h"
#include "impeller/fixtures/golden_heart.h"
#include "impeller/fixtures/quad_polyline.comp.h"
#include "impeller/fixtures/sample.comp.h"
#include "impeller/fixtures/stage1.comp.h"
#include "impeller/fixtures/stage2.comp.h"
#include "impeller/fixtures/stroke.comp.h"
#include "impeller/geometry/path.h"
#include "impeller/geometry/path_component.h"
#include "impeller/playground/compute_playground_test.h"
#include "impeller/renderer/command_buffer.h"
#include "impeller/renderer/compute_command.h"
#include "impeller/renderer/compute_pipeline_builder.h"
#include "impeller/renderer/formats.h"
#include "impeller/renderer/pipeline_library.h"

namespace impeller {
namespace testing {
using ComputeTest = ComputePlaygroundTest;
INSTANTIATE_COMPUTE_SUITE(ComputeTest);

TEST_P(ComputeTest, HeartCubicsToStrokeVertices) {
  using CS = CubicToQuadsComputeShader;
  using QS = QuadPolylineComputeShader;
  using SS = StrokeComputeShader;

  auto context = GetContext();
  ASSERT_TRUE(context);

  auto cmd_buffer = context->CreateCommandBuffer();
  auto pass = cmd_buffer->CreateComputePass();
  ASSERT_TRUE(pass && pass->IsValid());

  static constexpr size_t kCubicCount = 6;
  static constexpr Scalar kAccuracy = .1;

  DeviceBufferDescriptor quad_buffer_desc;
  quad_buffer_desc.storage_mode = StorageMode::kHostVisible;
  quad_buffer_desc.size = sizeof(CS::Quads<kCubicCount * 10>);
  auto quads = context->GetResourceAllocator()->CreateBuffer(quad_buffer_desc);
  quads->SetLabel("Quads");

  DeviceBufferDescriptor point_buffer_desc;
  point_buffer_desc.storage_mode = StorageMode::kHostVisible;
  // TODO(dnfield): Size this buffer more accurately.
  point_buffer_desc.size = sizeof(QS::Polyline<kCubicCount * 10 * 10>);
  auto polyline =
      context->GetResourceAllocator()->CreateBuffer(point_buffer_desc);
  polyline->SetLabel("polyline");

  DeviceBufferDescriptor vertex_buffer_desc;
  vertex_buffer_desc.storage_mode = StorageMode::kHostVisible;
  // TODO(dnfield): Size this buffer more accurately.
  vertex_buffer_desc.size = sizeof(SS::VertexBuffer<kCubicCount * 10 * 10 * 4>);
  auto vertex_buffer =
      context->GetResourceAllocator()->CreateBuffer(vertex_buffer_desc);
  vertex_buffer->SetLabel("VertexBuffer");

  {
    using CubicPipelineBuilder = ComputePipelineBuilder<CS>;
    auto pipeline_desc =
        CubicPipelineBuilder::MakeDefaultPipelineDescriptor(*context);
    ASSERT_TRUE(pipeline_desc.has_value());
    auto compute_pipeline =
        context->GetPipelineLibrary()->GetPipeline(pipeline_desc).Get();
    ASSERT_TRUE(compute_pipeline);

    pass->SetGridSize(ISize(1024, 1));
    pass->SetThreadGroupSize(ISize(1024, 1));

    ComputeCommand cmd;
    cmd.label = "Cubic To Quads";
    cmd.pipeline = compute_pipeline;

    CS::Config config{.accuracy = kAccuracy};
    CS::BindConfig(cmd, pass->GetTransientsBuffer().EmplaceUniform(config));
    CS::Cubics<kCubicCount> gpu_cubics;

    gpu_cubics.count = kCubicCount;
    for (size_t i = 0; i < kCubicCount; i++) {
      gpu_cubics.data[i] = {
          golden_heart_cubics[i].p1, golden_heart_cubics[i].cp1,
          golden_heart_cubics[i].cp2, golden_heart_cubics[i].p2};
    }

    CS::BindCubics(
        cmd, pass->GetTransientsBuffer().EmplaceStorageBuffer(gpu_cubics));
    CS::BindQuads(cmd, quads->AsBufferView());

    ASSERT_TRUE(pass->AddCommand(std::move(cmd)));
  }

  {
    using QuadPipelineBuilder = ComputePipelineBuilder<QS>;
    auto pipeline_desc =
        QuadPipelineBuilder::MakeDefaultPipelineDescriptor(*context);
    ASSERT_TRUE(pipeline_desc.has_value());
    auto compute_pipeline =
        context->GetPipelineLibrary()->GetPipeline(pipeline_desc).Get();
    ASSERT_TRUE(compute_pipeline);

    pass->SetGridSize(ISize(1024, 1));
    pass->SetThreadGroupSize(ISize(1024, 1));

    ComputeCommand cmd;
    cmd.label = "Quads to Polyline";
    cmd.pipeline = compute_pipeline;

    QS::Config config{.tolerance = kDefaultCurveTolerance};
    QS::BindConfig(cmd, pass->GetTransientsBuffer().EmplaceUniform(config));

    QS::BindQuads(cmd, quads->AsBufferView());
    QS::BindPolyline(cmd, polyline->AsBufferView());

    ASSERT_TRUE(pass->AddCommand(std::move(cmd)));
  }

  {
    using StrokePipelineBuilder = ComputePipelineBuilder<SS>;
    auto pipeline_desc =
        StrokePipelineBuilder::MakeDefaultPipelineDescriptor(*context);
    ASSERT_TRUE(pipeline_desc.has_value());
    auto compute_pipeline =
        context->GetPipelineLibrary()->GetPipeline(pipeline_desc).Get();
    ASSERT_TRUE(compute_pipeline);

    pass->SetGridSize(ISize(1024, 1));
    pass->SetThreadGroupSize(ISize(1024, 1));

    ComputeCommand cmd;
    cmd.label = "Stroke";
    cmd.pipeline = compute_pipeline;

    SS::Config config{.width = 1.0f, .cap = 1, .join = 1, .miter_limit = 4.0f};
    SS::BindConfig(cmd, pass->GetTransientsBuffer().EmplaceUniform(config));

    SS::BindPolyline(cmd, polyline->AsBufferView());
    SS::BindVertexBuffer(cmd, vertex_buffer->AsBufferView());

    ASSERT_TRUE(pass->AddCommand(std::move(cmd)));
  }

  ASSERT_TRUE(pass->EncodeCommands());

  fml::AutoResetWaitableEvent latch;
  ASSERT_TRUE(cmd_buffer->SubmitCommands([&latch, quads, polyline,
                                          vertex_buffer](
                                             CommandBuffer::Status status) {
    EXPECT_EQ(status, CommandBuffer::Status::kCompleted);

    auto* q = reinterpret_cast<CS::Quads<kCubicCount * 10>*>(
        quads->AsBufferView().contents);

    EXPECT_EQ(q->count, golden_heart_quads.size());
    for (size_t i = 0; i < golden_heart_quads.size(); i++) {
      EXPECT_LT(std::abs(golden_heart_quads[i].p1.x - q->data[i].p1.x), 1e-3);
      EXPECT_LT(std::abs(golden_heart_quads[i].p1.y - q->data[i].p1.y), 1e-3);

      EXPECT_LT(std::abs(golden_heart_quads[i].cp.x - q->data[i].cp.x), 1e-3);
      EXPECT_LT(std::abs(golden_heart_quads[i].cp.y - q->data[i].cp.y), 1e-3);

      EXPECT_LT(std::abs(golden_heart_quads[i].p2.x - q->data[i].p2.x), 1e-3);
      EXPECT_LT(std::abs(golden_heart_quads[i].p2.y - q->data[i].p2.y), 1e-3);
    }

    auto* p = reinterpret_cast<QS::Polyline<kCubicCount * 10 * 10>*>(
        polyline->AsBufferView().contents);
    EXPECT_EQ(p->count, golden_heart_points.size());
    for (size_t i = 0; i < p->count; i++) {
      EXPECT_LT(std::abs(p->data[i].x - golden_heart_points[i].x), 1e-3);
      EXPECT_LT(std::abs(p->data[i].y - golden_heart_points[i].y), 1e-3);
    }

    auto* v = reinterpret_cast<SS::VertexBuffer<kCubicCount * 10 * 10 * 4>*>(
        vertex_buffer->AsBufferView().contents);
    for (size_t i = 0; i < golden_heart_vertices.size(); i += 1) {
      EXPECT_LT(std::abs(golden_heart_vertices[i].x - v->position[i].x), 1e-3);
      EXPECT_LT(std::abs(golden_heart_vertices[i].y - v->position[i].y), 1e-3);
    }

    latch.Signal();
  }));

  latch.Wait();
}

TEST_P(ComputeTest, QuadsToPolyline) {
  using QS = QuadPolylineComputeShader;
  auto context = GetContext();
  ASSERT_TRUE(context);

  auto cmd_buffer = context->CreateCommandBuffer();
  auto pass = cmd_buffer->CreateComputePass();
  ASSERT_TRUE(pass && pass->IsValid());

  static constexpr size_t kQuadCount = 26;
  static constexpr size_t kPolylineCount = 1024;

  QS::Quads<kQuadCount> quads;
  quads.count = kQuadCount;
  for (size_t i = 0; i < kQuadCount; i++) {
    quads.data[i] = {golden_heart_quads[i].p1, golden_heart_quads[i].cp,
                     golden_heart_quads[i].p2};
  }

  DeviceBufferDescriptor point_buffer_desc;
  point_buffer_desc.storage_mode = StorageMode::kHostVisible;
  point_buffer_desc.size = sizeof(QS::Polyline<kPolylineCount>);
  auto polyline =
      context->GetResourceAllocator()->CreateBuffer(point_buffer_desc);
  polyline->SetLabel("polyline");

  {
    using QuadPipelineBuilder = ComputePipelineBuilder<QS>;
    auto pipeline_desc =
        QuadPipelineBuilder::MakeDefaultPipelineDescriptor(*context);
    ASSERT_TRUE(pipeline_desc.has_value());
    auto compute_pipeline =
        context->GetPipelineLibrary()->GetPipeline(pipeline_desc).Get();
    ASSERT_TRUE(compute_pipeline);

    pass->SetGridSize(ISize(1024, 1));
    pass->SetThreadGroupSize(ISize(1024, 1));

    ComputeCommand cmd;
    cmd.label = "Quads to Polyline";
    cmd.pipeline = compute_pipeline;

    QS::Config config{.tolerance = kDefaultCurveTolerance};
    QS::BindConfig(cmd, pass->GetTransientsBuffer().EmplaceUniform(config));

    QS::BindQuads(cmd, pass->GetTransientsBuffer().EmplaceStorageBuffer(quads));
    QS::BindPolyline(cmd, polyline->AsBufferView());

    ASSERT_TRUE(pass->AddCommand(std::move(cmd)));
  }

  ASSERT_TRUE(pass->EncodeCommands());

  fml::AutoResetWaitableEvent latch;
  ASSERT_TRUE(cmd_buffer->SubmitCommands(
      [&latch, polyline](CommandBuffer::Status status) {
        EXPECT_EQ(status, CommandBuffer::Status::kCompleted);

        auto* p = reinterpret_cast<QS::Polyline<kPolylineCount>*>(
            polyline->AsBufferView().contents);

        EXPECT_EQ(p->count, golden_heart_points.size());
        for (size_t i = 0; i < p->count; i++) {
          EXPECT_LT(std::abs(p->data[i].x - golden_heart_points[i].x), 1e-3);
          EXPECT_LT(std::abs(p->data[i].y - golden_heart_points[i].y), 1e-3);
        }

        latch.Signal();
      }));

  latch.Wait();
}

}  // namespace testing
}  // namespace impeller
