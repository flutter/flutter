// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/text_contents.h"

#include <cstring>
#include <optional>
#include <type_traits>
#include <utility>

#include "impeller/core/formats.h"
#include "impeller/core/sampler_descriptor.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/entity.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/sampler_library.h"
#include "impeller/typographer/glyph_atlas.h"
#include "impeller/typographer/lazy_glyph_atlas.h"

namespace impeller {

TextContents::TextContents() = default;

TextContents::~TextContents() = default;

void TextContents::SetTextFrame(const std::shared_ptr<TextFrame>& frame) {
  frame_ = frame;
}

std::shared_ptr<GlyphAtlas> TextContents::ResolveAtlas(
    Context& context,
    GlyphAtlas::Type type,
    const std::shared_ptr<LazyGlyphAtlas>& lazy_atlas) const {
  FML_DCHECK(lazy_atlas);
  if (lazy_atlas) {
    return lazy_atlas->CreateOrGetGlyphAtlas(context, type);
  }

  return nullptr;
}

void TextContents::SetColor(Color color) {
  color_ = color;
}

Color TextContents::GetColor() const {
  return color_.WithAlpha(color_.alpha * inherited_opacity_);
}

bool TextContents::CanInheritOpacity(const Entity& entity) const {
  return !frame_->MaybeHasOverlapping();
}

void TextContents::SetInheritedOpacity(Scalar opacity) {
  inherited_opacity_ = opacity;
}

void TextContents::SetOffset(Vector2 offset) {
  offset_ = offset;
}

std::optional<Rect> TextContents::GetCoverage(const Entity& entity) const {
  return frame_->GetBounds().TransformBounds(entity.GetTransformation());
}

void TextContents::PopulateGlyphAtlas(
    const std::shared_ptr<LazyGlyphAtlas>& lazy_glyph_atlas,
    Scalar scale) {
  lazy_glyph_atlas->AddTextFrame(*frame_, scale);
  scale_ = scale;
}

bool TextContents::Render(const ContentContext& renderer,
                          const Entity& entity,
                          RenderPass& pass) const {
  auto color = GetColor();
  if (color.IsTransparent()) {
    return true;
  }

  auto type = frame_->GetAtlasType();
  auto atlas =
      ResolveAtlas(*renderer.GetContext(), type, renderer.GetLazyGlyphAtlas());

  if (!atlas || !atlas->IsValid()) {
    VALIDATION_LOG << "Cannot render glyphs without prepared atlas.";
    return false;
  }

  // Information shared by all glyph draw calls.
  Command cmd;
  DEBUG_COMMAND_INFO(cmd, "TextFrame");
  auto opts = OptionsFromPassAndEntity(pass, entity);
  opts.primitive_type = PrimitiveType::kTriangle;
  if (type == GlyphAtlas::Type::kAlphaBitmap) {
    cmd.pipeline = renderer.GetGlyphAtlasPipeline(opts);
  } else {
    cmd.pipeline = renderer.GetGlyphAtlasColorPipeline(opts);
  }
  cmd.stencil_reference = entity.GetStencilDepth();

  using VS = GlyphAtlasPipeline::VertexShader;
  using FS = GlyphAtlasPipeline::FragmentShader;

  // Common vertex uniforms for all glyphs.
  VS::FrameInfo frame_info;
  frame_info.mvp = Matrix::MakeOrthographic(pass.GetRenderTargetSize());
  frame_info.atlas_size =
      Vector2{static_cast<Scalar>(atlas->GetTexture()->GetSize().width),
              static_cast<Scalar>(atlas->GetTexture()->GetSize().height)};
  frame_info.offset = offset_;
  frame_info.is_translation_scale =
      entity.GetTransformation().IsTranslationScaleOnly();
  frame_info.entity_transform = entity.GetTransformation();
  frame_info.text_color = ToVector(color.Premultiply());

  VS::BindFrameInfo(cmd, pass.GetTransientsBuffer().EmplaceUniform(frame_info));

  SamplerDescriptor sampler_desc;
  if (frame_info.is_translation_scale) {
    sampler_desc.min_filter = MinMagFilter::kNearest;
    sampler_desc.mag_filter = MinMagFilter::kNearest;
  } else {
    // Currently, we only propagate the scale of the transform to the atlas
    // renderer, so if the transform has more than just a translation, we turn
    // on linear sampling to prevent crunchiness caused by the pixel grid not
    // being perfectly aligned.
    // The downside is that this slightly over-blurs rotated/skewed text.
    sampler_desc.min_filter = MinMagFilter::kLinear;
    sampler_desc.mag_filter = MinMagFilter::kLinear;
  }
  sampler_desc.mip_filter = MipFilter::kNearest;

  FS::BindGlyphAtlasSampler(
      cmd,                  // command
      atlas->GetTexture(),  // texture
      renderer.GetContext()->GetSamplerLibrary()->GetSampler(
          sampler_desc)  // sampler
  );

  // Common vertex information for all glyphs.
  // All glyphs are given the same vertex information in the form of a
  // unit-sized quad. The size of the glyph is specified in per instance data
  // and the vertex shader uses this to size the glyph correctly. The
  // interpolated vertex information is also used in the fragment shader to
  // sample from the glyph atlas.

  constexpr std::array<Point, 6> unit_points = {Point{0, 0}, Point{1, 0},
                                                Point{0, 1}, Point{1, 0},
                                                Point{0, 1}, Point{1, 1}};

  auto& host_buffer = pass.GetTransientsBuffer();
  size_t vertex_count = 0;
  for (const auto& run : frame_->GetRuns()) {
    vertex_count += run.GetGlyphPositions().size();
  }
  vertex_count *= 6;

  auto buffer_view = host_buffer.Emplace(
      vertex_count * sizeof(VS::PerVertexData), alignof(VS::PerVertexData),
      [&](uint8_t* contents) {
        VS::PerVertexData vtx;
        VS::PerVertexData* vtx_contents =
            reinterpret_cast<VS::PerVertexData*>(contents);
        for (const TextRun& run : frame_->GetRuns()) {
          const Font& font = run.GetFont();
          Scalar rounded_scale = TextFrame::RoundScaledFontSize(
              scale_, font.GetMetrics().point_size);
          const FontGlyphAtlas* font_atlas =
              atlas->GetFontGlyphAtlas(font, rounded_scale);
          if (!font_atlas) {
            VALIDATION_LOG << "Could not find font in the atlas.";
            continue;
          }

          for (const TextRun::GlyphPosition& glyph_position :
               run.GetGlyphPositions()) {
            std::optional<Rect> maybe_atlas_glyph_bounds =
                font_atlas->FindGlyphBounds(glyph_position.glyph);
            if (!maybe_atlas_glyph_bounds.has_value()) {
              VALIDATION_LOG << "Could not find glyph position in the atlas.";
              continue;
            }
            const Rect& atlas_glyph_bounds = maybe_atlas_glyph_bounds.value();
            vtx.atlas_glyph_bounds = Vector4(
                atlas_glyph_bounds.origin.x, atlas_glyph_bounds.origin.y,
                atlas_glyph_bounds.size.width, atlas_glyph_bounds.size.height);
            vtx.glyph_bounds = Vector4(glyph_position.glyph.bounds.origin.x,
                                       glyph_position.glyph.bounds.origin.y,
                                       glyph_position.glyph.bounds.size.width,
                                       glyph_position.glyph.bounds.size.height);
            vtx.glyph_position = glyph_position.position;

            for (const Point& point : unit_points) {
              vtx.unit_position = point;
              std::memcpy(vtx_contents++, &vtx, sizeof(VS::PerVertexData));
            }
          }
        }
      });

  cmd.BindVertices({
      .vertex_buffer = buffer_view,
      .index_buffer = {},
      .vertex_count = vertex_count,
      .index_type = IndexType::kNone,
  });

  return pass.AddCommand(std::move(cmd));
}

}  // namespace impeller
