// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/solid_rrect_blur_contents.h"
#include <optional>

#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/entity.h"
#include "impeller/geometry/color.h"
#include "impeller/geometry/constants.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/vertex_buffer_builder.h"

namespace impeller {

bool SolidRRectBlurContents::SetPassInfo(RenderPass& pass,
                                         const ContentContext& renderer,
                                         PassContext& pass_context) const {
  using FS = RRectBlurPipeline::FragmentShader;

  FS::FragInfo frag_info;
  frag_info.color = GetColor();
  frag_info.center_adjust = Concat(pass_context.center, pass_context.adjust);
  frag_info.r1_exponent_exponentInv =
      Vector3(pass_context.r1, pass_context.exponent, pass_context.exponentInv);
  frag_info.sInv_minEdge_scale =
      Vector3(pass_context.sInv, pass_context.minEdge, pass_context.scale);

  auto& data_host_buffer = renderer.GetTransientsDataBuffer();
  pass.SetCommandLabel("RRect Shadow");
  pass.SetPipeline(renderer.GetRRectBlurPipeline(pass_context.opts));

  FS::BindFragInfo(pass, data_host_buffer.EmplaceUniform(frag_info));
  return true;
}

SolidRRectBlurContents::SolidRRectBlurContents() = default;

SolidRRectBlurContents::~SolidRRectBlurContents() = default;

}  // namespace impeller
