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
  frag_info.center = pass_context.center;
  frag_info.adjust = pass_context.adjust;
  frag_info.minEdge = pass_context.minEdge;
  frag_info.r1 = pass_context.r1;
  frag_info.exponent = pass_context.exponent;
  frag_info.sInv = pass_context.sInv;
  frag_info.exponentInv = pass_context.exponentInv;
  frag_info.scale = pass_context.scale;

  auto& host_buffer = renderer.GetTransientsBuffer();
  pass.SetCommandLabel("RRect Shadow");
  pass.SetPipeline(renderer.GetRRectBlurPipeline(pass_context.opts));

  FS::BindFragInfo(pass, host_buffer.EmplaceUniform(frag_info));
  return true;
}

SolidRRectBlurContents::SolidRRectBlurContents() = default;

SolidRRectBlurContents::~SolidRRectBlurContents() = default;

}  // namespace impeller
