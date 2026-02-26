// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/text_contents.h"

#include <cstring>
#include <optional>
#include <utility>

#include "impeller/core/buffer_view.h"
#include "impeller/core/formats.h"
#include "impeller/core/sampler_descriptor.h"
#include "impeller/entity/entity.h"
#include "impeller/geometry/color.h"
#include "impeller/geometry/point.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/typographer/glyph_atlas.h"

namespace impeller {
Point SizeToPoint(Size size) {
  return Point(size.width, size.height);
}

using VS = GlyphAtlasPipeline::VertexShader;
using FS = GlyphAtlasPipeline::FragmentShader;

TextContents::TextContents() = default;

TextContents::~TextContents() = default;

void TextContents::SetTextFrame(const std::shared_ptr<TextFrame>& frame) {
  frame_ = frame;
}

void TextContents::SetColor(Color color) {
  color_ = color;
}

Color TextContents::GetColor() const {
  return color_.WithAlpha(color_.alpha * inherited_opacity_);
}

void TextContents::SetInheritedOpacity(Scalar opacity) {
  inherited_opacity_ = opacity;
}

void TextContents::SetPosition(Point position) {
  position_ = position;
}

void TextContents::SetScreenTransform(const Matrix& transform) {
  screen_transform_ = transform;
}

void TextContents::SetForceTextColor(bool value) {
  force_text_color_ = value;
}

std::optional<Rect> TextContents::GetCoverage(const Entity& entity) const {
  const Matrix entity_offset_transform =
      entity.GetTransform() * Matrix::MakeTranslation(position_);
  return frame_->GetBounds().TransformBounds(entity_offset_transform);
}

void TextContents::SetTextProperties(
    Color color,
    const std::optional<StrokeParameters>& stroke) {
  if (frame_->HasColor()) {
    // Alpha is always applied when rendering, remove it here so
    // we do not double-apply the alpha.
    properties_.color = color.WithAlpha(1.0);
  }
  properties_.stroke = stroke;
}

namespace {
Scalar AttractToOne(Scalar x) {
  // Epsilon was decided by looking at the floating point inaccuracies in
  // the ScaledK test.
  const Scalar epsilon = 0.005f;
  if (std::abs(x - 1.f) < epsilon) {
    return 1.f;
  }
  if (std::abs(x + 1.f) < epsilon) {
    return -1.f;
  }
  return x;
}

}  // namespace

void TextContents::ComputeVertexData(
    VS::PerVertexData* vtx_contents,
    const Matrix& entity_transform,
    const std::shared_ptr<TextFrame>& frame,
    Point position,
    const Matrix& screen_transform,
    std::optional<GlyphProperties> glyph_properties,
    const std::shared_ptr<GlyphAtlas>& atlas) {
  // Common vertex information for all glyphs.
  // All glyphs are given the same vertex information in the form of a
  // unit-sized quad. The size of the glyph is specified in per instance data
  // and the vertex shader uses this to size the glyph correctly. The
  // interpolated vertex information is also used in the fragment shader to
  // sample from the glyph atlas.

  constexpr std::array<Point, 4> unit_points = {Point{0, 0}, Point{1, 0},
                                                Point{0, 1}, Point{1, 1}};

  Matrix entity_offset_transform =
      entity_transform * Matrix::MakeTranslation(position);

  ISize atlas_size = atlas->GetTexture()->GetSize();
  bool is_translation_scale = entity_offset_transform.IsTranslationScaleOnly();
  Matrix basis_transform = entity_offset_transform.Basis();

  VS::PerVertexData vtx;
  size_t i = 0u;

  const Matrix frame_transform =
      screen_transform * Matrix::MakeTranslation(position);
  Rational rounded_scale =
      TextFrame::RoundScaledFontSize(frame_transform.GetMaxBasisLengthXY());
  Scalar inverted_rounded_scale = static_cast<Scalar>(rounded_scale.Invert());
  Matrix unscaled_basis =
      basis_transform *
      Matrix::MakeScale({inverted_rounded_scale, inverted_rounded_scale, 1});

  // In typical scales < 48x these values should be -1 or 1. We round to
  // those to avoid inaccuracies.
  unscaled_basis.m[0] = AttractToOne(unscaled_basis.m[0]);
  unscaled_basis.m[5] = AttractToOne(unscaled_basis.m[5]);

  // Compute the device origin of the entire frame.
  Point screen_offset = (entity_offset_transform * Point(0, 0));

  for (const TextRun& run : frame->GetRuns()) {
    const Font& font = run.GetFont();
    const ScaledFont scaled_font{.font = font, .scale = rounded_scale};
    const FontGlyphAtlas* font_atlas = atlas->GetFontGlyphAtlas(scaled_font);

    if (!font_atlas) {
      VALIDATION_LOG << "Could not find font in the atlas.";
      // We will not find glyph bounds data for any characters in this run.
      break;
    }

    // Adjust glyph position based on the subpixel rounding used by the font.
    //
    // This value is really only used in the is_translation_scale case below,
    // but that usage appears inside a pair of nested loops so we compute it
    // once here for the common case for use many times below.
    // For the other case, this is a fairly quick computation if we are
    // only doing it just once.
    Point subpixel_adjustment(0.5, 0.5);
    switch (font.GetAxisAlignment()) {
      case AxisAlignment::kNone:
        break;
      case AxisAlignment::kX:
        subpixel_adjustment.x = 0.125;
        break;
      case AxisAlignment::kY:
        subpixel_adjustment.y = 0.125;
        break;
      case AxisAlignment::kAll:
        subpixel_adjustment.x = 0.125;
        subpixel_adjustment.y = 0.125;
        break;
    }

    for (const TextRun::GlyphPosition& glyph_position :
         run.GetGlyphPositions()) {
      SubpixelPosition subpixel = TextFrame::ComputeSubpixelPosition(
          glyph_position, font.GetAxisAlignment(), frame_transform);
      SubpixelGlyph subpixel_glyph(glyph_position.glyph, subpixel,
                                   glyph_properties);
      FrameBounds frame_bounds =
          font_atlas->FindGlyphBounds(subpixel_glyph).value_or(FrameBounds{});

      // If frame_bounds.is_placeholder is true, either this set of attributes
      // were not captured by the FirstPass dispatcher or this is the first
      // frame the glyph has been rendered and so its atlas position was not
      // known when the glyph was recorded. Perform a slow lookup into the
      // glyph atlas hash table.
      if (frame_bounds.is_placeholder) {
        VALIDATION_LOG << "Frame bounds are not present in the atlas "
                       << font_atlas;
        continue;
      }

      // For each glyph, we compute two rectangles. One for the vertex
      // positions and one for the texture coordinates (UVs). The atlas
      // glyph bounds are used to compute UVs in cases where the
      // destination and source sizes may differ due to clamping the sizes
      // of large glyphs.
      Point uv_origin = frame_bounds.atlas_bounds.GetLeftTop() / atlas_size;
      Point uv_size =
          SizeToPoint(frame_bounds.atlas_bounds.GetSize()) / atlas_size;

      for (const Point& point : unit_points) {
        Point position;
        if (is_translation_scale) {
          Point unrounded_glyph_position =
              // This is for RTL text.
              unscaled_basis * frame_bounds.glyph_bounds.GetLeftTop() +
              (basis_transform * glyph_position.position);

          Point screen_glyph_position =
              (screen_offset + unrounded_glyph_position + subpixel_adjustment)
                  .Floor();
          position =
              (screen_glyph_position +
               (unscaled_basis * point * frame_bounds.glyph_bounds.GetSize()))
                  .Round();
        } else {
          Rect scaled_bounds =
              frame_bounds.glyph_bounds.Scale(inverted_rounded_scale);
          position = entity_offset_transform *
                     (glyph_position.position + scaled_bounds.GetLeftTop() +
                      point * scaled_bounds.GetSize());
        }
        vtx.uv = uv_origin + (uv_size * point);
        vtx.position = position;
        vtx_contents[i++] = vtx;
      }
    }
  }
}

bool TextContents::Render(const ContentContext& renderer,
                          const Entity& entity,
                          RenderPass& pass) const {
  Color color = GetColor();
  if (color.IsTransparent()) {
    return true;
  }

  GlyphAtlas::Type type = frame_->GetAtlasType();
  const std::shared_ptr<GlyphAtlas>& atlas =
      renderer.GetLazyGlyphAtlas()->CreateOrGetGlyphAtlas(
          *renderer.GetContext(), renderer.GetTransientsDataBuffer(), type);

  if (!atlas || !atlas->IsValid()) {
    VALIDATION_LOG << "Cannot render glyphs without prepared atlas.";
    return false;
  }

  // Information shared by all glyph draw calls.
  pass.SetCommandLabel("TextFrame");
  auto opts = OptionsFromPassAndEntity(pass, entity);
  opts.primitive_type = PrimitiveType::kTriangle;
  pass.SetPipeline(renderer.GetGlyphAtlasPipeline(opts));

  // Common vertex uniforms for all glyphs.
  VS::FrameInfo frame_info;
  frame_info.mvp =
      Entity::GetShaderTransform(entity.GetShaderClipDepth(), pass, Matrix());
  const Matrix& entity_transform = entity.GetTransform();
  bool is_translation_scale = entity_transform.IsTranslationScaleOnly();

  VS::BindFrameInfo(
      pass, renderer.GetTransientsDataBuffer().EmplaceUniform(frame_info));

  FS::FragInfo frag_info;
  frag_info.use_text_color = force_text_color_ ? 1.0 : 0.0;
  frag_info.text_color = ToVector(color.Premultiply());
  frag_info.is_color_glyph = type == GlyphAtlas::Type::kColorBitmap;

  FS::BindFragInfo(
      pass, renderer.GetTransientsDataBuffer().EmplaceUniform(frag_info));

  SamplerDescriptor sampler_desc;
  if (is_translation_scale) {
    // When the transform is translation+scale only, we normally use nearest-
    // neighbor sampling for pixel-perfect text. However, if the X and Y
    // scales differ significantly (non-uniform / anisotropic scaling, e.g.
    // Transform.scale(scaleY: 2)), the glyph atlas entry is rasterized at
    // max(|scaleX|,|scaleY|) uniformly and the compensating unscaled_basis
    // squeezes one axis, causing a minification. Nearest-neighbor during
    // minification discards texel columns/rows, producing jagged diagonals
    // and varying stroke weights. Fall back to bilinear in that case.
    // See https://github.com/flutter/flutter/issues/182143
    constexpr Scalar kMinScaleForRatio = 0.001f;
    constexpr Scalar kAnisotropicScaleThreshold = 1.15f;
    const Scalar sx = entity_transform.GetBasisX().GetLength();
    const Scalar sy = entity_transform.GetBasisY().GetLength();
    const Scalar ratio = (sx > sy) ? sx / std::max(sy, kMinScaleForRatio)
                                   : sy / std::max(sx, kMinScaleForRatio);
    if (ratio > kAnisotropicScaleThreshold) {
      // Non-uniform scale — use bilinear to avoid aliasing.
      sampler_desc.min_filter = MinMagFilter::kLinear;
      sampler_desc.mag_filter = MinMagFilter::kLinear;
    } else {
      sampler_desc.min_filter = MinMagFilter::kNearest;
      sampler_desc.mag_filter = MinMagFilter::kNearest;
    }
  } else {
    // Currently, we only propagate the scale of the transform to the atlas
    // renderer, so if the transform has more than just a translation, we turn
    // on linear sampling to prevent crunchiness caused by the pixel grid not
    // being perfectly aligned.
    // The downside is that this slightly over-blurs rotated/skewed text.
    sampler_desc.min_filter = MinMagFilter::kLinear;
    sampler_desc.mag_filter = MinMagFilter::kLinear;
  }

  // No mipmaps for glyph atlas (glyphs are generated at exact scales).
  sampler_desc.mip_filter = MipFilter::kBase;

  FS::BindGlyphAtlasSampler(
      pass,                 // command
      atlas->GetTexture(),  // texture
      renderer.GetContext()->GetSamplerLibrary()->GetSampler(
          sampler_desc)  // sampler
  );

  HostBuffer& data_host_buffer = renderer.GetTransientsDataBuffer();
  HostBuffer& indexes_host_buffer = renderer.GetTransientsIndexesBuffer();
  size_t glyph_count = 0;
  for (const auto& run : frame_->GetRuns()) {
    glyph_count += run.GetGlyphPositions().size();
  }
  size_t vertex_count = glyph_count * 4;
  size_t index_count = glyph_count * 6;

  BufferView buffer_view = data_host_buffer.Emplace(
      vertex_count * sizeof(VS::PerVertexData), alignof(VS::PerVertexData),
      [&](uint8_t* data) {
        VS::PerVertexData* vtx_contents =
            reinterpret_cast<VS::PerVertexData*>(data);
        ComputeVertexData(/*vtx_contents=*/vtx_contents,
                          /*entity_transform=*/entity.GetTransform(),
                          /*frame=*/frame_,
                          /*position=*/position_,
                          /*screen_transform=*/screen_transform_,
                          /*glyph_properties=*/GetGlyphProperties(),
                          /*atlas=*/atlas);
      });
  BufferView index_buffer_view = indexes_host_buffer.Emplace(
      index_count * sizeof(uint16_t), alignof(uint16_t), [&](uint8_t* data) {
        uint16_t* indices = reinterpret_cast<uint16_t*>(data);
        size_t j = 0;
        for (auto i = 0u; i < glyph_count; i++) {
          size_t base = i * 4;
          indices[j++] = base + 0;
          indices[j++] = base + 1;
          indices[j++] = base + 2;
          indices[j++] = base + 1;
          indices[j++] = base + 2;
          indices[j++] = base + 3;
        }
      });

  pass.SetVertexBuffer(std::move(buffer_view));
  pass.SetIndexBuffer(index_buffer_view, IndexType::k16bit);
  pass.SetElementCount(index_count);

  return pass.Draw().ok();
}

std::optional<GlyphProperties> TextContents::GetGlyphProperties() const {
  return (properties_.stroke || frame_->HasColor())
             ? std::optional<GlyphProperties>(properties_)
             : std::nullopt;
}

}  // namespace impeller
