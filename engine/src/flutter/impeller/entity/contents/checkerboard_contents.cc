// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/checkerboard_contents.h"

#include <memory>

#include "impeller/core/formats.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/renderer/command.h"
#include "impeller/renderer/render_pass.h"

namespace impeller {

CheckerboardContents::CheckerboardContents() = default;

CheckerboardContents::~CheckerboardContents() = default;

bool CheckerboardContents::Render(const ContentContext& renderer,
                                  const Entity& entity,
                                  RenderPass& pass) const {
  auto& host_buffer = pass.GetTransientsBuffer();

  using VS = CheckerboardPipeline::VertexShader;
  using FS = CheckerboardPipeline::FragmentShader;

  Command cmd;
  DEBUG_COMMAND_INFO(cmd, "Checkerboard");

  auto options = OptionsFromPass(pass);
  options.blend_mode = BlendMode::kSourceOver;
  options.stencil_compare = CompareFunction::kAlways;  // Ignore all clips.
  options.stencil_operation = StencilOperation::kKeep;
  options.primitive_type = PrimitiveType::kTriangleStrip;
  cmd.pipeline = renderer.GetCheckerboardPipeline(options);

  VertexBufferBuilder<typename VS::PerVertexData> vtx_builder;
  vtx_builder.AddVertices({
      {Point(-1, -1)},
      {Point(1, -1)},
      {Point(-1, 1)},
      {Point(1, 1)},
  });
  cmd.BindVertices(vtx_builder.CreateVertexBuffer(host_buffer));

  FS::FragInfo frag_info;
  frag_info.color = color_;
  frag_info.square_size = square_size_;
  FS::BindFragInfo(cmd, host_buffer.EmplaceUniform(frag_info));

  pass.AddCommand(std::move(cmd));

  return true;
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
