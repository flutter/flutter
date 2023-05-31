// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/text_contents.h"

#include <optional>
#include <type_traits>
#include <utility>

#include "impeller/core/formats.h"
#include "impeller/core/sampler_descriptor.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/entity.h"
#include "impeller/geometry/path_builder.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/sampler_library.h"
#include "impeller/tessellator/tessellator.h"
#include "impeller/typographer/glyph_atlas.h"
#include "impeller/typographer/lazy_glyph_atlas.h"

namespace impeller {

TextContents::TextContents() = default;

TextContents::~TextContents() = default;

void TextContents::SetTextFrame(const TextFrame& frame) {
  frame_ = frame;
}

void TextContents::SetGlyphAtlas(std::shared_ptr<LazyGlyphAtlas> atlas) {
  lazy_atlas_ = std::move(atlas);
}

std::shared_ptr<GlyphAtlas> TextContents::ResolveAtlas(
    GlyphAtlas::Type type,
    std::shared_ptr<GlyphAtlasContext> atlas_context,
    std::shared_ptr<Context> context) const {
  FML_DCHECK(lazy_atlas_);
  if (lazy_atlas_) {
    return lazy_atlas_->CreateOrGetGlyphAtlas(type, std::move(atlas_context),
                                              std::move(context));
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
  return !frame_.MaybeHasOverlapping();
}

void TextContents::SetInheritedOpacity(Scalar opacity) {
  inherited_opacity_ = opacity;
}

void TextContents::SetOffset(Vector2 offset) {
  offset_ = offset;
}

std::optional<Rect> TextContents::GetTextFrameBounds() const {
  return frame_.GetBounds();
}

std::optional<Rect> TextContents::GetCoverage(const Entity& entity) const {
  auto bounds = frame_.GetBounds();
  if (!bounds.has_value()) {
    return std::nullopt;
  }
  return bounds->TransformBounds(entity.GetTransformation());
}

static bool CommonRender(const ContentContext& renderer,
                         const Entity& entity,
                         RenderPass& pass,
                         const Color& color,
                         const TextFrame& frame,
                         Vector2 offset,
                         const std::shared_ptr<GlyphAtlas>& atlas,
                         Command& cmd) {
  using VS = GlyphAtlasPipeline::VertexShader;
  using FS = GlyphAtlasPipeline::FragmentShader;

  // Common vertex uniforms for all glyphs.
  VS::FrameInfo frame_info;
  frame_info.mvp = Matrix::MakeOrthographic(pass.GetRenderTargetSize());
  frame_info.atlas_size =
      Vector2{static_cast<Scalar>(atlas->GetTexture()->GetSize().width),
              static_cast<Scalar>(atlas->GetTexture()->GetSize().height)};
  frame_info.offset = offset;
  frame_info.is_translation_scale =
      entity.GetTransformation().IsTranslationScaleOnly();
  frame_info.entity_transform = entity.GetTransformation();

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

  FS::FragInfo frag_info;
  frag_info.text_color = ToVector(color.Premultiply());
  FS::BindFragInfo(cmd, pass.GetTransientsBuffer().EmplaceUniform(frag_info));

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

  constexpr std::array<Point, 4> unit_points = {Point{0, 0}, Point{1, 0},
                                                Point{0, 1}, Point{1, 1}};
  constexpr std::array<uint32_t, 6> indices = {0, 1, 2, 1, 2, 3};

  VertexBufferBuilder<typename VS::PerVertexData> vertex_builder;

  size_t count = 0;
  for (const auto& run : frame.GetRuns()) {
    count += run.GetGlyphPositions().size();
  }

  vertex_builder.Reserve(count * 4);
  vertex_builder.ReserveIndices(count * 6);

  uint32_t index_offset = 0u;
  for (auto i = 0u; i < count; i++) {
    for (const auto& index : indices) {
      vertex_builder.AppendIndex(index + index_offset);
    }
    index_offset += 4;
  }

  for (const auto& run : frame.GetRuns()) {
    const Font& font = run.GetFont();

    for (const auto& glyph_position : run.GetGlyphPositions()) {
      FontGlyphPair font_glyph_pair{font, glyph_position.glyph};
      auto atlas_glyph_bounds = atlas->FindFontGlyphBounds(font_glyph_pair);
      if (!atlas_glyph_bounds.has_value()) {
        VALIDATION_LOG << "Could not find glyph position in the atlas.";
        return false;
      }
      Vector4 atlas_glyph_bounds_vec = Vector4(
          atlas_glyph_bounds->origin.x, atlas_glyph_bounds->origin.y,
          atlas_glyph_bounds->size.width, atlas_glyph_bounds->size.height);
      Vector4 glyph_bounds_vec =
          Vector4(glyph_position.glyph.bounds.origin.x,
                  glyph_position.glyph.bounds.origin.y,
                  glyph_position.glyph.bounds.size.width,
                  glyph_position.glyph.bounds.size.height);

      for (const auto& point : unit_points) {
        vertex_builder.AppendVertex(VS::PerVertexData{
            .atlas_glyph_bounds = atlas_glyph_bounds_vec,
            .glyph_bounds = glyph_bounds_vec,
            .unit_position = point,
            .glyph_position = glyph_position.position,
        });
      }
    }
  }
  auto vertex_buffer =
      vertex_builder.CreateVertexBuffer(pass.GetTransientsBuffer());
  cmd.BindVertices(vertex_buffer);

  return pass.AddCommand(cmd);
}

bool TextContents::Render(const ContentContext& renderer,
                          const Entity& entity,
                          RenderPass& pass) const {
  auto color = GetColor();
  if (color.IsTransparent()) {
    return true;
  }

  auto type = frame_.GetAtlasType();
  auto atlas = ResolveAtlas(type, renderer.GetGlyphAtlasContext(type),
                            renderer.GetContext());

  if (!atlas || !atlas->IsValid()) {
    VALIDATION_LOG << "Cannot render glyphs without prepared atlas.";
    return false;
  }

  // Information shared by all glyph draw calls.
  Command cmd;
  cmd.label = "TextFrame";
  auto opts = OptionsFromPassAndEntity(pass, entity);
  opts.primitive_type = PrimitiveType::kTriangle;
  if (type == GlyphAtlas::Type::kAlphaBitmap) {
    cmd.pipeline = renderer.GetGlyphAtlasPipeline(opts);
  } else {
    cmd.pipeline = renderer.GetGlyphAtlasColorPipeline(opts);
  }
  cmd.stencil_reference = entity.GetStencilDepth();

  return CommonRender(renderer, entity, pass, color, frame_, offset_, atlas,
                      cmd);
}

}  // namespace impeller
