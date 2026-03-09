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

  void SetTextFrame(const std::shared_ptr<TextFrame>& frame);

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

  // The position provided in the DrawTextFrame call.
  void SetPosition(Point position);

  // The true screen space transform of the text, ignoring any offsets
  // and adjustments that may be imparted on the text by the rendering
  // context. This value is equivalent to Canvas::GetCurrentTransform()
  // from the DrawTextFrame call.
  void SetScreenTransform(const Matrix& transform);

  // |Contents|
  std::optional<Rect> GetCoverage(const Entity& entity) const override;

  // |Contents|
  bool Render(const ContentContext& renderer,
              const Entity& entity,
              RenderPass& pass) const override;

  /// @brief    Computes the vertex data for the render operation from
  ///           a collection of data drawn from the DrawTextFrame call
  ///           itself and the entity environment.
  ///
  /// vtx_contents       A pointer to the array of PerVertexData to fill.
  /// entity_transform   The transform from the entity which might include
  ///                    offsets due to an intermediate temporary rendering
  ///                    target. This transform is used for final placement
  ///                    of glyphs on the screen.
  /// frame              The TextFrame object from the DrawTextFrame call.
  /// position           The position from the DrawTextFrame call.
  /// screen_transform   The value of Canvas::GetCurrentTransform() from the
  ///                    DrawTextFrame call. It is the full transform of the
  ///                    text relative to screen space and is not adjusted
  ///                    relative to the origin of an intermidate buffer
  ///                    as the entity_transform may be. This transform is
  ///                    used to retrieve metrics and glyph information from
  ///                    the atlas so that the data matches what was stored
  ///                    in the atlas when the global DisplayList did a
  ///                    pre-pass to collect the glyph information.
  /// glyph_properties   The GlyphProperties providing the color and stroke
  ///                    information from the Paint object used in the
  ///                    DrawTextFrame call, optionally and only if they
  ///                    should come into play for rendering the glyphs.
  /// atlas              The glyph atlas containing the glyph texture and
  ///                    placement metrics for all of the glyphs that
  ///                    appear in the TextFrame.
  static void ComputeVertexData(
      GlyphAtlasPipeline::VertexShader::PerVertexData* vtx_contents,
      const Matrix& entity_transform,
      const std::shared_ptr<TextFrame>& frame,
      Point position,
      const Matrix& screen_transform,
      std::optional<GlyphProperties> glyph_properties,
      const std::shared_ptr<GlyphAtlas>& atlas);

 private:
  std::optional<GlyphProperties> GetGlyphProperties() const;

  std::shared_ptr<TextFrame> frame_;
  Scalar inherited_opacity_ = 1.0;
  Point position_;
  Matrix screen_transform_;
  bool force_text_color_ = false;
  Color color_;
  GlyphProperties properties_;

  TextContents(const TextContents&) = delete;

  TextContents& operator=(const TextContents&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_CONTENTS_TEXT_CONTENTS_H_
