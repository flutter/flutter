// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_CONTENTS_TEXT_CONTENTS_H_
#define FLUTTER_IMPELLER_ENTITY_CONTENTS_TEXT_CONTENTS_H_

#include <memory>

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

  void SetTextFrame(const std::shared_ptr<TextFrame>& frame);

  void SetColor(Color color);

  /// @brief Force the text color to apply to the rendered glyphs, even if those
  ///        glyphs are bitmaps.
  ///
  ///        This is used to ensure that mask blurs work correctly on emoji.
  void SetForceTextColor(bool value);

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
  std::shared_ptr<TextFrame> frame_;
  Scalar scale_ = 1.0;
  Color color_;
  Scalar inherited_opacity_ = 1.0;
  Vector2 offset_;
  bool force_text_color_ = false;

  TextContents(const TextContents&) = delete;

  TextContents& operator=(const TextContents&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_CONTENTS_TEXT_CONTENTS_H_
