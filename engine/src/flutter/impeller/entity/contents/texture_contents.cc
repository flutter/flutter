// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/texture_contents.h"

#include <memory>
#include <optional>
#include <utility>

#include "impeller/core/formats.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/entity.h"
#include "impeller/entity/texture_fill.frag.h"
#include "impeller/entity/texture_fill.vert.h"
#include "impeller/entity/texture_fill_external.frag.h"
#include "impeller/geometry/constants.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/vertex_buffer_builder.h"

namespace impeller {

TextureContents::TextureContents() = default;

TextureContents::~TextureContents() = default;

std::shared_ptr<TextureContents> TextureContents::MakeRect(Rect destination) {
  auto contents = std::make_shared<TextureContents>();
  contents->destination_rect_ = destination;
  return contents;
}

void TextureContents::SetLabel(std::string label) {
  label_ = std::move(label);
}

void TextureContents::SetDestinationRect(Rect rect) {
  destination_rect_ = rect;
}

void TextureContents::SetTexture(std::shared_ptr<Texture> texture) {
  texture_ = std::move(texture);
}

std::shared_ptr<Texture> TextureContents::GetTexture() const {
  return texture_;
}

void TextureContents::SetOpacity(Scalar opacity) {
  opacity_ = opacity;
}

void TextureContents::SetStencilEnabled(bool enabled) {
  stencil_enabled_ = enabled;
}

bool TextureContents::CanInheritOpacity(const Entity& entity) const {
  return true;
}

void TextureContents::SetInheritedOpacity(Scalar opacity) {
  inherited_opacity_ = opacity;
}

Scalar TextureContents::GetOpacity() const {
  return opacity_ * inherited_opacity_;
}

std::optional<Rect> TextureContents::GetCoverage(const Entity& entity) const {
  if (GetOpacity() == 0) {
    return std::nullopt;
  }
  return destination_rect_.TransformBounds(entity.GetTransform());
};

std::optional<Snapshot> TextureContents::RenderToSnapshot(
    const ContentContext& renderer,
    const Entity& entity,
    std::optional<Rect> coverage_limit,
    const std::optional<SamplerDescriptor>& sampler_descriptor,
    bool msaa_enabled,
    int32_t mip_count,
    const std::string& label) const {
  // Passthrough textures that have simple rectangle paths and complete source
  // rects.
  auto bounds = destination_rect_;
  auto opacity = GetOpacity();
  if (source_rect_ == Rect::MakeSize(texture_->GetSize()) &&
      (opacity >= 1 - kEhCloseEnough || defer_applying_opacity_)) {
    auto scale = Vector2(bounds.GetSize() / Size(texture_->GetSize()));
    return Snapshot{
        .texture = texture_,
        .transform = entity.GetTransform() *
                     Matrix::MakeTranslation(bounds.GetOrigin()) *
                     Matrix::MakeScale(scale),
        .sampler_descriptor = sampler_descriptor.value_or(sampler_descriptor_),
        .opacity = opacity};
  }
  return Contents::RenderToSnapshot(
      renderer,                                          // renderer
      entity,                                            // entity
      std::nullopt,                                      // coverage_limit
      sampler_descriptor.value_or(sampler_descriptor_),  // sampler_descriptor
      true,                                              // msaa_enabled
      /*mip_count=*/mip_count,
      label);  // label
}

bool TextureContents::Render(const ContentContext& renderer,
                             const Entity& entity,
                             RenderPass& pass) const {
  auto capture = entity.GetCapture().CreateChild("TextureContents");

  using VS = TextureFillVertexShader;
  using FS = TextureFillFragmentShader;
  using FSStrictSrc = TextureFillStrictSrcFragmentShader;
  using FSExternal = TextureFillExternalFragmentShader;

  if (destination_rect_.IsEmpty() || source_rect_.IsEmpty() ||
      texture_ == nullptr || texture_->GetSize().IsEmpty()) {
    return true;  // Nothing to render.
  }

  bool is_external_texture =
      texture_->GetTextureDescriptor().type == TextureType::kTextureExternalOES;

  auto source_rect = capture.AddRect("Source rect", source_rect_);
  auto texture_coords =
      Rect::MakeSize(texture_->GetSize()).Project(source_rect);

  VertexBufferBuilder<VS::PerVertexData> vertex_builder;

  auto destination_rect =
      capture.AddRect("Destination rect", destination_rect_);
  vertex_builder.AddVertices({
      {destination_rect.GetLeftTop(), texture_coords.GetLeftTop()},
      {destination_rect.GetRightTop(), texture_coords.GetRightTop()},
      {destination_rect.GetLeftBottom(), texture_coords.GetLeftBottom()},
      {destination_rect.GetRightBottom(), texture_coords.GetRightBottom()},
  });

  auto& host_buffer = renderer.GetTransientsBuffer();

  VS::FrameInfo frame_info;
  frame_info.mvp = entity.GetShaderTransform(pass);
  frame_info.texture_sampler_y_coord_scale = texture_->GetYCoordScale();
  frame_info.alpha = capture.AddScalar("Alpha", GetOpacity());

#ifdef IMPELLER_DEBUG
  if (label_.empty()) {
    pass.SetCommandLabel("Texture Fill");
  } else {
    pass.SetCommandLabel("Texture Fill: " + label_);
  }
#endif  // IMPELLER_DEBUG

  auto pipeline_options = OptionsFromPassAndEntity(pass, entity);
  if (!stencil_enabled_) {
    pipeline_options.stencil_mode = ContentContextOptions::StencilMode::kIgnore;
  }
  pipeline_options.primitive_type = PrimitiveType::kTriangleStrip;

  std::shared_ptr<Pipeline<PipelineDescriptor>> pipeline;
#ifdef IMPELLER_ENABLE_OPENGLES
  if (is_external_texture) {
    pipeline = renderer.GetTextureExternalPipeline(pipeline_options);
  }
#endif  // IMPELLER_ENABLE_OPENGLES

  if (!pipeline) {
    if (strict_source_rect_enabled_) {
      pipeline = renderer.GetTextureStrictSrcPipeline(pipeline_options);
    } else {
      pipeline = renderer.GetTexturePipeline(pipeline_options);
    }
  }
  pass.SetPipeline(pipeline);

  pass.SetStencilReference(entity.GetClipDepth());
  pass.SetVertexBuffer(vertex_builder.CreateVertexBuffer(host_buffer));
  VS::BindFrameInfo(pass, host_buffer.EmplaceUniform(frame_info));
  if (is_external_texture) {
    FSExternal::BindSAMPLEREXTERNALOESTextureSampler(
        pass, texture_,
        renderer.GetContext()->GetSamplerLibrary()->GetSampler(
            sampler_descriptor_));
  } else if (strict_source_rect_enabled_) {
    // For a strict source rect, shrink the texture coordinate range by half a
    // texel to ensure that linear filtering does not sample anything outside
    // the source rect bounds.
    auto strict_texture_coords =
        Rect::MakeSize(texture_->GetSize()).Project(source_rect.Expand(-0.5));

    FSStrictSrc::FragInfo frag_info;
    frag_info.source_rect = Vector4(strict_texture_coords.GetLTRB());
    FSStrictSrc::BindFragInfo(pass, host_buffer.EmplaceUniform(frag_info));
    FSStrictSrc::BindTextureSampler(
        pass, texture_,
        renderer.GetContext()->GetSamplerLibrary()->GetSampler(
            sampler_descriptor_));
  } else {
    FS::BindTextureSampler(
        pass, texture_,
        renderer.GetContext()->GetSamplerLibrary()->GetSampler(
            sampler_descriptor_));
  }
  return pass.Draw().ok();
}

void TextureContents::SetSourceRect(const Rect& source_rect) {
  source_rect_ = source_rect;
}

const Rect& TextureContents::GetSourceRect() const {
  return source_rect_;
}

void TextureContents::SetStrictSourceRect(bool strict) {
  strict_source_rect_enabled_ = strict;
}

bool TextureContents::GetStrictSourceRect() const {
  return strict_source_rect_enabled_;
}

void TextureContents::SetSamplerDescriptor(SamplerDescriptor desc) {
  sampler_descriptor_ = std::move(desc);
}

const SamplerDescriptor& TextureContents::GetSamplerDescriptor() const {
  return sampler_descriptor_;
}

void TextureContents::SetDeferApplyingOpacity(bool defer_applying_opacity) {
  defer_applying_opacity_ = defer_applying_opacity;
}

}  // namespace impeller
