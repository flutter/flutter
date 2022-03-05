// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "solid_color_contents.h"

#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/entity.h"
#include "impeller/geometry/path.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/tessellator/tessellator.h"

namespace impeller {

SolidColorContents::SolidColorContents() = default;

SolidColorContents::~SolidColorContents() = default;

void SolidColorContents::SetColor(Color color) {
  color_ = color;
}

const Color& SolidColorContents::GetColor() const {
  return color_;
}

VertexBuffer SolidColorContents::CreateSolidFillVertices(const Path& path,
                                                         HostBuffer& buffer) {
  using VS = SolidFillPipeline::VertexShader;

  VertexBufferBuilder<VS::PerVertexData> vtx_builder;

  auto tesselation_result = Tessellator{path.GetFillType()}.Tessellate(
      path.CreatePolyline(), [&vtx_builder](auto point) {
        VS::PerVertexData vtx;
        vtx.vertices = point;
        vtx_builder.AppendVertex(vtx);
      });
  if (!tesselation_result) {
    return {};
  }

  return vtx_builder.CreateVertexBuffer(buffer);
}

bool SolidColorContents::Render(const ContentContext& renderer,
                                const Entity& entity,
                                RenderPass& pass) const {
  if (color_.IsTransparent()) {
    return true;
  }

  using VS = SolidFillPipeline::VertexShader;

  Command cmd;
  cmd.label = "SolidFill";
  cmd.pipeline = renderer.GetSolidFillPipeline(OptionsFromPass(pass));
  cmd.stencil_reference = entity.GetStencilDepth();
  cmd.BindVertices(
      CreateSolidFillVertices(entity.GetPath(), pass.GetTransientsBuffer()));

  VS::FrameInfo frame_info;
  frame_info.mvp = Matrix::MakeOrthographic(pass.GetRenderTargetSize()) *
                   entity.GetTransformation();
  frame_info.color = color_;
  VS::BindFrameInfo(cmd, pass.GetTransientsBuffer().EmplaceUniform(frame_info));

  cmd.primitive_type = PrimitiveType::kTriangle;

  if (!pass.AddCommand(std::move(cmd))) {
    return false;
  }

  return true;
}

std::unique_ptr<SolidColorContents> SolidColorContents::Make(Color color) {
  auto contents = std::make_unique<SolidColorContents>();
  contents->SetColor(color);
  return contents;
}

}  // namespace impeller
