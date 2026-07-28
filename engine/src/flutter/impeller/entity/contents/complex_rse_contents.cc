// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/complex_rse_contents.h"

#include "impeller/entity/contents/color_source_contents.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/contents/pipelines.h"
#include "impeller/entity/geometry/geometry.h"

namespace impeller {

namespace {

using PipelineBuilderCallback =
    std::function<PipelineRef(ContentContextOptions)>;

using VS = ComplexRSEPipeline::VertexShader;
using FS = ComplexRSEPipeline::FragmentShader;

}  // namespace

std::unique_ptr<ComplexRoundedSuperellipseContents>
ComplexRoundedSuperellipseContents::Make(
    Color color,
    const Rect& bounds,
    const RoundSuperellipseParam& round_superellipse_params,
    std::optional<StrokeParameters> stroke) {
  return std::unique_ptr<ComplexRoundedSuperellipseContents>(
      new ComplexRoundedSuperellipseContents(
          color, bounds, round_superellipse_params, stroke));
}

ComplexRoundedSuperellipseContents::ComplexRoundedSuperellipseContents(
    Color color,
    const Rect& bounds,
    const RoundSuperellipseParam& round_superellipse_params,
    std::optional<StrokeParameters> stroke)
    : color_(color),
      bounds_(bounds),
      round_superellipse_params_(round_superellipse_params),
      stroke_(stroke) {
  if (stroke) {
    geometry_ = Geometry::MakeRect(bounds_.Expand(stroke->width / 2.0f));
  } else {
    geometry_ = Geometry::MakeRect(bounds_);
  }
}

bool ComplexRoundedSuperellipseContents::Render(const ContentContext& renderer,
                                                const Entity& entity,
                                                RenderPass& pass) const {
  auto& data_host_buffer = renderer.GetTransientsDataBuffer();

  Point center = bounds_.GetCenter();

  RoundSuperellipseParam::Quadrant top_right =
      round_superellipse_params_.top_right;
  RoundSuperellipseParam::Quadrant bottom_right =
      round_superellipse_params_.bottom_right;
  RoundSuperellipseParam::Quadrant bottom_left =
      round_superellipse_params_.bottom_left;
  RoundSuperellipseParam::Quadrant top_left =
      round_superellipse_params_.top_left;

  Point top_right_center_relative = top_right.offset - center;
  Point bottom_right_center_relative = bottom_right.offset - center;
  Point bottom_left_center_relative = bottom_left.offset - center;
  Point top_left_center_relative = top_left.offset - center;

  Point size = Point(bounds_.GetSize() * 0.5f);

  VS::FrameInfo frame_info;
  FS::FragInfo frag_info;

  frag_info.color = color_.WithAlpha(color_.alpha * GetOpacityFactor());
  frag_info.center = center;
  frag_info.size = size;
  frag_info.stroked = stroke_ ? 1.0f : 0.0f;
  frag_info.stroke_width = stroke_ ? stroke_->width : 0.0f;

  frag_info.superellipse_degrees_top =
      Vector4(bottom_right.top.se_n, top_right.top.se_n, bottom_left.top.se_n,
              top_left.top.se_n);
  frag_info.superellipse_degrees_right =
      Vector4(bottom_right.right.se_n, top_right.right.se_n,
              bottom_left.right.se_n, top_left.right.se_n);
  frag_info.superellipse_semi_axes_top =
      Vector4(bottom_right.top.se_a, top_right.top.se_a, bottom_left.top.se_a,
              top_left.top.se_a);
  frag_info.superellipse_semi_axes_right =
      Vector4(bottom_right.right.se_a, top_right.right.se_a,
              bottom_left.right.se_a, top_left.right.se_a);
  frag_info.angle_spans_top = Vector4(bottom_right.top.circle_max_angle.radians,
                                      top_right.top.circle_max_angle.radians,
                                      bottom_left.top.circle_max_angle.radians,
                                      top_left.top.circle_max_angle.radians);
  frag_info.angle_spans_right =
      Vector4(bottom_right.right.circle_max_angle.radians,
              top_right.right.circle_max_angle.radians,
              bottom_left.right.circle_max_angle.radians,
              top_left.right.circle_max_angle.radians);
  frag_info.octant_offsets_c =
      Vector4(bottom_right.top.se_a - bottom_right.right.se_a,
              top_right.top.se_a - top_right.right.se_a,
              bottom_left.top.se_a - bottom_left.right.se_a,
              top_left.top.se_a - top_left.right.se_a);
  frag_info.radii_width =
      Vector4(bottom_right.top.circle_radius, top_right.top.circle_radius,
              bottom_left.top.circle_radius, top_left.top.circle_radius);
  frag_info.radii_height =
      Vector4(bottom_right.right.circle_radius, top_right.right.circle_radius,
              bottom_left.right.circle_radius, top_left.right.circle_radius);
  frag_info.circle_centers_top_x =
      Vector4(bottom_right.top.circle_center.x, top_right.top.circle_center.x,
              bottom_left.top.circle_center.x, top_left.top.circle_center.x);
  frag_info.circle_centers_top_y =
      Vector4(bottom_right.top.circle_center.y, top_right.top.circle_center.y,
              bottom_left.top.circle_center.y, top_left.top.circle_center.y);
  frag_info.circle_centers_right_x = Vector4(
      bottom_right.right.circle_center.x, top_right.right.circle_center.x,
      bottom_left.right.circle_center.x, top_left.right.circle_center.x);
  frag_info.circle_centers_right_y = Vector4(
      bottom_right.right.circle_center.y, top_right.right.circle_center.y,
      bottom_left.right.circle_center.y, top_left.right.circle_center.y);
  frag_info.superellipse_scales_x =
      Vector4(bottom_right.signed_scale.Abs().x, top_right.signed_scale.Abs().x,
              bottom_left.signed_scale.Abs().x, top_left.signed_scale.Abs().x);
  frag_info.superellipse_scales_y =
      Vector4(bottom_right.signed_scale.Abs().y, top_right.signed_scale.Abs().y,
              bottom_left.signed_scale.Abs().y, top_left.signed_scale.Abs().y);
  frag_info.quadrant_centers_x =
      Vector4(bottom_right_center_relative.x, top_right_center_relative.x,
              bottom_left_center_relative.x, top_left_center_relative.x);
  frag_info.quadrant_centers_y =
      Vector4(bottom_right_center_relative.y, top_right_center_relative.y,
              bottom_left_center_relative.y, top_left_center_relative.y);
  frag_info.quadrant_splits =
      Vector4(round_superellipse_params_.top_split - center.x,
              round_superellipse_params_.bottom_split - center.x,
              round_superellipse_params_.left_split - center.y,
              round_superellipse_params_.right_split - center.y);

  auto geometry_result =
      GetGeometry()->GetPositionBuffer(renderer, entity, pass);

  PipelineBuilderCallback pipeline_callback =
      [&renderer](ContentContextOptions options) {
        return renderer.GetComplexRSEPipeline(options);
      };

  return ColorSourceContents::DrawGeometry<VS>(
      this, GetGeometry(), renderer, entity, pass, pipeline_callback,
      frame_info,
      /*bind_fragment_callback=*/
      [&frag_info, &data_host_buffer](RenderPass& pass) {
        FS::BindFragInfo(pass, data_host_buffer.EmplaceUniform(frag_info));
        return true;
      });
}

std::optional<Rect> ComplexRoundedSuperellipseContents::GetCoverage(
    const Entity& entity) const {
  return GetGeometry()->GetCoverage(entity.GetTransform());
}

const Geometry* ComplexRoundedSuperellipseContents::GetGeometry() const {
  return geometry_.get();
}

}  // namespace impeller
