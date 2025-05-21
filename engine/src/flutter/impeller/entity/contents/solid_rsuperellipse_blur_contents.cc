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

  frag_info.octantOffset = (rect.GetHeight() - rect.GetWidth()) / 2;

  auto compute_info = [radius](RoundSuperellipseParam::Octant& octant) {
    Scalar n = octant.se_n;
    Point point_peak = Point(octant.se_a - radius, octant.se_a);
    Scalar peak_radian = std::atan2(point_peak.x, point_peak.y);
    Scalar peak_gap =
        (1 - pow(1 + pow(tan(peak_radian), n), -1 / n)) * octant.se_a;
    return Vector3(peak_radian, n, peak_gap);
  };
  frag_info.infoTop = compute_info(param.top_right.top);
  frag_info.infoRight = compute_info(param.top_right.right);

  auto compute_poly = [radius](RoundSuperellipseParam::Octant& octant) {
    // Imperical formula that decreases the initial slope as the a/r ratio
    // increases.
    Scalar v0 = radius / octant.se_a * 3;
    // A polynomial that satisfies f(0) = 1, f'(0) = v0, f(1) = 0, f'(1) = 0
    return Vector4(v0 + 2.0, -2.0 * v0 - 3.0, v0, 1.0);
  };
  frag_info.polyTop = compute_poly(param.top_right.top);
  frag_info.polyRight = compute_poly(param.top_right.right);

  // A polynomial that satisfies f(0) = 1, f'(0) = v0, f(1) = 0, f'(1) = 0
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
