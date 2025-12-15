// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <optional>

#include "impeller/core/formats.h"
#include "impeller/entity/contents/atlas_contents.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/contents/filters/blend_filter_contents.h"
#include "impeller/entity/contents/pipelines.h"
#include "impeller/entity/entity.h"
#include "impeller/entity/texture_fill.frag.h"
#include "impeller/entity/texture_fill.vert.h"
#include "impeller/geometry/color.h"
#include "impeller/renderer/render_pass.h"

namespace impeller {

DrawImageRectAtlasGeometry::DrawImageRectAtlasGeometry(
    std::shared_ptr<Texture> texture,
    const Rect& source,
    const Rect& destination,
    const Color& color,
    BlendMode blend_mode,
    const SamplerDescriptor& desc,
    bool use_strict_src_rect)
    : texture_(std::move(texture)),
      source_(source),
      destination_(destination),
      color_(color),
      blend_mode_(blend_mode),
      desc_(desc),
      use_strict_src_rect_(use_strict_src_rect) {}

DrawImageRectAtlasGeometry::~DrawImageRectAtlasGeometry() = default;

bool DrawImageRectAtlasGeometry::ShouldUseBlend() const {
  return true;
}

bool DrawImageRectAtlasGeometry::ShouldSkip() const {
  return false;
}

VertexBuffer DrawImageRectAtlasGeometry::CreateSimpleVertexBuffer(
    HostBuffer& data_host_buffer) const {
  using VS = TextureFillVertexShader;
  constexpr size_t indices[6] = {0, 1, 2, 1, 2, 3};

  BufferView buffer_view = data_host_buffer.Emplace(
      sizeof(VS::PerVertexData) * 6, alignof(VS::PerVertexData),
      [&](uint8_t* raw_data) {
        VS::PerVertexData* data =
            reinterpret_cast<VS::PerVertexData*>(raw_data);
        int offset = 0;
        std::array<TPoint<float>, 4> destination_points =
            destination_.GetPoints();
        std::array<TPoint<float>, 4> texture_coords =
            Rect::MakeSize(texture_->GetSize()).Project(source_).GetPoints();
        for (size_t j = 0; j < 6; j++) {
          data[offset].position = destination_points[indices[j]];
          data[offset].texture_coords = texture_coords[indices[j]];
          offset++;
        }
      });

  return VertexBuffer{
      .vertex_buffer = buffer_view,
      .index_buffer = {},
      .vertex_count = 6,
      .index_type = IndexType::kNone,
  };
}

VertexBuffer DrawImageRectAtlasGeometry::CreateBlendVertexBuffer(
    HostBuffer& data_host_buffer) const {
  using VS = PorterDuffBlendVertexShader;
  constexpr size_t indices[6] = {0, 1, 2, 1, 2, 3};

  BufferView buffer_view = data_host_buffer.Emplace(
      sizeof(VS::PerVertexData) * 6, alignof(VS::PerVertexData),
      [&](uint8_t* raw_data) {
        VS::PerVertexData* data =
            reinterpret_cast<VS::PerVertexData*>(raw_data);
        int offset = 0;
        std::array<TPoint<float>, 4> texture_coords =
            Rect::MakeSize(texture_->GetSize()).Project(source_).GetPoints();
        std::array<TPoint<float>, 4> destination_points =
            destination_.GetPoints();
        for (size_t j = 0; j < 6; j++) {
          data[offset].vertices = destination_points[indices[j]];
          data[offset].texture_coords = texture_coords[indices[j]];
          data[offset].color = color_.Premultiply();
          offset++;
        }
      });

  return VertexBuffer{
      .vertex_buffer = buffer_view,
      .index_buffer = {},
      .vertex_count = 6,
      .index_type = IndexType::kNone,
  };
}

Rect DrawImageRectAtlasGeometry::ComputeBoundingBox() const {
  return destination_;
}

const std::shared_ptr<Texture>& DrawImageRectAtlasGeometry::GetAtlas() const {
  return texture_;
}

const SamplerDescriptor& DrawImageRectAtlasGeometry::GetSamplerDescriptor()
    const {
  return desc_;
}

BlendMode DrawImageRectAtlasGeometry::GetBlendMode() const {
  return blend_mode_;
}

bool DrawImageRectAtlasGeometry::ShouldInvertBlendMode() const {
  return false;
}

std::optional<Rect> DrawImageRectAtlasGeometry::GetStrictSrcRect() const {
  if (use_strict_src_rect_) {
    // For a strict source rect, shrink the texture coordinate range by half a
    // texel to ensure that linear filtering does not sample anything outside
    // the source rect bounds.
    return Rect::MakeSize(texture_->GetSize()).Project(source_.Expand(-0.5));
  }
  return std::nullopt;
}

////

AtlasContents::AtlasContents() = default;

AtlasContents::~AtlasContents() = default;

std::optional<Rect> AtlasContents::GetCoverage(const Entity& entity) const {
  if (!geometry_) {
    return std::nullopt;
  }
  return geometry_->ComputeBoundingBox().TransformBounds(entity.GetTransform());
}

void AtlasContents::SetGeometry(AtlasGeometry* geometry) {
  geometry_ = geometry;
}

void AtlasContents::SetAlpha(Scalar alpha) {
  alpha_ = alpha;
}

bool AtlasContents::Render(const ContentContext& renderer,
                           const Entity& entity,
                           RenderPass& pass) const {
  if (geometry_->ShouldSkip() || alpha_ <= 0.0) {
    return true;
  }

  const SamplerDescriptor& dst_sampler_descriptor =
      geometry_->GetSamplerDescriptor();
  raw_ptr<const Sampler> dst_sampler =
      renderer.GetContext()->GetSamplerLibrary()->GetSampler(
          dst_sampler_descriptor);

  auto& data_host_buffer = renderer.GetTransientsDataBuffer();
  if (!geometry_->ShouldUseBlend()) {
    using VS = TextureFillVertexShader;
    using FS = TextureFillFragmentShader;

    raw_ptr<const Sampler> dst_sampler =
        renderer.GetContext()->GetSamplerLibrary()->GetSampler(
            dst_sampler_descriptor);

    auto pipeline_options = OptionsFromPassAndEntity(pass, entity);
    pipeline_options.primitive_type = PrimitiveType::kTriangle;
    pipeline_options.depth_write_enabled =
        pipeline_options.blend_mode == BlendMode::kSrc;

    pass.SetPipeline(renderer.GetTexturePipeline(pipeline_options));
    pass.SetVertexBuffer(geometry_->CreateSimpleVertexBuffer(data_host_buffer));
#ifdef IMPELLER_DEBUG
    pass.SetCommandLabel("DrawAtlas");
#endif  // IMPELLER_DEBUG

    VS::FrameInfo frame_info;
    frame_info.mvp = entity.GetShaderTransform(pass);
    frame_info.texture_sampler_y_coord_scale =
        geometry_->GetAtlas()->GetYCoordScale();

    VS::BindFrameInfo(pass, data_host_buffer.EmplaceUniform(frame_info));

    FS::FragInfo frag_info;
    frag_info.alpha = alpha_;
    FS::BindFragInfo(pass, data_host_buffer.EmplaceUniform((frag_info)));
    FS::BindTextureSampler(pass, geometry_->GetAtlas(), dst_sampler);
    return pass.Draw().ok();
  }

  BlendMode blend_mode = geometry_->GetBlendMode();

  if (blend_mode <= BlendMode::kModulate) {
    using VS = PorterDuffBlendPipeline::VertexShader;
    using FS = PorterDuffBlendPipeline::FragmentShader;

#ifdef IMPELLER_DEBUG
    pass.SetCommandLabel("DrawAtlas Blend");
#endif  // IMPELLER_DEBUG
    pass.SetVertexBuffer(geometry_->CreateBlendVertexBuffer(data_host_buffer));
    BlendMode inverted_blend_mode =
        geometry_->ShouldInvertBlendMode()
            ? (InvertPorterDuffBlend(blend_mode).value_or(BlendMode::kSrc))
            : blend_mode;
    pass.SetPipeline(renderer.GetPorterDuffPipeline(
        inverted_blend_mode, OptionsFromPassAndEntity(pass, entity)));

    FS::FragInfo frag_info;
    VS::FrameInfo frame_info;

    FS::BindTextureSamplerDst(pass, geometry_->GetAtlas(), dst_sampler);
    frame_info.texture_sampler_y_coord_scale =
        geometry_->GetAtlas()->GetYCoordScale();

    frag_info.input_alpha_output_alpha_tmx_tmy =
        Vector4(1.0, alpha_, static_cast<int>(Entity::TileMode::kDecal),
                static_cast<int>(Entity::TileMode::kDecal));
    if (auto rect = geometry_->GetStrictSrcRect(); rect.has_value()) {
      Rect src_rect = rect.value();
      frag_info.source_rect =
          Vector4(src_rect.GetX(), src_rect.GetY(), src_rect.GetRight(),
                  src_rect.GetBottom());
      frag_info.use_strict_source_rect = 1.0;
    } else {
      frag_info.use_strict_source_rect = 0.0;
    }

    FS::BindFragInfo(pass, data_host_buffer.EmplaceUniform(frag_info));

    frame_info.mvp = entity.GetShaderTransform(pass);

    auto uniform_view = data_host_buffer.EmplaceUniform(frame_info);
    VS::BindFrameInfo(pass, uniform_view);

    return pass.Draw().ok();
  }

  using VUS = VerticesUber1Shader::VertexShader;
  using FS = VerticesUber1Shader::FragmentShader;

#ifdef IMPELLER_DEBUG
  pass.SetCommandLabel("DrawAtlas Advanced Blend");
#endif  // IMPELLER_DEBUG
  pass.SetVertexBuffer(geometry_->CreateBlendVertexBuffer(data_host_buffer));

  pass.SetPipeline(renderer.GetDrawVerticesUberPipeline(
      blend_mode, OptionsFromPassAndEntity(pass, entity)));
  FS::BindTextureSampler(pass, geometry_->GetAtlas(), dst_sampler);

  VUS::FrameInfo frame_info;
  FS::FragInfo frag_info;

  frame_info.texture_sampler_y_coord_scale =
      geometry_->GetAtlas()->GetYCoordScale();
  frame_info.mvp = entity.GetShaderTransform(pass);

  frag_info.alpha = alpha_;
  frag_info.blend_mode = static_cast<int>(blend_mode);

  // These values are ignored on platforms that natively support decal.
  frag_info.tmx = static_cast<int>(Entity::TileMode::kDecal);
  frag_info.tmy = static_cast<int>(Entity::TileMode::kDecal);

  FS::BindFragInfo(pass, data_host_buffer.EmplaceUniform(frag_info));
  VUS::BindFrameInfo(pass, data_host_buffer.EmplaceUniform(frame_info));

  return pass.Draw().ok();
}

///////////////

ColorFilterAtlasContents::ColorFilterAtlasContents() = default;

ColorFilterAtlasContents::~ColorFilterAtlasContents() = default;

std::optional<Rect> ColorFilterAtlasContents::GetCoverage(
    const Entity& entity) const {
  if (!geometry_) {
    return std::nullopt;
  }
  return geometry_->ComputeBoundingBox().TransformBounds(entity.GetTransform());
}

void ColorFilterAtlasContents::SetGeometry(AtlasGeometry* geometry) {
  geometry_ = geometry;
}

void ColorFilterAtlasContents::SetAlpha(Scalar alpha) {
  alpha_ = alpha;
}

void ColorFilterAtlasContents::SetMatrix(ColorMatrix matrix) {
  matrix_ = matrix;
}

bool ColorFilterAtlasContents::Render(const ContentContext& renderer,
                                      const Entity& entity,
                                      RenderPass& pass) const {
  if (geometry_->ShouldSkip() || alpha_ <= 0.0) {
    return true;
  }

  const SamplerDescriptor& dst_sampler_descriptor =
      geometry_->GetSamplerDescriptor();

  raw_ptr<const Sampler> dst_sampler =
      renderer.GetContext()->GetSamplerLibrary()->GetSampler(
          dst_sampler_descriptor);

  auto& data_host_buffer = renderer.GetTransientsDataBuffer();

  using VS = ColorMatrixColorFilterPipeline::VertexShader;
  using FS = ColorMatrixColorFilterPipeline::FragmentShader;

#ifdef IMPELLER_DEBUG
  pass.SetCommandLabel("Atlas ColorFilter");
#endif  // IMPELLER_DEBUG
  pass.SetVertexBuffer(geometry_->CreateSimpleVertexBuffer(data_host_buffer));
  pass.SetPipeline(
      renderer.GetColorMatrixColorFilterPipeline(OptionsFromPass(pass)));

  FS::FragInfo frag_info;
  VS::FrameInfo frame_info;

  FS::BindInputTexture(pass, geometry_->GetAtlas(), dst_sampler);
  frame_info.texture_sampler_y_coord_scale =
      geometry_->GetAtlas()->GetYCoordScale();

  frag_info.input_alpha = 1;
  frag_info.output_alpha = alpha_;
  const float* matrix = matrix_.array;
  frag_info.color_v = Vector4(matrix[4], matrix[9], matrix[14], matrix[19]);
  frag_info.color_m = Matrix(matrix[0], matrix[5], matrix[10], matrix[15],  //
                             matrix[1], matrix[6], matrix[11], matrix[16],  //
                             matrix[2], matrix[7], matrix[12], matrix[17],  //
                             matrix[3], matrix[8], matrix[13], matrix[18]   //
  );

  FS::BindFragInfo(pass, data_host_buffer.EmplaceUniform(frag_info));

  frame_info.mvp = entity.GetShaderTransform(pass);

  auto uniform_view = data_host_buffer.EmplaceUniform(frame_info);
  VS::BindFrameInfo(pass, uniform_view);

  return pass.Draw().ok();
}

}  // namespace impeller
