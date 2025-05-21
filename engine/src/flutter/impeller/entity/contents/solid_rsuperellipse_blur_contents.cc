// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/solid_rsuperellipse_blur_contents.h"
#include <optional>

#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/entity.h"
#include "impeller/geometry/color.h"
#include "impeller/geometry/constants.h"
#include "impeller/geometry/round_superellipse_param.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/vertex_buffer_builder.h"

namespace impeller {

SolidRSuperellipseBlurContents::SolidRSuperellipseBlurContents() = default;

SolidRSuperellipseBlurContents::~SolidRSuperellipseBlurContents() = default;

bool SolidRSuperellipseBlurContents::SetPassInfo(
    RenderPass& pass,
    const ContentContext& renderer,
    PassContext& pass_context) const {
  using VS = RSuperellipseBlurPipeline::VertexShader;
  using FS = RSuperellipseBlurPipeline::FragmentShader;

  std::array<VS::PerVertexData, 4> vertices = {
      VS::PerVertexData{pass_context.vertices[0]},
      VS::PerVertexData{pass_context.vertices[1]},
      VS::PerVertexData{pass_context.vertices[2]},
      VS::PerVertexData{pass_context.vertices[3]},
  };
  VS::FrameInfo frame_info;
  frame_info.mvp = pass_context.transform;

  FS::FragInfo frag_info;
  frag_info.color = GetColor();
  frag_info.center = pass_context.center;
  frag_info.adjust = pass_context.adjust;
  frag_info.minEdge = pass_context.minEdge;
  frag_info.r1 = pass_context.r1;
  frag_info.exponent = pass_context.exponent;
  frag_info.sInv = pass_context.sInv;
  frag_info.exponentInv = pass_context.exponentInv;
  frag_info.scale = pass_context.scale;

  // Additional math for RSuperellipse. See the frag file for explanation.
  Scalar radius = GetCornerRadius();
  Rect rect = GetRect();
  RoundSuperellipseParam param =
      RoundSuperellipseParam::MakeBoundsRadius(rect, radius);

  auto compute_factor = [radius](RoundSuperellipseParam::Octant& octant) {
    Scalar n = octant.se_n;
    Point point_peak = Point(octant.se_a - radius, octant.se_a);
    Scalar peak_radian = std::atan2(point_peak.x, point_peak.y);
    Scalar peak_gap =
        (1 - pow(1 + pow(tan(peak_radian), n), -1 / n)) * octant.se_a;
    Scalar v0 = radius / octant.se_a * 3;
    return Vector4(peak_radian, n, peak_gap, v0);
  };
  frag_info.octantOffset = (rect.GetHeight() - rect.GetWidth()) / 2;
  frag_info.factorTop = compute_factor(param.top_right.top);
  frag_info.factorRight = compute_factor(param.top_right.right);
  frag_info.retractionDepth = radius;

  // Back to pass setup.
  auto& host_buffer = renderer.GetTransientsBuffer();
  pass.SetCommandLabel("RSuperellipse Shadow");
  pass.SetPipeline(renderer.GetRSuperellipseBlurPipeline(pass_context.opts));
  pass.SetVertexBuffer(CreateVertexBuffer(vertices, host_buffer));

  VS::BindFrameInfo(pass, host_buffer.EmplaceUniform(frame_info));
  FS::BindFragInfo(pass, host_buffer.EmplaceUniform(frag_info));
  return true;
}

}  // namespace impeller
