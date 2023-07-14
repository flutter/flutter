// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/color_source_text_contents.h"

#include "color_source_text_contents.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/contents/texture_contents.h"
#include "impeller/renderer/render_pass.h"

namespace impeller {

ColorSourceTextContents::ColorSourceTextContents() = default;

ColorSourceTextContents::~ColorSourceTextContents() = default;

void ColorSourceTextContents::SetTextContents(
    std::shared_ptr<TextContents> text_contents) {
  text_contents_ = std::move(text_contents);
}

void ColorSourceTextContents::SetColorSourceContents(
    std::shared_ptr<ColorSourceContents> color_source_contents) {
  color_source_contents_ = std::move(color_source_contents);
}

std::optional<Rect> ColorSourceTextContents::GetCoverage(
    const Entity& entity) const {
  return text_contents_->GetCoverage(entity);
}

void ColorSourceTextContents::SetTextPosition(Point position) {
  position_ = position;
}

void ColorSourceTextContents::PopulateGlyphAtlas(
    const std::shared_ptr<LazyGlyphAtlas>& lazy_glyph_atlas,
    Scalar scale) {
  text_contents_->PopulateGlyphAtlas(lazy_glyph_atlas, scale);
}

bool ColorSourceTextContents::Render(const ContentContext& renderer,
                                     const Entity& entity,
                                     RenderPass& pass) const {
  auto text_bounds = text_contents_->GetTextFrameBounds();
  if (!text_bounds.has_value()) {
    return true;
  }

  text_contents_->SetColor(Color::Black());
  color_source_contents_->SetGeometry(
      Geometry::MakeRect(Rect::MakeSize(text_bounds->size)));

  // offset the color source so it behaves as if it were drawn in the original
  // position.
  auto effect_transform =
      color_source_contents_->GetInverseEffectTransform().Invert().Translate(
          -position_);
  color_source_contents_->SetEffectTransform(effect_transform);

  auto new_texture = renderer.MakeSubpass(
      "Text Color Blending", ISize::Ceil(text_bounds.value().size),
      [&](const ContentContext& context, RenderPass& pass) {
        Entity sub_entity;
        sub_entity.SetContents(text_contents_);
        sub_entity.SetBlendMode(BlendMode::kSource);
        if (!sub_entity.Render(context, pass)) {
          return false;
        }

        sub_entity.SetContents(color_source_contents_);
        sub_entity.SetBlendMode(BlendMode::kSourceIn);
        return sub_entity.Render(context, pass);
      });
  if (!new_texture) {
    return false;
  }

  auto dest_rect = Rect::MakeSize(new_texture->GetSize()).Shift(position_);

  auto texture_contents = TextureContents::MakeRect(dest_rect);
  texture_contents->SetTexture(new_texture);
  texture_contents->SetSourceRect(Rect::MakeSize(new_texture->GetSize()));
  return texture_contents->Render(renderer, entity, pass);
}

}  // namespace impeller
