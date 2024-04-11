// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "vertices_contents.h"

#include "fml/logging.h"
#include "impeller/core/formats.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/contents/contents.h"
#include "impeller/entity/contents/filters/blend_filter_contents.h"
#include "impeller/entity/contents/filters/color_filter_contents.h"
#include "impeller/entity/geometry/geometry.h"
#include "impeller/entity/geometry/vertices_geometry.h"
#include "impeller/entity/position_color.vert.h"
#include "impeller/entity/vertices.frag.h"
#include "impeller/geometry/color.h"
#include "impeller/renderer/render_pass.h"

namespace impeller {

namespace {
static std::optional<SamplerAddressMode> TileModeToAddressMode(
    Entity::TileMode tile_mode,
    const Capabilities& capabilities) {
  switch (tile_mode) {
    case Entity::TileMode::kClamp:
      return SamplerAddressMode::kClampToEdge;
      break;
    case Entity::TileMode::kMirror:
      return SamplerAddressMode::kMirror;
      break;
    case Entity::TileMode::kRepeat:
      return SamplerAddressMode::kRepeat;
      break;
    case Entity::TileMode::kDecal:
      if (capabilities.SupportsDecalSamplerAddressMode()) {
        return SamplerAddressMode::kDecal;
      }
      return std::nullopt;
  }
}
}  // namespace

VerticesContents::VerticesContents() = default;

VerticesContents::~VerticesContents() = default;

std::optional<Rect> VerticesContents::GetCoverage(const Entity& entity) const {
  return geometry_->GetCoverage(entity.GetTransform());
};

void VerticesContents::SetGeometry(std::shared_ptr<VerticesGeometry> geometry) {
  geometry_ = std::move(geometry);
}

void VerticesContents::SetSourceContents(std::shared_ptr<Contents> contents) {
  src_contents_ = std::move(contents);
}

std::shared_ptr<VerticesGeometry> VerticesContents::GetGeometry() const {
  return geometry_;
}

void VerticesContents::SetAlpha(Scalar alpha) {
  alpha_ = alpha;
}

void VerticesContents::SetBlendMode(BlendMode blend_mode) {
  blend_mode_ = blend_mode;
}

const std::shared_ptr<Contents>& VerticesContents::GetSourceContents() const {
  return src_contents_;
}

bool VerticesContents::Render(const ContentContext& renderer,
                              const Entity& entity,
                              RenderPass& pass) const {
  if (blend_mode_ == BlendMode::kClear) {
    return true;
  }

  std::shared_ptr<Contents> src_contents = src_contents_;
  src_contents->SetCoverageHint(GetCoverageHint());
  if (geometry_->HasTextureCoordinates()) {
    auto contents = std::make_shared<VerticesUVContents>(*this);
    contents->SetCoverageHint(GetCoverageHint());
    if (!geometry_->HasVertexColors()) {
      contents->SetAlpha(alpha_);
      return contents->Render(renderer, entity, pass);
    }
    src_contents = contents;
  }

  auto dst_contents = std::make_shared<VerticesColorContents>(*this);
  dst_contents->SetCoverageHint(GetCoverageHint());

  std::shared_ptr<Contents> contents;
  if (blend_mode_ == BlendMode::kDestination) {
    dst_contents->SetAlpha(alpha_);
    contents = dst_contents;
  } else {
    auto color_filter_contents = ColorFilterContents::MakeBlend(
        blend_mode_, {FilterInput::Make(dst_contents, false),
                      FilterInput::Make(src_contents, false)});
    color_filter_contents->SetAlpha(alpha_);
    color_filter_contents->SetCoverageHint(GetCoverageHint());
    contents = color_filter_contents;
  }

  FML_DCHECK(contents->GetCoverageHint() == GetCoverageHint());
  return contents->Render(renderer, entity, pass);
}

//------------------------------------------------------
// VerticesUVContents

VerticesUVContents::VerticesUVContents(const VerticesContents& parent)
    : parent_(parent) {}

VerticesUVContents::~VerticesUVContents() {}

std::optional<Rect> VerticesUVContents::GetCoverage(
    const Entity& entity) const {
  return parent_.GetCoverage(entity);
}

void VerticesUVContents::SetAlpha(Scalar alpha) {
  alpha_ = alpha;
}

bool VerticesUVContents::Render(const ContentContext& renderer,
                                const Entity& entity,
                                RenderPass& pass) const {
  using VS = TexturePipeline::VertexShader;
  using FS = TexturePipeline::FragmentShader;

  auto src_contents = parent_.GetSourceContents();

  auto snapshot =
      src_contents->RenderToSnapshot(renderer,           // renderer
                                     entity,             // entity
                                     GetCoverageHint(),  // coverage_limit
                                     std::nullopt,       // sampler_descriptor
                                     true,               // msaa_enabled
                                     /*mip_count=*/1,
                                     "VerticesUVContents Snapshot");  // label
  if (!snapshot.has_value()) {
    return false;
  }

  pass.SetCommandLabel("VerticesUV");
  auto& host_buffer = renderer.GetTransientsBuffer();
  const std::shared_ptr<Geometry>& geometry = parent_.GetGeometry();

  auto coverage = src_contents->GetCoverage(Entity{});
  if (!coverage.has_value()) {
    return false;
  }
  auto geometry_result = geometry->GetPositionUVBuffer(
      coverage.value(), Matrix(), renderer, entity, pass);
  auto opts = OptionsFromPassAndEntity(pass, entity);
  opts.primitive_type = geometry_result.type;
  pass.SetPipeline(renderer.GetTexturePipeline(opts));
  pass.SetVertexBuffer(std::move(geometry_result.vertex_buffer));

  VS::FrameInfo frame_info;
  frame_info.mvp = geometry_result.transform;
  frame_info.texture_sampler_y_coord_scale =
      snapshot->texture->GetYCoordScale();
  frame_info.alpha = alpha_ * snapshot->opacity;
  VS::BindFrameInfo(pass, host_buffer.EmplaceUniform(frame_info));

  FS::BindTextureSampler(pass, snapshot->texture,
                         renderer.GetContext()->GetSamplerLibrary()->GetSampler(
                             snapshot->sampler_descriptor));

  return pass.Draw().ok();
}

//------------------------------------------------------
// VerticesColorContents

VerticesColorContents::VerticesColorContents(const VerticesContents& parent)
    : parent_(parent) {}

VerticesColorContents::~VerticesColorContents() {}

std::optional<Rect> VerticesColorContents::GetCoverage(
    const Entity& entity) const {
  return parent_.GetCoverage(entity);
}

void VerticesColorContents::SetAlpha(Scalar alpha) {
  alpha_ = alpha;
}

bool VerticesColorContents::Render(const ContentContext& renderer,
                                   const Entity& entity,
                                   RenderPass& pass) const {
  using VS = GeometryColorPipeline::VertexShader;
  using FS = GeometryColorPipeline::FragmentShader;

  pass.SetCommandLabel("VerticesColors");
  auto& host_buffer = renderer.GetTransientsBuffer();
  const std::shared_ptr<VerticesGeometry>& geometry = parent_.GetGeometry();

  auto geometry_result =
      geometry->GetPositionColorBuffer(renderer, entity, pass);
  auto opts = OptionsFromPassAndEntity(pass, entity);
  opts.primitive_type = geometry_result.type;
  pass.SetPipeline(renderer.GetGeometryColorPipeline(opts));
  pass.SetVertexBuffer(std::move(geometry_result.vertex_buffer));

  VS::FrameInfo frame_info;
  frame_info.mvp = geometry_result.transform;
  VS::BindFrameInfo(pass, host_buffer.EmplaceUniform(frame_info));

  FS::FragInfo frag_info;
  frag_info.alpha = alpha_;
  FS::BindFragInfo(pass, host_buffer.EmplaceUniform(frag_info));

  return pass.Draw().ok();
}

//------------------------------------------------------
// VerticesSimpleBlendContents

VerticesSimpleBlendContents::VerticesSimpleBlendContents() {}

VerticesSimpleBlendContents::~VerticesSimpleBlendContents() {}

void VerticesSimpleBlendContents::SetGeometry(
    std::shared_ptr<VerticesGeometry> geometry) {
  geometry_ = std::move(geometry);
}

void VerticesSimpleBlendContents::SetAlpha(Scalar alpha) {
  alpha_ = alpha;
}

void VerticesSimpleBlendContents::SetBlendMode(BlendMode blend_mode) {
  FML_DCHECK(blend_mode <= BlendMode::kModulate);
  blend_mode_ = blend_mode;
}

void VerticesSimpleBlendContents::SetTexture(std::shared_ptr<Texture> texture) {
  texture_ = std::move(texture);
}

std::optional<Rect> VerticesSimpleBlendContents::GetCoverage(
    const Entity& entity) const {
  return geometry_->GetCoverage(entity.GetTransform());
}

void VerticesSimpleBlendContents::SetSamplerDescriptor(
    SamplerDescriptor descriptor) {
  descriptor_ = std::move(descriptor);
}

void VerticesSimpleBlendContents::SetTileMode(Entity::TileMode tile_mode_x,
                                              Entity::TileMode tile_mode_y) {
  tile_mode_x_ = tile_mode_x;
  tile_mode_y_ = tile_mode_y;
}

void VerticesSimpleBlendContents::SetEffectTransform(Matrix transform) {
  inverse_matrix_ = transform.Invert();
}

bool VerticesSimpleBlendContents::Render(const ContentContext& renderer,
                                         const Entity& entity,
                                         RenderPass& pass) const {
  FML_DCHECK(texture_);
  FML_DCHECK(geometry_->HasVertexColors());

  // Simple Porter-Duff blends can be accomplished without a sub renderpass.
  using VS = PorterDuffBlendPipeline::VertexShader;
  using FS = PorterDuffBlendPipeline::FragmentShader;

  GeometryResult geometry_result = geometry_->GetPositionUVColorBuffer(
      Rect::MakeSize(texture_->GetSize()), inverse_matrix_, renderer, entity,
      pass);
  if (geometry_result.vertex_buffer.vertex_count == 0) {
    return true;
  }
  FML_DCHECK(geometry_result.mode == GeometryResult::Mode::kNormal);

#ifdef IMPELLER_DEBUG
  pass.SetCommandLabel(SPrintF("DrawVertices Porterduff Blend (%s)",
                               BlendModeToString(blend_mode_)));
#endif  // IMPELLER_DEBUG
  pass.SetVertexBuffer(std::move(geometry_result.vertex_buffer));

  auto options = OptionsFromPassAndEntity(pass, entity);
  options.primitive_type = geometry_result.type;
  pass.SetPipeline(renderer.GetPorterDuffBlendPipeline(options));

  auto dst_sampler_descriptor = descriptor_;
  dst_sampler_descriptor.width_address_mode =
      TileModeToAddressMode(tile_mode_x_, renderer.GetDeviceCapabilities())
          .value_or(SamplerAddressMode::kClampToEdge);
  dst_sampler_descriptor.height_address_mode =
      TileModeToAddressMode(tile_mode_y_, renderer.GetDeviceCapabilities())
          .value_or(SamplerAddressMode::kClampToEdge);

  const std::unique_ptr<const Sampler>& dst_sampler =
      renderer.GetContext()->GetSamplerLibrary()->GetSampler(
          dst_sampler_descriptor);
  FS::BindTextureSamplerDst(pass, texture_, dst_sampler);

  FS::FragInfo frag_info;
  VS::FrameInfo frame_info;

  frame_info.texture_sampler_y_coord_scale = texture_->GetYCoordScale();
  frag_info.output_alpha = alpha_;
  frag_info.input_alpha = 1.0;

  auto inverted_blend_mode =
      InvertPorterDuffBlend(blend_mode_).value_or(BlendMode::kSource);
  auto blend_coefficients =
      kPorterDuffCoefficients[static_cast<int>(inverted_blend_mode)];
  frag_info.src_coeff = blend_coefficients[0];
  frag_info.src_coeff_dst_alpha = blend_coefficients[1];
  frag_info.dst_coeff = blend_coefficients[2];
  frag_info.dst_coeff_src_alpha = blend_coefficients[3];
  frag_info.dst_coeff_src_color = blend_coefficients[4];

  auto& host_buffer = renderer.GetTransientsBuffer();
  FS::BindFragInfo(pass, host_buffer.EmplaceUniform(frag_info));

  frame_info.mvp = geometry_result.transform;

  auto uniform_view = host_buffer.EmplaceUniform(frame_info);
  VS::BindFrameInfo(pass, uniform_view);

  return pass.Draw().ok();
}

}  // namespace impeller
