// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <functional>
#include <memory>
#include <variant>
#include <vector>

#include "flutter/fml/macros.h"
#include "impeller/entity/contents/contents.h"
#include "impeller/geometry/color.h"
#include "impeller/typographer/glyph_atlas.h"
#include "impeller/typographer/text_frame.h"

namespace impeller {

class LazyGlyphAtlas;
class Context;

class TextContents final : public Contents {
 public:
  TextContents();

  ~TextContents();

  void SetTextFrame(const TextFrame& frame);

  void SetColor(Color color);

  Color GetColor() const;

  // |Contents|
  bool CanInheritOpacity(const Entity& entity) const override;

  // |Contents|
  void SetInheritedOpacity(Scalar opacity) override;

  void SetOffset(Vector2 offset);

  std::optional<Rect> GetTextFrameBounds() const;

  // |Contents|
  std::optional<Rect> GetCoverage(const Entity& entity) const override;

  // |Contents|
  void PopulateGlyphAtlas(
      const std::shared_ptr<LazyGlyphAtlas>& lazy_glyph_atlas,
      Scalar scale) override;

  // |Contents|
  bool Render(const ContentContext& renderer,
              const Entity& entity,
              RenderPass& pass) const override;

 private:
  TextFrame frame_;
  Scalar scale_ = 1.0;
  Color color_;
  Scalar inherited_opacity_ = 1.0;
  Vector2 offset_;

  std::shared_ptr<GlyphAtlas> ResolveAtlas(
      GlyphAtlas::Type type,
      const std::shared_ptr<LazyGlyphAtlas>& lazy_atlas,
      std::shared_ptr<GlyphAtlasContext> atlas_context,
      std::shared_ptr<Context> context) const;

  FML_DISALLOW_COPY_AND_ASSIGN(TextContents);
};

}  // namespace impeller
