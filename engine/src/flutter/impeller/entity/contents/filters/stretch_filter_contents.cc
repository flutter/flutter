// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/filters/stretch_filter_contents.h"

#include <cmath>

#include "impeller/entity/contents/anonymous_contents.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/contents/contents.h"
#include "impeller/entity/contents/texture_contents.h"
#include "impeller/geometry/point.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/vertex_buffer_builder.h"

namespace impeller {

StretchFilterContents::StretchFilterContents() = default;

StretchFilterContents::~StretchFilterContents() = default;

void StretchFilterContents::SetOverscroll(Scalar overscroll_x,
                                          Scalar overscroll_y) {
  overscroll_x_ = overscroll_x;
  overscroll_y_ = overscroll_y;
}

void StretchFilterContents::SetInterpolationStrength(
    Scalar interpolation_strength) {
  interpolation_strength_ = interpolation_strength;
}

void StretchFilterContents::SetStretchBounds(const Rect& stretch_bounds) {
  stretch_bounds_ = stretch_bounds;
}

std::optional<Rect> StretchFilterContents::GetFilterSourceCoverage(
    const Matrix& effect_transform,
    const Rect& output_limit) const {
  if (output_limit.IsEmpty()) {
    return std::nullopt;
  }
  if (!stretch_bounds_.IsEmpty()) {
    // Under a rotated CTM, TransformBounds computes the axis-aligned bounding
    // box in device space, so the stretch distortion acts along device axes.
    Rect transformed_stretch = stretch_bounds_.TransformBounds(effect_transform);
    if (!transformed_stretch.IntersectsWithRect(output_limit)) {
      return std::nullopt;
    }
    return output_limit.Union(transformed_stretch);
  }
  return output_limit;
}

std::optional<Entity> StretchFilterContents::RenderFilter(
    const FilterInput::Vector& inputs,
    const ContentContext& renderer,
    const Entity& entity,
    const Matrix& effect_transform,
    const Rect& coverage,
    const std::optional<Rect>& coverage_hint) const {
  if (inputs.empty()) {
    return std::nullopt;
  }

  using VS = StretchFilterPipeline::VertexShader;
  using FS = StretchFilterPipeline::FragmentShader;

  auto input_snapshot = inputs[0]->GetSnapshot("Stretch", renderer, entity);
  if (!input_snapshot.has_value()) {
    return std::nullopt;
  }

  if (ScalarNearlyZero(overscroll_x_) && ScalarNearlyZero(overscroll_y_)) {
    return Entity::FromSnapshot(input_snapshot.value(), entity.GetBlendMode());
  }

  Scalar abs_ox = std::abs(overscroll_x_);
  Scalar abs_oy = std::abs(overscroll_y_);
  Vector2 overscroll(overscroll_x_, overscroll_y_);
  Vector2 u_d(1.0f / (1.0f + abs_ox), 1.0f / (1.0f + abs_oy));
  Vector2 u_s(1.0f + abs_ox * (1.0f - interpolation_strength_),
              1.0f + abs_oy * (1.0f - interpolation_strength_));
  Scalar interp = interpolation_strength_;

  Vector4 container_uv(0.0f, 0.0f, 1.0f, 1.0f);
  if (!stretch_bounds_.IsEmpty()) {
    const auto size = input_snapshot->texture->GetSize();
    const Matrix uv_to_pass =
        input_snapshot->transform * Matrix::MakeScale(Vector2(size));
    if (uv_to_pass.IsInvertible()) {
      const Rect pass_stretch =
          stretch_bounds_.TransformBounds(effect_transform);
      const Rect uv_rect = pass_stretch.TransformBounds(uv_to_pass.Invert());
      container_uv = Vector4(uv_rect.GetLeft(), uv_rect.GetTop(),
                             uv_rect.GetWidth(), uv_rect.GetHeight());
    }
  }

  RenderProc render_proc =
      [input_snapshot, overscroll, u_d, u_s, interp, container_uv](
          const ContentContext& renderer, const Entity& entity,
          RenderPass& pass) -> bool {
    pass.SetCommandLabel("Stretch Filter");

    auto options = OptionsFromPassAndEntity(pass, entity);
    options.primitive_type = PrimitiveType::kTriangleStrip;
    pass.SetPipeline(renderer.GetStretchFilterPipeline(options));

    auto size = input_snapshot->texture->GetSize();

    std::array<VS::PerVertexData, 4> vertices = {
        VS::PerVertexData{Point(0, 0)},
        VS::PerVertexData{Point(1, 0)},
        VS::PerVertexData{Point(0, 1)},
        VS::PerVertexData{Point(1, 1)},
    };

    auto& data_host_buffer = renderer.GetTransientsDataBuffer();
    pass.SetVertexBuffer(CreateVertexBuffer(vertices, data_host_buffer));

    Matrix snapshot_to_pass = entity.GetTransform() *
                              input_snapshot->transform *
                              Matrix::MakeScale(Vector2(size));

    VS::FrameInfo frame_info;
    frame_info.mvp = Entity::GetShaderTransform(
        entity.GetShaderClipDepth(), pass, snapshot_to_pass);

    FS::FragInfo frag_info;
    frag_info.container_uv = container_uv;
    frag_info.overscroll = overscroll;
    frag_info.u_d = u_d;
    frag_info.u_s = u_s;
    frag_info.interpolation_strength = interp;
    frag_info.input_alpha = input_snapshot->opacity;

    SamplerDescriptor sampler_desc = input_snapshot->sampler_descriptor;
    sampler_desc.width_address_mode = SamplerAddressMode::kClampToEdge;
    sampler_desc.height_address_mode = SamplerAddressMode::kClampToEdge;
    raw_ptr<const Sampler> sampler =
        renderer.GetContext()->GetSamplerLibrary()->GetSampler(sampler_desc);
    FS::BindInputTexture(pass, input_snapshot->texture, sampler);
    FS::BindFragInfo(pass, data_host_buffer.EmplaceUniform(frag_info));
    VS::BindFrameInfo(pass, data_host_buffer.EmplaceUniform(frame_info));

    return pass.Draw().ok();
  };

  CoverageProc coverage_proc =
      [coverage](const Entity& entity) -> std::optional<Rect> {
    return coverage.TransformBounds(entity.GetTransform());
  };

  std::shared_ptr<Contents> contents =
      AnonymousContents::Make(render_proc, coverage_proc);

  Entity sub_entity;
  sub_entity.SetContents(std::move(contents));
  sub_entity.SetBlendMode(entity.GetBlendMode());
  return sub_entity;
}

}  // namespace impeller
