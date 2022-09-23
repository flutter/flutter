// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/text_contents.h"

#include <optional>
#include <type_traits>

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

void TextContents::SetTextFrame(TextFrame frame) {
  frame_ = std::move(frame);
}

void TextContents::SetGlyphAtlas(std::shared_ptr<LazyGlyphAtlas> atlas) {
  lazy_atlas_ = std::move(atlas);
}

std::shared_ptr<GlyphAtlas> TextContents::ResolveAtlas(
    GlyphAtlas::Type type,
    std::shared_ptr<Context> context) const {
  FML_DCHECK(lazy_atlas_);
  if (lazy_atlas_) {
    return lazy_atlas_->CreateOrGetGlyphAtlas(type, context);
  }

  return nullptr;
}

void TextContents::SetColor(Color color) {
  color_ = color;
}

std::optional<Rect> TextContents::GetCoverage(const Entity& entity) const {
  auto bounds = frame_.GetBounds();
  if (!bounds.has_value()) {
    return std::nullopt;
  }
  return bounds->TransformBounds(entity.GetTransformation());
}

template <class TPipeline>
static bool CommonRender(const ContentContext& renderer,
                         const Entity& entity,
                         RenderPass& pass,
                         const Color& color,
                         const TextFrame& frame,
                         std::shared_ptr<GlyphAtlas> atlas,
                         Command& cmd) {
  using VS = typename TPipeline::VertexShader;
  using FS = typename TPipeline::FragmentShader;

  // Common vertex uniforms for all glyphs.
  typename VS::FrameInfo frame_info;
  frame_info.mvp = Matrix::MakeOrthographic(pass.GetRenderTargetSize()) *
                   entity.GetTransformation();
  VS::BindFrameInfo(cmd, pass.GetTransientsBuffer().EmplaceUniform(frame_info));

  SamplerDescriptor sampler_desc;
  sampler_desc.min_filter = MinMagFilter::kLinear;
  sampler_desc.mag_filter = MinMagFilter::kLinear;

  typename FS::FragInfo frag_info;
  frag_info.text_color = ToVector(color.Premultiply());
  frag_info.atlas_size =
      Point{static_cast<Scalar>(atlas->GetTexture()->GetSize().width),
            static_cast<Scalar>(atlas->GetTexture()->GetSize().height)};
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

  const std::vector<Point> unit_vertex_points = {
      {0, 0}, {1, 0}, {0, 1}, {1, 0}, {0, 1}, {1, 1},
  };

  VertexBufferBuilder<typename VS::PerVertexData> vertex_builder;
  for (const auto& run : frame.GetRuns()) {
    auto font = run.GetFont();
    auto glyph_size = ISize::Ceil(font.GetMetrics().GetBoundingBox().size);
    for (const auto& glyph_position : run.GetGlyphPositions()) {
      FontGlyphPair font_glyph_pair{font, glyph_position.glyph};

      for (const auto& point : unit_vertex_points) {
        typename VS::PerVertexData vtx;
        vtx.unit_vertex = point;

        auto atlas_glyph_pos = atlas->FindFontGlyphPosition(font_glyph_pair);
        if (!atlas_glyph_pos.has_value()) {
          VALIDATION_LOG << "Could not find glyph position in the atlas.";
          return false;
        }
        vtx.glyph_position =
            glyph_position.position +
            Point{font.GetMetrics().min_extent.x, font.GetMetrics().ascent};
        vtx.glyph_size = Point{static_cast<Scalar>(glyph_size.width),
                               static_cast<Scalar>(glyph_size.height)};
        vtx.atlas_position =
            atlas_glyph_pos->origin + Point{1 / atlas_glyph_pos->size.width,
                                            1 / atlas_glyph_pos->size.height};
        vtx.atlas_glyph_size =
            Point{atlas_glyph_pos->size.width, atlas_glyph_pos->size.height};
        if constexpr (std::is_same_v<TPipeline, GlyphAtlasPipeline>) {
          vtx.color_glyph =
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
  auto atlas = ResolveAtlas(GlyphAtlas::Type::kSignedDistanceField,
                            renderer.GetContext());

  if (!atlas || !atlas->IsValid()) {
    VALIDATION_LOG << "Cannot render glyphs without prepared atlas.";
    return false;
  }

  // Information shared by all glyph draw calls.
  Command cmd;
  cmd.label = "TextFrameSDF";
  cmd.primitive_type = PrimitiveType::kTriangle;
  cmd.pipeline =
      renderer.GetGlyphAtlasSdfPipeline(OptionsFromPassAndEntity(pass, entity));
  cmd.stencil_reference = entity.GetStencilDepth();

  return CommonRender<GlyphAtlasSdfPipeline>(renderer, entity, pass, color_,
                                             frame_, atlas, cmd);
}

bool TextContents::Render(const ContentContext& renderer,
                          const Entity& entity,
                          RenderPass& pass) const {
  if (color_.IsTransparent()) {
    return true;
  }

  // This TextContents may be for a frame that doesn't have color, but the
  // lazy atlas for this scene alraedy does have color.
  // Benchmarks currently show that creating two atlases per pass regresses
  // render time. This should get re-evaluated if we start caching atlases
  // between frames or get significantly faster at creating atlases, because
  // we're potentially trading memory for time here.
  auto atlas =
      ResolveAtlas(lazy_atlas_->HasColor() ? GlyphAtlas::Type::kColorBitmap
                                           : GlyphAtlas::Type::kAlphaBitmap,
                   renderer.GetContext());

  if (!atlas || !atlas->IsValid()) {
    VALIDATION_LOG << "Cannot render glyphs without prepared atlas.";
    return false;
  }

  // Information shared by all glyph draw calls.
  Command cmd;
  cmd.label = "TextFrame";
  cmd.primitive_type = PrimitiveType::kTriangle;
  cmd.pipeline =
      renderer.GetGlyphAtlasPipeline(OptionsFromPassAndEntity(pass, entity));
  cmd.stencil_reference = entity.GetStencilDepth();

  return CommonRender<GlyphAtlasPipeline>(renderer, entity, pass, color_,
                                          frame_, atlas, cmd);
}

}  // namespace impeller
