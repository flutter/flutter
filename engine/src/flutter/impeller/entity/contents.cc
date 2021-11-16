// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents.h"

#include <memory>

#include "flutter/fml/logging.h"
#include "impeller/entity/content_renderer.h"
#include "impeller/entity/entity.h"
#include "impeller/geometry/path_builder.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/sampler_library.h"
#include "impeller/renderer/surface.h"
#include "impeller/renderer/tessellator.h"
#include "impeller/renderer/vertex_buffer_builder.h"

namespace impeller {

/*******************************************************************************
 ******* Contents
 ******************************************************************************/

Contents::Contents() = default;

Contents::~Contents() = default;

/*******************************************************************************
 ******* Linear Gradient Contents
 ******************************************************************************/

LinearGradientContents::LinearGradientContents() = default;

LinearGradientContents::~LinearGradientContents() = default;

void LinearGradientContents::SetEndPoints(Point start_point, Point end_point) {
  start_point_ = start_point;
  end_point_ = end_point;
}

void LinearGradientContents::SetColors(std::vector<Color> colors) {
  colors_ = std::move(colors);
  if (colors_.empty()) {
    colors_.push_back(Color::Black());
    colors_.push_back(Color::Black());
  } else if (colors_.size() < 2u) {
    colors_.push_back(colors_.back());
  }
}

const std::vector<Color>& LinearGradientContents::GetColors() const {
  return colors_;
}

bool LinearGradientContents::Render(const ContentRenderer& renderer,
                                    const Entity& entity,
                                    const Surface& surface,
                                    RenderPass& pass) const {
  using VS = GradientFillPipeline::VertexShader;
  using FS = GradientFillPipeline::FragmentShader;

  auto vertices_builder = VertexBufferBuilder<VS::PerVertexData>();
  {
    auto result = Tessellator{}.Tessellate(entity.GetPath().CreatePolyline(),
                                           [&vertices_builder](Point point) {
                                             VS::PerVertexData vtx;
                                             vtx.vertices = point;
                                             vertices_builder.AppendVertex(vtx);
                                           });
    if (!result) {
      return false;
    }
  }

  VS::FrameInfo frame_info;
  frame_info.mvp =
      Matrix::MakeOrthographic(surface.GetSize()) * entity.GetTransformation();

  FS::GradientInfo gradient_info;
  gradient_info.start_point = start_point_;
  gradient_info.end_point = end_point_;
  gradient_info.start_color = colors_[0];
  gradient_info.end_color = colors_[1];

  Command cmd;
  cmd.label = "LinearGradientFill";
  cmd.pipeline = renderer.GetGradientFillPipeline();
  cmd.BindVertices(vertices_builder.CreateVertexBuffer(
      *renderer.GetContext()->GetPermanentsAllocator()));
  cmd.primitive_type = PrimitiveType::kTriangle;
  FS::BindGradientInfo(
      cmd, pass.GetTransientsBuffer().EmplaceUniform(gradient_info));
  VS::BindFrameInfo(cmd, pass.GetTransientsBuffer().EmplaceUniform(frame_info));
  return pass.AddCommand(std::move(cmd));
}

/*******************************************************************************
 ******* SolidColorContents
 ******************************************************************************/

SolidColorContents::SolidColorContents() = default;

SolidColorContents::~SolidColorContents() = default;

void SolidColorContents::SetColor(Color color) {
  color_ = color;
}

const Color& SolidColorContents::GetColor() const {
  return color_;
}

bool SolidColorContents::Render(const ContentRenderer& renderer,
                                const Entity& entity,
                                const Surface& surface,
                                RenderPass& pass) const {
  using VS = SolidFillPipeline::VertexShader;

  Command cmd;
  cmd.label = "SolidFill";
  cmd.pipeline = renderer.GetSolidFillPipeline();
  if (cmd.pipeline == nullptr) {
    return false;
  }

  VertexBufferBuilder<VS::PerVertexData> vtx_builder;
  {
    auto tesselation_result = Tessellator{}.Tessellate(
        entity.GetPath().CreatePolyline(), [&vtx_builder](auto point) {
          VS::PerVertexData vtx;
          vtx.vertices = point;
          vtx_builder.AppendVertex(vtx);
        });
    if (!tesselation_result) {
      return false;
    }
  }

  if (!vtx_builder.HasVertices()) {
    return true;
  }

  cmd.BindVertices(vtx_builder.CreateVertexBuffer(
      *renderer.GetContext()->GetPermanentsAllocator()));

  VS::FrameInfo frame_info;
  frame_info.mvp =
      Matrix::MakeOrthographic(surface.GetSize()) * entity.GetTransformation();
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

/*******************************************************************************
 ******* SolidStrokeContents
 ******************************************************************************/

void SolidStrokeContents::SetColor(Color color) {
  color_ = color;
}

const Color& SolidStrokeContents::GetColor() const {
  return color_;
}

/*******************************************************************************
 ******* TextureContents
 ******************************************************************************/

TextureContents::TextureContents() = default;

TextureContents::~TextureContents() = default;

void TextureContents::SetTexture(std::shared_ptr<Texture> texture) {
  texture_ = std::move(texture);
}

std::shared_ptr<Texture> TextureContents::GetTexture() const {
  return texture_;
}

bool TextureContents::Render(const ContentRenderer& renderer,
                             const Entity& entity,
                             const Surface& surface,
                             RenderPass& pass) const {
  if (texture_ == nullptr) {
    return true;
  }

  using VS = TextureFillVertexShader;
  using FS = TextureFillFragmentShader;

  const auto coverage_rect = entity.GetPath().GetBoundingBox();
  if (coverage_rect.size.IsEmpty()) {
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
        entity.GetPath().CreatePolyline(),
        [&vertex_builder, &coverage_rect](Point vtx) {
          VS::PerVertexData data;
          data.vertices = vtx;
          data.texture_coords =
              ((vtx - coverage_rect.origin) / coverage_rect.size);
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
  frame_info.mvp =
      Matrix::MakeOrthographic(surface.GetSize()) * entity.GetTransformation();

  auto frame_info_view = host_buffer.EmplaceUniform(frame_info);

  Command cmd;
  cmd.label = "TextureFill";
  cmd.pipeline = renderer.GetTexturePipeline();
  cmd.BindVertices(vertex_builder.CreateVertexBuffer(host_buffer));
  VS::BindFrameInfo(cmd, frame_info_view);
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
