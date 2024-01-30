// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/compute_tessellator.h"

#include <cstdint>

#include "impeller/core/host_buffer.h"
#include "impeller/renderer/command_buffer.h"
#include "impeller/renderer/path_polyline.comp.h"
#include "impeller/renderer/pipeline_library.h"
#include "impeller/renderer/stroke.comp.h"

namespace impeller {

ComputeTessellator::ComputeTessellator() = default;
ComputeTessellator::~ComputeTessellator() = default;

template <typename T>
static std::shared_ptr<DeviceBuffer> CreateDeviceBuffer(
    const std::shared_ptr<Context>& context,
    const std::string& label,
    StorageMode storage_mode = StorageMode::kDevicePrivate) {
  DeviceBufferDescriptor desc;
  desc.storage_mode = storage_mode;
  desc.size = sizeof(T);
  auto buffer = context->GetResourceAllocator()->CreateBuffer(desc);
  buffer->SetLabel(label);
  return buffer;
}

ComputeTessellator& ComputeTessellator::SetStyle(Style value) {
  style_ = value;
  return *this;
}

ComputeTessellator& ComputeTessellator::SetStrokeWidth(Scalar value) {
  stroke_width_ = value;
  return *this;
}

ComputeTessellator& ComputeTessellator::SetStrokeJoin(Join value) {
  stroke_join_ = value;
  return *this;
}
ComputeTessellator& ComputeTessellator::SetStrokeCap(Cap value) {
  stroke_cap_ = value;
  return *this;
}
ComputeTessellator& ComputeTessellator::SetMiterLimit(Scalar value) {
  miter_limit_ = value;
  return *this;
}
ComputeTessellator& ComputeTessellator::SetCubicAccuracy(Scalar value) {
  cubic_accuracy_ = value;
  return *this;
}
ComputeTessellator& ComputeTessellator::SetQuadraticTolerance(Scalar value) {
  quad_tolerance_ = value;
  return *this;
}

ComputeTessellator::Status ComputeTessellator::Tessellate(
    const Path& path,
    HostBuffer& host_buffer,
    const std::shared_ptr<Context>& context,
    BufferView vertex_buffer,
    BufferView vertex_buffer_count,
    const CommandBuffer::CompletionCallback& callback) const {
  FML_DCHECK(style_ == Style::kStroke);
  using PS = PathPolylineComputeShader;
  using SS = StrokeComputeShader;

  auto cubic_count = path.GetComponentCount(Path::ComponentType::kCubic);
  auto quad_count = path.GetComponentCount(Path::ComponentType::kQuadratic) +
                    (cubic_count * 6);
  auto line_count =
      path.GetComponentCount(Path::ComponentType::kLinear) + (quad_count * 6);
  if (cubic_count > kMaxCubicCount || quad_count > kMaxQuadCount ||
      line_count > kMaxLineCount) {
    return Status::kTooManyComponents;
  }
  PS::Cubics<kMaxCubicCount> cubics{.count = 0};
  PS::Quads<kMaxQuadCount> quads{.count = 0};
  PS::Lines<kMaxLineCount> lines{.count = 0};
  PS::Components<kMaxComponentCount> components{.count = 0};
  PS::Config config{.cubic_accuracy = cubic_accuracy_,
                    .quad_tolerance = quad_tolerance_};

  path.EnumerateComponents(
      [&lines, &components](size_t index, const LinearPathComponent& linear) {
        ::memcpy(&lines.data[lines.count], &linear,
                 sizeof(LinearPathComponent));
        components.data[components.count++] = {lines.count++, 2};
      },
      [&quads, &components](size_t index, const QuadraticPathComponent& quad) {
        ::memcpy(&quads.data[quads.count], &quad,
                 sizeof(QuadraticPathComponent));
        components.data[components.count++] = {quads.count++, 3};
      },
      [&cubics, &components](size_t index, const CubicPathComponent& cubic) {
        ::memcpy(&cubics.data[cubics.count], &cubic,
                 sizeof(CubicPathComponent));
        components.data[components.count++] = {cubics.count++, 4};
      },
      [](size_t index, const ContourComponent& contour) {});

  auto polyline_buffer =
      CreateDeviceBuffer<PS::Polyline<2048>>(context, "Polyline");

  auto cmd_buffer = context->CreateCommandBuffer();
  auto pass = cmd_buffer->CreateComputePass();
  FML_DCHECK(pass && pass->IsValid());

  {
    using PathPolylinePipelineBuilder = ComputePipelineBuilder<PS>;
    auto pipeline_desc =
        PathPolylinePipelineBuilder::MakeDefaultPipelineDescriptor(*context);
    FML_DCHECK(pipeline_desc.has_value());
    auto compute_pipeline =
        context->GetPipelineLibrary()->GetPipeline(pipeline_desc).Get();
    FML_DCHECK(compute_pipeline);

    pass->SetPipeline(compute_pipeline);
    pass->SetCommandLabel("Generate Polyline");

    PS::BindConfig(*pass, host_buffer.EmplaceUniform(config));
    PS::BindCubics(*pass, host_buffer.EmplaceStorageBuffer(cubics));
    PS::BindQuads(*pass, host_buffer.EmplaceStorageBuffer(quads));
    PS::BindLines(*pass, host_buffer.EmplaceStorageBuffer(lines));
    PS::BindComponents(*pass, host_buffer.EmplaceStorageBuffer(components));
    PS::BindPolyline(*pass, DeviceBuffer::AsBufferView(polyline_buffer));

    if (!pass->Compute(ISize(line_count, 1)).ok()) {
      return Status::kCommandInvalid;
    }
  }

  {
    using StrokePipelineBuilder = ComputePipelineBuilder<SS>;
    auto pipeline_desc =
        StrokePipelineBuilder::MakeDefaultPipelineDescriptor(*context);
    FML_DCHECK(pipeline_desc.has_value());
    auto compute_pipeline =
        context->GetPipelineLibrary()->GetPipeline(pipeline_desc).Get();
    FML_DCHECK(compute_pipeline);

    pass->AddBufferMemoryBarrier();
    pass->SetPipeline(compute_pipeline);
    pass->SetCommandLabel("Compute Stroke");

    SS::Config config{
        .width = stroke_width_,
        .cap = static_cast<uint32_t>(stroke_cap_),
        .join = static_cast<uint32_t>(stroke_join_),
        .miter_limit = miter_limit_,
    };
    SS::BindConfig(*pass, host_buffer.EmplaceUniform(config));

    SS::BindPolyline(*pass, DeviceBuffer::AsBufferView(polyline_buffer));
    SS::BindVertexBufferCount(*pass, std::move(vertex_buffer_count));
    SS::BindVertexBuffer(*pass, std::move(vertex_buffer));

    if (!pass->Compute(ISize(line_count, 1)).ok()) {
      return Status::kCommandInvalid;
    }
  }

  if (!pass->EncodeCommands()) {
    return Status::kCommandInvalid;
  }

  if (!context->GetCommandQueue()->Submit({cmd_buffer}, callback).ok()) {
    return Status::kCommandInvalid;
  }

  return Status::kOk;
}

}  // namespace impeller
