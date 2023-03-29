// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <numeric>

#include "compute_tessellator.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/fml/time/time_point.h"
#include "flutter/testing/testing.h"
#include "gmock/gmock.h"
#include "impeller/base/strings.h"
#include "impeller/core/formats.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/fixtures/cubic_to_quads.comp.h"
#include "impeller/fixtures/golden_paths.h"
#include "impeller/fixtures/quad_polyline.comp.h"
#include "impeller/fixtures/sample.comp.h"
#include "impeller/fixtures/stage1.comp.h"
#include "impeller/fixtures/stage2.comp.h"
#include "impeller/geometry/path.h"
#include "impeller/geometry/path_builder.h"
#include "impeller/geometry/path_component.h"
#include "impeller/playground/compute_playground_test.h"
#include "impeller/renderer/command_buffer.h"
#include "impeller/renderer/compute_command.h"
#include "impeller/renderer/compute_pipeline_builder.h"
#include "impeller/renderer/compute_tessellator.h"
#include "impeller/renderer/path_polyline.comp.h"
#include "impeller/renderer/pipeline_library.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/stroke.comp.h"

namespace impeller {
namespace testing {
using ComputeSubgroupTest = ComputePlaygroundTest;
INSTANTIATE_COMPUTE_SUITE(ComputeSubgroupTest);

TEST_P(ComputeSubgroupTest, QuadAndCubicInOnePath) {
  using SS = StrokeComputeShader;

  auto context = GetContext();
  ASSERT_TRUE(context);
  ASSERT_TRUE(context->GetCapabilities()->SupportsComputeSubgroups());

  auto vertex_buffer = CreateHostVisibleDeviceBuffer<SS::VertexBuffer<2048>>(
      context, "VertexBuffer");
  auto vertex_buffer_count =
      CreateHostVisibleDeviceBuffer<SS::VertexBufferCount>(context,
                                                           "VertexBufferCount");

  auto path = PathBuilder{}
                  .AddCubicCurve({140, 20}, {73, 20}, {20, 74}, {20, 140})
                  .AddQuadraticCurve({20, 140}, {93, 90}, {100, 42})
                  .TakePath();

  auto tessellator = ComputeTessellator{};

  fml::AutoResetWaitableEvent latch;

  auto status = tessellator.Tessellate(
      path, context, vertex_buffer->AsBufferView(),
      vertex_buffer_count->AsBufferView(),
      [&latch](CommandBuffer::Status status) {
        EXPECT_EQ(status, CommandBuffer::Status::kCompleted);
        latch.Signal();
      });

  ASSERT_EQ(status, ComputeTessellator::Status::kOk);

  auto callback = [&](RenderPass& pass) -> bool {
    ContentContext renderer(context);
    if (!renderer.IsValid()) {
      return false;
    }

    using VS = SolidFillPipeline::VertexShader;
    using FS = SolidFillPipeline::FragmentShader;

    Command cmd;
    cmd.label = "Draw Stroke";
    cmd.stencil_reference = 0;

    ContentContextOptions options;
    options.sample_count = pass.GetRenderTarget().GetSampleCount();
    options.color_attachment_pixel_format =
        pass.GetRenderTarget().GetRenderTargetPixelFormat();
    options.has_stencil_attachment =
        pass.GetRenderTarget().GetStencilAttachment().has_value();
    options.blend_mode = BlendMode::kSourceIn;
    options.primitive_type = PrimitiveType::kTriangleStrip;
    options.stencil_compare = CompareFunction::kEqual;
    options.stencil_operation = StencilOperation::kIncrementClamp;

    cmd.pipeline = renderer.GetSolidFillPipeline(options);

    auto count = reinterpret_cast<SS::VertexBufferCount*>(
                     vertex_buffer_count->AsBufferView().contents)
                     ->count;
    auto& host_buffer = pass.GetTransientsBuffer();
    std::vector<uint16_t> indices(count);
    std::iota(std::begin(indices), std::end(indices), 0);

    VertexBuffer render_vertex_buffer{
        .vertex_buffer = vertex_buffer->AsBufferView(),
        .index_buffer = host_buffer.Emplace(
            indices.data(), count * sizeof(uint16_t), alignof(uint16_t)),
        .index_count = count,
        .index_type = IndexType::k16bit};
    cmd.BindVertices(render_vertex_buffer);

    VS::FrameInfo frame_info;
    auto world_matrix = Matrix::MakeScale(GetContentScale());
    frame_info.mvp =
        Matrix::MakeOrthographic(pass.GetRenderTargetSize()) * world_matrix;
    VS::BindFrameInfo(cmd,
                      pass.GetTransientsBuffer().EmplaceUniform(frame_info));

    FS::FragInfo frag_info;
    frag_info.color = Color::Red().Premultiply();
    FS::BindFragInfo(cmd, pass.GetTransientsBuffer().EmplaceUniform(frag_info));

    if (!pass.AddCommand(std::move(cmd))) {
      return false;
    }

    return true;
  };
  ASSERT_TRUE(OpenPlaygroundHere(callback));

  // The latch is down here because it's expected that on Metal the backend will
  // take care of synchronizing the buffer between the compute and render pass
  // usages, since it's not MTLHeap allocated.
  // However, if playgrounds are disabled, no render pass actually gets
  // submitted and we need to do a CPU latch here.
  latch.Wait();

  auto vertex_count = reinterpret_cast<SS::VertexBufferCount*>(
                          vertex_buffer_count->AsBufferView().contents)
                          ->count;
  EXPECT_EQ(vertex_count, golden_cubic_and_quad_points.size());
  auto vertex_buffer_data = reinterpret_cast<SS::VertexBuffer<2048>*>(
      vertex_buffer->AsBufferView().contents);
  for (size_t i = 0; i < vertex_count; i++) {
    EXPECT_LT(std::abs(golden_cubic_and_quad_points[i].x -
                       vertex_buffer_data->position[i].x),
              1e-3);
    EXPECT_LT(std::abs(golden_cubic_and_quad_points[i].y -
                       vertex_buffer_data->position[i].y),
              1e-3);
  }
}

TEST_P(ComputeSubgroupTest, HeartCubicsToStrokeVertices) {
  using CS = CubicToQuadsComputeShader;
  using QS = QuadPolylineComputeShader;
  using SS = StrokeComputeShader;

  auto context = GetContext();
  ASSERT_TRUE(context);
  ASSERT_TRUE(context->GetCapabilities()->SupportsComputeSubgroups());

  auto cmd_buffer = context->CreateCommandBuffer();
  auto pass = cmd_buffer->CreateComputePass();
  ASSERT_TRUE(pass && pass->IsValid());

  static constexpr size_t kCubicCount = 6;
  static constexpr Scalar kAccuracy = .1;

  auto quads = CreateHostVisibleDeviceBuffer<CS::Quads<kCubicCount * 10>>(
      context, "Quads");

  // TODO(dnfield): Size this buffer more accurately.
  auto polyline =
      CreateHostVisibleDeviceBuffer<QS::Polyline<kCubicCount * 10 * 10>>(
          context, "polyline");

  auto vertex_buffer_count =
      CreateHostVisibleDeviceBuffer<SS::VertexBufferCount>(context,
                                                           "VertexBufferCount");

  // TODO(dnfield): Size this buffer more accurately.
  auto vertex_buffer = CreateHostVisibleDeviceBuffer<
      SS::VertexBuffer<kCubicCount * 10 * 10 * 4>>(context, "VertexBuffer");

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
    cmd.label = "Compute Stroke";
    cmd.pipeline = compute_pipeline;

    SS::Config config{.width = 1.0f, .cap = 1, .join = 1, .miter_limit = 4.0f};
    SS::BindConfig(cmd, pass->GetTransientsBuffer().EmplaceUniform(config));

    SS::BindPolyline(cmd, polyline->AsBufferView());
    SS::BindVertexBufferCount(cmd, vertex_buffer_count->AsBufferView());
    SS::BindVertexBuffer(cmd, vertex_buffer->AsBufferView());

    ASSERT_TRUE(pass->AddCommand(std::move(cmd)));
  }

