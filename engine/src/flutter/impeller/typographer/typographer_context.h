// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_TYPOGRAPHER_TYPOGRAPHER_CONTEXT_H_
#define FLUTTER_IMPELLER_TYPOGRAPHER_TYPOGRAPHER_CONTEXT_H_

#include <memory>

#include "impeller/renderer/context.h"
#include "impeller/typographer/glyph_atlas.h"
#include "impeller/typographer/text_frame.h"

namespace impeller {

/// The data associated with a single rendering instance of a TextFrame,
/// used to pre-load the glyph atlas with glyph and bounds information.
struct RenderableText {
  /// The TextFrame being rendered.
  const std::shared_ptr<TextFrame> text_frame;

  /// The transform that places the origin of the TextFrame within screen
  /// space. This is the current transform (ctm) of the graphics context
  /// translated by the local space position of the TextFrame.
  const Matrix origin_transform;

  /// The properties needed for rendering stroked text and/or the color
  /// needed to cache a TextFrame where HasColor() == true.
  const std::optional<GlyphProperties> properties;
};

//------------------------------------------------------------------------------
/// @brief      The graphics context necessary to render text.
///
///             This is necessary to create and reference resources related to
///             rendering text on the GPU.
///
class TypographerContext {
 public:
  virtual ~TypographerContext();

  virtual bool IsValid() const;

  virtual std::shared_ptr<GlyphAtlasContext> CreateGlyphAtlasContext(
      GlyphAtlas::Type type) const = 0;

  virtual std::shared_ptr<GlyphAtlas> CreateGlyphAtlas(
      Context& context,
      GlyphAtlas::Type type,
      HostBuffer& host_buffer,
      const std::shared_ptr<GlyphAtlasContext>& atlas_context,
      const std::vector<RenderableText>& text_frames) const = 0;

 protected:
  //----------------------------------------------------------------------------
  /// @brief      Create a new context to render text that talks to an
  ///             underlying graphics context.
  ///
  TypographerContext();

 private:
  bool is_valid_ = false;

  TypographerContext(const TypographerContext&) = delete;

  TypographerContext& operator=(const TypographerContext&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_TYPOGRAPHER_TYPOGRAPHER_CONTEXT_H_
