// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_CONTENTS_TEXT_CONTENTS_H_
#define FLUTTER_IMPELLER_ENTITY_CONTENTS_TEXT_CONTENTS_H_

#include <memory>

#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/contents/contents.h"
#include "impeller/entity/contents/pipelines.h"
#include "impeller/geometry/color.h"
#include "impeller/geometry/stroke_parameters.h"
#include "impeller/typographer/font_glyph_pair.h"
#include "impeller/typographer/text_frame.h"

namespace impeller {

class LazyGlyphAtlas;
class Context;

class TextContents final : public Contents {
 public:
  TextContents();

  ~TextContents();

  void SetTextFrame(const std::shared_ptr<RenderTextFrame>& render_frame);

  void SetColor(Color color);

  /// @brief Force the text color to apply to the rendered glyphs, even if those
  ///        glyphs are bitmaps.
  ///
  ///        This is used to ensure that mask blurs work correctly on emoji.
  void SetForceTextColor(bool value);

  /// Must be set after text frame.
  void SetTextProperties(Color color,
                         const std::optional<StrokeParameters>& stroke);

  Color GetColor() const;

  // |Contents|
  void SetInheritedOpacity(Scalar opacity) override;

  std::optional<Rect> GetTextFrameBounds() const;

  // |Contents|
  std::optional<Rect> GetCoverage(const Entity& entity) const override;

  // |Contents|
  bool Render(const ContentContext& renderer,
              const Entity& entity,
              RenderPass& pass) const override;

  static void ComputeVertexData(
      GlyphAtlasPipeline::VertexShader::PerVertexData* vtx_contents,
      const std::shared_ptr<RenderTextFrame>& render_frame,
      const Matrix& entity_transform,
      std::optional<GlyphProperties> glyph_properties,
      const std::shared_ptr<GlyphAtlas>& atlas);

 private:
  std::optional<GlyphProperties> GetGlyphProperties() const;

  std::shared_ptr<RenderTextFrame> render_frame_;
  Scalar inherited_opacity_ = 1.0;
  bool force_text_color_ = false;
  Color color_;
  GlyphProperties properties_;

  TextContents(const TextContents&) = delete;

  TextContents& operator=(const TextContents&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_CONTENTS_TEXT_CONTENTS_H_
