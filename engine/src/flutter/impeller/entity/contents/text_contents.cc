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

std::optional<Rect> TextContents::GetCoverage(const Entity& entity) const {
  auto bounds = frame_.GetBounds();
  if (!bounds.has_value()) {
    return std::nullopt;
  }
  return bounds->TransformBounds(entity.GetTransformation());
}

template <class TPipeline>
static bool CommonRender(
    const ContentContext& renderer,
    const Entity& entity,
    RenderPass& pass,
    const Color& color,
    const TextFrame& frame,
    Vector2 offset,
    std::shared_ptr<GlyphAtlas>
        atlas,  // NOLINT(performance-unnecessary-value-param)
    Command& cmd) {
  using VS = typename TPipeline::VertexShader;
  using FS = typename TPipeline::FragmentShader;

  // Common vertex uniforms for all glyphs.
  typename VS::FrameInfo frame_info;

  frame_info.mvp = Matrix::MakeOrthographic(pass.GetRenderTargetSize());
  VS::BindFrameInfo(cmd, pass.GetTransientsBuffer().EmplaceUniform(frame_info));

  SamplerDescriptor sampler_desc;
  if (entity.GetTransformation().IsTranslationScaleOnly()) {
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

  typename FS::FragInfo frag_info;
  frag_info.text_color = ToVector(color.Premultiply());
  FS::BindFragInfo(cmd, pass.GetTransientsBuffer().EmplaceUniform(frag_info));

  // Common fragment uniforms for all glyphs.
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

  auto atlas_size =
      Point{static_cast<Scalar>(atlas->GetTexture()->GetSize().width),
            static_cast<Scalar>(atlas->GetTexture()->GetSize().height)};

  Vector2 screen_offset = (entity.GetTransformation() * offset).Round();

  for (const auto& run : frame.GetRuns()) {
    auto font = run.GetFont();

    for (const auto& glyph_position : run.GetGlyphPositions()) {
      FontGlyphPair font_glyph_pair{font, glyph_position.glyph};
      auto atlas_glyph_bounds = atlas->FindFontGlyphBounds(font_glyph_pair);
      if (!atlas_glyph_bounds.has_value()) {
        VALIDATION_LOG << "Could not find glyph position in the atlas.";
        return false;
      }

      // For each glyph, we compute two rectangles. One for the vertex positions
      // and one for the texture coordinates (UVs).

      auto uv_origin =
          (atlas_glyph_bounds->origin - Point(0.5, 0.5)) / atlas_size;
      auto uv_size = (atlas_glyph_bounds->size + Size(1, 1)) / atlas_size;

      // Rounding here prevents most jitter between glyphs in the run when
      // nearest sampling.
      auto screen_glyph_position =
          screen_offset +
          (entity.GetTransformation().Basis() *
           (glyph_position.position + glyph_position.glyph.bounds.origin))
              .Round();

      for (const auto& point : unit_points) {
        typename VS::PerVertexData vtx;

        if (entity.GetTransformation().IsTranslationScaleOnly()) {
          // Rouding up here prevents the bounds from becoming 1 pixel too small
          // when nearest sampling. This path breaks down for projections.
          vtx.position =
              screen_glyph_position + (entity.GetTransformation().Basis() *
                                       point * glyph_position.glyph.bounds.size)
                                          .Ceil();
        } else {
          vtx.position = entity.GetTransformation() *
                         Vector4(offset + glyph_position.position +
                                 glyph_position.glyph.bounds.origin +
                                 point * glyph_position.glyph.bounds.size);
        }
        vtx.uv = uv_origin + point * uv_size;

        if constexpr (std::is_same_v<TPipeline, GlyphAtlasPipeline>) {
          vtx.has_color =
              glyph_position.glyph.type == Glyph::Type::kBitmap ? 1.0 : 0.0;
        }

        vertex_builder.AppendVertex(std::move(vtx));
      }
    }
  }
  auto vertex_buffer =
      vertex_builder.CreateVertexBuffer(pass.GetTransientsBuffer());
  cmd.BindVertices(std::move(vertex_buffer));

  if (!pass.AddCommand(cmd)) {
    return false;
  }

  return true;
}

bool TextContents::RenderSdf(const ContentContext& renderer,
                             const Entity& entity,
                             RenderPass& pass) const {
  auto atlas =
      ResolveAtlas(GlyphAtlas::Type::kSignedDistanceField,
                   renderer.GetGlyphAtlasContext(), renderer.GetContext());

  if (!atlas || !atlas->IsValid()) {
    VALIDATION_LOG << "Cannot render glyphs without prepared atlas.";
    return false;
  }

  // Information shared by all glyph draw calls.
  Command cmd;
  cmd.label = "TextFrameSDF";
  auto opts = OptionsFromPassAndEntity(pass, entity);
  opts.primitive_type = PrimitiveType::kTriangle;
  cmd.pipeline = renderer.GetGlyphAtlasSdfPipeline(opts);
  cmd.stencil_reference = entity.GetStencilDepth();

  return CommonRender<GlyphAtlasSdfPipeline>(renderer, entity, pass, GetColor(),
                                             frame_, offset_, atlas, cmd);
}

bool TextContents::Render(const ContentContext& renderer,
                          const Entity& entity,
                          RenderPass& pass) const {
  auto color = GetColor();
  if (color.IsTransparent()) {
    return true;
  }

  // This TextContents may be for a frame that doesn't have color, but the
  // lazy atlas for this scene already does have color.
  // Benchmarks currently show that creating two atlases per pass regresses
  // render time. This should get re-evaluated if we start caching atlases
  // between frames or get significantly faster at creating atlases, because
  // we're potentially trading memory for time here.
  auto atlas =
      ResolveAtlas(lazy_atlas_->HasColor() ? GlyphAtlas::Type::kColorBitmap
                                           : GlyphAtlas::Type::kAlphaBitmap,
                   renderer.GetGlyphAtlasContext(), renderer.GetContext());

  if (!atlas || !atlas->IsValid()) {
    VALIDATION_LOG << "Cannot render glyphs without prepared atlas.";
    return false;
  }

  // Information shared by all glyph draw calls.
  Command cmd;
  cmd.label = "TextFrame";
  auto opts = OptionsFromPassAndEntity(pass, entity);
  opts.primitive_type = PrimitiveType::kTriangle;
  cmd.pipeline = renderer.GetGlyphAtlasPipeline(opts);
  cmd.stencil_reference = entity.GetStencilDepth();

  return CommonRender<GlyphAtlasPipeline>(renderer, entity, pass, color, frame_,
                                          offset_, atlas, cmd);
}

}  // namespace impeller
