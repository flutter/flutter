// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <future>
#include <numeric>

#include "compute_tessellator.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/fml/time/time_point.h"
#include "flutter/testing/testing.h"
#include "gmock/gmock.h"
#include "impeller/base/strings.h"
#include "impeller/core/formats.h"
#include "impeller/display_list/skia_conversions.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/fixtures/golden_paths.h"
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
#include "third_party/imgui/imgui.h"
#include "third_party/skia/include/utils/SkParsePath.h"

namespace impeller {
namespace testing {

using ComputeSubgroupTest = ComputePlaygroundTest;
INSTANTIATE_COMPUTE_SUITE(ComputeSubgroupTest);

TEST_P(ComputeSubgroupTest, CapabilitiesSuportSubgroups) {
  auto context = GetContext();
  ASSERT_TRUE(context);
  ASSERT_TRUE(context->GetCapabilities()->SupportsComputeSubgroups());
}

TEST_P(ComputeSubgroupTest, PathPlayground) {
  // Renders stroked SVG paths in an interactive playground.
  using SS = StrokeComputeShader;

  auto context = GetContext();
  ASSERT_TRUE(context);
  ASSERT_TRUE(context->GetCapabilities()->SupportsComputeSubgroups());
  char svg_path_data[16384] =
      "M140 20 "
      "C73 20 20 74 20 140 "
      "c0 135 136 170 228 303 "
      "88-132 229-173 229-303 "
      "0-66-54-120-120-120 "
      "-48 0-90 28-109 69 "
      "-19-41-60-69-108-69z";
  size_t vertex_count = 0;
  Scalar stroke_width = 1.0;

  auto vertex_buffer = CreateHostVisibleDeviceBuffer<SS::VertexBuffer<2048>>(
      context, "VertexBuffer");
  auto vertex_buffer_count =
      CreateHostVisibleDeviceBuffer<SS::VertexBufferCount>(context,
                                                           "VertexCount");

  auto callback = [&](RenderPass& pass) -> bool {
    ::memset(vertex_buffer_count->AsBufferView().contents, 0,
             sizeof(SS::VertexBufferCount));
    ::memset(vertex_buffer->AsBufferView().contents, 0,
             sizeof(SS::VertexBuffer<2048>));
    const auto* main_viewport = ImGui::GetMainViewport();
    ImGui::SetNextWindowPos(
        ImVec2(main_viewport->WorkPos.x + 650, main_viewport->WorkPos.y + 20));
    ImGui::Begin("Path data", nullptr, ImGuiWindowFlags_AlwaysAutoResize);
    ImGui::InputTextMultiline("Path", svg_path_data,
                              IM_ARRAYSIZE(svg_path_data));
    ImGui::DragFloat("Stroke width", &stroke_width, .1, 0.0, 25.0);

    SkPath sk_path;
    if (SkParsePath::FromSVGString(svg_path_data, &sk_path)) {
      std::promise<bool> promise;
      auto future = promise.get_future();

      auto path = skia_conversions::ToPath(sk_path);
      auto status =
          ComputeTessellator{}
              .SetStrokeWidth(stroke_width)
              .Tessellate(
                  path, context, vertex_buffer->AsBufferView(),
                  vertex_buffer_count->AsBufferView(),
                  [vertex_buffer_count, &vertex_count,
                   &promise](CommandBuffer::Status status) {
                    vertex_count =
                        reinterpret_cast<SS::VertexBufferCount*>(
                            vertex_buffer_count->AsBufferView().contents)
                            ->count;
                    promise.set_value(status ==
                                      CommandBuffer::Status::kCompleted);
                  });
      switch (status) {
        case ComputeTessellator::Status::kCommandInvalid:
          ImGui::Text("Failed to submit compute job (invalid command)");
          break;
        case ComputeTessellator::Status::kTooManyComponents:
          ImGui::Text("Failed to submit compute job (too many components) ");
          break;
        case ComputeTessellator::Status::kOk:
          break;
      }
      if (!future.get()) {
        ImGui::Text("Failed to submit compute job.");
        return false;
      }
      if (vertex_count > 0) {
        ImGui::Text("Vertex count: %zu", vertex_count);
      }
    } else {
      ImGui::Text("Failed to parse path data");
    }
    ImGui::End();

    ContentContext renderer(context);
    if (!renderer.IsValid()) {
      return false;
    }

    using VS = SolidFillPipeline::VertexShader;

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

    VertexBuffer render_vertex_buffer{
        .vertex_buffer = vertex_buffer->AsBufferView(),
        .vertex_count = count,
        .index_type = IndexType::kNone};
    cmd.BindVertices(render_vertex_buffer);

    VS::FrameInfo frame_info;
    auto world_matrix = Matrix::MakeScale(GetContentScale());
    frame_info.mvp =
        Matrix::MakeOrthographic(pass.GetRenderTargetSize()) * world_matrix;
    frame_info.color = Color::Red().Premultiply();
    VS::BindFrameInfo(cmd,
                      pass.GetTransientsBuffer().EmplaceUniform(frame_info));

    if (!pass.AddCommand(std::move(cmd))) {
      return false;
    }

    return true;
  };
  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

TEST_P(ComputeSubgroupTest, LargePath) {
  // The path in here is large enough to highlight issues around exceeding
  // subgroup size.
  using SS = StrokeComputeShader;

  auto context = GetContext();
  ASSERT_TRUE(context);
  ASSERT_TRUE(context->GetCapabilities()->SupportsComputeSubgroups());
  size_t vertex_count = 0;
  Scalar stroke_width = 1.0;

  auto vertex_buffer = CreateHostVisibleDeviceBuffer<SS::VertexBuffer<2048>>(
      context, "VertexBuffer");
  auto vertex_buffer_count =
      CreateHostVisibleDeviceBuffer<SS::VertexBufferCount>(context,
                                                           "VertexCount");

  auto complex_path =
      PathBuilder{}
          .MoveTo({359.934, 96.6335})
          .CubicCurveTo({358.189, 96.7055}, {356.436, 96.7908},
                        {354.673, 96.8895})
          .CubicCurveTo({354.571, 96.8953}, {354.469, 96.9016},
                        {354.367, 96.9075})
          .CubicCurveTo({352.672, 97.0038}, {350.969, 97.113},
                        {349.259, 97.2355})
          .CubicCurveTo({349.048, 97.2506}, {348.836, 97.2678},
                        {348.625, 97.2834})
          .CubicCurveTo({347.019, 97.4014}, {345.407, 97.5299},
                        {343.789, 97.6722})
          .CubicCurveTo({343.428, 97.704}, {343.065, 97.7402},
                        {342.703, 97.7734})
          .CubicCurveTo({341.221, 97.9086}, {339.736, 98.0505},
                        {338.246, 98.207})
          .CubicCurveTo({337.702, 98.2642}, {337.156, 98.3292},
                        {336.612, 98.3894})
          .CubicCurveTo({335.284, 98.5356}, {333.956, 98.6837},
                        {332.623, 98.8476})
          .CubicCurveTo({332.495, 98.8635}, {332.366, 98.8818},
                        {332.237, 98.8982})
          .LineTo({332.237, 102.601})
          .LineTo({321.778, 102.601})
          .LineTo({321.778, 100.382})
          .CubicCurveTo({321.572, 100.413}, {321.367, 100.442},
                        {321.161, 100.476})
          .CubicCurveTo({319.22, 100.79}, {317.277, 101.123},
                        {315.332, 101.479})
          .CubicCurveTo({315.322, 101.481}, {315.311, 101.482},
                        {315.301, 101.484})
          .LineTo({310.017, 105.94})
          .LineTo({309.779, 105.427})
          .LineTo({314.403, 101.651})
          .CubicCurveTo({314.391, 101.653}, {314.379, 101.656},
                        {314.368, 101.658})
          .CubicCurveTo({312.528, 102.001}, {310.687, 102.366},
                        {308.846, 102.748})
          .CubicCurveTo({307.85, 102.955}, {306.855, 103.182}, {305.859, 103.4})
          .CubicCurveTo({305.048, 103.579}, {304.236, 103.75},
                        {303.425, 103.936})
          .LineTo({299.105, 107.578})
          .LineTo({298.867, 107.065})
          .LineTo({302.394, 104.185})
          .LineTo({302.412, 104.171})
          .CubicCurveTo({301.388, 104.409}, {300.366, 104.67},
                        {299.344, 104.921})
          .CubicCurveTo({298.618, 105.1}, {297.89, 105.269}, {297.165, 105.455})
          .CubicCurveTo({295.262, 105.94}, {293.36, 106.445},
                        {291.462, 106.979})
          .CubicCurveTo({291.132, 107.072}, {290.802, 107.163},
                        {290.471, 107.257})
          .CubicCurveTo({289.463, 107.544}, {288.455, 107.839},
                        {287.449, 108.139})
          .CubicCurveTo({286.476, 108.431}, {285.506, 108.73},
                        {284.536, 109.035})
          .CubicCurveTo({283.674, 109.304}, {282.812, 109.579},
                        {281.952, 109.859})
          .CubicCurveTo({281.177, 110.112}, {280.406, 110.377},
                        {279.633, 110.638})
          .CubicCurveTo({278.458, 111.037}, {277.256, 111.449},
                        {276.803, 111.607})
          .CubicCurveTo({276.76, 111.622}, {276.716, 111.637},
                        {276.672, 111.653})
          .CubicCurveTo({275.017, 112.239}, {273.365, 112.836},
                        {271.721, 113.463})
          .LineTo({271.717, 113.449})
          .CubicCurveTo({271.496, 113.496}, {271.238, 113.559},
                        {270.963, 113.628})
          .CubicCurveTo({270.893, 113.645}, {270.822, 113.663},
                        {270.748, 113.682})
          .CubicCurveTo({270.468, 113.755}, {270.169, 113.834},
                        {269.839, 113.926})
          .CubicCurveTo({269.789, 113.94}, {269.732, 113.957},
                        {269.681, 113.972})
          .CubicCurveTo({269.391, 114.053}, {269.081, 114.143},
                        {268.756, 114.239})
          .CubicCurveTo({268.628, 114.276}, {268.5, 114.314},
                        {268.367, 114.354})
          .CubicCurveTo({268.172, 114.412}, {267.959, 114.478},
                        {267.752, 114.54})
          .CubicCurveTo({263.349, 115.964}, {258.058, 117.695},
                        {253.564, 119.252})
          .CubicCurveTo({253.556, 119.255}, {253.547, 119.258},
                        {253.538, 119.261})
          .CubicCurveTo({251.844, 119.849}, {250.056, 120.474},
                        {248.189, 121.131})
          .CubicCurveTo({248, 121.197}, {247.812, 121.264}, {247.621, 121.331})
          .CubicCurveTo({247.079, 121.522}, {246.531, 121.715},
                        {245.975, 121.912})
          .CubicCurveTo({245.554, 122.06}, {245.126, 122.212},
                        {244.698, 122.364})
          .CubicCurveTo({244.071, 122.586}, {243.437, 122.811},
                        {242.794, 123.04})
          .CubicCurveTo({242.189, 123.255}, {241.58, 123.472},
                        {240.961, 123.693})
          .CubicCurveTo({240.659, 123.801}, {240.357, 123.909},
                        {240.052, 124.018})
          .CubicCurveTo({239.12, 124.351}, {238.18, 124.687}, {237.22, 125.032})
          .LineTo({237.164, 125.003})
          .CubicCurveTo({236.709, 125.184}, {236.262, 125.358},
                        {235.81, 125.538})
          .CubicCurveTo({235.413, 125.68}, {234.994, 125.832},
                        {234.592, 125.977})
          .CubicCurveTo({234.592, 125.977}, {234.591, 125.977},
                        {234.59, 125.977})
          .CubicCurveTo({222.206, 130.435}, {207.708, 135.753},
                        {192.381, 141.429})
          .CubicCurveTo({162.77, 151.336}, {122.17, 156.894}, {84.1123, 160})
          .LineTo({360, 160})
          .LineTo({360, 119.256})
          .LineTo({360, 106.332})
          .LineTo({360, 96.6307})
          .CubicCurveTo({359.978, 96.6317}, {359.956, 96.6326},
                        {359.934, 96.6335})
          .Close()
          .TakePath();

  auto callback = [&](RenderPass& pass) -> bool {
    ::memset(vertex_buffer_count->AsBufferView().contents, 0,
             sizeof(SS::VertexBufferCount));
    ::memset(vertex_buffer->AsBufferView().contents, 0,
             sizeof(SS::VertexBuffer<2048>));

    ComputeTessellator{}
        .SetStrokeWidth(stroke_width)
        .Tessellate(
            complex_path, context, vertex_buffer->AsBufferView(),
            vertex_buffer_count->AsBufferView(),
            [vertex_buffer_count, &vertex_count](CommandBuffer::Status status) {
              vertex_count = reinterpret_cast<SS::VertexBufferCount*>(
                                 vertex_buffer_count->AsBufferView().contents)
                                 ->count;
            });

    ContentContext renderer(context);
    if (!renderer.IsValid()) {
      return false;
    }

    using VS = SolidFillPipeline::VertexShader;

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

    VertexBuffer render_vertex_buffer{
        .vertex_buffer = vertex_buffer->AsBufferView(),
        .vertex_count = count,
        .index_type = IndexType::kNone};
    cmd.BindVertices(render_vertex_buffer);

    VS::FrameInfo frame_info;
    auto world_matrix = Matrix::MakeScale(GetContentScale());
    frame_info.mvp =
        Matrix::MakeOrthographic(pass.GetRenderTargetSize()) * world_matrix;
    frame_info.color = Color::Red().Premultiply();
    VS::BindFrameInfo(cmd,
                      pass.GetTransientsBuffer().EmplaceUniform(frame_info));

    if (!pass.AddCommand(std::move(cmd))) {
      return false;
    }

    return true;
  };
  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

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

    VertexBuffer render_vertex_buffer{
        .vertex_buffer = vertex_buffer->AsBufferView(),
        .vertex_count = count,
        .index_type = IndexType::kNone};
    cmd.BindVertices(render_vertex_buffer);

    VS::FrameInfo frame_info;
    auto world_matrix = Matrix::MakeScale(GetContentScale());
    frame_info.mvp =
        Matrix::MakeOrthographic(pass.GetRenderTargetSize()) * world_matrix;
    frame_info.color = Color::Red().Premultiply();
    VS::BindFrameInfo(cmd,
                      pass.GetTransientsBuffer().EmplaceUniform(frame_info));

    if (!pass.AddCommand(std::move(cmd))) {
      return false;
    }

    return true;
  };
  ASSERT_TRUE(OpenPlaygroundHere(callback));

  // The latch is down here because it's expected that on Metal the backend
  // will take care of synchronizing the buffer between the compute and render
  // pass usages, since it's not MTLHeap allocated. However, if playgrounds
  // are disabled, no render pass actually gets submitted and we need to do a
  // CPU latch here.
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

}  // namespace testing
}  // namespace impeller
