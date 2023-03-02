// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <optional>
#include <unordered_map>
#include <utility>

#include "flutter/fml/macros.h"

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

#ifdef FML_OS_PHYSICAL_IOS
#include "impeller/entity/contents/framebuffer_blend_contents.h"
#endif

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

struct AtlasBlenderKey {
  Color color;
  Rect rect;
  uint32_t color_key;

  struct Hash {
    std::size_t operator()(const AtlasBlenderKey& key) const {
      return fml::HashCombine(key.color_key, key.rect.size.width,
                              key.rect.size.height, key.rect.origin.x,
                              key.rect.origin.y);
    }
  };

  struct Equal {
    bool operator()(const AtlasBlenderKey& lhs,
                    const AtlasBlenderKey& rhs) const {
      return lhs.rect == rhs.rect && lhs.color_key == rhs.color_key;
    }
  };
};

std::shared_ptr<SubAtlasResult> AtlasContents::GenerateSubAtlas() const {
  FML_DCHECK(colors_.size() > 0 && blend_mode_ != BlendMode::kSource &&
             blend_mode_ != BlendMode::kDestination);

  std::unordered_map<AtlasBlenderKey, std::vector<Matrix>,
                     AtlasBlenderKey::Hash, AtlasBlenderKey::Equal>
      sub_atlas = {};

  for (auto i = 0u; i < texture_coords_.size(); i++) {
    AtlasBlenderKey key = {.color = colors_[i],
                           .rect = texture_coords_[i],
                           .color_key = Color::ToIColor(colors_[i])};
    if (sub_atlas.find(key) == sub_atlas.end()) {
      sub_atlas[key] = {transforms_[i]};
    } else {
      sub_atlas[key].push_back(transforms_[i]);
    }
  }

  auto result = std::make_shared<SubAtlasResult>();
  Scalar x_offset = 0.0;
  Scalar y_offset = 0.0;
  Scalar x_extent = 0.0;
  Scalar y_extent = 0.0;

  for (auto it = sub_atlas.begin(); it != sub_atlas.end(); it++) {
    // This size was arbitrarily chosen to keep the textures from getting too
    // wide. We could instead use a more generic rect packer but in the majority
    // of cases the sample rects will be fairly close in size making this a good
    // enough approximation.
    if (x_offset >= 1000) {
      y_offset = y_extent + 1;
      x_offset = 0.0;
    }

    auto key = it->first;
    auto transforms = it->second;

    auto new_rect = Rect::MakeXYWH(x_offset, y_offset, key.rect.size.width,
                                   key.rect.size.height);
    auto sub_transform = Matrix::MakeTranslation(Vector2(x_offset, y_offset));

    x_offset += std::ceil(key.rect.size.width) + 1.0;

    result->sub_texture_coords.push_back(key.rect);
    result->sub_colors.push_back(key.color);
    result->sub_transforms.push_back(sub_transform);

    x_extent = std::max(x_extent, x_offset);
    y_extent = std::max(y_extent, std::ceil(y_offset + key.rect.size.height));

    for (auto transform : transforms) {
      result->result_texture_coords.push_back(new_rect);
      result->result_transforms.push_back(transform);
    }
  }
  result->size = ISize(std::ceil(x_extent), std::ceil(y_extent));
  return result;
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

  auto sub_atlas = GenerateSubAtlas();
  auto sub_coverage = Rect::MakeSize(sub_atlas->size);

  auto src_contents = std::make_shared<AtlasTextureContents>(*this);
  src_contents->SetSubAtlas(sub_atlas);
  src_contents->SetCoverage(sub_coverage);

  auto dst_contents = std::make_shared<AtlasColorContents>(*this);
  dst_contents->SetSubAtlas(sub_atlas);
  dst_contents->SetCoverage(sub_coverage);

#ifdef FML_OS_PHYSICAL_IOS
  auto new_texture = renderer.MakeSubpass(
      "Atlas Blend", sub_atlas->size,
      [&](const ContentContext& context, RenderPass& pass) {
        Entity entity;
        entity.SetContents(dst_contents);
        entity.SetBlendMode(BlendMode::kSource);
        if (!entity.Render(context, pass)) {
          return false;
        }
        if (blend_mode_ >= Entity::kLastPipelineBlendMode) {
          auto contents = std::make_shared<FramebufferBlendContents>();
          contents->SetBlendMode(blend_mode_);
          contents->SetChildContents(src_contents);
          entity.SetContents(std::move(contents));
          entity.SetBlendMode(BlendMode::kSource);
          return entity.Render(context, pass);
        }
        entity.SetContents(src_contents);
        entity.SetBlendMode(blend_mode_);
        return entity.Render(context, pass);
      });
#else
  auto contents = ColorFilterContents::MakeBlend(
      blend_mode_,
      {FilterInput::Make(dst_contents), FilterInput::Make(src_contents)});
  auto snapshot = contents->RenderToSnapshot(renderer, entity);
  if (!snapshot.has_value()) {
    return false;
  }
  auto new_texture = snapshot.value().texture;
#endif

  auto child_contents = AtlasTextureContents(*this);
  child_contents.SetAlpha(alpha_);
  child_contents.SetCoverage(coverage);
  child_contents.SetTexture(new_texture);
  child_contents.SetUseDestination(true);
  child_contents.SetSubAtlas(sub_atlas);
  return child_contents.Render(renderer, entity, pass);
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

void AtlasTextureContents::SetUseDestination(bool value) {
  use_destination_ = value;
}

void AtlasTextureContents::SetSubAtlas(
    const std::shared_ptr<SubAtlasResult>& subatlas) {
  subatlas_ = subatlas;
}

void AtlasTextureContents::SetTexture(std::shared_ptr<Texture> texture) {
  texture_ = std::move(texture);
}

bool AtlasTextureContents::Render(const ContentContext& renderer,
                                  const Entity& entity,
                                  RenderPass& pass) const {
  using VS = TextureFillVertexShader;
  using FS = TextureFillFragmentShader;

  auto texture = texture_.value_or(parent_.GetTexture());
  std::vector<Rect> texture_coords;
  std::vector<Matrix> transforms;
  if (subatlas_.has_value()) {
    auto subatlas = subatlas_.value();
    texture_coords = use_destination_ ? subatlas->result_texture_coords
                                      : subatlas->sub_texture_coords;
    transforms = use_destination_ ? subatlas->result_transforms
                                  : subatlas->sub_transforms;
  } else {
    texture_coords = parent_.GetTextureCoordinates();
    transforms = parent_.GetTransforms();
  }

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

void AtlasColorContents::SetSubAtlas(
    const std::shared_ptr<SubAtlasResult>& subatlas) {
  subatlas_ = subatlas;
}

bool AtlasColorContents::Render(const ContentContext& renderer,
                                const Entity& entity,
                                RenderPass& pass) const {
  using VS = GeometryColorPipeline::VertexShader;
  using FS = GeometryColorPipeline::FragmentShader;

  std::vector<Rect> texture_coords;
  std::vector<Matrix> transforms;
  std::vector<Color> colors;
  if (subatlas_.has_value()) {
    auto subatlas = subatlas_.value();
    texture_coords = subatlas->sub_texture_coords;
    colors = subatlas->sub_colors;
    transforms = subatlas->sub_transforms;
  } else {
    texture_coords = parent_.GetTextureCoordinates();
    transforms = parent_.GetTransforms();
    colors = parent_.GetColors();
  }

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
