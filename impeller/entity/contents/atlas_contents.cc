// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <optional>
#include <utility>

#include "impeller/entity/contents/atlas_contents.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/contents/filters/color_filter_contents.h"
#include "impeller/entity/contents/filters/filter_contents.h"
#include "impeller/entity/contents/texture_contents.h"
#include "impeller/entity/entity.h"
#include "impeller/entity/geometry.h"
#include "impeller/entity/texture_fill.frag.h"
#include "impeller/entity/texture_fill.vert.h"
#include "impeller/renderer/formats.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/sampler_library.h"
#include "impeller/renderer/vertex_buffer_builder.h"

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
  transforms_ = std::move(transforms);
  bounding_box_cache_.reset();
}

void AtlasContents::SetTextureCoordinates(std::vector<Rect> texture_coords) {
  texture_coords_ = std::move(texture_coords);
  bounding_box_cache_.reset();
}

void AtlasContents::SetColors(std::vector<Color> colors) {
  colors_ = std::move(colors);
}

void AtlasContents::SetAlpha(Scalar alpha) {
  alpha_ = alpha;
}

void AtlasContents::SetBlendMode(BlendMode blend_mode) {
  blend_mode_ = blend_mode;
}

void AtlasContents::SetCullRect(std::optional<Rect> cull_rect) {
  cull_rect_ = cull_rect;
}

std::optional<Rect> AtlasContents::GetCoverage(const Entity& entity) const {
  if (cull_rect_.has_value()) {
    return cull_rect_.value().TransformBounds(entity.GetTransformation());
  }
  return ComputeBoundingBox().TransformBounds(entity.GetTransformation());
}

Rect AtlasContents::ComputeBoundingBox() const {
  if (!bounding_box_cache_.has_value()) {
    Rect bounding_box = {};
    for (size_t i = 0; i < texture_coords_.size(); i++) {
      auto matrix = transforms_[i];
      auto sample_rect = texture_coords_[i];
      auto bounds = Rect::MakeSize(sample_rect.size).TransformBounds(matrix);
      bounding_box = bounds.Union(bounding_box);
    }
    bounding_box_cache_ = bounding_box;
  }
  return bounding_box_cache_.value();
}

void AtlasContents::SetSamplerDescriptor(SamplerDescriptor desc) {
  sampler_descriptor_ = std::move(desc);
}

const SamplerDescriptor& AtlasContents::GetSamplerDescriptor() const {
  return sampler_descriptor_;
}

const std::vector<Matrix>& AtlasContents::GetTransforms() const {
  return transforms_;
}

const std::vector<Rect>& AtlasContents::GetTextureCoordinates() const {
  return texture_coords_;
}

const std::vector<Color>& AtlasContents::GetColors() const {
  return colors_;
}

bool AtlasContents::Render(const ContentContext& renderer,
                           const Entity& entity,
                           RenderPass& pass) const {
  if (texture_ == nullptr || blend_mode_ == BlendMode::kClear ||
      alpha_ <= 0.0) {
    return true;
  }

  // Ensure that we use the actual computed bounds and not a cull-rect
  // approximation of them.
  auto coverage = ComputeBoundingBox();

  if (blend_mode_ == BlendMode::kSource || colors_.size() == 0) {
    auto child_contents = AtlasTextureContents(*this);
    child_contents.SetAlpha(alpha_);
    child_contents.SetCoverage(coverage);
    return child_contents.Render(renderer, entity, pass);
  }
  if (blend_mode_ == BlendMode::kDestination) {
    auto child_contents = AtlasColorContents(*this);
    child_contents.SetAlpha(alpha_);
    child_contents.SetCoverage(coverage);
    return child_contents.Render(renderer, entity, pass);
  }

  auto src_contents = std::make_shared<AtlasTextureContents>(*this);
  src_contents->SetCoverage(coverage);

  auto dst_contents = std::make_shared<AtlasColorContents>(*this);
  dst_contents->SetCoverage(coverage);

  auto contents = ColorFilterContents::MakeBlend(
      blend_mode_,
      {FilterInput::Make(dst_contents), FilterInput::Make(src_contents)});
  contents->SetAlpha(alpha_);
  return contents->Render(renderer, entity, pass);
}

// AtlasTextureContents
// ---------------------------------------------------------

AtlasTextureContents::AtlasTextureContents(const AtlasContents& parent)
    : parent_(parent) {}

AtlasTextureContents::~AtlasTextureContents() {}

std::optional<Rect> AtlasTextureContents::GetCoverage(
    const Entity& entity) const {
  return coverage_.TransformBounds(entity.GetTransformation());
}

void AtlasTextureContents::SetAlpha(Scalar alpha) {
  alpha_ = alpha;
}

void AtlasTextureContents::SetCoverage(Rect coverage) {
  coverage_ = coverage;
}

