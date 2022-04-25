// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/text_contents.h"

#include <optional>

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

void TextContents::SetTextFrame(TextFrame frame) {
  frame_ = std::move(frame);
}

void TextContents::SetGlyphAtlas(std::shared_ptr<GlyphAtlas> atlas) {
  atlas_ = std::move(atlas);
}

void TextContents::SetGlyphAtlas(std::shared_ptr<LazyGlyphAtlas> atlas) {
  atlas_ = std::move(atlas);
}

std::shared_ptr<GlyphAtlas> TextContents::ResolveAtlas(
    std::shared_ptr<Context> context) const {
  if (auto lazy_atlas = std::get_if<std::shared_ptr<LazyGlyphAtlas>>(&atlas_)) {
    return lazy_atlas->get()->CreateOrGetGlyphAtlas(context);
  }

  if (auto atlas = std::get_if<std::shared_ptr<GlyphAtlas>>(&atlas_)) {
    return *atlas;
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

bool TextContents::Render(const ContentContext& renderer,
                          const Entity& entity,
                          RenderPass& pass) const {
  if (color_.IsTransparent()) {
    return true;
  }

  auto atlas = ResolveAtlas(renderer.GetContext());

  if (!atlas || !atlas->IsValid()) {
    VALIDATION_LOG << "Cannot render glyphs without prepared atlas.";
    return false;
  }

  using VS = GlyphAtlasPipeline::VertexShader;
  using FS = GlyphAtlasPipeline::FragmentShader;

  // Information shared by all glyph draw calls.
  Command cmd;
  cmd.label = "TextFrame";
  cmd.primitive_type = PrimitiveType::kTriangle;
  cmd.pipeline =
      renderer.GetGlyphAtlasPipeline(OptionsFromPassAndEntity(pass, entity));
  cmd.stencil_reference = entity.GetStencilDepth();

  // Common vertex uniforms for all glyphs.
  VS::FrameInfo frame_info;
  frame_info.mvp = Matrix::MakeOrthographic(pass.GetRenderTargetSize()) *
                   entity.GetTransformation();
  frame_info.atlas_size =
      Point{static_cast<Scalar>(atlas->GetTexture()->GetSize().width),
            static_cast<Scalar>(atlas->GetTexture()->GetSize().height)};
  frame_info.text_color = ToVector(color_.Premultiply());
  VS::BindFrameInfo(cmd, pass.GetTransientsBuffer().EmplaceUniform(frame_info));

  // Common fragment uniforms for all glyphs.
  FS::BindGlyphAtlasSampler(
      cmd,                                                        // command
      atlas->GetTexture(),                                        // texture
      renderer.GetContext()->GetSamplerLibrary()->GetSampler({})  // sampler
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

  VertexBufferBuilder<VS::PerVertexData> vertex_builder;
  for (const auto& run : frame_.GetRuns()) {
    auto font = run.GetFont();
    auto glyph_size = ISize::Ceil(font.GetMetrics().GetBoundingBox().size);
    for (const auto& glyph_position : run.GetGlyphPositions()) {
      for (const auto& point : unit_vertex_points) {
        VS::PerVertexData vtx;
        vtx.unit_vertex = point;

        FontGlyphPair font_glyph_pair{font, glyph_position.glyph};
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
        vtx.atlas_position = atlas_glyph_pos->origin;
        vtx.atlas_glyph_size =
            Point{atlas_glyph_pos->size.width, atlas_glyph_pos->size.height};
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

}  // namespace impeller
