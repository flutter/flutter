// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "text_contents.h"

#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/entity.h"
#include "impeller/geometry/path_builder.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/sampler_library.h"
#include "impeller/tessellator/tessellator.h"
#include "impeller/typographer/glyph_atlas.h"

namespace impeller {
TextContents::TextContents() = default;

TextContents::~TextContents() = default;

void TextContents::SetTextFrame(TextFrame frame) {
  frame_ = std::move(frame);
}

void TextContents::SetGlyphAtlas(std::shared_ptr<GlyphAtlas> atlas) {
  atlas_ = std::move(atlas);
}

void TextContents::SetColor(Color color) {
  color_ = color;
}

bool TextContents::Render(const ContentContext& renderer,
                          const Entity& entity,
                          RenderPass& pass) const {
  if (color_.IsTransparent()) {
    return true;
  }

  if (!atlas_ || !atlas_->IsValid()) {
    VALIDATION_LOG << "Cannot render glyphs without prepared atlas.";
    return false;
  }

  using VS = GlyphAtlasPipeline::VertexShader;
  using FS = GlyphAtlasPipeline::FragmentShader;

  // Information shared by all glyph draw calls.
  Command cmd;
  cmd.label = "Glyph";
  cmd.primitive_type = PrimitiveType::kTriangle;
  cmd.pipeline =
      renderer.GetGlyphAtlasPipeline(OptionsFromPassAndEntity(pass, entity));
  cmd.stencil_reference = entity.GetStencilDepth();

  // Common vertex uniforms for all glyphs.
  VS::FrameInfo frame_info;
  frame_info.mvp = Matrix::MakeOrthographic(pass.GetRenderTargetSize()) *
                   entity.GetTransformation();
  frame_info.atlas_size =
      Point{static_cast<Scalar>(atlas_->GetTexture()->GetSize().width),
            static_cast<Scalar>(atlas_->GetTexture()->GetSize().height)};
  frame_info.text_color = ToVector(color_);
  VS::BindFrameInfo(cmd, pass.GetTransientsBuffer().EmplaceUniform(frame_info));

  // Common fragment uniforms for all glyphs.
  FS::BindGlyphAtlasSampler(
      cmd,                                                        // command
      atlas_->GetTexture(),                                       // texture
      renderer.GetContext()->GetSamplerLibrary()->GetSampler({})  // sampler
  );

  // Common vertex information for all glyphs.
  // Currently, glyphs are being drawn individually. This can be batched later.
  // But we don't want to give each glyph unique vertex information. So all
  // glyphs are given the same vertex information in the form of a unit-sized
  // quad. The size of the glyph is specified in uniform data and the vertex
  // shader uses this to size the glyph correctly. The interpolated vertex
  // information is also used in the fragment shader to sample from the glyph
  // atlas.
  {
    VertexBufferBuilder<VS::PerVertexData> vertex_builder;
    if (!Tessellator{}.Tessellate(
            FillType::kPositive,
            PathBuilder{}
                .AddRect(Rect::MakeXYWH(0.0, 0.0, 1.0, 1.0))
                .TakePath()
                .CreatePolyline(),
            [&vertex_builder](Point point) {
              VS::PerVertexData vtx;
              vtx.unit_vertex = point;
              vertex_builder.AppendVertex(std::move(vtx));
            })) {
      return false;
    }
    auto dummy = vertex_builder.CreateVertexBuffer(pass.GetTransientsBuffer());
    auto vertex_buffer = dummy;
    if (!vertex_buffer) {
      return false;
    }
    cmd.BindVertices(std::move(vertex_buffer));
  }

  // Iterate through all the runs in the blob.
  for (const auto& run : frame_.GetRuns()) {
    auto font = run.GetFont();
    auto glyph_size = ISize::Ceil(font.GetMetrics().GetBoundingBox().size);
    // Draw each glyph individually. This should probably be batched.
    for (const auto& glyph_position : run.GetGlyphPositions()) {
      FontGlyphPair font_glyph_pair{font, glyph_position.glyph};
      auto atlas_glyph_pos = atlas_->FindFontGlyphPosition(font_glyph_pair);
      if (!atlas_glyph_pos.has_value()) {
        VALIDATION_LOG << "Could not find glyph position in the atlas.";
        return false;
      }

      VS::GlyphInfo glyph_info;
      glyph_info.position = glyph_position.position.Translate(
          {font.GetMetrics().min_extent.x, font.GetMetrics().ascent, 0.0});
      glyph_info.glyph_size = {static_cast<Scalar>(glyph_size.width),
                               static_cast<Scalar>(glyph_size.height)};
      glyph_info.atlas_position = atlas_glyph_pos->origin;
      glyph_info.atlas_glyph_size = {atlas_glyph_pos->size.width,
                                     atlas_glyph_pos->size.height};
      VS::BindGlyphInfo(cmd,
                        pass.GetTransientsBuffer().EmplaceUniform(glyph_info));

      if (!pass.AddCommand(cmd)) {
        return false;
      }
    }
  }

  return true;
}

}  // namespace impeller
