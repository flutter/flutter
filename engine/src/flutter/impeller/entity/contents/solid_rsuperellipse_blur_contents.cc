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

namespace {
Vector3 Concat3(Size a, Scalar b) {
  return {a.width, a.height, b};
}
}  // namespace

SolidRSuperellipseBlurContents::SolidRSuperellipseBlurContents() = default;

SolidRSuperellipseBlurContents::~SolidRSuperellipseBlurContents() = default;

bool SolidRSuperellipseBlurContents::SetPassInfo(
    RenderPass& pass,
    const ContentContext& renderer,
    PassContext& pass_context) const {
  using FS = RSuperellipseBlurPipeline::FragmentShader;

  FS::FragInfo frag_info;
  frag_info.color = GetColor();
  frag_info.center_adjust = Concat(pass_context.center, pass_context.adjust);
  frag_info.r1_exponent_exponentInv =
      Vector3(pass_context.r1, pass_context.exponent, pass_context.exponentInv);
  frag_info.sInv_minEdge_scale =
      Vector3(pass_context.sInv, pass_context.minEdge, pass_context.scale);

  // Additional math for RSuperellipse. See the frag file for explanation.
  Scalar radius = GetCornerRadius();
  Rect rect = GetRect();
  RoundSuperellipseParam param =
      RoundSuperellipseParam::MakeBoundsRadius(rect, radius);

  // Avoid 0-division error when radius is 0.
  Scalar retractionDepth = fmax(radius, 0.001);

  frag_info.halfAxes_retractionDepth =
      Concat3(rect.GetSize() / 2, retractionDepth);

  auto compute_info = [radius](RoundSuperellipseParam::Octant& octant) {
    if (octant.se_n < 1) {  // A rectangular corner
      // Use a large split_radian, which is equivalent to kPiOver4 but avoids
      // floating errors.
      const Scalar kLargeSplitRadian = kPiOver2;
      const Scalar kReallyLargeN = 1e10;
      return Vector4(kLargeSplitRadian, 0, kReallyLargeN, -1.0 / kReallyLargeN);
    }
    Scalar n = octant.se_n;
    Point split_point = Point(octant.se_a - radius, octant.se_a);
    Scalar split_radian = std::atan2(split_point.x, split_point.y);
    Scalar split_retraction =
        (1 - pow(1 + pow(tan(split_radian), n), -1.0 / n)) * octant.se_a;
    return Vector4(split_radian, split_retraction, n, -1.0 / n);
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

  // Back to pass setup.
  auto& data_host_buffer = renderer.GetTransientsDataBuffer();
  pass.SetCommandLabel("RSuperellipse Shadow");
  pass.SetPipeline(renderer.GetRSuperellipseBlurPipeline(pass_context.opts));

  FS::BindFragInfo(pass, data_host_buffer.EmplaceUniform(frag_info));
  return true;
}

}  // namespace impeller
