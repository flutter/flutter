// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "texture_contents.h"

#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/entity.h"
#include "impeller/entity/texture_fill.frag.h"
#include "impeller/entity/texture_fill.vert.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/sampler_library.h"
#include "impeller/tessellator/tessellator.h"

namespace impeller {

TextureContents::TextureContents() = default;

TextureContents::~TextureContents() = default;

void TextureContents::SetTexture(std::shared_ptr<Texture> texture) {
  texture_ = std::move(texture);
}

std::shared_ptr<Texture> TextureContents::GetTexture() const {
  return texture_;
}

void TextureContents::SetOpacity(Scalar opacity) {
  opacity_ = opacity;
}

bool TextureContents::Render(const ContentContext& renderer,
                             const Entity& entity,
                             RenderPass& pass) const {
  if (texture_ == nullptr) {
    return true;
  }

  using VS = TextureFillVertexShader;
  using FS = TextureFillFragmentShader;

  const auto coverage_rect = entity.GetPath().GetBoundingBox();

  if (!coverage_rect.has_value()) {
    return true;
  }

  if (coverage_rect->size.IsEmpty()) {
    return true;
  }

  const auto texture_size = texture_->GetSize();
  if (texture_size.IsEmpty()) {
    return true;
  }

  if (source_rect_.IsEmpty()) {
    return true;
  }

  VertexBufferBuilder<VS::PerVertexData> vertex_builder;
  {
    const auto tess_result = Tessellator{}.Tessellate(
        entity.GetPath().GetFillType(), entity.GetPath().CreatePolyline(),
        [this, &vertex_builder, &coverage_rect, &texture_size](Point vtx) {
          VS::PerVertexData data;
          data.vertices = vtx;
          auto coverage_coords =
              (vtx - coverage_rect->origin) / coverage_rect->size;
          data.texture_coords =
              (source_rect_.origin + source_rect_.size * coverage_coords) /
              texture_size;
          vertex_builder.AppendVertex(data);
        });
    if (!tess_result) {
      return false;
    }
  }

  if (!vertex_builder.HasVertices()) {
    return true;
  }

  auto& host_buffer = pass.GetTransientsBuffer();

  VS::FrameInfo frame_info;
  frame_info.mvp = Matrix::MakeOrthographic(pass.GetRenderTargetSize()) *
                   entity.GetTransformation();
  frame_info.alpha = opacity_;

  Command cmd;
  cmd.label = "TextureFill";
  cmd.pipeline =
      renderer.GetTexturePipeline(OptionsFromPassAndEntity(pass, entity));
  cmd.stencil_reference = entity.GetStencilDepth();
  cmd.BindVertices(vertex_builder.CreateVertexBuffer(host_buffer));
  VS::BindFrameInfo(cmd, host_buffer.EmplaceUniform(frame_info));
  FS::BindTextureSampler(
      cmd, texture_,
      renderer.GetContext()->GetSamplerLibrary()->GetSampler({}));
  pass.AddCommand(std::move(cmd));

  return true;
}

void TextureContents::SetSourceRect(const IRect& source_rect) {
  source_rect_ = source_rect;
}

const IRect& TextureContents::GetSourceRect() const {
  return source_rect_;
}

}  // namespace impeller
