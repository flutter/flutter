// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <optional>

#include "impeller/renderer/formats.h"
#include "impeller/renderer/sampler_library.h"
#include "impeller/renderer/vertex_buffer_builder.h"

#include "impeller/entity/atlas_fill.frag.h"
#include "impeller/entity/atlas_fill.vert.h"
#include "impeller/entity/contents/atlas_contents.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/entity.h"
#include "impeller/renderer/render_pass.h"

namespace impeller {

AtlasContents::AtlasContents() = default;

AtlasContents::~AtlasContents() = default;

void AtlasContents::SetTexture(std::shared_ptr<Texture> texture) {
  texture_ = std::move(texture);
}

std::shared_ptr<Texture> AtlasContents::GetTexture() const {
  return texture_;
}

void AtlasContents::SetTransforms(std::vector<Matrix> transforms) {
  transforms_ = transforms;
}

void AtlasContents::SetTextureCoordinates(std::vector<Rect> texture_coords) {
  texture_coords_ = texture_coords;
}

void AtlasContents::SetColors(std::vector<Color> colors) {
  colors_ = colors;
}

void AtlasContents::SetAlpha(Scalar alpha) {
  alpha_ = alpha;
}

void AtlasContents::SetBlendMode(BlendMode blend_mode) {
  // TODO(jonahwilliams): blending of colors with texture.
  blend_mode_ = blend_mode;
}

void AtlasContents::SetCullRect(std::optional<Rect> cull_rect) {
  cull_rect_ = cull_rect;
}

std::optional<Rect> AtlasContents::GetCoverage(const Entity& entity) const {
  if (cull_rect_.has_value()) {
    return cull_rect_.value().TransformBounds(entity.GetTransformation());
  }

  Rect bounding_box = {};
  for (size_t i = 0; i < texture_coords_.size(); i++) {
    auto matrix = transforms_[i];
    auto sample_rect = texture_coords_[i];
    auto bounds = Rect::MakeSize(sample_rect.size).TransformBounds(matrix);
    bounding_box = bounds.Union(bounding_box);
  }
  return bounding_box.TransformBounds(entity.GetTransformation());
}

void AtlasContents::SetSamplerDescriptor(SamplerDescriptor desc) {
  sampler_descriptor_ = std::move(desc);
}

const SamplerDescriptor& AtlasContents::GetSamplerDescriptor() const {
  return sampler_descriptor_;
}

bool AtlasContents::Render(const ContentContext& renderer,
                           const Entity& entity,
                           RenderPass& pass) const {
  if (texture_ == nullptr) {
    return true;
  }

  using VS = AtlasFillVertexShader;
  using FS = AtlasFillFragmentShader;

  const auto texture_size = texture_->GetSize();
  if (texture_size.IsEmpty()) {
    return true;
  }

  VertexBufferBuilder<VS::PerVertexData> vertex_builder;
  vertex_builder.Reserve(texture_coords_.size() * 6);
  constexpr size_t indices[6] = {0, 1, 2, 1, 2, 3};
  constexpr Scalar width[6] = {0, 1, 0, 1, 0, 1};
  constexpr Scalar height[6] = {0, 0, 1, 0, 1, 1};
  for (size_t i = 0; i < texture_coords_.size(); i++) {
    auto sample_rect = texture_coords_[i];
    auto matrix = transforms_[i];
    auto color = colors_.size() > 0 ? colors_[i] : Color::Black();
    auto transformed_points =
        Rect::MakeSize(sample_rect.size).GetTransformedPoints(matrix);

    for (size_t j = 0; j < 6; j++) {
      VS::PerVertexData data;
      data.position = transformed_points[indices[j]];
      data.texture_coords =
          (sample_rect.origin + Point(sample_rect.size.width * width[j],
                                      sample_rect.size.height * height[j])) /
          texture_size;
      data.color = color.Premultiply();
      vertex_builder.AppendVertex(data);
    }
  }

  if (!vertex_builder.HasVertices()) {
    return true;
  }

  auto& host_buffer = pass.GetTransientsBuffer();

  VS::VertInfo vert_info;
  vert_info.mvp = Matrix::MakeOrthographic(pass.GetRenderTargetSize()) *
                  entity.GetTransformation();

  FS::FragInfo frag_info;
  frag_info.texture_sampler_y_coord_scale = texture_->GetYCoordScale();
  frag_info.has_vertex_color = colors_.size() > 0 ? 1.0 : 0.0;
  frag_info.alpha = alpha_;

  Command cmd;
  cmd.label = "DrawAtlas";
  cmd.pipeline =
      renderer.GetAtlasPipeline(OptionsFromPassAndEntity(pass, entity));
  cmd.stencil_reference = entity.GetStencilDepth();
  cmd.BindVertices(vertex_builder.CreateVertexBuffer(host_buffer));
  VS::BindVertInfo(cmd, host_buffer.EmplaceUniform(vert_info));
  FS::BindFragInfo(cmd, host_buffer.EmplaceUniform(frag_info));
  FS::BindTextureSampler(cmd, texture_,
                         renderer.GetContext()->GetSamplerLibrary()->GetSampler(
                             sampler_descriptor_));
  pass.AddCommand(std::move(cmd));

  return true;
}

}  // namespace impeller
