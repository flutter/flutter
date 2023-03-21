// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/text_contents.h"

#include <optional>
#include <type_traits>
#include <utility>

#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/entity.h"
#include "impeller/geometry/path_builder.h"
#include "impeller/renderer/formats.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/sampler_descriptor.h"
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
  return color_;
}

bool TextContents::CanAcceptOpacity(const Entity& entity) const {
  return !frame_.MaybeHasOverlapping();
}

void TextContents::SetInheritedOpacity(Scalar opacity) {
  auto color = color_;
  color_ = color.WithAlpha(color.alpha * opacity);
}

void TextContents::SetInverseMatrix(Matrix matrix) {
  inverse_matrix_ = matrix;
}

std::optional<Rect> TextContents::GetCoverage(const Entity& entity) const {
  auto bounds = frame_.GetBounds();
  if (!bounds.has_value()) {
    return std::nullopt;
  }
  return bounds->TransformBounds(entity.GetTransformation());
}

static Vector4 PositionForGlyphPosition(const Matrix& translation,
                                        Point unit_position,
                                        Size destination_size) {
  return translation * (unit_position * destination_size);
}

template <class TPipeline>
static bool CommonRender(
    const ContentContext& renderer,
    const Entity& entity,
    RenderPass& pass,
    const Color& color,
    const TextFrame& frame,
    const Matrix& inverse_matrix,
    std::shared_ptr<GlyphAtlas>
        atlas,  // NOLINT(performance-unnecessary-value-param)
    Command& cmd) {
  using VS = typename TPipeline::VertexShader;
  using FS = typename TPipeline::FragmentShader;

  // Common vertex uniforms for all glyphs.
  typename VS::FrameInfo frame_info;
  frame_info.mvp = Matrix::MakeOrthographic(pass.GetRenderTargetSize()) *
                   entity.GetTransformation();
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

  uint32_t offset = 0u;
  for (auto i = 0u; i < count; i++) {
    for (const auto& index : indices) {
      vertex_builder.AppendIndex(index + offset);
    }
    offset += 4;
  }

  auto atlas_size =
      Point{static_cast<Scalar>(atlas->GetTexture()->GetSize().width),
            static_cast<Scalar>(atlas->GetTexture()->GetSize().height)};

  for (const auto& run : frame.GetRuns()) {
    auto font = run.GetFont();

    for (const auto& glyph_position : run.GetGlyphPositions()) {
      FontGlyphPair font_glyph_pair{font, glyph_position.glyph};
      auto atlas_glyph_pos = atlas->FindFontGlyphPosition(font_glyph_pair);
      if (!atlas_glyph_pos.has_value()) {
        VALIDATION_LOG << "Could not find glyph position in the atlas.";
        return false;
      }

      auto offset_glyph_position =
          glyph_position.position + glyph_position.glyph.bounds.origin;

      auto uv_scaler_a = atlas_glyph_pos->size / atlas_size;
      auto uv_scaler_b = (Point::Round(atlas_glyph_pos->origin) / atlas_size);
      auto translation =
          Matrix::MakeTranslation(
              Vector3(offset_glyph_position.x, offset_glyph_position.y, 0)) *
          inverse_matrix;

      for (const auto& point : unit_points) {
        typename VS::PerVertexData vtx;
        auto position = PositionForGlyphPosition(
            translation, point, glyph_position.glyph.bounds.size);
        vtx.uv = point * uv_scaler_a + uv_scaler_b;
        vtx.position = position;

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

  return CommonRender<GlyphAtlasSdfPipeline>(
      renderer, entity, pass, color_, frame_, inverse_matrix_, atlas, cmd);
}

bool TextContents::Render(const ContentContext& renderer,
                          const Entity& entity,
                          RenderPass& pass) const {
  if (color_.IsTransparent()) {
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

  return CommonRender<GlyphAtlasPipeline>(renderer, entity, pass, color_,
                                          frame_, inverse_matrix_, atlas, cmd);
}

}  // namespace impeller
