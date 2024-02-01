// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/checkerboard_contents.h"

#include "impeller/core/formats.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/vertex_buffer_builder.h"

namespace impeller {

CheckerboardContents::CheckerboardContents() = default;

CheckerboardContents::~CheckerboardContents() = default;

bool CheckerboardContents::Render(const ContentContext& renderer,
                                  const Entity& entity,
                                  RenderPass& pass) const {
  auto& host_buffer = renderer.GetTransientsBuffer();

  using VS = CheckerboardPipeline::VertexShader;
  using FS = CheckerboardPipeline::FragmentShader;

  auto options = OptionsFromPass(pass);
  options.blend_mode = BlendMode::kSourceOver;
  options.stencil_mode = ContentContextOptions::StencilMode::kIgnore;
  options.primitive_type = PrimitiveType::kTriangleStrip;

  VertexBufferBuilder<typename VS::PerVertexData> vtx_builder;
  vtx_builder.AddVertices({
      {Point(-1, -1)},
      {Point(1, -1)},
      {Point(-1, 1)},
      {Point(1, 1)},
  });

  pass.SetCommandLabel("Checkerboard");
  pass.SetPipeline(renderer.GetCheckerboardPipeline(options));
  pass.SetVertexBuffer(vtx_builder.CreateVertexBuffer(host_buffer));

  FS::FragInfo frag_info;
  frag_info.color = color_;
  frag_info.square_size = square_size_;
  FS::BindFragInfo(pass, host_buffer.EmplaceUniform(frag_info));

  return pass.Draw().ok();
}

std::optional<Rect> CheckerboardContents::GetCoverage(
    const Entity& entity) const {
  return std::nullopt;
}

void CheckerboardContents::SetColor(Color color) {
  color_ = color;
}

void CheckerboardContents::SetSquareSize(Scalar square_size) {
  square_size_ = square_size;
}

}  // namespace impeller