  ASSERT_TRUE(pass->EncodeCommands());

  fml::AutoResetWaitableEvent latch;
  ASSERT_TRUE(cmd_buffer->SubmitCommands([&latch, quads, polyline,
                                          vertex_buffer_count, vertex_buffer](
                                             CommandBuffer::Status status) {
    EXPECT_EQ(status, CommandBuffer::Status::kCompleted);

    auto* q = reinterpret_cast<CS::Quads<kCubicCount * 10>*>(
        quads->AsBufferView().contents);

    EXPECT_EQ(q->count, golden_heart_quads.size());
    for (size_t i = 0; i < q->count; i++) {
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
    auto* v_count = reinterpret_cast<SS::VertexBufferCount*>(
        vertex_buffer_count->AsBufferView().contents);
    EXPECT_EQ(v_count->count, golden_heart_vertices.size());
    for (size_t i = 0; i < v_count->count; i += 1) {
      EXPECT_LT(std::abs(golden_heart_vertices[i].x - v->position[i].x), 1e-3);
      EXPECT_LT(std::abs(golden_heart_vertices[i].y - v->position[i].y), 1e-3);
    }

    latch.Signal();
  }));

  latch.Wait();

  auto callback = [&](RenderPass& pass) -> bool {
    ContentContext renderer(context);
    if (!renderer.IsValid()) {
      return false;
    }

    using VS = SolidFillPipeline::VertexShader;
    using FS = SolidFillPipeline::FragmentShader;

    Command cmd;
    cmd.label = "Draw Stroke";
    cmd.stencil_reference = 0;

    ContentContextOptions options;
    options.sample_count = pass.GetRenderTarget().GetSampleCount();
    options.color_attachment_pixel_format =
        pass.GetRenderTarget().GetRenderTargetPixelFormat();
    options.has_stencil_attachment =
        pass.GetRenderTarget().GetStencilAttachment().has_value();
    options.blend_mode = BlendMode::kSourceIn;
    options.primitive_type = PrimitiveType::kTriangleStrip;
    options.stencil_compare = CompareFunction::kEqual;
    options.stencil_operation = StencilOperation::kIncrementClamp;

    cmd.pipeline = renderer.GetSolidFillPipeline(options);

    auto count = reinterpret_cast<SS::VertexBufferCount*>(
                     vertex_buffer_count->AsBufferView().contents)
                     ->count;
    auto& host_buffer = pass.GetTransientsBuffer();
    std::vector<uint16_t> indices(count);
    std::iota(std::begin(indices), std::end(indices), 0);

    VertexBuffer render_vertex_buffer{
        .vertex_buffer = vertex_buffer->AsBufferView(),
        .index_buffer = host_buffer.Emplace(
            indices.data(), count * sizeof(uint16_t), alignof(uint16_t)),
        .index_count = count,
        .index_type = IndexType::k16bit};
    cmd.BindVertices(render_vertex_buffer);

    VS::FrameInfo frame_info;
    auto world_matrix = Matrix::MakeScale(GetContentScale());
    frame_info.mvp =
        Matrix::MakeOrthographic(pass.GetRenderTargetSize()) * world_matrix;
    VS::BindFrameInfo(cmd,
                      pass.GetTransientsBuffer().EmplaceUniform(frame_info));

    FS::FragInfo frag_info;
    frag_info.color = Color::Red().Premultiply();
    FS::BindFragInfo(cmd, pass.GetTransientsBuffer().EmplaceUniform(frag_info));

    if (!pass.AddCommand(std::move(cmd))) {
      return false;
    }

    return true;
  };
  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

TEST_P(ComputeSubgroupTest, QuadsToPolyline) {
  using QS = QuadPolylineComputeShader;
  auto context = GetContext();
  ASSERT_TRUE(context);
  ASSERT_TRUE(context->GetCapabilities()->SupportsComputeSubgroups());

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

  auto polyline = CreateHostVisibleDeviceBuffer<QS::Polyline<kPolylineCount>>(
      context, "polyline");

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