bool AtlasTextureContents::Render(const ContentContext& renderer,
                                  const Entity& entity,
                                  RenderPass& pass) const {
  using VS = TextureFillVertexShader;
  using FS = TextureFillFragmentShader;

  auto texture = parent_.GetTexture();
  auto texture_coords = parent_.GetTextureCoordinates();
  auto transforms = parent_.GetTransforms();

  const Size texture_size(texture->GetSize());
  VertexBufferBuilder<VS::PerVertexData> vertex_builder;
  vertex_builder.Reserve(texture_coords.size() * 6);
  constexpr size_t indices[6] = {0, 1, 2, 1, 2, 3};
  constexpr Scalar width[6] = {0, 1, 0, 1, 0, 1};
  constexpr Scalar height[6] = {0, 0, 1, 0, 1, 1};
  for (size_t i = 0; i < texture_coords.size(); i++) {
    auto sample_rect = texture_coords[i];
    auto matrix = transforms[i];
    auto transformed_points =
        Rect::MakeSize(sample_rect.size).GetTransformedPoints(matrix);

    for (size_t j = 0; j < 6; j++) {
      VS::PerVertexData data;
      data.position = transformed_points[indices[j]];
      data.texture_coords =
          (sample_rect.origin + Point(sample_rect.size.width * width[j],
                                      sample_rect.size.height * height[j])) /
          texture_size;
      vertex_builder.AppendVertex(data);
    }
  }

  if (!vertex_builder.HasVertices()) {
    return true;
  }

  Command cmd;
  cmd.label = "AtlasTexture";

  auto& host_buffer = pass.GetTransientsBuffer();

  VS::FrameInfo frame_info;
  frame_info.mvp = Matrix::MakeOrthographic(pass.GetRenderTargetSize()) *
                   entity.GetTransformation();
  frame_info.texture_sampler_y_coord_scale = texture->GetYCoordScale();

  FS::FragInfo frag_info;
  frag_info.alpha = alpha_;

  auto options = OptionsFromPassAndEntity(pass, entity);
  cmd.pipeline = renderer.GetTexturePipeline(options);
  cmd.stencil_reference = entity.GetStencilDepth();
  cmd.BindVertices(vertex_builder.CreateVertexBuffer(host_buffer));
  VS::BindFrameInfo(cmd, host_buffer.EmplaceUniform(frame_info));
  FS::BindFragInfo(cmd, host_buffer.EmplaceUniform(frag_info));
  FS::BindTextureSampler(cmd, texture,
                         renderer.GetContext()->GetSamplerLibrary()->GetSampler(
                             parent_.GetSamplerDescriptor()));
  return pass.AddCommand(std::move(cmd));
}

// AtlasColorContents
// ---------------------------------------------------------

AtlasColorContents::AtlasColorContents(const AtlasContents& parent)
    : parent_(parent) {}

AtlasColorContents::~AtlasColorContents() {}

std::optional<Rect> AtlasColorContents::GetCoverage(
    const Entity& entity) const {
  return coverage_.TransformBounds(entity.GetTransformation());
}

void AtlasColorContents::SetAlpha(Scalar alpha) {
  alpha_ = alpha;
}

void AtlasColorContents::SetCoverage(Rect coverage) {
  coverage_ = coverage;
}

bool AtlasColorContents::Render(const ContentContext& renderer,
                                const Entity& entity,
                                RenderPass& pass) const {
  using VS = GeometryColorPipeline::VertexShader;
  using FS = GeometryColorPipeline::FragmentShader;

  auto texture_coords = parent_.GetTextureCoordinates();
  auto transforms = parent_.GetTransforms();
  auto colors = parent_.GetColors();

  VertexBufferBuilder<VS::PerVertexData> vertex_builder;
  vertex_builder.Reserve(texture_coords.size() * 6);
  constexpr size_t indices[6] = {0, 1, 2, 1, 2, 3};
  for (size_t i = 0; i < texture_coords.size(); i++) {
    auto sample_rect = texture_coords[i];
    auto matrix = transforms[i];
    auto transformed_points =
        Rect::MakeSize(sample_rect.size).GetTransformedPoints(matrix);

    for (size_t j = 0; j < 6; j++) {
      VS::PerVertexData data;
      data.position = transformed_points[indices[j]];
      data.color = colors[i].Premultiply();
      vertex_builder.AppendVertex(data);
    }
  }

  if (!vertex_builder.HasVertices()) {
    return true;
  }

  Command cmd;
  cmd.label = "AtlasColors";

  auto& host_buffer = pass.GetTransientsBuffer();

  VS::FrameInfo frame_info;
  frame_info.mvp = Matrix::MakeOrthographic(pass.GetRenderTargetSize()) *
                   entity.GetTransformation();

  FS::FragInfo frag_info;
  frag_info.alpha = alpha_;

  auto opts = OptionsFromPassAndEntity(pass, entity);
  opts.blend_mode = BlendMode::kSourceOver;
  cmd.pipeline = renderer.GetGeometryColorPipeline(opts);
  cmd.stencil_reference = entity.GetStencilDepth();
  cmd.BindVertices(vertex_builder.CreateVertexBuffer(host_buffer));
  VS::BindFrameInfo(cmd, host_buffer.EmplaceUniform(frame_info));
  FS::BindFragInfo(cmd, host_buffer.EmplaceUniform(frag_info));
  return pass.AddCommand(std::move(cmd));
}

}  // namespace impeller
